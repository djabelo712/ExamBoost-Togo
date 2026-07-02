// test/integration/language_switch_test.dart
// Integration scenario: Settings -> switch language to EN -> verify
// LocaleProvider.locale changes -> verify AppLocalizations produces EN
// strings -> navigate through Home/Revision and verify the locale persists.
//
// Uses FakeLocaleProvider (no SharedPreferences) + FakeThemeProvider +
// FakeUserProvider + MockQuestionService + MockSrsService. The test wraps
// the router in a MaterialApp.router that respects locale +
// localizationsDelegates + supportedLocales.
//
// LIMITATIONS:
//   Most screens (home, revision, settings) currently use hardcoded FR
//   strings instead of AppLocalizations.of(context).*. The full text-
//   translation verification therefore happens at the AppLocalizations level
//   (we verify that AppLocalizations.of(context)!.welcomeGreeting('Amina')
//   returns "Hello, Amina!" when the locale is EN). When the screens are
//   migrated to use AppLocalizations, the test should be extended to assert
//   the visible text on each screen.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/locale_provider.dart';
import 'package:examboost_togo/providers/theme_provider.dart';
import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';
import 'package:examboost_togo/screens/settings/settings_screen.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';
import 'package:examboost_togo/theme/app_theme.dart';
import 'package:examboost_togo/utils/app_router.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';
import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: language switch', () {
    late FakeLocaleProvider localeProvider;
    late FakeThemeProvider themeProvider;
    late FakeUserProvider userProvider;
    late MockQuestionService questionService;
    late MockSrsService srsService;
    late GoRouter router;

    setUp(() {
      localeProvider = FakeLocaleProvider();
      themeProvider = FakeThemeProvider();
      userProvider = FakeUserProvider(user: createTestUser());
      questionService = MockQuestionService(initialQuestions: sampleQuestions);
      srsService = MockSrsService();
      router = AppRouter.router;
    });

    /// Pump the router with locale + theme support. We use Consumer to
    /// rebuild MaterialApp.router when either provider changes.
    Future<void> pumpLocalizedApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            Provider<QuestionService>.value(value: questionService),
            Provider<SrsService>.value(value: srsService),
          ],
          child: Consumer2<LocaleProvider, ThemeProvider>(
            builder: (context, lp, tp, child) {
              return MaterialApp.router(
                routerConfig: router,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: tp.themeMode,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: lp.locale,
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        ),
      );
      // Skip the splash.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    // ─── Step 1: default locale is FR ────────────────────────────
    // Spec: implicit (the app starts in French by default).
    testWidgets('Step 1 : LocaleProvider démarre en FR', (tester) async {
      await pumpLocalizedApp(tester);

      expect(localeProvider.locale.languageCode, 'fr');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    // ─── Step 2: navigate to Settings -> Langue section ──────────
    // Spec: Step 1 (aller à Settings).
    testWidgets('Step 2 : Home -> Paramètres affiche la section Langue',
        (tester) async {
      await pumpLocalizedApp(tester);

      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Langue'), findsOneWidget);

      // The SegmentedButton shows both options.
      expect(find.text('Francais'), findsOneWidget);
      expect(find.text('Anglais'), findsOneWidget);
    });

    // ─── Step 3: switch to EN ────────────────────────────────────
    // Spec: Step 2 (switch langue -> EN).
    testWidgets('Step 3 : Tap "Anglais" -> LocaleProvider.locale = en',
        (tester) async {
      await pumpLocalizedApp(tester);

      // Go to Settings.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();

      // Tap "Anglais" segment.
      await tester.tap(find.text('Anglais'));
      await tester.pumpAndSettle();

      // The LocaleProvider's locale is now EN.
      expect(localeProvider.locale.languageCode, 'en');
    });

    // ─── Step 4: verify AppLocalizations produces EN strings ─────
    // Spec: Step 3 (vérifier que les textes changent — Bonjour -> Hello).
    //
    // We verify the AppLocalizations layer directly via a Builder. When
    // the locale is EN, AppLocalizations.of(context)!.welcomeGreeting('Amina')
    // must return "Hello, Amina!". When FR, "Bonjour, Amina !".
    testWidgets('Step 4 : AppLocalizations EN -> "Hello, Amina !" / FR -> "Bonjour, Amina !"',
        (tester) async {
      await pumpLocalizedApp(tester);

      // Helper to read the current AppLocalizations greeting.
      String? readGreeting() {
        final context = tester.element(find.byType(HomeScreen).first);
        final l10n = AppLocalizations.of(context);
        return l10n?.welcomeGreeting('Amina');
      }

      // Default is FR.
      expect(localeProvider.locale.languageCode, 'fr');
      await tester.pumpAndSettle();
      expect(readGreeting(), 'Bonjour, Amina !');

      // Switch to EN via Settings.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anglais'));
      await tester.pumpAndSettle();

      // Go back to Home.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Now AppLocalizations returns the EN greeting.
      expect(localeProvider.locale.languageCode, 'en');
      expect(readGreeting(), 'Hello, Amina!');
    });

    // ─── Step 5: locale persists across navigation ───────────────
    // Spec: Step 4 (naviguer à travers Home, Révision — vérifier traductions).
    testWidgets('Step 5 : Navigation Home -> Révision conserve la locale EN',
        (tester) async {
      await pumpLocalizedApp(tester);

      // Switch to EN via Settings.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anglais'));
      await tester.pumpAndSettle();
      expect(localeProvider.locale.languageCode, 'en');

      // Back to Home.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(localeProvider.locale.languageCode, 'en');

      // Navigate to Revision.
      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();
      expect(localeProvider.locale.languageCode, 'en');

      // Quit the revision (close button -> quit dialog -> "Quitter").
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();

      // Back on Home, locale still EN.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(localeProvider.locale.languageCode, 'en');
    });

    // ─── Step 6: switch back to FR ───────────────────────────────
    // Bonus: verify we can switch back to French.
    testWidgets('Step 6 : Tap "Francais" -> LocaleProvider.locale = fr',
        (tester) async {
      await pumpLocalizedApp(tester);

      // Switch to EN first.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anglais'));
      await tester.pumpAndSettle();
      expect(localeProvider.locale.languageCode, 'en');

      // Switch back to FR.
      await tester.tap(find.text('Francais'));
      await tester.pumpAndSettle();
      expect(localeProvider.locale.languageCode, 'fr');
    });
  });
}
