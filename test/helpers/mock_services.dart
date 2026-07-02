// test/helpers/mock_services.dart
// Manual mocks for SrsService, QuestionService, UserProvider,
// FavoritesService, and SyncService.
//
// We avoid `mockito`'s `@GenerateMocks` (which requires build_runner) by
// writing lightweight subclasses that override the public methods used by
// the UI. This keeps the test suite self-contained.
//
// Design:
//   - MockSrsService        : in-memory ReviewCard store (no Hive). Records
//                             every recordAnswer() call for assertions.
//   - MockQuestionService   : loads from assets by default; supports injecting
//                             a custom list of questions or forcing a load
//                             failure.
//   - FakeUserProvider      : preset user without Hive/SharedPreferences.
//   - FakeFavoritesService  : in-memory favorites + notes (no Hive boxes).
//                             Added by Agent BU (Session 4).
//   - FakeSyncService       : super with throwaway deps + overridden getters
//                             (status, pendingCount, lastError) so the
//                             underlying state is never touched. Added by
//                             Agent BU (Session 4).

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import 'package:examboost_togo/models/question.dart';
import 'package:examboost_togo/models/review_card.dart';
import 'package:examboost_togo/models/sync_status.dart';
import 'package:examboost_togo/models/tts_settings.dart';
import 'package:examboost_togo/models/user.dart';
import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/favorites/models/favorite_question.dart';
import 'package:examboost_togo/screens/favorites/models/question_note.dart';
import 'package:examboost_togo/screens/favorites/services/favorites_service.dart';
import 'package:examboost_togo/services/audio_playback_service.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';
import 'package:examboost_togo/services/sync_queue.dart';
import 'package:examboost_togo/services/sync_service.dart';
import 'package:examboost_togo/services/tts_service.dart';

// ─── MockSrsService ────────────────────────────────────────────────

/// In-memory mock of [SrsService] that doesn't touch Hive.
///
/// Records every call to `recordAnswer` in [recordedCalls] for assertions.
class MockSrsService extends SrsService {
  /// All recordAnswer() calls, in order.
  final List<RecordedAnswer> recordedCalls = [];

  /// In-memory card store keyed by `userId_questionId`.
  final Map<String, ReviewCard> _cards = {};

  /// If true, the next recordAnswer/getDueCards/getStats call throws.
  bool shouldFail = false;

  String _key(String userId, String questionId) => '${userId}_$questionId';

  @override
  ReviewCard getOrCreate(String userId, String questionId) {
    final key = _key(userId, questionId);
    return _cards.putIfAbsent(
      key,
      () => ReviewCard(userId: userId, questionId: questionId),
    );
  }

  @override
  Future<ReviewCard> recordAnswer({
    required String userId,
    required String questionId,
    required int quality,
  }) async {
    if (shouldFail) throw Exception('MockSrsService: forced failure');
    recordedCalls.add(RecordedAnswer(userId, questionId, quality));
    final card = getOrCreate(userId, questionId);
    card.applyReview(quality);
    return card;
  }

  @override
  List<ReviewCard> getDueCards(String userId, {int limit = 20}) {
    if (shouldFail) throw Exception('MockSrsService: forced failure');
    final all = _cards.values.where((c) => c.userId == userId).toList();
    all.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    return all.take(limit).toList();
  }

  @override
  SrsStats getStats(String userId) {
    final allCards = _cards.values.where((c) => c.userId == userId).toList();
    final now = DateTime.now();
    return SrsStats(
      totalCards: allCards.length,
      dueToday: allCards.where((c) => c.isDue).length,
      mastered: allCards
          .where((c) => !c.isLearning && c.successRate >= 0.8)
          .length,
      learning: allCards.where((c) => c.isLearning).length,
      newCards: allCards.where((c) => c.totalAttempts == 0).length,
      dueIn7Days: allCards
          .where((c) => c.nextReviewDate.isBefore(now.add(const Duration(days: 7))))
          .length,
    );
  }

  /// Direct access to the in-memory card (for assertions in tests).
  ReviewCard? cardFor(String userId, String questionId) =>
      _cards[_key(userId, questionId)];

