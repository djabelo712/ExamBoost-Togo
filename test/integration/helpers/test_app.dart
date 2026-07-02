// test/integration/helpers/test_app.dart
// Shared helpers for integration (E2E) tests.
//
// The integration tests pump real screens via GoRouter + MultiProvider, but
// we substitute the Hive-backed services with in-memory fakes so that the
// tests run fast (no Hive init, no SharedPreferences) and stay deterministic.
//
// Fakes provided here:
//   - launchApp()                  : pump the real router with mock providers.
//   - FakeFavoritesService         : in-memory FavoritesService (no Hive).
//   - FakeSyncService              : in-memory SyncService (no Dio, no Hive).
//   - FakeTutorController          : in-memory TutorController (no Hive).
//   - FakeLocaleProvider           : LocaleProvider without SharedPreferences.
//   - FakeThemeProvider            : ThemeProvider without SharedPreferences.
//
// All fakes keep the same public surface as the real classes so that the
// screens consume them transparently via Provider.of / context.watch.
//
// NOTE: The real UserProvider / SrsService / QuestionService fakes live in
// test/helpers/mock_services.dart and are re-used here.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/models/badge.dart';
import 'package:examboost_togo/models/review_card.dart';
import 'package:examboost_togo/models/user.dart';
import 'package:examboost_togo/providers/locale_provider.dart';
import 'package:examboost_togo/providers/theme_provider.dart';
import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/favorites/models/favorite_question.dart';
import 'package:examboost_togo/screens/favorites/models/question_note.dart';
import 'package:examboost_togo/screens/favorites/services/favorites_service.dart';
import 'package:examboost_togo/screens/tutor/models/chat_message.dart';
import 'package:examboost_togo/screens/tutor/tutor_controller.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';
import 'package:examboost_togo/services/sync_service.dart';
import 'package:examboost_togo/utils/app_router.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_data.dart';

// ─── launchApp ──────────────────────────────────────────────────

/// Pump the real ExamBoost Togo router with mock providers.
///
/// [isFirstLaunch] : if false, pre-seeds a user (so the router lands on
///   /home instead of /onboarding).
/// [questions]     : the in-memory question pool (defaults to the 10
///   sample questions from test_data.dart).
/// [extras]        : additional providers (FavoritesService, SyncService,
///   ThemeProvider, LocaleProvider, ...) the test wants to inject.
Future<void> launchApp(
  WidgetTester tester, {
  bool isFirstLaunch = true,
  List<Question>? questions,
  AppUser? user,
  SrsService? srsService,
  QuestionService? questionService,
  List<SingleChildWidget> extras = const [],
}) async {
  final ups = FakeUserProvider(
    user: isFirstLaunch ? null : (user ?? createTestUser()),
  );
  final qs = questionService ??
      MockQuestionService(initialQuestions: questions ?? sampleQuestions);
  final srs = srsService ?? MockSrsService();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: ups),
        Provider<QuestionService>.value(value: qs),
        Provider<SrsService>.value(value: srs),
        ...extras,
      ],
      child: MaterialApp.router(routerConfig: AppRouter.router),
    ),
  );
  // Single pump so the router can render the initial frame. The caller
  // is expected to pumpAndSettle() (or pump a duration) for animations.
  await tester.pump();
}

// ─── FakeFavoritesService ───────────────────────────────────────

/// In-memory FavoritesService. Backed by two simple Maps.
///
/// Mirrors the public API of [FavoritesService] so that FavoritesScreen /
/// NotesScreen / FavoriteButton can consume it via Provider without
/// noticing the swap.
class FakeFavoritesService extends FavoritesService {
  // userId_questionId -> FavoriteQuestion
  final Map<String, FavoriteQuestion> _favs = {};
  // userId_questionId -> QuestionNote
  final Map<String, QuestionNote> _notes = {};

  @override
  bool get isInitialized => true;

  @override
  Future<void> init() async {
    // No-op: in-memory only.
  }

