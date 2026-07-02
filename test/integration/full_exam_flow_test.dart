// test/integration/full_exam_flow_test.dart
// Integration scenario: home -> simulation -> config -> exam -> rapport.
//
// Uses FakeUserProvider + MockQuestionService (10 BEPC QCM questions) +
// MockSrsService. The full E2E test exercises:
//   1. Home (authenticated user).
//   2. Tap "Simulation d'Examen".
//   3. Config screen (BEPC already selected, pick "10 questions").
//   4. Tap "Démarrer l'examen".
//   5. Answer all 10 questions (tap 'A' on each QCM).
//   6. Tap "Terminer" on the last question.
//   7. Confirm dialog -> tap "Terminer".
//   8. Rapport displayed with score "/ 20".
//
// NOTE: The SimulationScreen uses Hive boxes, so this test requires the
// generated .g.dart adapters. Run:
//   dart run build_runner build --delete-conflicting-outputs

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/models/question.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
      // Skip the 2.5s splash animation so we land on /home directly.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    // ─── Smoke tests (existing) ─────────────────────────────────

    testWidgets('Navigation home -> simulation affiche SimulationScreen',
        (tester) async {
      await pumpApp(tester);

      // Verify we're on home.
      expect(find.byType(HomeScreen), findsOneWidget);

      // Tap "Simulation d'Examen".
      await tester.tap(find.text("Simulation d'Examen"));
      await tester.pumpAndSettle();

      // Should be on the SimulationScreen.
      expect(find.byType(SimulationScreen), findsOneWidget);
    });

    testWidgets('Home -> dashboard navigation works', (tester) async {
      await pumpApp(tester);

      // Tap "Mon Tableau de Bord".
      await tester.tap(find.text('Mon Tableau de Bord'));
      await tester.pumpAndSettle();

      // DashboardScreen should be present.
      // Note: we don't import DashboardScreen to avoid extra deps; we just
      // verify that we navigated away from HomeScreen.
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Home -> paramètres navigation works', (tester) async {
      await pumpApp(tester);

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

    // ─── Full E2E scenario: 8 steps ─────────────────────────────
    // Spec: full_exam_flow_test.dart — 8 steps.
    //
    // Steps:
    //   1. User already onboarded (mocked) — lands on /home.
    //   2. Tap "Simulation d'Examen" -> /simulation.
    //   3. Config screen displayed; BEPC selected by default.
    //   4. Tap "10 questions" chip.
    //   5. Tap "Démarrer l'examen".
    //   6. Answer all 10 QCM questions (tap 'A' on each, then Suivant/Terminer).
    //   7. Confirm dialog -> tap "Terminer".
    //   8. Rapport displayed with score "/ 20".
    testWidgets('E2E : home -> simulation BEPC 10 questions -> rapport (8 étapes)',
        (tester) async {
      // Build a custom pool of 10 BEPC QCM questions where 'A' is correct.
      // This makes the answer flow deterministic (always tap 'A').
      final bepcQcmPool = List<Question>.generate(10, (i) {
        return Question(
          id: 'TG-BEPC-QCM-Q${i.toString().padLeft(2, '0')}',
          enonce: 'Question ${i + 1} : Quelle est la bonne réponse ?',
          reponse: 'A',
          explication: 'A est correct.',
          matiere: 'Mathématiques',
          chapitre: 'Chapitre QCM $i',
          competenceId: 'TG-MATHS-QCM-$i',
          examen: 'BEPC',
          annee: 2022,
          type: QuestionType.qcm,
          choix: const ['A', 'B', 'C', 'D'],
          points: 2,
          irtB: -0.5,
        );
      });
      // Override the question service with the custom pool.
      questionService = MockQuestionService(initialQuestions: bepcQcmPool);

      // Step 1 — Pump the router with an authenticated user.
      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      // Step 2 — Tap "Simulation d'Examen".
      await tester.tap(find.text("Simulation d'Examen"));
      await tester.pumpAndSettle();

      // Step 3 — Config screen displayed. BEPC is selected by default
      // (the home screen passes examen='BEPC'). The AppBar shows
      // "Configuration de l'examen".
      expect(find.byType(SimulationScreen), findsOneWidget);
      expect(find.text('Configuration de l\'examen'), findsOneWidget);
      expect(find.text('Choisis ton examen'), findsOneWidget);

      // Step 4 — Tap "10 questions" chip (default is 20).
      expect(find.text('10 questions'), findsOneWidget);
      await tester.tap(find.text('10 questions'));
      await tester.pumpAndSettle();

      // The résumé card now shows "10 questions".
      expect(find.textContaining('10 questions'), findsWidgets);

      // Step 5 — Tap "Démarrer l'examen".
      expect(find.text('Démarrer l\'examen'), findsOneWidget);
      await tester.tap(find.text('Démarrer l\'examen'));
      await tester.pumpAndSettle();

      // Step 6 — Answer all 10 QCM questions. For each question, tap 'A'
      // (the correct choice), then tap "Suivant" (or "Terminer" on the
      // last question).
      for (var i = 0; i < bepcQcmPool.length; i++) {
        // The exam phase shows the question counter "Question N / 10".
        expect(
          find.text('Question ${i + 1} / ${bepcQcmPool.length}'),
          findsOneWidget,
          reason: 'Question ${i + 1}: counter absent.',
        );

        // Tap the 'A' choice (correct). The QCM choices are rendered as
        // InkWell with the choice text. Multiple widgets may contain 'A',
        // so we use the first find to disambiguate.
        final aFinder = find.text('A');
        expect(aFinder, findsWidgets,
            reason: 'Question ${i + 1}: choice "A" not found.');
        await tester.tap(aFinder.first);
        await tester.pumpAndSettle();

        // Tap "Suivant" (or "Terminer" on the last question).
        final isLast = i == bepcQcmPool.length - 1;
        final navButtonFinder = find.text(isLast ? 'Terminer' : 'Suivant');
        expect(navButtonFinder, findsOneWidget,
            reason: 'Question ${i + 1}: navigation button absent.');
        await tester.tap(navButtonFinder);
        await tester.pumpAndSettle();

        // On the last question, a confirm dialog appears.
        if (isLast) {
          // Step 7 — Confirm dialog -> tap "Terminer".
          expect(find.text('Terminer l\'examen ?'), findsOneWidget);
          // The dialog has TWO "Terminer" entries: the navigation button
          // (now hidden behind the dialog overlay) and the dialog's
          // ElevatedButton. We tap the dialog's "Terminer" via the
          // last match.
          final dialogTerminer = find.text('Terminer');
          expect(dialogTerminer, findsWidgets,
              reason: 'Confirm dialog: "Terminer" button not found.');
          await tester.tap(dialogTerminer.last);
          await tester.pumpAndSettle();
        }
      }

      // Step 8 — Rapport displayed with score "/ 20".
      expect(find.text('Rapport d\'examen'), findsOneWidget);
      expect(find.text('Examen terminé !'), findsOneWidget);
      // The percentage "100%" is displayed (all answers correct).
      expect(find.text('100%'), findsOneWidget);
      // The score sur 20 is displayed as "X.X / 20".
      expect(find.textContaining('/ 20'), findsOneWidget);
    });
  });
}
