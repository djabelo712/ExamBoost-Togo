// lib/main.dart
// Point d'entree principal d'ExamBoost Togo
//
// Architecture :
//   - Hive (offline-first) : boxes "users", "review_cards"
//   - Providers : SrsService, QuestionService, UserProvider (global),
//                 LocaleProvider (i18n FR/EN runtime),
//                 ThemeProvider (clair/sombre/systeme)
//   - Router GoRouter : splash au demarrage, redirect vers /onboarding
//                       si pas d'user connecte (sauf /admin/* qui a son
//                       propre auth)
//   - i18n FR/EN active (165 cles) via flutter_localizations + gen-l10n
//   - Theme clair + theme sombre (Material 3)
//
// Pour generer les adaptateurs Hive :
//   dart run build_runner build --delete-conflicting-outputs
// Pour regenerer les traductions apres modification d'un .arb :
//   flutter gen-l10n   (ou simplement flutter run grace a generate: true)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/question.dart';
import 'models/review_card.dart';
import 'models/user.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'services/srs_service.dart';
import 'services/question_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Orientation : portrait uniquement (mobile) ────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Initialisation Hive (base de donnees locale) ─────────────
  await Hive.initFlutter();
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(ReviewCardAdapter());
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(QuestionTypeAdapter());

  // Ouvrir la box "users" tot (utilisee par UserProvider)
  await Hive.openBox<AppUser>('users');

  // ─── Initialisation des services ──────────────────────────────
  final srsService = SrsService();
  await srsService.init();

  final questionService = QuestionService();
  await questionService.loadQuestions();

  // ─── UserProvider (auth + persistance) ────────────────────────
  final userProvider = UserProvider();
  await userProvider.initialize();

  // ─── LocaleProvider (i18n FR/EN runtime) ──────────────────────
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();

  // ─── ThemeProvider (clair/sombre/systeme) ─────────────────────
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<SrsService>.value(value: srsService),
        Provider<QuestionService>.value(value: questionService),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const ExamBoostApp(),
    ),
  );
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