  String _key(String userId, String questionId) => '${userId}_$questionId';

  @override
  bool isFavorite(String userId, String questionId) {
    return _favs.containsKey(_key(userId, questionId));
  }

  @override
  Future<bool> toggleFavorite(String userId, String questionId) async {
    final key = _key(userId, questionId);
    if (_favs.containsKey(key)) {
      _favs.remove(key);
      notifyListeners();
      return false;
    }
    _favs[key] = FavoriteQuestion(
      userId: userId,
      questionId: questionId,
      addedAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  @override
  List<String> getFavoriteIds(String userId) {
    return _favs.values
        .where((f) => f.userId == userId)
        .map((f) => f.questionId)
        .toList();
  }

  @override
  List<FavoriteQuestion> getFavorites(String userId) {
    final list = _favs.values.where((f) => f.userId == userId).toList();
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  @override
  int favoritesCount(String userId) {
    return _favs.values.where((f) => f.userId == userId).length;
  }

  @override
  QuestionNote? getNote(String userId, String questionId) {
    return _notes[_key(userId, questionId)];
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
    final key = _key(userId, questionId);
    final existing = _notes[key];
    if (existing != null) {
      existing.content = trimmed;
      existing.color = color;
      existing.updatedAt = DateTime.now();
    } else {
      _notes[key] = QuestionNote(
        id: 'note_${_notes.length}',
        userId: userId,
        questionId: questionId,
        content: trimmed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: color,
      );
    }
    notifyListeners();
  }

  @override
  Future<void> deleteNote(String userId, String questionId) async {
    _notes.remove(_key(userId, questionId));
    notifyListeners();
  }

  @override
  List<QuestionNote> getAllNotes(String userId) {
    final list = _notes.values.where((n) => n.userId == userId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }
}

// ─── FakeSyncService ────────────────────────────────────────────

/// In-memory SyncService. Does NOT touch Dio, Connectivity, or Hive.
///
/// Exposes the same getters as [SyncService] (status, pendingCount, ...)
/// plus [recordAction] and [syncNow] which the SyncIndicator consumes.
class FakeSyncService extends ChangeNotifier {
  FakeSyncService({SyncStatus initialStatus = SyncStatus.idle})
      : _status = initialStatus;

  SyncStatus _status;
  int _pending = 0;
  DateTime? _lastSyncAt;
  String? _lastError;

  SyncStatus get status => _status;
  int get pendingCount => _pending;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastError => _lastError;
  int? get retryInSeconds => null;
  int get abandonedCount => 0;
  int get syncedCount => _syncedCount;
  int _syncedCount = 0;

  /// Simulates a recorded action (offline). Increments the pending count.
  void recordAction() {
    _pending++;
    if (_status == SyncStatus.idle || _status == SyncStatus.success) {
      _status = SyncStatus.offline;
    }
    notifyListeners();
  }

  /// Simulates a return to network: drains the pending queue and resets
  /// status to SyncStatus.success.
  Future<void> syncNow({String reason = 'manual'}) async {
    if (_pending == 0) {
      _status = SyncStatus.idle;
      notifyListeners();
      return;
    }
    _status = SyncStatus.syncing;
    notifyListeners();
    // Simulate network delay.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _syncedCount += _pending;
    _pending = 0;
    _lastSyncAt = DateTime.now();
    _lastError = null;
    _status = SyncStatus.success;
    notifyListeners();
  }

  /// Force the status to offline (used to simulate loss of network).
  void goOffline() {
    _status = SyncStatus.offline;
    notifyListeners();
  }

  /// Force the status back to online and trigger an auto-sync.
  Future<void> comeBackOnline() async {
    await syncNow(reason: 'networkRestored');
  }
}

// ─── FakeTutorController ────────────────────────────────────────

/// In-memory TutorController. Skips Hive persistence and the backend call.
///
/// [responseFactory] lets the test customise the assistant reply (mock or
/// canned text). Defaults to a deterministic Pythagore explanation.
class FakeTutorController extends ChangeNotifier {
  FakeTutorController({String Function(String question)? responseFactory})
      : _responseFactory =
            responseFactory ?? _defaultResponseFactory;

  final String Function(String question) _responseFactory;

  List<ChatMessage> _messages = <ChatMessage>[];
  TutorStatus _status = TutorStatus.idle;
  String? _lastErrorMessage;
  List<String> _suggestedFollowups = const <String>[];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  TutorStatus get status => _status;
  bool get isLoading => _status == TutorStatus.loading;
  bool get isOffline => _status == TutorStatus.offline;
  bool get hasError => _status == TutorStatus.error;
  String? get lastErrorMessage => _lastErrorMessage;
  List<String> get suggestedFollowups =>
      List.unmodifiable(_suggestedFollowups);
  bool get isEmpty => _messages.isEmpty;

  Future<void> init() async {
    // No-op: no Hive box to load from.
    notifyListeners();
  }

  Future<void> ask({
    required String question,
    String? matiere,
    String? chapitre,
    String? competenceId,
  }) async {
    if (question.trim().isEmpty) return;
    // 1. Append the user message immediately.
    _messages = <ChatMessage>[
      ..._messages,
      ChatMessage.user(
        id: 'msg_${_messages.length}_u',
        content: question,
        timestamp: DateTime.now(),
        matiere: matiere,
      ),
    ];
    _status = TutorStatus.loading;
    notifyListeners();

    // 2. Simulate the network round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // 3. Append the assistant response.
    final answer = _responseFactory(question);
    _messages = <ChatMessage>[
      ..._messages,
      ChatMessage.assistant(
        id: 'msg_${_messages.length}_a',
        content: answer,
        timestamp: DateTime.now(),
        matiere: matiere,
      ),
    ];
    _status = TutorStatus.idle;
    notifyListeners();
  }

  Future<void> clearConversation() async {
    _messages = const <ChatMessage>[];
    _status = TutorStatus.idle;
    _lastErrorMessage = null;
    notifyListeners();
  }

  Future<void> retryLast() async {
    // No-op for the fake.
  }

  Future<void> startNewConversation() async {
    _messages = const <ChatMessage>[];
    _status = TutorStatus.idle;
    notifyListeners();
  }

  static String _defaultResponseFactory(String question) {
    return 'Le théorème de Pythagore dit : dans un triangle rectangle, '
        'le carré de l\'hypoténuse est égal à la somme des carrés des '
        'deux autres côtés : **a² + b² = c²**.';
  }
}

// ─── FakeLocaleProvider / FakeThemeProvider ─────────────────────

/// LocaleProvider that skips SharedPreferences. Useful for language-switch
/// integration tests where we want to assert side-effects of setLocale()
/// without poking the plugin channel.
class FakeLocaleProvider extends LocaleProvider {
  @override
  Future<void> initialize() async {
    _initialized = true;
    notifyListeners();
  }
}

/// ThemeProvider that skips SharedPreferences.
class FakeThemeProvider extends ThemeProvider {
  @override
  Future<void> initialize() async {
    _initialized = true;
    notifyListeners();
  }
}

// ─── Badge helpers (no Hive) ────────────────────────────────────

/// Build an in-memory UserBadge (not persisted to Hive) for the given
/// badge with the given progress. Useful for asserting BadgeUnlockDialog
/// rendering or BadgeCard rendering without touching Hive.
UserBadge buildUserBadge({
  required String badgeId,
  required int progress,
  DateTime? unlockedAt,
}) {
  final ub = UserBadge()
    ..badgeId = badgeId
    ..progress = progress
    ..unlockedAt = unlockedAt;
  return ub;
}

/// Convenience: the "Premier pas" badge (id `premier_pas_or`).
/// Triggered as soon as the student has answered at least 1 question.
Badge get premierPasBadge =>
    Badges.all.firstWhere((b) => b.id == 'premier_pas_or');
