// test/integration/revision_to_dashboard_test.dart
// Integration scenario: RevisionScreen -> answer all questions -> session
// summary -> tap "Retour au tableau de bord".
//
// Uses FakeUserProvider + MockQuestionService + MockSrsService.
// The full E2E variant uses the GoRouter so we can navigate from
// home -> revision -> session summary -> back to home (the current
// implementation of "Retour au tableau de bord" calls Navigator.pop,
// which returns to the previous route).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';
import 'package:examboost_togo/screens/revision/revision_screen.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';
import 'package:examboost_togo/utils/app_router.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: revision -> session end -> dashboard', () {
    // ─── Direct-screen tests (MaterialApp.home) ──────────────────

    testWidgets('Session complète : 1 question -> résumé -> retour',
        (tester) async {
      // Use only 1 maths question to end the session after one answer.
      final oneQuestion = sampleQuestions
          .where((q) => q.matiere == 'Mathématiques')
          .take(1)
          .toList();
      final mockSrs = MockSrsService();
      final questionService = MockQuestionService(initialQuestions: oneQuestion);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(user: createTestUser()),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: mockSrs),
            ],
            child: const RevisionScreen(
              matiere: 'Mathématiques',
              userId: 'test-user',
            ),
          ),
        ),
      );

      // Wait for loading.
      await tester.pumpAndSettle();

      // Step 1: reveal the answer.
      await tester.tap(find.text('Voir la réponse'));
      await tester.pumpAndSettle();

      // Step 2: tap "Facile" (quality=5).
      await tester.tap(find.text('Facile'));
      await tester.pumpAndSettle();

      // Step 3: session summary visible.
      expect(find.text('Session terminée !'), findsOneWidget);
      expect(find.textContaining('Tu as répondu correctement'), findsOneWidget);
      // The success rate (100%).
      expect(find.text('100%'), findsOneWidget);

      // The SRS recorded the answer.
      expect(mockSrs.recordedCalls.length, 1);
      expect(mockSrs.recordedCalls.first.quality, 5);
      expect(mockSrs.recordedCalls.first.userId, 'test-user');
    });

    testWidgets('Session complète : 2 questions -> résumé 50%',
        (tester) async {
      final twoQuestions = sampleQuestions
          .where((q) => q.matiere == 'Mathématiques')
          .take(2)
          .toList();
      final mockSrs = MockSrsService();
      final questionService =
          MockQuestionService(initialQuestions: twoQuestions);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(user: createTestUser()),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: mockSrs),
            ],
            child: const RevisionScreen(
              matiere: 'Mathématiques',
              userId: 'test-user',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Question 1: success (Facile).
      await tester.tap(find.text('Voir la réponse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Facile'));
      await tester.pumpAndSettle();

      // Question 2: failure (Oublié).
      await tester.tap(find.text('Voir la réponse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oublié'));
      await tester.pumpAndSettle();

      // Summary: 1/2 = 50%.
      expect(find.text('Session terminée !'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      // 2 SRS calls.
      expect(mockSrs.recordedCalls.length, 2);
      expect(mockSrs.recordedCalls[0].quality, 5); // Facile
      expect(mockSrs.recordedCalls[1].quality, 1); // Oublié
    });

    testWidgets('Tap "Recommencer une session" relance une session',
        (tester) async {
      final oneQuestion = sampleQuestions
          .where((q) => q.matiere == 'Mathématiques')
          .take(1)
          .toList();
      final mockSrs = MockSrsService();
      final questionService = MockQuestionService(initialQuestions: oneQuestion);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(user: createTestUser()),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: mockSrs),
            ],
            child: const RevisionScreen(
              matiere: 'Mathématiques',
              userId: 'test-user',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Answer the only question.
      await tester.tap(find.text('Voir la réponse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Facile'));
      await tester.pumpAndSettle();

      // On summary screen.
      expect(find.text('Session terminée !'), findsOneWidget);

      // Tap "Recommencer une session".
      await tester.tap(find.text('Recommencer une session'));
      await tester.pumpAndSettle();

      // Back to the question screen.
      expect(find.text('Voir la réponse'), findsOneWidget);
      expect(find.text('Session terminée !'), findsNothing);
    });

    testWidgets('Message motivant affiché dans le résumé', (tester) async {
      final oneQuestion = sampleQuestions
          .where((q) => q.matiere == 'Mathématiques')
          .take(1)
          .toList();
      final mockSrs = MockSrsService();
      final questionService = MockQuestionService(initialQuestions: oneQuestion);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(user: createTestUser()),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: mockSrs),
            ],
            child: const RevisionScreen(
              matiere: 'Mathématiques',
              userId: 'test-user',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Voir la réponse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Facile'));
      await tester.pumpAndSettle();

      // The message contains the key phrase "Tu progresses en X ! Continue !"
      expect(find.textContaining('Tu progresses en Mathématiques'), findsOneWidget);
      expect(find.textContaining('Continue'), findsOneWidget);
    });

    // ─── Full E2E scenario: 7 steps ──────────────────────────────
    // Spec: revision_to_dashboard_test.dart — 7 steps.
    //
    // Steps:
    //   1. User already onboarded (mocked) — lands on /home.
    //   2. Tap "Révision Adaptative" -> /revision/Mathématiques.
    //   3. Answer all questions in the mock pool (3 maths questions).
    //   4. Session summary ("Session terminée !") visible.
    //   5. Tap "Retour au tableau de bord" -> Navigator.pop -> back to home.
    //   6. Home screen is visible again.
    //   7. The SrsService recorded all 3 answers (stats updated).
    testWidgets('E2E : home -> révision -> 3 questions -> résumé -> retour (7 étapes)',
        (tester) async {
      // Build a 3-question maths pool (the 3 maths questions from the
      // sample dataset). The spec asks for 5, but the sample dataset only
      // has 3 maths questions; we use 3 to stay within the sample pool.
      final mathsQuestions = sampleQuestions
          .where((q) => q.matiere == 'Mathématiques')
          .toList();
      expect(mathsQuestions.length, 3,
          reason: 'Le pool de mock doit contenir 3 questions de maths.');

      final mockSrs = MockSrsService();
      final questionService =
          MockQuestionService(initialQuestions: mathsQuestions);
      final userProvider =
          FakeUserProvider(user: createTestUser(prenom: 'Amina'));

      // Step 1 — Pump the router with an authenticated user. We start at
      // /splash, but the router redirects to / because the user is
      // authenticated (the splash guard skips redirect, but the
      // post-splash logic sends us to /).
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            Provider<QuestionService>.value(value: questionService),
            Provider<SrsService>.value(value: mockSrs),
          ],
          child: MaterialApp.router(routerConfig: AppRouter.router),
        ),
      );

      // Advance past the splash animation (2.5s) so the splash's
      // post-animation callback fires context.go('/').
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Step 1 (assertion) — We're on HomeScreen.
      expect(find.byType(HomeScreen), findsOneWidget);

      // Step 2 — Tap "Révision Adaptative" -> /revision/Mathématiques.
      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();

      expect(find.byType(RevisionScreen), findsOneWidget);

      // Wait for the questions to load.
      await tester.pumpAndSettle();

      // Step 3 — Answer all 3 questions with "Facile" (quality=5).
      for (var i = 0; i < mathsQuestions.length; i++) {
        // Reveal the answer.
        expect(find.text('Voir la réponse'), findsOneWidget,
            reason: 'Question $i: bouton "Voir la réponse" absent.');
        await tester.tap(find.text('Voir la réponse'));
        await tester.pumpAndSettle();

        // Tap "Facile".
        expect(find.text('Facile'), findsOneWidget,
            reason: 'Question $i: bouton "Facile" absent.');
        await tester.tap(find.text('Facile'));
        await tester.pumpAndSettle();
      }

      // Step 4 — Session summary visible.
      expect(find.text('Session terminée !'), findsOneWidget);
      expect(find.textContaining('Tu as répondu correctement'), findsOneWidget);
      // 3/3 = 100%.
      expect(find.text('100%'), findsOneWidget);

      // Step 5 — Tap "Retour au tableau de bord".
      expect(find.text('Retour au tableau de bord'), findsOneWidget);
      await tester.tap(find.text('Retour au tableau de bord'));
      await tester.pumpAndSettle();

      // Step 6 — We're back on HomeScreen (the current implementation
      // calls Navigator.pop, which returns to the previous route).
      expect(find.byType(RevisionScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);

      // Step 7 — The SrsService recorded all 3 answers.
      expect(mockSrs.recordedCalls.length, mathsQuestions.length);
      for (final call in mockSrs.recordedCalls) {
        expect(call.quality, 5);
        expect(call.userId, 'test-user');
      }
    });
  });
}
