// test/widget/screens/settings_screen_test.dart
// Tests for the SettingsScreen — 6 sections (Langue, Thème, Compte,
// À propos, Données, Notifications).
//
// The SettingsScreen uses LocaleProvider + ThemeProvider (Consumer) and
// reads SharedPreferences in initState for the toggle states. We wrap
// the screen with the two providers and pre-seed SharedPreferences with
// empty values (defaults are used).
//
// We test:
//   - 6 section titles visible (Langue, Thème, Compte, À propos,
//     Données et confidentialité, Notifications).
//   - Switch langue FR → EN updates the LocaleProvider.
//   - Switch thème → Sombre updates the ThemeProvider.
//
// Note: the screen uses context.go(...) on the back button, which we
// avoid tapping to keep the test free of GoRouter wiring.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:examboost_togo/providers/locale_provider.dart';
import 'package:examboost_togo/providers/theme_provider.dart';
import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/settings/settings_screen.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('SettingsScreen widget', () {
    setUpAll(() {
      // Empty SharedPreferences — the screen uses defaults
      // (_analyticsEnabled=true, _dailyReminderEnabled=true, etc.).
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    Future<void> pumpSettings(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              ChangeNotifierProvider<LocaleProvider>.value(
                value: LocaleProvider(),
              ),
              ChangeNotifierProvider<ThemeProvider>.value(
                value: ThemeProvider(),
              ),
            ],
            child: const SettingsScreen(),
          ),
        ),
      );
      // Let _loadSettings() resolve.
      await tester.pumpAndSettle();
    }

    testWidgets('6 sections visibles (Langue, Thème, Compte, À propos, Données, Notifications)',
        (tester) async {
      await pumpSettings(tester);
      // The source uses unaccented strings (Langue, Theme, Compte,
      // A propos, Donnees et confidentialite, Notifications) — matches
      // the existing code style of the project.
      expect(find.text('Langue'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Compte'), findsOneWidget);
      expect(find.text('A propos'), findsOneWidget);
      expect(find.text('Donnees et confidentialite'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('Switch langue FR → EN : LocaleProvider change en "en"',
        (tester) async {
      final localeProvider = LocaleProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              ChangeNotifierProvider<LocaleProvider>.value(
                value: localeProvider,
              ),
              ChangeNotifierProvider<ThemeProvider>.value(
                value: ThemeProvider(),
              ),
            ],
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default locale is 'fr'.
      expect(localeProvider.locale.languageCode, 'fr');

      // Tap the "Anglais" segment.
      await tester.tap(find.text('Anglais'));
      await tester.pumpAndSettle();

      // The LocaleProvider should now be 'en'.
      expect(localeProvider.locale.languageCode, 'en');
    });

    testWidgets('Switch thème → Sombre : ThemeProvider passe en ThemeMode.dark',
        (tester) async {
      final themeProvider = ThemeProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              ChangeNotifierProvider<LocaleProvider>.value(
                value: LocaleProvider(),
              ),
              ChangeNotifierProvider<ThemeProvider>.value(
                value: themeProvider,
              ),
            ],
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default theme is system.
      expect(themeProvider.themeMode, ThemeMode.system);

      // Tap the "Sombre" segment.
      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.dark);
    });
  });
}
