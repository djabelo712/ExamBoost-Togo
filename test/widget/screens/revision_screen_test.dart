// test/widget/screens/revision_screen_test.dart
// Tests for the RevisionScreen — uses MockSrsService and MockQuestionService.
//
// We test:
//   - Loading state shows CircularProgressIndicator.
//   - After loading, the question enonce is displayed.
//   - "Voir la réponse" tap reveals the answer + SrsButtons.
//   - SrsButtons tap records the answer and advances to the next question.
//   - Empty state (no questions for the matiere) shows the empty widget.
//   - Session end shows the summary screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/revision/revision_screen.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_data.dart';

void main() {
  group('RevisionScreen widget', () {
    // ─── Loading + success path ───────────────────────────────────
    testWidgets('Affiche l\'indicateur de chargement initial',
        (tester) async {
      final questionService = MockQuestionService(
        initialQuestions: sampleQuestions,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: MockSrsService()),
            ],
            child: const RevisionScreen(
              matiere: 'Mathématiques',
              userId: 'test-user',
            ),
          ),
        ),
      );

      // Before the post-frame callback fires, the loading state should be visible.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement des questions...'), findsOneWidget);
    });

    testWidgets('Affiche la première question après chargement',
        (tester) async {
      final questionService = MockQuestionService(
        initialQuestions: sampleQuestions,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: MockSrsService()),
            ],
            child: const RevisionScreen(
              matiere: 'Mathématiques',
              userId: 'test-user',
            ),
          ),
        ),
      );

      // Wait for the post-frame callback + setState.
      await tester.pumpAndSettle();

      // AppBar shows the matiere.
      expect(find.text('Mathématiques'), findsWidgets);
      // Progress counter "1 / N".
      expect(find.textContaining('1 /'), findsOneWidget);
      // "Voir la réponse" button visible.
      expect(find.text('Voir la réponse'), findsOneWidget);
    });

    testWidgets('Tap "Voir la réponse" révèle SrsButtons', (tester) async {
      final questionService = MockQuestionService(
        initialQuestions: sampleQuestions,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: MockSrsService()),
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

      // SrsButtons now visible.
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Difficile'), findsOneWidget);
      expect(find.text('Oublié'), findsOneWidget);
    });

    testWidgets('Tap "Facile" enregistre la réponse et avance',
        (tester) async {
      final mockSrs = MockSrsService();
      final questionService = MockQuestionService(
        initialQuestions: sampleQuestions,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
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

      // Counter before: "1 / N"
      expect(find.textContaining('1 /'), findsOneWidget);

      await tester.tap(find.text('Voir la réponse'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Facile'));
      await tester.pumpAndSettle();

      // Counter after: "2 / N"
      expect(find.textContaining('2 /'), findsOneWidget);

      // recordAnswer was called once with quality=5.
      expect(mockSrs.recordedCalls.length, 1);
      expect(mockSrs.recordedCalls.first.quality, 5);
    });

    testWidgets('État vide : affiche "Aucune question disponible"',
        (tester) async {
      final questionService = MockQuestionService(
        initialQuestions: const [], // empty
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: MockSrsService()),
            ],
            child: const RevisionScreen(
              matiere: 'Philosophie', // not in sampleQuestions
              userId: 'test-user',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Aucune question disponible'), findsOneWidget);
      expect(find.text('Retour'), findsOneWidget);
    });

    testWidgets('État d\'erreur : affiche le bouton "Réessayer"',
        (tester) async {
      final questionService = MockQuestionService(shouldFail: true);
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: MockSrsService()),
            ],
            child: const RevisionScreen(
              matiere: 'Mathématiques',
              userId: 'test-user',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('Bouton "Passer la question" avance sans enregistrer',
        (tester) async {
      final mockSrs = MockSrsService();
      final questionService = MockQuestionService(
        initialQuestions: sampleQuestions,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
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
      expect(find.textContaining('1 /'), findsOneWidget);

      await tester.tap(find.text('Passer la question'));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 /'), findsOneWidget);
      // No SRS call recorded (passing = no answer).
      expect(mockSrs.recordedCalls.length, 0);
    });

    testWidgets('Fin de session : affiche l\'écran de résumé', (tester) async {
      // Use only 1 question to reach the end fast.
      final oneQuestion = sampleQuestions
          .where((q) => q.matiere == 'Mathématiques')
          .take(1)
          .toList();
      final mockSrs = MockSrsService();
      final questionService = MockQuestionService(
        initialQuestions: oneQuestion,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
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

      // End of session summary.
      expect(find.text('Session terminée !'), findsOneWidget);
      expect(find.text('Retour au tableau de bord'), findsOneWidget);
      expect(find.text('Recommencer une session'), findsOneWidget);
    });

    testWidgets('AppBar : bouton close ouvre le dialog de confirmation',
        (tester) async {
      final questionService = MockQuestionService(
        initialQuestions: sampleQuestions,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              Provider<QuestionService>.value(value: questionService),
              Provider<SrsService>.value(value: MockSrsService()),
            ],
            child: const RevisionScreen(
              matiere: 'Mathématiques',
              userId: 'test-user',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Quitter la session ?'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.text('Quitter'), findsOneWidget);
    });
  });
}
