// test/widget/widgets/question_card_test.dart
// Tests for the QuestionCard widget (front: question, back: answer).
//
// The card uses an Animation<double> for the flip effect. We test:
//   - Front: shows question.enonce and chapitre, NOT the answer.
//   - Back: shows question.reponse and explication, NOT the enonce.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/question.dart';
import 'package:examboost_togo/widgets/cards/question_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('QuestionCard widget', () {
    late AnimationController controller;
    late Animation<double> animation;

    setUp(() {
      // We'll create the controller inside each testWidgets since it needs
      // a TickerProvider.
    });

    testWidgets('Affiche l\'énoncé quand flipAnimation.value < 0.5 (recto)',
        (tester) async {
      final q = createTestQuestion(
        enonce: 'Combien font 2+2 ?',
        reponse: '4',
        chapitre: 'Arithmétique',
      );

      controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );
      animation = Tween<double>(begin: 0, end: 1).animate(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: QuestionCard(
                question: q,
                reponseVisible: false,
                flipAnimation: animation,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Combien font 2+2 ?'), findsOneWidget);
      expect(find.text('Arithmétique'), findsOneWidget);
      // The answer should NOT be visible on the front.
      expect(find.text('4'), findsNothing);
    });

    testWidgets('Affiche la réponse quand flipAnimation.value > 0.5 (verso)',
        (tester) async {
      final q = createTestQuestion(
        enonce: 'Combien font 2+2 ?',
        reponse: '4',
        explication: 'Addition de base.',
        chapitre: 'Arithmétique',
      );

      controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );
      // Jump to the end (value=1.0) so isBack=true.
      controller.value = 1.0;
      animation = Tween<double>(begin: 0, end: 1).animate(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: QuestionCard(
                question: q,
                reponseVisible: true,
                flipAnimation: animation,
              ),
            ),
          ),
        ),
      );

      // The answer should be visible.
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Addition de base.'), findsOneWidget);
      expect(find.text('Réponse'), findsOneWidget);
    });

    testWidgets('Affiche l\'explication seulement si elle est non null',
        (tester) async {
      final qWithout = createTestQuestion(
        enonce: 'Q sans explication',
        reponse: 'R',
        explication: null,
      );

      controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );
      controller.value = 1.0;
      animation = Tween<double>(begin: 0, end: 1).animate(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: QuestionCard(
                question: qWithout,
                reponseVisible: true,
                flipAnimation: animation,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Explication'), findsNothing);
    });

    testWidgets('Affiche les points si disponibles (recto)', (tester) async {
      final q = createTestQuestion(
        enonce: 'Q avec points',
        reponse: 'R',
        points: 5,
      );

      controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );
      animation = Tween<double>(begin: 0, end: 1).animate(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: QuestionCard(
                question: q,
                reponseVisible: false,
                flipAnimation: animation,
              ),
            ),
          ),
        ),
      );

      expect(find.text('5 pts'), findsOneWidget);
    });

    testWidgets('N\'affiche pas les points si null (recto)', (tester) async {
      final q = createTestQuestion(
        enonce: 'Q sans points',
        reponse: 'R',
        points: null,
      );

      controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );
      animation = Tween<double>(begin: 0, end: 1).animate(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: QuestionCard(
                question: q,
                reponseVisible: false,
                flipAnimation: animation,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('pts'), findsNothing);
    });

    // Added by Agent BU2 (Session 4 — reduced widget scope).
    // Verifies the recto UX affordances: the help icon + the hint text
    // inviting the student to reveal the answer.
    testWidgets('Recto : affiche l\'icône d\'aide et l\'indice "Voir la réponse"',
        (tester) async {
      final q = createTestQuestion(
        enonce: 'Q avec indice',
        reponse: 'R',
      );

      controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );
      animation = Tween<double>(begin: 0, end: 1).animate(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: QuestionCard(
                question: q,
                reponseVisible: false,
                flipAnimation: animation,
              ),
            ),
          ),
        ),
      );

      // The recto shows a help_outline icon as a visual cue.
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      // The hint text invites the student to reveal the answer.
      expect(find.textContaining('Voir la réponse'), findsOneWidget);
    });

    tearDown(() {
      controller.dispose();
    });
  });
}
