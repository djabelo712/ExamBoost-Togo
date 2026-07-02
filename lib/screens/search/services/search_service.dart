// lib/screens/search/services/search_service.dart
// Service de recherche full-text + filtres multiples sur la banque de
// questions ExamBoost Togo.
//
// Architecture :
//   - Source de donnees : QuestionService (deja expose via Provider global).
//     Comme QuestionService ne possede pas de getter public `allQuestions`,
//     on recombine la liste via `matieres` + `getByMatiere` (sans toucher
//     au service existant — contrainte Session 3).
//   - Pipeline de recherche (SearchFilters -> List<Question>) :
//       1. Filtre keyword (full-text sur enonce + explication + chapitre + matiere)
//       2. Filtre matiere (egalite exacte)
//       3. Filtre examen (egalite exacte)
//       4. Filtre serie (egalite exacte — null pour BEPC)
//       5. Filtre yearFrom / yearTo (intervalle inclusif)
//       6. Filtre type (enum QuestionType)
//       7. Filtre difficultyRange (basé sur irtB — seuils -0.5 / 0.8)
//       8. Filtre pointsMin (>= seuil)
//       9. Filtre onlyFavorites (booleen — necessite un Set<String> de favoris,
//          fourni par l'Agent AN via une box Hive "question_favorites")
//      10. Filtre onlyNotMastered (P(L) < 0.85 — necessite un Map<String,double>
//          bktMaitrise, fourni par AppUser)
//      11. Tri (7 options — relevance, difficulty, year, points)
//   - Suggestions : chapitres correspondant au keyword en cours de saisie.
//   - Sauvegarde : box Hive "saved_searches" (box<String> + JSON).
//
// Decisions cles :
//   - Pas de dependance externe (pas de FTS SQLite, pas d'Elasticsearch) :
//     la recherche full-text est faite en Dart sur la liste en memoire.
//     Suffisant pour <= 1000 questions (64 actuellement, cible 5000+).
//   - Le score de pertinence est simple : 10 pts pour une correspondance
//     dans l'enonce, 5 dans le chapitre, 3 dans l'explication, 1 dans la
//     matiere. On pourrait etendre (TF-IDF, BM25) quand on passera au
//     backend.

import 'dart:convert';
import 'dart:math';

import 'package:hive/hive.dart';

import '../../../models/question.dart';
import '../../../services/question_service.dart';
import '../models/saved_search.dart';
import '../models/search_filters.dart';

class SearchService {
  SearchService({required QuestionService questionService})
      : _questionService = questionService;

  final QuestionService _questionService;

  // ─── Cache de la liste complete des questions ───────────────────────
  // Recombiner via matieres + getByMatiere (QuestionService ne possede pas
  // de getter public allQuestions — on ne peut pas modifier ce service).
  List<Question> _allQuestionsCache = const [];
  bool _cacheBuilt = false;

  /// Liste complete des questions (construite une fois, mise en cache).
  List<Question> get allQuestions {
    if (_cacheBuilt) return _allQuestionsCache;
    final matieres = _questionService.matieres;
    final Map<String, Question> uniq = {}; // dedoublonnage par id
    for (final m in matieres) {
      for (final q in _questionService.getByMatiere(m)) {
        uniq[q.id] = q;
      }
    }
    _allQuestionsCache = uniq.values.toList();
    _cacheBuilt = true;
    return _allQuestionsCache;
  }

  // ─── Recherche principale ───────────────────────────────────────────

