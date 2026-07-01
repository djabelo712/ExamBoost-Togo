// test/golden/home_screen_golden_test.dart
// Golden test for the HomeScreen — captures a screenshot for visual
// regression testing.
//
// Golden files are pixel-perfect captures that fail when the UI changes.
// They are platform-specific (font rendering, anti-aliasing differ between
// macOS, Linux, Windows). Use them with caution in CI.
//
// To generate the baseline:
//   flutter test --update-goldens test/golden/home_screen_golden_test.dart
//
// To verify (CI):
//   flutter test test/golden/home_screen_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/auth/onboarding_screen.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';
import 'package:examboost_togo/widgets/buttons/srs_buttons.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Golden tests', () {
    testWidgets('HomeScreen golden (with user)', (tester) async {
      // Use a fixed user so the greeting is stable.
      final user = createTestUser(prenom: 'Kofi', nom: 'Komla');
      final userProvider = FakeUserProvider(user: user);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_screen.png'),
      );
    });

    testWidgets('HomeScreen golden (no user)', (tester) async {
      final userProvider = FakeUserProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_screen_no_user.png'),
      );
    });

    testWidgets('OnboardingScreen golden (welcome step)', (tester) async {
      final userProvider = FakeUserProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OnboardingScreen),
        matchesGoldenFile('goldens/onboarding_welcome.png'),
      );
    });

    testWidgets('SrsButtons golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SrsButtons(onQualitySelected: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SrsButtons),
        matchesGoldenFile('goldens/srs_buttons.png'),
      );
    });
  });
}
