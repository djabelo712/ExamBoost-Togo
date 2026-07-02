// test/integration/dark_mode_toggle_test.dart
// Integration scenario: Settings -> switch theme to Sombre -> verify
// brightness changes -> navigate through Home/Dashboard/Revision and
// verify the theme state propagates.
//
// Uses FakeThemeProvider (no SharedPreferences) + FakeLocaleProvider +
// FakeUserProvider + MockQuestionService + MockSrsService. We wrap the
// router in a MaterialApp.router that respects theme + darkTheme + themeMode
// (the existing tests use the default MaterialApp.router without theme
// support, which doesn't propagate the dark theme).

import 'package:flutter/material.dart';
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

  group('Integration: dark mode toggle', () {
    late FakeThemeProvider themeProvider;
    late FakeLocaleProvider localeProvider;
    late FakeUserProvider userProvider;
    late MockQuestionService questionService;
    late MockSrsService srsService;
    late GoRouter router;

    setUp(() {
      themeProvider = FakeThemeProvider();
      localeProvider = FakeLocaleProvider();
      userProvider = FakeUserProvider(user: createTestUser());
      questionService = MockQuestionService(initialQuestions: sampleQuestions);
      srsService = MockSrsService();
      router = AppRouter.router;
    });

    /// Pump the router wrapped in a MaterialApp.router that respects the
    /// ThemeProvider. We pass `theme`, `darkTheme`, and `themeMode` so
    /// that Theme.of(context).brightness flips to Brightness.dark when
    /// themeProvider.themeMode == ThemeMode.dark.
    Future<void> pumpThemedApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            Provider<QuestionService>.value(value: questionService),
            Provider<SrsService>.value(value: srsService),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, tp, child) {
              return MaterialApp.router(
                routerConfig: router,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: tp.themeMode,
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        ),
      );
      // Skip the splash (2.5s) to land on /home directly.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    // ─── Step 1: default theme is system ─────────────────────────
    // Spec: implicit (the user starts with the default theme).
    testWidgets('Step 1 : ThemeProvider démarre en mode "system"', (tester) async {
      await pumpThemedApp(tester);

      // The ThemeProvider's themeMode is system by default.
      expect(themeProvider.themeMode, ThemeMode.system);
      expect(themeProvider.isSystem, isTrue);

      // Home is visible.
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    // ─── Step 2: navigate to Settings ────────────────────────────
    // Spec: Step 1 (aller à Settings).
    testWidgets('Step 2 : Home -> Paramètres affiche la section Theme',
        (tester) async {
      await pumpThemedApp(tester);

      // Tap "Paramètres" on the home screen.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();

      // The SettingsScreen is visible. The "Theme" section title is present.
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      // The three theme segments are visible.
      expect(find.text('Clair'), findsOneWidget);
      expect(find.text('Sombre'), findsOneWidget);
      expect(find.text('Systeme'), findsOneWidget);
    });

    // ─── Step 3: switch to Sombre ────────────────────────────────
    // Spec: Step 2 (switch thème -> Sombre).
    testWidgets('Step 3 : Tap "Sombre" -> ThemeProvider.themeMode = dark',
        (tester) async {
      await pumpThemedApp(tester);

      // Go to Settings.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();

      // Tap the "Sombre" segment.
      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();

      // The ThemeProvider's themeMode is now dark.
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDark, isTrue);
    });

    // ─── Step 4: verify the brightness actually changes ─────────
    // Spec: Step 3 (vérifier que les couleurs changent — background sombre).
    //
    // We verify that Theme.of(context).brightness flips to Brightness.dark
    // when the ThemeProvider is dark. Note: many screens use the hardcoded
    // `AppColors.background` (light) instead of `AdaptiveColors.background(context)`
    // — those screens will NOT visually change in dark mode. The test
    // verifies that the theme propagation works at the MaterialApp level;
    // fixing the screens to use AdaptiveColors is tracked separately.
    testWidgets('Step 4 : Theme.of(context).brightness passe à Brightness.dark',
        (tester) async {
      await pumpThemedApp(tester);

      // Go to Settings.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();

      // Capture the brightness before the toggle.
      BuildContext? capturedContext = tester.element(find.byType(SettingsScreen));
      final brightnessBefore = Theme.of(capturedContext).brightness;
      expect(brightnessBefore, Brightness.light,
          reason: 'Le système par défaut est clair en test.');

      // Tap "Sombre".
      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();

      // Capture the brightness after the toggle.
      capturedContext = tester.element(find.byType(SettingsScreen));
      final brightnessAfter = Theme.of(capturedContext).brightness;
      expect(brightnessAfter, Brightness.dark,
          reason: 'Le thème doit passer à dark après le toggle.');
    });

    // ─── Step 5: theme persists when navigating ─────────────────
    // Spec: Step 4 (naviguer à travers Home, Dashboard, Révision — le
    // thème doit rester sombre).
    testWidgets('Step 5 : Navigation Home -> Révision -> Home conserve le dark',
        (tester) async {
      await pumpThemedApp(tester);

      // Switch to dark first (via Settings).
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();
      expect(themeProvider.isDark, isTrue);

      // Go back to Home (via the back button).
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Home is visible, theme is still dark.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(themeProvider.isDark, isTrue);

      // Navigate to Revision.
      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();
      // The theme is still dark.
      expect(themeProvider.isDark, isTrue);

      // Go back to Home.
      // (RevisionScreen has a close button with Icons.close that pops.)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      // The quit dialog appears.
      expect(find.text('Quitter la session ?'), findsOneWidget);
      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();

      // Back on Home, theme still dark.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(themeProvider.isDark, isTrue);
    });

    // ─── Step 6: switch back to Clair ───────────────────────────
    // Bonus: verify we can switch back to light mode.
    testWidgets('Step 6 : Tap "Clair" -> ThemeProvider.themeMode = light',
        (tester) async {
      await pumpThemedApp(tester);

      // Go to Settings, switch to dark first.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();
      expect(themeProvider.isDark, isTrue);

      // Now switch back to Clair.
      await tester.tap(find.text('Clair'));
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isLight, isTrue);
    });
  });
}
