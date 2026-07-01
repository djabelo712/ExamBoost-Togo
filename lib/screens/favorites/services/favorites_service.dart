// lib/screens/favorites/services/favorites_service.dart
// Service de gestion des favoris + notes personnelles sur les questions.
//
// Persistance : Hive (offline-first). Deux boxes :
//   - "favorite_questions" : Box<FavoriteQuestion>
//   - "question_notes"     : Box<QuestionNote>
//
// API publique :
//   - init()                       : ouvrir les boxes (au demarrage app)
//   - isFavorite(userId, qId)      : boolean
//   - toggleFavorite(userId, qId)  : ajout ou retrait (idempotent)
//   - getFavoriteIds(userId)       : List<String>
//   - getFavorites(userId)         : List<FavoriteQuestion> (avec date)
//   - getNote(userId, qId)         : QuestionNote? (1 par couple user×question)
//   - saveNote(...)                : create or update
//   - deleteNote(userId, qId)      : remove note
//   - getAllNotes(userId)          : List<QuestionNote> triees par updatedAt desc
//   - exportNotesAsText(userId)    : String (export ASCII pour partage)
//
// Le service est un ChangeNotifier pour que les ecrans favoris/notes
// recompilent automatiquement quand une entree change. On l'enregistre
// comme ChangeNotifierProvider<FavoritesService> dans main.dart (voir
// README.md pour le snippet d'integration).

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/favorite_question.dart';
import '../models/question_note.dart';

class FavoritesService extends ChangeNotifier {
  static const String _favBoxName = 'favorite_questions';
  static const String _noteBoxName = 'question_notes';

  // Lazy-ouverture : les boxes sont null avant init(). On garde les
  // late final pour beneficier du check au runtime si on oublie d'appeler
  // init() (plutot qu'un NullPointer silencieux).
  late Box<FavoriteQuestion> _favBox;
  late Box<QuestionNote> _noteBox;
  bool _initialized = false;

  /// True si init() a ete appele avec succes.
  bool get isInitialized => _initialized;

  /// Ouvre les deux boxes Hive. A appeler dans main.dart avant runApp().
  Future<void> init() async {
    if (_initialized) return;
    _favBox = await Hive.openBox<FavoriteQuestion>(_favBoxName);
    _noteBox = await Hive.openBox<QuestionNote>(_noteBoxName);
    _initialized = true;
  }

  // ─── Favoris ────────────────────────────────────────────────────

  /// Verifie si une question est dans les favoris de l'utilisateur.
  /// Retourne false si le service n'est pas encore initialise (cas
  /// marginal : appel avant init()).
  bool isFavorite(String userId, String questionId) {
    if (!_initialized) return false;
    for (final fav in _favBox.values) {
      if (fav.userId == userId && fav.questionId == questionId) {
        return true;
      }
    }
    return false;
  }

  /// Ajoute ou retire la question des favoris. Idempotent.
  /// Retourne true si la question est desormais favorite, false sinon.
  Future<bool> toggleFavorite(String userId, String questionId) async {
    if (!_initialized) return false;

    // Recherche de l'entree existante.
    dynamic existingKey;
    FavoriteQuestion? existing;
    for (final key in _favBox.keys) {
      final fav = _favBox.get(key);
      if (fav != null &&
          fav.userId == userId &&
          fav.questionId == questionId) {
        existingKey = key;
        existing = fav;
        break;
      }
    }

    if (existing != null) {
      // Deja en favoris -> on retire.
      await _favBox.delete(existingKey);
      notifyListeners();
      return false;
    }

    // Pas en favoris -> on ajoute.
    final fav = FavoriteQuestion(
      userId: userId,
      questionId: questionId,
      addedAt: DateTime.now(),
    );
    await _favBox.add(fav);
    notifyListeners();
    return true;
  }

  /// Liste des IDs de questions favorites pour l'utilisateur.
  /// (Pratique pour brancher QuestionService.getByIds.)
  List<String> getFavoriteIds(String userId) {
    if (!_initialized) return const [];
    return _favBox.values
        .where((f) => f.userId == userId)
        .map((f) => f.questionId)
        .toList();
  }