  /// Reset all state (useful between tests).
  void reset() {
    recordedCalls.clear();
    _cards.clear();
    shouldFail = false;
  }
}

/// One recorded recordAnswer() call.
class RecordedAnswer {
  final String userId;
  final String questionId;
  final int quality;
  const RecordedAnswer(this.userId, this.questionId, this.quality);

  @override
  String toString() =>
      'RecordedAnswer(userId: $userId, questionId: $questionId, quality: $quality)';
}

// ─── MockQuestionService ───────────────────────────────────────────

/// Mock of [QuestionService] that can inject test data or load from assets.
///
/// Behaviors:
///   - If [initialQuestions] is non-null, returns those for all filters.
///   - Else if [shouldFail] is true, loadQuestions() throws.
///   - Else loads from `assets/data/questions.json` via the real implementation.
class MockQuestionService extends QuestionService {
  MockQuestionService({
    this.initialQuestions,
    this.shouldFail = false,
  });

  /// If non-null, used as the in-memory question pool.
  final List<Question>? initialQuestions;

  /// If true, loadQuestions() throws (for testing error states).
  final bool shouldFail;

  List<Question> get _pool => initialQuestions ?? <Question>[];

  @override
  Future<void> loadQuestions() async {
    if (shouldFail) {
      throw Exception('MockQuestionService: forced failure');
    }
    if (initialQuestions == null) {
      // Delegate to the real loader (reads bundled assets).
      await super.loadQuestions();
    }
  }

  @override
  List<Question> getByMatiere(String matiere) {
    if (initialQuestions != null) {
      return _pool.where((q) => q.matiere == matiere).toList();
    }
    return super.getByMatiere(matiere);
  }

  @override
  List<Question> getByExamen(String examen, {String? serie}) {
    if (initialQuestions != null) {
      return _pool
          .where((q) =>
              q.examen == examen && (serie == null || q.serie == serie))
          .toList();
    }
    return super.getByExamen(examen, serie: serie);
  }

  @override
  List<Question> getByCompetence(String competenceId) {
    if (initialQuestions != null) {
      return _pool.where((q) => q.competenceId == competenceId).toList();
    }
    return super.getByCompetence(competenceId);
  }

  @override
  List<Question> getByIds(List<String> ids) {
    if (initialQuestions != null) {
      return _pool.where((q) => ids.contains(q.id)).toList();
    }
    return super.getByIds(ids);
  }

  @override
  Question? getById(String id) {
    if (initialQuestions != null) {
      for (final q in _pool) {
        if (q.id == id) return q;
      }
      return null;
    }
    return super.getById(id);
  }

  @override
  List<Question> getForAdaptiveRevision({
    required String matiere,
    required List<String> excludeIds,
    int limit = 50,
  }) {
    if (initialQuestions != null) {
      return _pool
          .where((q) => q.matiere == matiere && !excludeIds.contains(q.id))
          .take(limit)
          .toList();
    }
    return super.getForAdaptiveRevision(
      matiere: matiere,
      excludeIds: excludeIds,
      limit: limit,
    );
  }

  @override
  List<Question> generateSimulation({
    required String examen,
    required String? serie,
    int nombreQuestions = 20,
  }) {
    if (initialQuestions != null) {
      final pool = getByExamen(examen, serie: serie);
      pool.shuffle();
      return pool.take(nombreQuestions).toList();
    }
    return super.generateSimulation(
      examen: examen,
      serie: serie,
      nombreQuestions: nombreQuestions,
    );
  }

  @override
  List<String> get matieres {
    if (initialQuestions != null) {
      return _pool.map((q) => q.matiere).toSet().toList()..sort();
    }
    return super.matieres;
  }

  @override
  int get totalQuestions {
    if (initialQuestions != null) return _pool.length;
    return super.totalQuestions;
  }
}

// ─── FakeUserProvider ──────────────────────────────────────────────

/// Fake [UserProvider] that doesn't touch Hive or SharedPreferences.
///
/// The router's redirect logic uses [isInitialized], [isAuthenticated],
/// and [currentUserId] — all overridden here.
class FakeUserProvider extends UserProvider {
  FakeUserProvider({AppUser? user}) : _user = user;

  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isInitialized => true;

