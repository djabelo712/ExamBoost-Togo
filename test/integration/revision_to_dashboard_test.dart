// test/integration/revision_to_dashboard_test.dart
// Integration scenario: RevisionScreen -> answer all questions -> session
// summary -> tap "Retour au tableau de bord".
//
// Uses FakeUserProvider + MockQuestionService (1 question) + MockSrsService.
// We use a small question pool so the session ends after one answer.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/revision/revision_screen.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Integration: revision -> session end -> dashboard', () {
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
  });
}
