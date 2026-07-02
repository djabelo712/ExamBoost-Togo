// test/integration/onboarding_to_home_test.dart
// Integration scenario (basic E2E): full onboarding journey -> home screen.
//
// Scope (reduced): splash -> welcome step -> identity -> niveau -> matieres
// -> success animation -> home. 10 steps, no detours.
//
// Uses the real GoRouter + FakeUserProvider (no Hive) + MockQuestionService
// + MockSrsService. The fake user provider starts empty so the router lands
// on /splash, then on /onboarding after the 2.5s splash animation. The
// onboarding screen itself calls context.go('/') once the matiere step has
// been submitted and the success view has played for 1.5s.
//
// NOTE: This file imports models annotated with @HiveType, so it requires
// the generated .g.dart adapters. Run:
//   dart run build_runner build --delete-conflicting-outputs

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/auth/onboarding_screen.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';
import 'package:examboost_togo/screens/splash/splash_screen.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';
import 'package:examboost_togo/utils/app_router.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: onboarding -> home (basic E2E)', () {
    late FakeUserProvider userProvider;
    late MockQuestionService questionService;
    late MockSrsService srsService;
    late GoRouter router;

    setUp(() {
      // Fresh state per test -- no pre-seeded user (first launch).
      userProvider = FakeUserProvider();
      questionService =
          MockQuestionService(initialQuestions: sampleQuestions);
      srsService = MockSrsService();
      router = AppRouter.router;
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            Provider<QuestionService>.value(value: questionService),
            Provider<SrsService>.value(value: srsService),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    // ─── Full E2E scenario: 10 steps ─────────────────────────────
    // Steps:
    //   1. Launch app (router starts at /splash).
    //   2. Verify the splash screen is rendered.
    //   3. Pump past the 2.5s splash animation + 50ms redirect delay.
    //   4. Verify OnboardingScreen visible with "Commencer" button.
    //   5. Tap "Commencer" -> identity step (verify "Prenom *" label).
    //   6. Fill "Amina" + "Kossi" in the identity fields.
    //   7. Tap "Suivant" -> niveau step (verify "Ton niveau scolaire").
    //   8. Tap "3eme" + tap "Suivant" -> matieres step.
    //   9. Tap "Mathematiques" + tap "Creer mon profil" + pump past 1.5s
    //      success delay.
    //  10. Verify HomeScreen visible with "Bonjour, Amina".
    testWidgets('E2E : onboarding 5 etapes -> home (10 etapes)',
        (tester) async {
      // Step 1 — Launch app (router starts at /splash).
      await pumpApp(tester);
      await tester.pump();

      // Step 2 — Splash screen rendered.
      expect(find.byType(SplashScreen), findsOneWidget);

      // Step 3 — Pump past the 2.5s splash animation + redirect delay.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Step 4 — Onboarding welcome step. "Commencer" button is rendered.
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);

      // Step 5 — Tap "Commencer" -> identity step.
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      expect(find.text('Prénom *'), findsOneWidget);

      // Step 6 — Fill "Amina" + "Kossi".
      await tester.enterText(
        find.widgetWithText(TextField, 'Prénom *'),
        'Amina',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom *'),
        'Kossi',
      );
      await tester.pumpAndSettle();

      // Step 7 — Tap "Suivant" -> niveau step.
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Ton niveau scolaire'), findsOneWidget);

      // Step 8 — Tap "3eme" -> niveau selected; tap "Suivant" -> matieres step.
      await tester.tap(find.text('3ème'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Tes matières préférées'), findsOneWidget);

      // Step 9 — Tap "Mathematiques" FilterChip + tap "Creer mon profil".
      await tester.tap(find.text('Mathématiques'));
      await tester.pumpAndSettle();
      expect(find.text('Créer mon profil'), findsOneWidget);
      await tester.tap(find.text('Créer mon profil'));

      // The success view shows for 1.5s before context.go(home) fires.
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      // Step 10 — Home screen displayed with "Bonjour, Amina".
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Amina'), findsOneWidget);
    });
  });
}
