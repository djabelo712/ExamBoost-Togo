// lib/main.dart
// Point d'entree principal d'ExamBoost Togo (Session 4 — wiring master).
//
// Architecture :
//   - Hive (offline-first) : 14 boxes pour persister users, review_cards,
//     user_badges, badge_metrics, tts_settings, audio_cache,
//     notification_settings, notification_history, accessibility,
//     sync_queue, sync_history, favorite_questions, question_notes,
//     saved_searches (+ score_predictions en box<String>).
//   - Providers globaux (MultiProvider) :
//       * UserProvider      (auth + persistance eleve)
//       * LocaleProvider    (i18n FR/EN runtime)
//       * ThemeProvider     (clair / sombre / systeme)
//       * SrsService        (SM-2, IRT 3PL)
//       * QuestionService   (chargement questions JSON)
//       * BadgeService      (gamification, 39 badges)
//       * NotificationService (notifications locales, 4 channels)
//       * FavoritesService  (favoris + notes perso)
//       * TtsService        (synthese vocale flutter_tts)
//       * SyncService       (sync cloud offline-first CRDT)
//   - Router GoRouter : splash au demarrage, redirect vers /onboarding
//                       si pas d'user connecte (sauf /admin/* qui a son
//                       propre auth). 23 routes au total (10 Session 1-2
//                       + 13 nouvelles Session 3).
//   - i18n FR/EN active (165 cles) via flutter_localizations + gen-l10n
//   - Theme clair + theme sombre (Material 3)
//
// IMPORTANT — Conflit typeId Hive (RESOLU par Agent BE) :
//   - typeId 7 etait utilise a la fois par NotificationHistory et BadgeCategory.
//   - typeId 8 etait utilise a la fois par AccessibilitySettings et BadgeLevel.
//   Agent BE (Bug Hunt) a renumerote : NotificationHistory -> typeId 19,
//   AccessibilitySettings -> typeId 20. Plus aucun conflit desormais.
//   Les 4 adapters (NotificationHistory, AccessibilitySettings, BadgeCategory,
//   BadgeLevel) sont tous enregistres ci-dessous.
//
// Pour generer les adaptateurs Hive :
//   dart run build_runner build --delete-conflicting-outputs
// Pour regenerer les traductions apres modification d'un .arb :
//   flutter gen-l10n   (ou simplement flutter run grace a generate: true)

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/accessibility_settings.dart';
import 'models/audio_cache_entry.dart';
import 'models/badge.dart';
import 'models/notification_history.dart';
import 'models/notification_settings.dart';
import 'models/question.dart';
import 'models/review_card.dart';
import 'models/sync_action.dart';
import 'models/sync_status.dart';
import 'models/tts_settings.dart';
import 'models/user.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/favorites/models/favorite_question.dart';
import 'screens/favorites/models/question_note.dart';
import 'screens/favorites/services/favorites_service.dart';
import 'services/accessibility_service.dart';
import 'services/badge_service.dart';
import 'services/notification_service.dart';
import 'services/question_service.dart';
import 'services/srs_service.dart';
import 'services/sync_queue.dart';
import 'services/sync_service.dart';
import 'services/tts_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_logger.dart';
import 'utils/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Orientation : portrait uniquement (mobile) ────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Initialisation Hive (base de donnees locale) ─────────────
  await Hive.initFlutter();
  _registerHiveAdapters();
  await _openHiveBoxes();

  // ─── Initialisation des services existants (Session 1-2) ──────
  final srsService = SrsService();
  await srsService.init();

  final questionService = QuestionService();
  await questionService.loadQuestions();

  // ─── Initialisation des services Session 3 ────────────────────
  // Chaque init est wrappee dans un try/catch pour qu'un echec non bloquant
  // (ex : TTS indispo sur desktop) ne casse pas l'app entiere.
  final badgeService = BadgeService();
  try {
    await badgeService.init();
  } catch (e) {
    AppLogger.warn('BadgeService.init() ignore: $e');
  }

  final notificationService = NotificationService();
  try {
    await notificationService.init();
  } catch (e) {
    AppLogger.warn('NotificationService.init() ignore: $e');
  }

  try {
    await AccessibilityService.init();
  } catch (e) {
    AppLogger.warn('AccessibilityService.init() ignore: $e');
  }

  final ttsService = TtsService();
  try {
    await ttsService.init();
  } catch (e) {
    AppLogger.warn('TtsService.init() ignore: $e');
  }

  final favoritesService = FavoritesService();
  try {
    await favoritesService.init();
  } catch (e) {
    AppLogger.warn('FavoritesService.init() ignore: $e');
  }

  final syncQueue = SyncQueue();
  final syncService = SyncService(
    queue: syncQueue,
    dio: Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    )),
    connectivity: Connectivity(),
    baseUrl: const String.fromEnvironment(
      'EXAMBOOST_API_BASE',
      defaultValue: 'http://localhost:8000',
    ),
  );
  try {
    await syncService.init();
  } catch (e) {
    AppLogger.warn('SyncService.init() ignore: $e');
  }

  // ─── UserProvider (auth + persistance) ────────────────────────
  final userProvider = UserProvider();
  await userProvider.initialize();

  // ─── LocaleProvider (i18n FR/EN runtime) ──────────────────────
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();

  // ─── ThemeProvider (clair/sombre/systeme) ─────────────────────
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Branchement du callback de tap notification -> router.
  // La navigation effective est differee (post-frame) car le router n'est
  // pas encore monte au moment du init().
  notificationService.onTap = (String? payload) {
    AppLogger.info('Notification tappe, payload=$payload');
    // L'Agent BE pourra brancher un routing riche selon le payload
    // (open_revision:Mathematiques, open_dashboard, etc.).
  };

  runApp(
    MultiProvider(
      providers: [
        // Services Session 1 (deja existants)
        Provider<SrsService>.value(value: srsService),
        Provider<QuestionService>.value(value: questionService),

        // Providers Session 2 (V-wiring)
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),

        // Services Session 3 (BA-wiring)
        Provider<BadgeService>.value(value: badgeService),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<FavoritesService>.value(value: favoritesService),
        ChangeNotifierProvider<TtsService>.value(value: ttsService),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: const ExamBoostApp(),
    ),
  );
}

