// lib/screens/search/models/search_filters.dart
// Modele des filtres de recherche avances ExamBoost Togo.
//
// Regroupe en une seule classe tous les criteres de recherche possibles :
//   - keyword (recherche full-text dans enonce / explication / chapitre / matiere)
//   - matiere, examen, serie (selection par categorie)
//   - yearFrom / yearTo (intervalle d'annees)
//   - type (enum QuestionType : calcul, ouvert, qcm, vraiFaux, redaction)
//   - difficultyRange (facile / moyen / difficile / tous — base sur irtB)
//   - pointsMin (note minimale 1-5)
//   - onlyFavorites / onlyNotMastered (booleens — branchement Agent AN)
//   - sortBy + sortAscending (7 options de tri)
//
// Ce modele n'EST PAS un @HiveType (pas besoin de codegen) : il est embarque
// dans SavedSearch qui le serialise en JSON. La methode toJson/fromJson
// permet la persistance dans Hive box<String>('saved_searches').

import '../../../models/question.dart';

// ─── Enums de filtrage ──────────────────────────────────────────────────

/// Plage de difficulte (basee sur le parametre IRT b — q.irtB).
/// Seuils coherents avec Question.difficulte :
///   - facile   : b < -0.5
///   - moyen    : -0.5 <= b < 0.8
///   - difficile : b >= 0.8
enum DifficultyRange {
  tous,
  facile,
  moyen,
  difficile;

  String get label => switch (this) {
        tous => 'Tous niveaux',
        facile => 'Facile',
        moyen => 'Moyen',
        difficile => 'Difficile',
      };
}

/// Critere de tri des resultats.
/// 7 options : pertinence, difficulte (asc/desc), annee (recentes/anciennes),
/// points (haut/bas).
enum SortBy {
  relevance,
  difficultyAsc,
  difficultyDesc,
  yearNewest,
  yearOldest,
  pointsHigh,
  pointsLow;

  String get label => switch (this) {
        relevance => 'Pertinence',
        difficultyAsc => 'Difficulte (facile -> difficile)',
        difficultyDesc => 'Difficulte (difficile -> facile)',
        yearNewest => 'Annee (recentes en premier)',
        yearOldest => 'Annee (anciennes en premier)',
        pointsHigh => 'Points (eleves en premier)',
        pointsLow => 'Points (faibles en premier)',
      };

  /// Indique si le tri par defaut (sans inversion) est croissant.
  bool get defaultAscending => switch (this) {
        relevance => false, // pertinence = descendant (meilleur score en premier)
        difficultyAsc => true,
        difficultyDesc => false,
        yearNewest => false,
        yearOldest => true,
        pointsHigh => false,
        pointsLow => true,
      };
}

// ─── Modele principal ──────────────────────────────────────────────────

class SearchFilters {
  /// Mot-cle full-text (recherche dans enonce, explication, chapitre, matiere).
  /// Null ou vide = pas de filtre keyword.
  final String? keyword;

  /// Matiere : "Mathematiques", "Francais", "Sciences Physiques", "SVT",
  /// "Histoire-Geographie", "Anglais".
  final String? matiere;

  /// Examen : "BEPC", "BAC1", "BAC2", "Probatoire".
  final String? examen;

  /// Serie : "A", "B", "C", "D", "F". Null pour BEPC.
  final String? serie;

  /// Annee minimale (inclusive).
  final int? yearFrom;

  /// Annee maximale (inclusive).
  final int? yearTo;

  /// Type de question (calcul, ouvert, qcm, vraiFaux, redaction).
  final QuestionType? type;

  /// Plage de difficulte (facile / moyen / difficile / tous).
  final DifficultyRange? difficultyRange;

  /// Points minimum (1-5).
  final int? pointsMin;

  /// Restreindre aux questions marquees comme favorites (cf Agent AN).
  /// Null = pas de filtre favori.
  final bool? onlyFavorites;

  /// Restreindre aux questions pas encore maitrisees (P(L) < 0.85 en BKT).
  /// Null = pas de filtre maitrise.
  final bool? onlyNotMastered;

  /// Critere de tri des resultats.
  final SortBy sortBy;

  /// Ordre de tri ascendant (true) ou descendant (false).
  /// Pour sortBy == relevance, ce champ est ignore (toujours descendant).
  final bool sortAscending;

  const SearchFilters({
    this.keyword,
    this.matiere,
    this.examen,
    this.serie,
    this.yearFrom,
    this.yearTo,
    this.type,
    this.difficultyRange,
    this.pointsMin,
    this.onlyFavorites,
    this.onlyNotMastered,
    this.sortBy = SortBy.relevance,
    this.sortAscending = false,
  });

  /// Filtres par defaut (vierge).
  static SearchFilters get empty => const SearchFilters();

  /// Indique si au moins un filtre est actif (hors tri qui s'applique
  /// meme sans filtre). Le tri seul ne compte pas comme "filtre actif"
  /// car il n'elimine aucune question — il reorganise juste la liste.
  bool get hasActiveFilters {
    return (keyword != null && keyword!.isNotEmpty) ||
        matiere != null ||
        examen != null ||
        serie != null ||
        yearFrom != null ||
        yearTo != null ||
        type != null ||
        (difficultyRange != null && difficultyRange != DifficultyRange.tous) ||
        pointsMin != null ||
        onlyFavorites == true ||
        onlyNotMastered == true;
  }