  /// Applique les filtres et le tri sur la liste complete.
  /// [favoriteIds] : IDs des questions favorites (pour onlyFavorites).
  /// [maitriseMap] : competenceId -> P(L) (pour onlyNotMastered).
  List<Question> search(
    SearchFilters filters, {
    Set<String>? favoriteIds,
    Map<String, double>? maitriseMap,
  }) {
    var results = allQuestions.toList();

    // 1. Filtre keyword (full-text dans enonce + explication + chapitre + matiere)
    if (filters.keyword != null && filters.keyword!.trim().isNotEmpty) {
      final kw = filters.keyword!.toLowerCase().trim();
      results = results.where((q) {
        return q.enonce.toLowerCase().contains(kw) ||
            (q.explication?.toLowerCase().contains(kw) ?? false) ||
            q.chapitre.toLowerCase().contains(kw) ||
            q.matiere.toLowerCase().contains(kw);
      }).toList();
    }

    // 2. Filtre matiere
    if (filters.matiere != null) {
      results = results.where((q) => q.matiere == filters.matiere).toList();
    }

    // 3. Filtre examen
    if (filters.examen != null) {
      results = results.where((q) => q.examen == filters.examen).toList();
    }

    // 4. Filtre serie
    if (filters.serie != null) {
      results = results.where((q) => q.serie == filters.serie).toList();
    }

    // 5. Filtre annee (intervalle inclusif)
    if (filters.yearFrom != null) {
      results = results
          .where((q) => q.annee != null && q.annee! >= filters.yearFrom!)
          .toList();
    }
    if (filters.yearTo != null) {
      results = results
          .where((q) => q.annee != null && q.annee! <= filters.yearTo!)
          .toList();
    }

    // 6. Filtre type
    if (filters.type != null) {
      results = results.where((q) => q.type == filters.type).toList();
    }

    // 7. Filtre difficulte (basé sur irtB — seuils -0.5 / 0.8)
    if (filters.difficultyRange != null &&
        filters.difficultyRange != DifficultyRange.tous) {
      results = results.where((q) {
        final b = q.irtB ?? 0.0;
        switch (filters.difficultyRange!) {
          case DifficultyRange.facile:
            return b < -0.5;
          case DifficultyRange.moyen:
            return b >= -0.5 && b < 0.8;
          case DifficultyRange.difficile:
            return b >= 0.8;
          case DifficultyRange.tous:
            return true;
        }
      }).toList();
    }

    // 8. Filtre points minimum
    if (filters.pointsMin != null) {
      results =
          results.where((q) => (q.points ?? 0) >= filters.pointsMin!).toList();
    }

    // 9. Filtre favoris (seulement si onlyFavorites == true)
    if (filters.onlyFavorites == true) {
      final favs = favoriteIds ?? const <String>{};
      results = results.where((q) => favs.contains(q.id)).toList();
    }

    // 10. Filtre "pas encore maitrise" (P(L) < 0.85 par competence)
    if (filters.onlyNotMastered == true) {
      final maitrise = maitriseMap ?? const <String, double>{};
      results = results.where((q) {
        final pl = maitrise[q.competenceId] ?? 0.0;
        return pl < 0.85;
      }).toList();
    }

    // 11. Tri
    _applySort(results, filters);

    return results;
  }

