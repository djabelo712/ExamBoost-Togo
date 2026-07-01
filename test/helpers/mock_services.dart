// test/helpers/mock_services.dart
// Manual mocks for SrsService, QuestionService, and UserProvider.
//
// We avoid `mockito`'s `@GenerateMocks` (which requires build_runner) by
// writing lightweight subclasses that override the public methods used by
// the UI. This keeps the test suite self-contained.
//
// Design:
//   - MockSrsService : in-memory ReviewCard store (no Hive). Records every
//     recordAnswer() call for assertions.
//   - MockQuestionService : loads from assets by default; supports injecting
//     a custom list of questions or forcing a load failure.
//   - FakeUserProvider : preset user without Hive/SharedPreferences.

import 'package:examboost_togo/models/question.dart';
import 'package:examboost_togo/models/review_card.dart';
import 'package:examboost_togo/models/user.dart';
import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';

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
