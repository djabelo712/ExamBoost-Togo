// test/integration/full_exam_flow_test.dart
// Integration scenario: home -> simulation -> (config) -> exam questions.
//
// This is a smoke test that verifies the SimulationScreen renders after
// navigation from HomeScreen. Full simulation flow (timer, scoring) is
// tested separately in the simulation_screen_test.dart (if available).
//
// NOTE: The SimulationScreen uses Hive boxes, so this test requires the
// generated .g.dart adapters. Run:
//   dart run build_runner build --delete-conflicting-outputs

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';
import 'package:examboost_togo/screens/simulation/simulation_screen.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';
import 'package:examboost_togo/utils/app_router.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Integration: full exam flow (home -> simulation)', () {
    late FakeUserProvider userProvider;
    late MockQuestionService questionService;
    late MockSrsService srsService;
    late GoRouter router;

    setUp(() {
      userProvider = FakeUserProvider(user: createTestUser());
      questionService = MockQuestionService(initialQuestions: sampleQuestions);
      srsService = MockSrsService();
      router = AppRouter.router;
    });

    testWidgets('Navigation home -> simulation affiche SimulationScreen',
        (tester) async {
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
      await tester.pumpAndSettle();

      // Verify we're on home.
      expect(find.byType(HomeScreen), findsOneWidget);

      // Tap "Simulation d'Examen".
      await tester.tap(find.text("Simulation d'Examen"));
      await tester.pumpAndSettle();

      // Should be on the SimulationScreen.
      expect(find.byType(SimulationScreen), findsOneWidget);
    });

    testWidgets('Home -> dashboard navigation works', (tester) async {
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
      await tester.pumpAndSettle();

      // Tap "Mon Tableau de Bord".
      await tester.tap(find.text('Mon Tableau de Bord'));
      await tester.pumpAndSettle();

      // DashboardScreen should be present.
      // Note: we don't import DashboardScreen to avoid extra deps; we just
      // verify that we navigated away from HomeScreen.
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Home -> paramètres navigation works', (tester) async {
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();

      // Navigated away from home.
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Onboarding -> home -> simulation (full flow)',
        (tester) async {
      // Start without a user.
      userProvider = FakeUserProvider();

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
      await tester.pumpAndSettle();

      // Should be on onboarding (no user).
      expect(find.text('Commencer'), findsOneWidget);

      // Now simulate a login (as if the user completed onboarding).
      await userProvider.setCurrentUser(createTestUser());
      await tester.pumpAndSettle();

      // Now on home.
      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to simulation.
      await tester.tap(find.text("Simulation d'Examen"));
      await tester.pumpAndSettle();

      expect(find.byType(SimulationScreen), findsOneWidget);
    });
  });
}
