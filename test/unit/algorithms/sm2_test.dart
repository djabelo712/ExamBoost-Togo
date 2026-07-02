// test/unit/algorithms/sm2_test.dart
// SM-2 algorithm tests — pure formula verification (no Hive needed).
//
// The ReviewCard model implements SM-2 in applyReview(). These tests verify
// the algorithm directly against the published SM-2 formulas:
//
//   On correct (q >= 3):
//     n=0  -> I(1) = 1
//     n=1  -> I(2) = 6
//     n>=2 -> I(n) = floor(I(n-1) * EF)
//   On incorrect (q < 3):
//     n -> 0, I -> 1
//   EF update (always):
//     EF' = EF + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)
//     EF' = max(EF', 1.3)
//
// See: https://www.supermemo.com/en/blog/application-of-a-computer-to-improve-the-results-obtained-in-working-with-the-supermemo-method

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/review_card.dart';

void main() {
  group('SM-2 Algorithm', () {
    // ─── Constructor defaults ─────────────────────────────────────
    group('Constructor defaults', () {
      test('New card has correct initial SM-2 state', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(card.repetitions, 0);
        expect(card.easinessFactor, 2.5);
        expect(card.intervalDays, 0);
        expect(card.isLearning, isTrue);
        expect(card.totalAttempts, 0);
        expect(card.correctAttempts, 0);
        expect(card.successRate, 0.0);
      });
    });

    // ─── applyReview - cas corrects ───────────────────────────────
    group('applyReview - cas corrects', () {
      test('Première réponse correcte (q=5) : intervalle doit être 1 jour', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5);
        expect(card.intervalDays, 1);
        expect(card.repetitions, 1);
        // EF increases when q=5: 2.5 + 0.1 = 2.6
        expect(card.easinessFactor, closeTo(2.6, 0.001));
        expect(card.isLearning, isFalse);
      });

      test('Première réponse correcte (q=3) : intervalle = 1, EF diminue légèrement', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(3);
        expect(card.intervalDays, 1);
        expect(card.repetitions, 1);
        // EF' = 2.5 + 0.1 - (5-3)*(0.08 + (5-3)*0.02) = 2.5 + 0.1 - 2*(0.12) = 2.5 - 0.14 = 2.36
        expect(card.easinessFactor, closeTo(2.36, 0.001));
      });

      test('Deuxième réponse correcte (q=4) : intervalle doit être 6 jours', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(4); // 1st correct -> I=1
        card.applyReview(4); // 2nd correct -> I=6
        expect(card.intervalDays, 6);
        expect(card.repetitions, 2);
      });

      test('Troisième réponse correcte : intervalle = floor(prev × EF)', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // I=1, EF=2.6
        card.applyReview(5); // I=6, EF=2.7
        card.applyReview(5); // I=floor(6 × 2.7) = floor(16.2) = 16
        expect(card.intervalDays, 16);
        expect(card.repetitions, 3);
        expect(card.easinessFactor, closeTo(2.8, 0.001));
      });

      test('Quatrième réponse correcte : I = floor(16 × EF)', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // I=1
        card.applyReview(5); // I=6
        card.applyReview(5); // I=16
        card.applyReview(5); // I=floor(16 × 2.8) = 44
        expect(card.intervalDays, 44);
        expect(card.repetitions, 4);
      });

      test('isLearning passe à false après première réponse correcte', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(card.isLearning, isTrue);
        card.applyReview(4);
        expect(card.isLearning, isFalse);
      });
    });

    // ─── applyReview - cas incorrects ─────────────────────────────
    group('applyReview - cas incorrects', () {
      test('Réponse incorrecte (q=2) : reset repetitions, intervalle=1', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // I=1
        card.applyReview(5); // I=6
        expect(card.repetitions, 2);
        card.applyReview(2); // FAILURE
        expect(card.repetitions, 0);
        expect(card.intervalDays, 1);
        expect(card.isLearning, isTrue);
      });

      test('Blackout complet (q=0) : EF diminue fortement', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        final efBefore = card.easinessFactor;
        card.applyReview(0);
        expect(card.easinessFactor, lessThan(efBefore));
        // EF' = 2.5 + 0.1 - (5-0)*(0.08 + (5-0)*0.02) = 2.5 + 0.1 - 5*0.18 = 2.5 - 0.8 = 1.7
        expect(card.easinessFactor, closeTo(1.7, 0.001));
      });

      test('Réponse incorrecte (q=1) : reset mais EF diminue moins que q=0', () {
        final card0 = ReviewCard(userId: 'u1', questionId: 'q1')..applyReview(0);
        final card1 = ReviewCard(userId: 'u1', questionId: 'q1')..applyReview(1);
        // EF(q=1)' = 2.5 + 0.1 - (5-1)*(0.08 + (5-1)*0.02) = 2.5 + 0.1 - 4*(0.16) = 2.5 - 0.54 = 1.96
        expect(card1.easinessFactor, closeTo(1.96, 0.001));
        expect(card0.easinessFactor, lessThan(card1.easinessFactor));
      });

      test('isLearning revient à true après un échec', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // isLearning=false
        expect(card.isLearning, isFalse);
        card.applyReview(2); // isLearning=true
        expect(card.isLearning, isTrue);
      });
    });

    // ─── EF minimum constraint ────────────────────────────────────
    group('EF minimum constraint', () {
      test('EF ne descend jamais sous 1.3', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        for (int i = 0; i < 10; i++) {
          card.applyReview(0); // Many failures
        }
        expect(card.easinessFactor, greaterThanOrEqualTo(1.3));
      });

      test('EF exactement 1.3 après q=0 répétés', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        // After ~3 q=0, EF should hit the 1.3 floor and stay there.
        for (int i = 0; i < 5; i++) {
          card.applyReview(0);
        }
        expect(card.easinessFactor, 1.3);
      });
    });

    // ─── Quality bounds ───────────────────────────────────────────
    group('Quality bounds', () {
      test('q < 0 doit throw assertion error', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(() => card.applyReview(-1), throwsA(isA<AssertionError>()));
      });

      test('q > 5 doit throw assertion error', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(() => card.applyReview(6), throwsA(isA<AssertionError>()));
      });

      test('q = 0 (limite basse) est accepté', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(() => card.applyReview(0), returnsNormally);
      });

      test('q = 5 (limite haute) est accepté', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(() => card.applyReview(5), returnsNormally);
      });
    });

    // ─── Stats ────────────────────────────────────────────────────
    group('Stats', () {
      test('successRate calcul correct (2/3)', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // success
        card.applyReview(2); // fail
        card.applyReview(4); // success
        expect(card.totalAttempts, 3);
        expect(card.correctAttempts, 2);
        expect(card.successRate, closeTo(0.667, 0.01));
      });

      test('successRate = 0 si aucune tentative', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(card.totalAttempts, 0);
        expect(card.successRate, 0.0);
      });

      test('successRate = 1.0 si que des succès', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5);
        card.applyReview(4);
        card.applyReview(3);
        expect(card.successRate, 1.0);
      });

      test('totalAttempts et correctAttempts incrémentés correctement', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(3); // correct
        expect(card.totalAttempts, 1);
        expect(card.correctAttempts, 1);
        card.applyReview(2); // incorrect
        expect(card.totalAttempts, 2);
        expect(card.correctAttempts, 1);
        card.applyReview(5); // correct
        expect(card.totalAttempts, 3);
        expect(card.correctAttempts, 2);
      });
    });

    // ─── Dates ────────────────────────────────────────────────────
    group('Date management', () {
      test('nextReviewDate est dans le futur après applyReview', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        final before = DateTime.now();
        card.applyReview(5);
        // interval=1 day, so nextReview ≈ now + 1 day
        expect(card.nextReviewDate.isAfter(before), isTrue);
        expect(
          card.nextReviewDate.difference(before).inDays,
          lessThanOrEqualTo(1),
        );
      });

      test('lastReviewDate est mis à jour après applyReview', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(card.lastReviewDate, isNull);
        final before = DateTime.now();
        card.applyReview(5);
        expect(card.lastReviewDate, isNotNull);
        expect(card.lastReviewDate!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      });

      test('isDue true si nextReviewDate dans le passé', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final card = ReviewCard(
          userId: 'u1',
          questionId: 'q1',
          nextReviewDate: pastDate,
        );
        expect(card.isDue, isTrue);
      });

      test('isDue false si nextReviewDate dans le futur', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final card = ReviewCard(
          userId: 'u1',
          questionId: 'q1',
          nextReviewDate: futureDate,
        );
        expect(card.isDue, isFalse);
      });

      test('daysOverdue calcule le retard en jours', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final card = ReviewCard(
          userId: 'u1',
          questionId: 'q1',
          nextReviewDate: twoDaysAgo,
        );
        // Should be 1 or 2 (depending on hour-of-day rounding).
        expect(card.daysOverdue, greaterThanOrEqualTo(1));
        expect(card.daysOverdue, lessThanOrEqualTo(2));
      });

      test('daysOverdue = 0 si pas en retard', () {
        final future = DateTime.now().add(const Duration(days: 3));
        final card = ReviewCard(
          userId: 'u1',
          questionId: 'q1',
          nextReviewDate: future,
        );
        expect(card.daysOverdue, 0);
      });
    });

    // ─── SrsQuality enum ──────────────────────────────────────────
    group('SrsQuality enum', () {
      test('Contient les 6 niveaux de qualité (0 à 5)', () {
        expect(SrsQuality.values.length, 6);
        expect(SrsQuality.values.map((q) => q.value).toList(), [0, 1, 2, 3, 4, 5]);
      });

      test('Chaque qualité a un label et une description non vides', () {
        for (final q in SrsQuality.values) {
          expect(q.label, isNotEmpty);
          expect(q.description, isNotEmpty);
        }
      });

      test('Labels des 6 qualités', () {
        expect(SrsQuality.echec0.label, 'Oublié');
        expect(SrsQuality.echec1.label, 'Très difficile');
        expect(SrsQuality.echec2.label, 'Difficile');
        expect(SrsQuality.correct3.label, 'Correct');
        expect(SrsQuality.correct4.label, 'Bien');
        expect(SrsQuality.parfait5.label, 'Parfait');
      });
    });
  });
}
