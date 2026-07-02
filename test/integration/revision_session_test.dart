// test/integration/revision_session_test.dart
// Integration scenario (basic E2E): home -> revision -> answer 3 questions
// -> session summary. 8 steps, no detours.
//
// Scope (reduced): a single complete revision session end-to-end through
// the GoRouter. We use the 3 maths questions from the sample pool so the
// session ends after exactly 3 answers (Facile = quality 5) and the
// "Session terminee !" summary is displayed.
//
// Uses FakeUserProvider (pre-seeded user, no Hive) + MockQuestionService +
// MockSrsService (in-memory, records every recordAnswer call).
//
// NOTE: Requires generated Hive adapters. Run:
//   dart run build_runner build --delete-conflicting-outputs

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: revision session (basic E2E)', () {
    // ─── Full E2E scenario: 8 steps ──────────────────────────────
    // Steps:
    //   1. Launch app with pre-seeded user -> router will redirect to /home
    //      after the splash animation.
    //   2. Pump past splash -> HomeScreen visible.
    //   3. Tap "Revision Adaptative" -> RevisionScreen visible.
    //   4. Verify first question loaded ("1 / 3" counter + "Voir la reponse"
    //      button visible).
    //   5. Q1: tap "Voir la reponse" -> tap "Facile".
    //   6. Q2: tap "Voir la reponse" -> tap "Facile".
    //   7. Q3: tap "Voir la reponse" -> tap "Facile".
    //   8. Verify "Session terminee !" + "100%" + SrsService recorded 3 calls.
    testWidgets(
        'E2E : home -> revision -> 3 questions -> resume (8 etapes)',
        (tester) async {
      // Build a 3-question maths pool (the 3 maths questions from the sample
      // dataset). The spec asks for a complete session, so we use all 3.
      final mathsQuestions = sampleQuestions
          .where((q) => q.matiere == 'Mathématiques')
          .toList();
      expect(
        mathsQuestions.length,
        3,
        reason: 'Mock pool must contain exactly 3 maths questions.',
      );

      final mockSrs = MockSrsService();
      final questionService =
          MockQuestionService(initialQuestions: mathsQuestions);
      final userProvider =
          FakeUserProvider(user: createTestUser(prenom: 'Amina'));

      // Step 1 — Launch app with pre-seeded user. The router starts at
      // /splash; the splash will call context.go('/') at 2.5s because the
      // user is authenticated.
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

      // Step 2 — Pump past splash (2.5s) -> HomeScreen visible.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Step 3 — Tap "Revision Adaptative" -> RevisionScreen visible.
      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();
      expect(find.byType(RevisionScreen), findsOneWidget);

      // Wait for the questions to load asynchronously (the RevisionScreen
      // fetches them via QuestionService.getForAdaptiveRevision in
      // initState -> _loadQuestions).
      await tester.pumpAndSettle();

      // Step 4 — Verify first question loaded ("1 / 3" counter + "Voir la
      // reponse" button visible).
      expect(find.textContaining('1 /'), findsOneWidget);
      expect(find.text('Voir la réponse'), findsOneWidget);

      // Steps 5-7 — Answer all 3 questions with "Facile" (quality=5).
      for (var i = 0; i < mathsQuestions.length; i++) {
        // Reveal the answer.
        expect(
          find.text('Voir la réponse'),
          findsOneWidget,
          reason: 'Question $i: "Voir la réponse" button missing.',
        );
        await tester.tap(find.text('Voir la réponse'));
        await tester.pumpAndSettle();

        // Rate the question "Facile" (quality=5 -> success).
        expect(
          find.text('Facile'),
          findsOneWidget,
          reason: 'Question $i: "Facile" button missing.',
        );
        await tester.tap(find.text('Facile'));
        await tester.pumpAndSettle();
      }

      // Step 8 — Session summary visible ("Session terminee !" + 100% +
      // SrsService recorded all 3 answers with quality=5).
      expect(find.text('Session terminée !'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(mockSrs.recordedCalls.length, mathsQuestions.length);
      for (final call in mockSrs.recordedCalls) {
        expect(call.quality, 5);
        expect(call.userId, 'test-user');
      }
    });
  });
}