  @override
  String get currentUserId => _user?.id ?? 'user_demo';

  @override
  Future<void> setCurrentUser(AppUser user) async {
    _user = user;
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    // No-op: user is in-memory only.
  }
}

// ─── FakeFavoritesService (Agent BU — Session 4) ─────────────────
//
// In-memory mock of [FavoritesService] that doesn't touch Hive boxes.
// Used by widget tests for FavoriteButton, FavoritesScreen, SearchScreen.
// Mirrors the real service's public API surface so widgets can consume it
// transparently via Provider<FavoritesService>.

class FakeFavoritesService extends FavoritesService {
  FakeFavoritesService();

  final List<FavoriteQuestion> _favorites = [];
  final List<QuestionNote> _notes = [];

  // The parent's `_initialized` field is private. We override the public
  // getter so all public methods (which short-circuit on !isInitialized)
  // work without calling init() — and therefore without opening Hive boxes.
  @override
  bool get isInitialized => true;

  @override
  bool isFavorite(String userId, String questionId) {
    return _favorites.any(
      (f) => f.userId == userId && f.questionId == questionId,
    );
  }

  @override
  Future<bool> toggleFavorite(String userId, String questionId) async {
    final existingIndex = _favorites.indexWhere(
      (f) => f.userId == userId && f.questionId == questionId,
    );
    if (existingIndex >= 0) {
      _favorites.removeAt(existingIndex);
      notifyListeners();
      return false;
    }
    _favorites.add(
      FavoriteQuestion(
        userId: userId,
        questionId: questionId,
        addedAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  @override
  List<String> getFavoriteIds(String userId) {
    return _favorites
        .where((f) => f.userId == userId)
        .map((f) => f.questionId)
        .toList();
  }

  @override
  List<FavoriteQuestion> getFavorites(String userId) {
    final list =
        _favorites.where((f) => f.userId == userId).toList();
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  @override
  int favoritesCount(String userId) =>
      _favorites.where((f) => f.userId == userId).length;

  @override
  QuestionNote? getNote(String userId, String questionId) {
    for (final n in _notes) {
      if (n.userId == userId && n.questionId == questionId) return n;
    }
    return null;
  }

  @override
  Future<void> saveNote({
    required String userId,
    required String questionId,
    required String content,
    String color = 'yellow',
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      await deleteNote(userId, questionId);
      return;
    }
    final existing = getNote(userId, questionId);
    if (existing != null) {
      existing.content = trimmed;
      existing.color = color;
      existing.updatedAt = DateTime.now();
    } else {
      _notes.add(
        QuestionNote(
          id: 'note-${_notes.length + 1}',
          userId: userId,
          questionId: questionId,
          content: trimmed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          color: color,
        ),
      );
    }
    notifyListeners();
  }

  @override
  Future<void> deleteNote(String userId, String questionId) async {
    _notes.removeWhere(
      (n) => n.userId == userId && n.questionId == questionId,
    );
    notifyListeners();
  }

  @override
  List<QuestionNote> getAllNotes(String userId) {
    final list = _notes.where((n) => n.userId == userId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  int notesCount(String userId) =>
      _notes.where((n) => n.userId == userId).length;

  /// Direct helper for tests: pre-seed the favorites list with no async work.
  void seedFavorite(String userId, String questionId, {DateTime? addedAt}) {
    if (!isFavorite(userId, questionId)) {
      _favorites.add(
        FavoriteQuestion(
          userId: userId,
          questionId: questionId,
          addedAt: addedAt ?? DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }
}

// ─── FakeSyncService (Agent BU — Session 4) ──────────────────────
//
// Mock [SyncService] for widget tests that consume SyncIndicator.
// The real SyncService has a complex constructor (Dio, Connectivity,
// SyncQueue) and triggers network calls on init — overkill for widget
// tests that only need to render the indicator in different states.
//
// This fake calls super() with throwaway dependencies, then overrides
// the three getters consumed by SyncIndicator (status, pendingCount,
// lastError) so the underlying state is never touched.

class FakeSyncService extends SyncService {
  FakeSyncService()
      : super(
          queue: SyncQueue(),
          dio: Dio(),
          connectivity: Connectivity(),
        );

  SyncStatus _status = SyncStatus.idle;
  int _pending = 0;
  String? _error;

  @override
  SyncStatus get status => _status;

  @override
  int get pendingCount => _pending;

  @override
  String? get lastError => _error;

  /// Test-only setter to simulate a status change.
  void setStatus(SyncStatus s) {
    _status = s;
    notifyListeners();
  }

  /// Test-only setter to simulate pending actions in the queue.
  void setPending(int n) {
    _pending = n;
    notifyListeners();
  }

  /// Test-only setter to simulate an error message.
  void setLastError(String? e) {
    _error = e;
    notifyListeners();
  }
}

// ─── FakeTtsService + FakeAudioPlaybackService (Agent BU — Session 4) ──
//
// Lightweight fakes for the audio playback stack. The real TtsService
// initialises a FlutterTts engine (native plugin) + Hive box, neither of
// which work in widget tests. We extend the real classes and override
// the public surface consumed by AudioPlayerButton / AudioPlayerBar:
//   - settings (TtsSettings)
//   - isSpeaking / isPaused / currentlySpokenText
//   - isSpeakingText(text)
//   - speak / pause / resume / stop (no-op, record calls)
//   - AudioPlaybackService.isPlayingText / isPausedText / play

class FakeTtsService extends TtsService {
  TtsSettings _fakeSettings = TtsSettings();
  bool _fakeIsSpeaking = false;
  bool _fakeIsPaused = false;
  String _fakeCurrentText = '';

  final List<String> speakCalls = <String>[];
  final List<void Function()> _pauseCalls = <void Function()>[];
  int _stopCallCount = 0;

  @override
  TtsSettings get settings => _fakeSettings;

  @override
  bool get isSpeaking => _fakeIsSpeaking;

  @override
  bool get isPaused => _fakeIsPaused;

  @override
  String get currentlySpokenText => _fakeCurrentText;

  @override
  bool isSpeakingText(String text) =>
      _fakeIsSpeaking && _fakeCurrentText == text;

  /// Test-only: simulate the TTS engine starting playback of [text].
  void simulatePlaying(String text) {
    _fakeIsSpeaking = true;
    _fakeIsPaused = false;
    _fakeCurrentText = text;
    notifyListeners();
  }

  /// Test-only: simulate the TTS engine pausing.
  void simulatePaused(String text) {
    _fakeIsSpeaking = true;
    _fakeIsPaused = true;
    _fakeCurrentText = text;
    notifyListeners();
  }

  /// Test-only: simulate the TTS engine idle (no playback).
  void simulateIdle() {
    _fakeIsSpeaking = false;
    _fakeIsPaused = false;
    _fakeCurrentText = '';
    notifyListeners();
  }

  /// Test-only: change the settings (e.g. disable TTS).
  void setSettings(TtsSettings s) {
    _fakeSettings = s;
    notifyListeners();
  }

  // ── No-op overrides (avoid touching the native plugin) ─────────

  @override
  Future<void> speak(String text) async {
    speakCalls.add(text);
    // Mimic the engine: start speaking immediately.
    simulatePlaying(text);
  }

  @override
  Future<void> pause() async {
    _fakeIsPaused = true;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    _fakeIsPaused = false;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    _stopCallCount++;
    simulateIdle();
  }
}

class FakeAudioPlaybackService extends AudioPlaybackService {
  FakeAudioPlaybackService(FakeTtsService tts) : super(tts);

  final List<String> playCalls = <String>[];

  @override
  bool isPlayingText(String text) =>
      ttsService.isSpeaking &&
      ttsService.currentlySpokenText == text &&
      !ttsService.isPaused;

  @override
  bool isPausedText(String text) =>
      ttsService.isSpeaking &&
      ttsService.isPaused &&
      ttsService.currentlySpokenText == text;

  @override
  Future<void> play(String text) async {
    playCalls.add(text);
    // Delegate to the TtsService fake (which will simulatePlaying).
    await ttsService.speak(text);
  }
}