  /// Liste des entrees FavoriteQuestion (avec date d'ajout) pour
  /// l'utilisateur, triees par addedAt decroissant (plus recent en premier).
  List<FavoriteQuestion> getFavorites(String userId) {
    if (!_initialized) return const [];
    final list = _favBox.values.where((f) => f.userId == userId).toList();
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  /// Nombre de favoris pour l'utilisateur (utilise pour les compteurs UI).
  int favoritesCount(String userId) {
    if (!_initialized) return 0;
    int n = 0;
    for (final fav in _favBox.values) {
      if (fav.userId == userId) n++;
    }
    return n;
  }

  // ─── Notes ──────────────────────────────────────────────────────

  /// Recupere la note associee a (userId, questionId), ou null si aucune.
  /// Une seule note par couple : on retourne la premiere trouvee.
  QuestionNote? getNote(String userId, String questionId) {
    if (!_initialized) return null;
    for (final note in _noteBox.values) {
      if (note.userId == userId && note.questionId == questionId) {
        return note;
      }
    }
    return null;
  }

  /// Cree ou met a jour la note. Si une note existe deja pour ce couple
  /// (userId, questionId), son contenu et sa couleur sont ecrases et
  /// updatedAt est rafraichi. Sinon, une nouvelle entree est ajoutee.
  Future<void> saveNote({
    required String userId,
    required String questionId,
    required String content,
    String color = 'yellow',
  }) async {
    if (!_initialized) return;
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      // Si on tente de sauver une note vide, on la supprime (UX : un
      // eleve qui efface tout et valide ne veut pas d'une note vide).
      await deleteNote(userId, questionId);
      return;
    }

    final existing = getNote(userId, questionId);
    if (existing != null) {
      existing.content = trimmed;
      existing.color = color;
      existing.updatedAt = DateTime.now();
      await existing.save();
    } else {
      final note = QuestionNote(
        id: const Uuid().v4(),
        userId: userId,
        questionId: questionId,
        content: trimmed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: color,
      );
      await _noteBox.add(note);
    }
    notifyListeners();
  }

  /// Supprime la note associee a (userId, questionId). No-op si aucune.
  Future<void> deleteNote(String userId, String questionId) async {
    if (!_initialized) return;
    dynamic keyToDelete;
    for (final key in _noteBox.keys) {
      final note = _noteBox.get(key);
      if (note != null &&
          note.userId == userId &&
          note.questionId == questionId) {
        keyToDelete = key;
        break;
      }
    }
    if (keyToDelete != null) {
      await _noteBox.delete(keyToDelete);
      notifyListeners();
    }
  }

  /// Toutes les notes de l'utilisateur, triees par updatedAt decroissant.
  List<QuestionNote> getAllNotes(String userId) {
    if (!_initialized) return const [];
    final list = _noteBox.values.where((n) => n.userId == userId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Nombre de notes pour l'utilisateur.
  int notesCount(String userId) {
    if (!_initialized) return 0;
    int n = 0;
    for (final note in _noteBox.values) {
      if (note.userId == userId) n++;
    }
    return n;
  }

  /// Genere un export texte ASCII de toutes les notes (utile pour le
  /// bouton "Exporter" de NotesScreen). Format :
  ///   ExamBoost Togo - Mes notes (X)
  ///   Genere le JJ/MM/AAAA HH:MM
  ///
  ///   [#A revoir] 12/03/2026 14:32
  ///   <contenu de la note>
  ///   Question: <extrait enonce>
  ///   -----
  String exportNotesAsText(String userId, {String Function(String?)? questionLabelResolver}) {
    final notes = getAllNotes(userId);
    final now = DateTime.now();
    final buf = StringBuffer();
    buf.writeln('ExamBoost Togo - Mes notes (${notes.length})');
    buf.writeln(
      'Genere le ${_twoDigits(now.day)}/${_twoDigits(now.month)}/${now.year} '
      '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}',
    );
    buf.writeln();
    if (notes.isEmpty) {
      buf.writeln('Aucune note pour le moment.');
      return buf.toString();
    }
    for (final n in notes) {
      final cat = NoteCategory.byId(n.category);
      buf.writeln('[#${cat.label}] ${_fmtDate(n.updatedAt)}');
      buf.writeln(n.content);
      final label = questionLabelResolver != null
          ? questionLabelResolver(n.questionId)
          : n.questionId;
      if (label != null && label.isNotEmpty) {
        buf.writeln('Question: $label');
      }
      buf.writeln('-----');
    }
    return buf.toString();
  }

  String _fmtDate(DateTime d) =>
      '${_twoDigits(d.day)}/${_twoDigits(d.month)}/${d.year} '
      '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