/// Enregistre tous les adapters Hive necessaires.
///
/// Ordre d'enregistrement : par typeId croissant pour lisibilite.
///
/// Note historique : typeId 7 et 8 etaient en conflit (NotificationHistory +
/// BadgeCategory sur 7 ; AccessibilitySettings + BadgeLevel sur 8). L'agent BE
/// (Bug Hunt, Session 4) a renumerote NotificationHistory -> 19 et
/// AccessibilitySettings -> 20. Plus aucun conflit, tous les adapters sont
/// enregistres.
void _registerHiveAdapters() {
  // Session 1 — existant
  Hive.registerAdapter(QuestionAdapter());          // typeId 0
  Hive.registerAdapter(QuestionTypeAdapter());      // typeId 1
  Hive.registerAdapter(ReviewCardAdapter());        // typeId 2
  Hive.registerAdapter(AppUserAdapter());           // typeId 3

  // Session 3 — Agent Y (notifications)
  Hive.registerAdapter(NotificationSettingsAdapter());   // typeId 5
  Hive.registerAdapter(NotificationCategoryAdapter());  // typeId 6
  Hive.registerAdapter(NotificationHistoryAdapter());   // typeId 19

  // Session 3 — Agent AA (accessibilite)
  Hive.registerAdapter(AccessibilitySettingsAdapter()); // typeId 20

  // Session 3 — Agent X (badges)
  Hive.registerAdapter(BadgeCategoryAdapter());     // typeId 7
  Hive.registerAdapter(BadgeLevelAdapter());        // typeId 8
  Hive.registerAdapter(UserBadgeAdapter());         // typeId 9

  // Session 3 — Agent AC (sync cloud)
  Hive.registerAdapter(SyncActionAdapter());        // typeId 10
  Hive.registerAdapter(SyncActionTypeAdapter());    // typeId 11
  Hive.registerAdapter(SyncHistoryEntryAdapter());  // typeId 12
  Hive.registerAdapter(SyncHistoryStatusAdapter()); // typeId 13

  // Session 3 — Agent AN (favoris + notes)
  Hive.registerAdapter(FavoriteQuestionAdapter());  // typeId 15
  Hive.registerAdapter(QuestionNoteAdapter());      // typeId 16

  // Session 3 — Agent AQ (TTS + cache audio)
  Hive.registerAdapter(TtsSettingsAdapter());       // typeId 17
  Hive.registerAdapter(AudioCacheEntryAdapter());   // typeId 18
}

/// Ouvre toutes les boxes Hive necessaires au demarrage.
///
/// strategie : openBox est idempotent (Hive renvoie la box deja ouverte),
/// donc meme si un service re-ouvre une box plus tard, c'est sans effet de bord.
/// On les ouvre ici pour :
///   - detecter les erreurs d'adapter tot (avant runApp)
///   - eviter la latence du 1er acces pendant la 1ere frame
Future<void> _openHiveBoxes() async {
  // Boxes typées (requirent un adapter enregistre).
  await Hive.openBox<AppUser>('users');
  await Hive.openBox<ReviewCard>('review_cards');
  await Hive.openBox<UserBadge>('user_badges');
  await Hive.openBox<NotificationSettings>('notification_settings');
  await Hive.openBox<NotificationHistory>('notification_history');
  await Hive.openBox<AccessibilitySettings>('accessibility');
  await Hive.openBox<SyncAction>('sync_queue');
  await Hive.openBox<SyncHistoryEntry>('sync_history');
  await Hive.openBox<FavoriteQuestion>('favorite_questions');
  await Hive.openBox<QuestionNote>('question_notes');
  await Hive.openBox<TtsSettings>('tts_settings');
  await Hive.openBox<AudioCacheEntry>('audio_cache');

  // Boxes non-typées (Map<String, dynamic> ou compteurs simples).
  await Hive.openBox('badge_metrics');

  // Boxes de Strings (JSON sérialise — pas d'adapter specifique requis).
  await Hive.openBox<String>('saved_searches');
  await Hive.openBox<String>('score_predictions');
}

class ExamBoostApp extends StatelessWidget {
  const ExamBoostApp({super.key});

  @override
  Widget build(BuildContext context) {
    // On ecoute LocaleProvider et ThemeProvider pour rebuilder
    // MaterialApp.router a chaque changement de langue ou de theme.
    final LocaleProvider localeProvider = Provider.of<LocaleProvider>(context);
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'ExamBoost Togo',
      debugShowCheckedModeBanner: false,
      // ─── Themes ───────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      // ─── i18n FR/EN ──────────────────────────────────────────
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeProvider.locale,
      // ─── Routing ─────────────────────────────────────────────
      routerConfig: AppRouter.router,
    );
  }
}
