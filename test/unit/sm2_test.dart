// test/unit/sm2_test.dart
// SM-2 algorithm tests — pure formula verification (no Hive needed).
//
// CRITICAL tests for the spaced-repetition algorithm at the heart of
// ExamBoost Togo. The ReviewCard.applyReview() method implements SM-2:
//
//   On correct (q >= 3):
//     n=0  -> I(1) = 1
//     n=1  -> I(2) = 6
//     n>=2 -> I(n) = floor(I(n-1) * EF)
//     repetitions++, isLearning = false
//   On incorrect (q < 3):
//     n -> 0, I -> 1, isLearning = true
//   EF update (always):
//     EF' = EF + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)
//     EF' = max(EF', 1.3)
//
// Reference: https://www.supermemo.com/en/blog/application-of-a-computer-to-improve-the-results-obtained-in-working-with-the-supermemo-method

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/review_card.dart';

void main() {
  group('SM-2 Algorithm', () {
    // ─── First correct answer ─────────────────────────────────────
    group('Premiere reponse correcte', () {
      test('q=5 (parfaite) : intervalle=1, repetitions=1, EF augmente', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5);
        expect(card.intervalDays, 1);
        expect(card.repetitions, 1);
        // EF = 2.5 + (0.1 - 0*(0.08 + 0*0.02)) = 2.5 + 0.1 = 2.6
        expect(card.easinessFactor, greaterThan(2.5));
        expect(card.easinessFactor, closeTo(2.6, 0.001));
        expect(card.isLearning, false);
        expect(card.correctAttempts, 1);
        expect(card.totalAttempts, 1);
      });

      test('q=4 (correcte) : intervalle=1, EF stable', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(4);
        // EF' = 2.5 + 0.1 - (5-4)*(0.08 + (5-4)*0.02) = 2.5 + 0.1 - 0.1 = 2.5
        expect(card.intervalDays, 1);
        expect(card.repetitions, 1);
        expect(card.easinessFactor, closeTo(2.5, 0.01));
      });

      test('q=3 (correcte difficile) : intervalle=1, EF diminue', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(3);
        // EF' = 2.5 + 0.1 - (5-3)*(0.08 + (5-3)*0.02) = 2.5 + 0.1 - 2*0.12 = 2.36
        expect(card.intervalDays, 1);
        expect(card.repetitions, 1);
        expect(card.easinessFactor, lessThan(2.5));
        expect(card.easinessFactor, closeTo(2.36, 0.01));
      });
    });

    // ─── Second correct answer ────────────────────────────────────
    group('Deuxieme reponse correcte', () {
      test('q=5 puis q=5 : intervalle=6', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // I=1, reps=1
        card.applyReview(5); // I=6, reps=2
        expect(card.intervalDays, 6);
        expect(card.repetitions, 2);
      });
    });

    // ─── Third correct answer ─────────────────────────────────────
    group('Troisieme reponse correcte', () {
      test('q=5 x3 : intervalle = floor(6 x EF)', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // I=1, EF=2.6
        card.applyReview(5); // I=6, EF=2.7
        card.applyReview(5); // I=floor(6 * 2.7) = floor(16.2) = 16, EF=2.8
        expect(card.intervalDays, 16);
        expect(card.repetitions, 3);
        expect(card.easinessFactor, closeTo(2.8, 0.001));
      });

      test('q=5 x4 : intervalle = floor(16 x EF)', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // I=1
        card.applyReview(5); // I=6
        card.applyReview(5); // I=16, EF=2.8
        card.applyReview(5); // I=floor(16 * 2.8) = floor(44.8) = 44, EF=2.9
        expect(card.intervalDays, 44);
        expect(card.repetitions, 4);
      });
    });

    // ─── Incorrect answer (q < 3) ─────────────────────────────────
    group('Reponse incorrecte (q < 3)', () {
      test('q=2 apres 2 correctes : reset repetitions, intervalle=1', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // I=1
        card.applyReview(5); // I=6, reps=2
        card.applyReview(2); // FAILURE
        expect(card.repetitions, 0);
        expect(card.intervalDays, 1);
        expect(card.isLearning, true);
        // correctAttempts has NOT increased on the failure.
        expect(card.correctAttempts, 2);
        expect(card.totalAttempts, 3);
      });

      test('q=0 (blackout) : EF diminue fortement', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        final efBefore = card.easinessFactor;
        card.applyReview(0);
        expect(card.easinessFactor, lessThan(efBefore));
        // EF = 2.5 + 0.1 - (5-0)*(0.08 + 5*0.02)
        //    = 2.5 + 0.1 - 5 * 0.18
        //    = 2.6 - 0.9 = 1.7
        expect(card.easinessFactor, closeTo(1.7, 0.01));
      });

      test('q=1 : EF diminue moins que q=0', () {
        final card0 = ReviewCard(userId: 'u1', questionId: 'q1')
          ..applyReview(0);
        final card1 = ReviewCard(userId: 'u1', questionId: 'q1')
          ..applyReview(1);
        // EF(q=1) = 2.5 + 0.1 - 4*(0.08 + 4*0.02) = 2.6 - 4*0.16 = 2.6 - 0.64 = 1.96
        expect(card1.easinessFactor, closeTo(1.96, 0.01));
        expect(card0.easinessFactor, lessThan(card1.easinessFactor));
      });

      test('isLearning revient a true apres un echec', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5);
        expect(card.isLearning, false);
        card.applyReview(2);
        expect(card.isLearning, true);
      });
    });

    // ─── EF minimum constraint ────────────────────────────────────
    group('EF minimum constraint', () {
      test('EF ne descend jamais sous 1.3', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        for (int i = 0; i < 20; i++) {
          card.applyReview(0);
        }
        expect(card.easinessFactor, greaterThanOrEqualTo(1.3));
      });

      test('EF se stabilise a 1.3 apres plusieurs q=0', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        for (int i = 0; i < 5; i++) {
          card.applyReview(0);
        }
        expect(card.easinessFactor, 1.3);
      });
    });

    // ─── Quality bounds ───────────────────────────────────────────
    group('Quality bounds', () {
      test('q < 0 lance AssertionError', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(() => card.applyReview(-1), throwsA(isA<AssertionError>()));
      });

      test('q > 5 lance AssertionError', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(() => card.applyReview(6), throwsA(isA<AssertionError>()));
      });

      test('q = 0 (limite basse) est accepte', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(() => card.applyReview(0), returnsNormally);
      });

      test('q = 5 (limite haute) est accepte', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(() => card.applyReview(5), returnsNormally);
      });
    });

    // ─── Stats ────────────────────────────────────────────────────
    group('Stats', () {
      test('successRate calcule correctement (2/3)', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // success
        card.applyReview(2); // fail
        card.applyReview(4); // success
        expect(card.totalAttempts, 3);
        expect(card.correctAttempts, 2);
        expect(card.successRate, closeTo(0.667, 0.01));
      });

      test('Carte jamais revue : successRate = 0', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(card.successRate, 0.0);
        expect(card.totalAttempts, 0);
      });

      test('successRate = 1.0 si que des succes', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5);
        card.applyReview(4);
        card.applyReview(3);
        expect(card.successRate, 1.0);
      });
    });

    // ─── isDue ────────────────────────────────────────────────────
    group('isDue', () {
      test('Carte fraichement cree est due', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        // nextReviewDate defaults to DateTime.now() at construction.
        // By the time isDue is evaluated, DateTime.now() has advanced a
        // few microseconds, so isAfter(nextReviewDate) returns true.
        expect(card.isDue, true);
      });

      test("Carte revue avec q=5 n'est pas due dans 1 jour", () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5);
        // nextReview = now + 1 day, so isDue should be false right now.
        expect(card.isDue, false);
      });

      test('isDue true si nextReviewDate dans le passe', () {
        final past = DateTime.now().subtract(const Duration(days: 1));
        final card = ReviewCard(
          userId: 'u1',
          questionId: 'q1',
          nextReviewDate: past,
        );
        expect(card.isDue, true);
      });

      test('isDue false si nextReviewDate dans le futur', () {
        final future = DateTime.now().add(const Duration(days: 1));
        final card = ReviewCard(
          userId: 'u1',
          questionId: 'q1',
          nextReviewDate: future,
        );
        expect(card.isDue, false);
      });
    });

    // ─── Date management ──────────────────────────────────────────
    group('Date management', () {
      test('nextReviewDate est dans le futur apres applyReview', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        final before = DateTime.now();
        card.applyReview(5);
        // interval=1 day, so nextReview approx now + 1 day.
        expect(card.nextReviewDate.isAfter(before), isTrue);
        expect(
          card.nextReviewDate.difference(before).inDays,
          lessThanOrEqualTo(1),
        );
      });

      test('lastReviewDate est mis a jour apres applyReview', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(card.lastReviewDate, isNull);
        final before = DateTime.now();
        card.applyReview(5);
        expect(card.lastReviewDate, isNotNull);
        expect(
          card.lastReviewDate!
              .isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    // ─── SrsQuality enum ──────────────────────────────────────────
    group('SrsQuality enum', () {
      test('Contient les 6 niveaux de qualite (0 a 5)', () {
        expect(SrsQuality.values.length, 6);
        expect(
          SrsQuality.values.map((q) => q.value).toList(),
          [0, 1, 2, 3, 4, 5],
        );
      });

      test('Chaque qualite a un label et une description non vides', () {
        for (final q in SrsQuality.values) {
          expect(q.label, isNotEmpty);
          expect(q.description, isNotEmpty);
        }
      });
    });
  });
}