  void _applySort(List<Question> results, SearchFilters filters) {
    switch (filters.sortBy) {
      case SortBy.relevance:
        // Si keyword present : tri par score de pertinence (descendant).
        // Sinon : ordre par defaut (garder l'ordre original).
        if (filters.keyword != null && filters.keyword!.trim().isNotEmpty) {
          results.sort(
            (a, b) => _relevanceScore(b, filters.keyword!)
                .compareTo(_relevanceScore(a, filters.keyword!)),
          );
        }
        // sortAscending ignore pour relevance (toujours descendant).
        break;
      case SortBy.difficultyAsc:
        results.sort((a, b) => (a.irtB ?? 0).compareTo(b.irtB ?? 0));
        if (!filters.sortAscending) results = results.reversed.toList();
        break;
      case SortBy.difficultyDesc:
        results.sort((a, b) => (b.irtB ?? 0).compareTo(a.irtB ?? 0));
        if (!filters.sortAscending) results = results.reversed.toList();
        break;
      case SortBy.yearNewest:
        results.sort((a, b) => (b.annee ?? 0).compareTo(a.annee ?? 0));
        if (!filters.sortAscending) results = results.reversed.toList();
        break;
      case SortBy.yearOldest:
        results.sort((a, b) => (a.annee ?? 0).compareTo(b.annee ?? 0));
        if (!filters.sortAscending) results = results.reversed.toList();
        break;
      case SortBy.pointsHigh:
        results.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));
        if (!filters.sortAscending) results = results.reversed.toList();
        break;
      case SortBy.pointsLow:
        results.sort((a, b) => (a.points ?? 0).compareTo(b.points ?? 0));
        if (!filters.sortAscending) results = results.reversed.toList();
        break;
    }
  }

  /// Score de pertinence d'une question pour un mot-cle donne.
  /// Pondération :
  ///   - +10 si le keyword est dans l'enonce (champ principal)
  ///   - +5  si le keyword est dans le chapitre (titre court, fort signal)
  ///   - +3  si le keyword est dans l'explication (secondaire)
  ///   - +1  si le keyword est dans la matiere (tres permissif)
  int _relevanceScore(Question q, String keyword) {
    int score = 0;
    final kw = keyword.toLowerCase().trim();
    if (kw.isEmpty) return 0;
    if (q.enonce.toLowerCase().contains(kw)) score += 10;
    if (q.chapitre.toLowerCase().contains(kw)) score += 5;
    if (q.explication?.toLowerCase().contains(kw) ?? false) score += 3;
    if (q.matiere.toLowerCase().contains(kw)) score += 1;
    return score;
  }

  // ─── Suggestions de mots-cles ───────────────────────────────────────

  /// Retourne les chapitres qui correspondent a la saisie partielle.
  /// Utilise pour l'autocompletion dans la barre de recherche.
  /// Limite a 5 suggestions pour ne pas surcharger l'UI.
  List<String> getKeywordSuggestions(String query) {
    if (query.trim().isEmpty) return const [];
    final q = query.toLowerCase().trim();
    final chapters = <String>{};
    for (final c in allQuestions) {
      chapters.add(c.chapitre);
    }
    final matches = chapters.where((c) => c.toLowerCase().contains(q)).toList()
      ..sort();
    return matches.take(5).toList();
  }

  /// Retourne les matieres disponibles (pour les ChoiceChips du bottom sheet).
  List<String> get availableMatieres {
    final matieres = <String>{};
    for (final q in allQuestions) {
      matieres.add(q.matiere);
    }
    final list = matieres.toList()..sort();
    return list;
  }

  /// Retourne les examens disponibles (pour les ChoiceChips du bottom sheet).
  List<String> get availableExamens {
    final examens = <String>{};
    for (final q in allQuestions) {
      examens.add(q.examen);
    }
    final list = examens.toList()..sort();
    return list;
  }

  /// Retourne les series disponibles (pour les ChoiceChips du bottom sheet).
  List<String> get availableSeries {
    final series = <String>{};
    for (final q in allQuestions) {
      if (q.serie != null) series.add(q.serie!);
    }
    final list = series.toList()..sort();
    return list;
  }

  /// Retourne l'annee minimale et maximale dans la base (pour les sliders).
  ({int min, int max}) get yearRange {
    if (allQuestions.isEmpty) return (min: 2010, max: 2024);
    int minYear = 9999;
    int maxYear = 0;
    for (final q in allQuestions) {
      final y = q.annee;
      if (y == null) continue;
      if (y < minYear) minYear = y;
      if (y > maxYear) maxYear = y;
    }
    if (minYear == 9999) minYear = 2010;
    if (maxYear == 0) maxYear = 2024;
    return (min: minYear, max: maxYear);
  }

  /// Recupere une "page" de questions populaires pour la section Suggestions.
  /// On simule la popularite par un tirage pseudo-aleatoire avec seed fixe
  /// (pour stabilite entre les runs). Pour la V2 backend, on utilisera un
  /// vrai score de popularite (nb de revisions, taux de reussite, etc.).
  List<Question> getPopularQuestions({int limit = 6, int seed = 42}) {
    final rng = Random(seed);
    final pool = allQuestions.toList()..shuffle(rng);
    return pool.take(limit).toList();
  }

  // ─── Sauvegarde des recherches favorites ────────────────────────────
  //
  // Persistance via Hive.box<String>('saved_searches') :
  //   - cle : SavedSearch.id
  //   - valeur : jsonEncode(SavedSearch.toJson())
  // Aucun adapter n'est necessaire (box<String> natif Hive).

  static const String _boxName = 'saved_searches';

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  /// Liste toutes les recherches sauvegardees, triees par date de creation
  /// (la plus recente en premier).
  Future<List<SavedSearch>> getAllSavedSearches() async {
    try {
      final box = await _openBox();
      final list = <SavedSearch>[];
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw == null) continue;
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          list.add(SavedSearch.fromJson(json));
        } catch (_) {
          // Entrée corrompue — on l'ignore (sans crash).
          continue;
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Sauvegarde (ou met a jour) une recherche.
  /// Genere un id si vide. Met a jour resultCount si fourni.
  Future<SavedSearch> saveSearch({
    required String name,
    required SearchFilters filters,
    int? resultCount,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final saved = SavedSearch(
      id: id,
      name: name,
      filters: filters,
      createdAt: DateTime.now(),
      resultCount: resultCount ?? 0,
    );
    final box = await _openBox();
    await box.put(id, jsonEncode(saved.toJson()));
    return saved;
  }

  /// Met a jour le nombre de resultats d'une recherche sauvegardee
  /// (appele quand l'utilisateur re-execute la recherche).
  Future<void> updateResultCount(String id, int newCount) async {
    try {
      final box = await _openBox();
      final raw = box.get(id);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final saved = SavedSearch.fromJson(json);
      final updated = saved.copyWith(resultCount: newCount);
      await box.put(id, jsonEncode(updated.toJson()));
    } catch (_) {
      // Mise a jour non bloquante.
    }
  }

  /// Renomme une recherche sauvegardee.
  Future<void> renameSearch(String id, String newName) async {
    try {
      final box = await _openBox();
      final raw = box.get(id);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final saved = SavedSearch.fromJson(json);
      final updated = saved.copyWith(name: newName);
      await box.put(id, jsonEncode(updated.toJson()));
    } catch (_) {
      // Renommage non bloquant.
    }
  }

  /// Supprime une recherche sauvegardee.
  Future<void> deleteSearch(String id) async {
    try {
      final box = await _openBox();
      await box.delete(id);
    } catch (_) {
      // Suppression non bloquante.
    }
  }

  /// Compte le nombre de recherches sauvegardees (pour badge home).
  Future<int> get savedSearchesCount async {
    try {
      final box = await _openBox();
      return box.length;
    } catch (_) {
      return 0;
    }
  }
}