  /// Nombre de filtres actifs (hors tri). Sert pour le badge "X filtres".
  int get activeFilterCount {
    int count = 0;
    if (keyword != null && keyword!.isNotEmpty) count++;
    if (matiere != null) count++;
    if (examen != null) count++;
    if (serie != null) count++;
    if (yearFrom != null || yearTo != null) count++;
    if (type != null) count++;
    if (difficultyRange != null && difficultyRange != DifficultyRange.tous) {
      count++;
    }
    if (pointsMin != null) count++;
    if (onlyFavorites == true) count++;
    if (onlyNotMastered == true) count++;
    return count;
  }

  /// Cree une copie avec certains champs modifies.
  SearchFilters copyWith({
    String? keyword,
    String? matiere,
    String? examen,
    String? serie,
    int? yearFrom,
    int? yearTo,
    QuestionType? type,
    DifficultyRange? difficultyRange,
    int? pointsMin,
    bool? onlyFavorites,
    bool? onlyNotMastered,
    SortBy? sortBy,
    bool? sortAscending,
    bool clearKeyword = false,
    bool clearMatiere = false,
    bool clearExamen = false,
    bool clearSerie = false,
    bool clearYearFrom = false,
    bool clearYearTo = false,
    bool clearType = false,
    bool clearDifficulty = false,
    bool clearPointsMin = false,
    bool clearOnlyFavorites = false,
    bool clearOnlyNotMastered = false,
  }) {
    return SearchFilters(
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      matiere: clearMatiere ? null : (matiere ?? this.matiere),
      examen: clearExamen ? null : (examen ?? this.examen),
      serie: clearSerie ? null : (serie ?? this.serie),
      yearFrom: clearYearFrom ? null : (yearFrom ?? this.yearFrom),
      yearTo: clearYearTo ? null : (yearTo ?? this.yearTo),
      type: clearType ? null : (type ?? this.type),
      difficultyRange:
          clearDifficulty ? null : (difficultyRange ?? this.difficultyRange),
      pointsMin: clearPointsMin ? null : (pointsMin ?? this.pointsMin),
      onlyFavorites:
          clearOnlyFavorites ? null : (onlyFavorites ?? this.onlyFavorites),
      onlyNotMastered: clearOnlyNotMastered
          ? null
          : (onlyNotMastered ?? this.onlyNotMastered),
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Serialisation JSON pour persistance Hive (box<String>) et
  /// pour passer dans state.extra de GoRouter.
  Map<String, dynamic> toJson() => {
        'keyword': keyword,
        'matiere': matiere,
        'examen': examen,
        'serie': serie,
        'yearFrom': yearFrom,
        'yearTo': yearTo,
        'type': type?.name,
        'difficultyRange': difficultyRange?.name,
        'pointsMin': pointsMin,
        'onlyFavorites': onlyFavorites,
        'onlyNotMastered': onlyNotMastered,
        'sortBy': sortBy.name,
        'sortAscending': sortAscending,
      };

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      keyword: json['keyword'] as String?,
      matiere: json['matiere'] as String?,
      examen: json['examen'] as String?,
      serie: json['serie'] as String?,
      yearFrom: json['yearFrom'] as int?,
      yearTo: json['yearTo'] as int?,
      type: json['type'] != null
          ? QuestionType.values.byName(json['type'] as String)
          : null,
      difficultyRange: json['difficultyRange'] != null
          ? DifficultyRange.values.byName(json['difficultyRange'] as String)
          : null,
      pointsMin: json['pointsMin'] as int?,
      onlyFavorites: json['onlyFavorites'] as bool?,
      onlyNotMastered: json['onlyNotMastered'] as bool?,
      sortBy: json['sortBy'] != null
          ? SortBy.values.byName(json['sortBy'] as String)
          : SortBy.relevance,
      sortAscending: (json['sortAscending'] as bool?) ?? false,
    );
  }

  /// Representation textuelle des filtres actifs pour affichage en chips
  /// dans SavedSearchesSection. Retourne une liste de labels courts.
  List<String> get activeFilterLabels {
    final labels = <String>[];
    if (keyword != null && keyword!.isNotEmpty) {
      labels.add('"${keyword!.length > 18 ? '${keyword!.substring(0, 15)}...' : keyword!}"');
    }
    if (matiere != null) labels.add(matiere!);
    if (examen != null) labels.add(examen!);
    if (serie != null) labels.add('Serie $serie');
    if (yearFrom != null || yearTo != null) {
      final from = yearFrom ?? 2010;
      final to = yearTo ?? 2024;
      labels.add('$from-$to');
    }
    if (type != null) {
      labels.add(_typeLabel(type!));
    }
    if (difficultyRange != null && difficultyRange != DifficultyRange.tous) {
      labels.add(difficultyRange!.label);
    }
    if (pointsMin != null) labels.add('>= $pointsMin pts');
    if (onlyFavorites == true) labels.add('Favoris');
    if (onlyNotMastered == true) labels.add('Non maitrise');
    return labels;
  }

  String _typeLabel(QuestionType t) {
    return switch (t) {
      QuestionType.calcul => 'Calcul',
      QuestionType.ouvert => 'Ouvert',
      QuestionType.qcm => 'QCM',
      QuestionType.vraiFaux => 'Vrai/Faux',
      QuestionType.redaction => 'Redaction',
    };
  }

  @override
  String toString() =>
      'SearchFilters(keyword: $keyword, matiere: $matiere, examen: $examen, '
      'serie: $serie, year: $yearFrom-$yearTo, type: $type, '
      'difficulty: $difficultyRange, pointsMin: $pointsMin, '
      'fav: $onlyFavorites, notMastered: $onlyNotMastered, '
      'sortBy: $sortBy, asc: $sortAscending)';
}
