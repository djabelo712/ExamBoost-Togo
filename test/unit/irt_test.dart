// test/unit/irt_test.dart
// IRT 3-Parameter Logistic (3PL) model tests.
//
// CRITICAL tests for the adaptive-question-selection probability model
// at the heart of ExamBoost Togo. The SrsService.irtProbability() implements:
//
//   P(correct) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))
//
// Where:
//   theta = student ability
//   a     = discrimination
//   b     = difficulty
//   c     = guessing (lower asymptote)
//
// selectBestQuestion() returns the question whose b is the closest to the
// student's theta (so the question targets the student's level).
//
// Reference: Birnbaum (1968), Lord (1980).

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/question.dart';
import 'package:examboost_togo/services/srs_service.dart';

void main() {
  late SrsService srs;

  setUp(() {
    // SrsService() constructor is safe to call without Hive init —
    // irtProbability and selectBestQuestion do not touch the box.
    srs = SrsService();
  });

  group('IRT 3PL', () {
    // ─── Basic shape ──────────────────────────────────────────────
    group('Forme de base', () {
      test('P = 0.5 quand theta = b (sans chance)', () {
        final p = srs.irtProbability(theta: 0.0, a: 1.0, b: 0.0, c: 0.0);
        expect(p, closeTo(0.5, 0.01));
      });

      test('P = 0.5 quand theta = b, meme avec a eleve', () {
        // At theta=b, exp(0)=1, so P=1/(1+1)=0.5 regardless of a.
        final p = srs.irtProbability(theta: 0.0, a: 5.0, b: 0.0, c: 0.0);
        expect(p, closeTo(0.5, 0.01));
      });

      test('P augmente avec theta', () {
        final p1 = srs.irtProbability(theta: -1, a: 1, b: 0, c: 0);
        final p2 = srs.irtProbability(theta: 0, a: 1, b: 0, c: 0);
        final p3 = srs.irtProbability(theta: 1, a: 1, b: 0, c: 0);
        expect(p1, lessThan(p2));
        expect(p2, lessThan(p3));
      });

      test('P diminue quand b augmente (theta fixe)', () {
        final p1 = srs.irtProbability(theta: 0, a: 1, b: -1, c: 0);
        final p2 = srs.irtProbability(theta: 0, a: 1, b: 0, c: 0);
        final p3 = srs.irtProbability(theta: 0, a: 1, b: 1, c: 0);
        expect(p1, greaterThan(p2));
        expect(p2, greaterThan(p3));
      });
    });

    // ─── Limites asymptotiques ───────────────────────────────────
    group('Limites asymptotiques', () {
      test('Avec chance (c=0.25), P minimale = 0.25', () {
        final p = srs.irtProbability(theta: -10, a: 1, b: 0, c: 0.25);
        expect(p, greaterThanOrEqualTo(0.25));
        expect(p, lessThan(0.30));
      });

      test('P maximale = 1.0 (theta tres grand, c=0)', () {
        final p = srs.irtProbability(theta: 10, a: 1, b: 0, c: 0.0);
        expect(p, closeTo(1.0, 0.01));
      });

      test('P maximale = 1.0 (theta tres grand, c>0)', () {
        final p = srs.irtProbability(theta: 10, a: 1, b: 0, c: 0.25);
        expect(p, closeTo(1.0, 0.01));
      });

      test('P minimale = 0 (theta tres petit, c=0)', () {
        final p = srs.irtProbability(theta: -10, a: 1, b: 0, c: 0.0);
        expect(p, lessThan(0.01));
      });

      test('Avec c=0.5, le plancher est 0.5', () {
        final p = srs.irtProbability(theta: -10, a: 1, b: 0, c: 0.5);
        expect(p, greaterThanOrEqualTo(0.5));
        expect(p, lessThan(0.55));
      });
    });

    // ─── Discrimination ───────────────────────────────────────────
    group('Discrimination (a)', () {
      test('a=0 donne P = c + (1-c)*0.5 (pas de discrimination)', () {
        // a=0 -> exp(0)=1 -> P = c + (1-c) * 0.5 = 0.5 (if c=0)
        final p = srs.irtProbability(theta: 5, a: 0, b: 0, c: 0);
        expect(p, closeTo(0.5, 0.001));
      });

      test('Discrimination elevee : P plus sensible a theta', () {
        // At theta=b+0.5, a higher a gives a higher P than a lower a.
        final pLowA = srs.irtProbability(theta: 0.5, a: 0.5, b: 0, c: 0);
        final pHighA = srs.irtProbability(theta: 0.5, a: 2.0, b: 0, c: 0);
        expect(pHighA, greaterThan(pLowA));
      });
    });

    // ─── Overflow protection ─────────────────────────────────────
    group('Overflow protection', () {
      test('theta extremaux ne crashent pas', () {
        expect(
          () => srs.irtProbability(theta: 1000, a: 1, b: 0, c: 0),
          returnsNormally,
        );
        expect(
          () => srs.irtProbability(theta: -1000, a: 1, b: 0, c: 0),
          returnsNormally,
        );
      });

      test('a extreme ne crash pas', () {
        expect(
          () => srs.irtProbability(theta: 1, a: 1000, b: 0, c: 0),
          returnsNormally,
        );
      });

      test('a negatif ne crash pas (item anti-discriminant)', () {
        // a < 0 is theoretically invalid but should not crash.
        final p = srs.irtProbability(theta: 1, a: -1, b: 0, c: 0);
        expect(p, greaterThanOrEqualTo(0.0));
        expect(p, lessThanOrEqualTo(1.0));
      });
    });

    // ─── Output bounds ────────────────────────────────────────────
    group('Output bounds', () {
      test('Toujours dans [0, 1] pour theta varies', () {
        for (double theta = -5; theta <= 5; theta += 0.5) {
          final p = srs.irtProbability(theta: theta, a: 1.5, b: 0, c: 0.2);
          expect(p, greaterThanOrEqualTo(0.0));
          expect(p, lessThanOrEqualTo(1.0));
        }
      });

      test('Toujours dans [c, 1] pour theta varies (c > 0)', () {
        const c = 0.25;
        for (double theta = -5; theta <= 5; theta += 0.5) {
          final p = srs.irtProbability(theta: theta, a: 1.5, b: 0, c: c);
          expect(p, greaterThanOrEqualTo(c));
          expect(p, lessThanOrEqualTo(1.0));
        }
      });
    });

    // ─── Symmetry ────────────────────────────────────────────────
    group('Symmetry', () {
      test('P(theta=b+x) = 1 - P(theta=b-x) quand c=0', () {
        // Without guessing, the ICC is symmetric around theta=b in logit space.
        const b = 0.5;
        final pPlus = srs.irtProbability(theta: b + 1, a: 1.2, b: b, c: 0);
        final pMinus = srs.irtProbability(theta: b - 1, a: 1.2, b: b, c: 0);
        expect(pPlus + pMinus, closeTo(1.0, 0.001));
      });
    });
  });

  // ─── selectBestQuestion ────────────────────────────────────────
  group('selectBestQuestion', () {
    Question makeQuestion(String id, double b) => Question(
          id: id,
          enonce: 'e',
          reponse: 'r',
          matiere: 'Mathematiques',
          chapitre: 'c',
          competenceId: 'comp',
          examen: 'BEPC',
          type: QuestionType.calcul,
          irtB: b,
        );

    test('Retourne la question dont b est le plus proche de theta', () {
      final questions = <Question>[
        makeQuestion('Q-easy', -1.5), // | -1.5 - 0 | = 1.5
        makeQuestion('Q-mid', 0.0), // |  0.0 - 0 | = 0.0 <-- closest
        makeQuestion('Q-hard', 1.5), // |  1.5 - 0 | = 1.5
      ];
      final best = srs.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: 0.0,
      );
      expect(best, isNotNull);
      expect(best!.id, 'Q-mid');
    });

    test('theta positif eleve -> choisit la question difficile', () {
      final questions = <Question>[
        makeQuestion('Q-easy', -1.0),
        makeQuestion('Q-mid', 0.0),
        makeQuestion('Q-hard', 1.0), // | 1.0 - 1.0 | = 0 <-- closest
      ];
      final best = srs.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: 1.0,
      );
      expect(best, isNotNull);
      expect(best!.id, 'Q-hard');
    });

    test('theta tres negatif -> choisit la question facile', () {
      final questions = <Question>[
        makeQuestion('Q-easy', -1.5), // | -1.5 - (-1.0) | = 0.5 <-- closest
        makeQuestion('Q-mid', 0.0),
        makeQuestion('Q-hard', 1.0),
      ];
      final best = srs.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: -1.0,
      );
      expect(best, isNotNull);
      expect(best!.id, 'Q-easy');
    });

    test('Retourne null si liste vide', () {
      final result = srs.selectBestQuestion(
        availableQuestions: <Question>[],
        thetaUser: 0.0,
      );
      expect(result, isNull);
    });

    test('Question sans irtB : considere b = 0.0', () {
      final qNoB = Question(
        id: 'Q-noB',
        enonce: 'e',
        reponse: 'r',
        matiere: 'Mathematiques',
        chapitre: 'c',
        competenceId: 'comp',
        examen: 'BEPC',
        type: QuestionType.calcul,
        // irtB null -> b defaults to 0.0 inside selectBestQuestion.
      );
      final qFar = makeQuestion('Q-far', 2.0);
      final best = srs.selectBestQuestion(
        availableQuestions: <Question>[qFar, qNoB],
        thetaUser: 0.0,
      );
      expect(best, isNotNull);
      expect(best!.id, 'Q-noB');
    });

    test('Single-element list returns that element', () {
      final questions = <Question>[makeQuestion('only', 0.5)];
      final best = srs.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: 0.0,
      );
      expect(best, isNotNull);
      expect(best!.id, 'only');
    });
  });
}
