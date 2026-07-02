// test/unit/models/review_card_test.dart
// Tests for the ReviewCard model (HiveType 2).
//
// Note: the SM-2 algorithm itself is exhaustively tested in
// test/unit/algorithms/sm2_test.dart. This file focuses on the model's
// non-algorithm behavior (constructor defaults, fields, dates, helpers).

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/review_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ReviewCard model', () {
    // ─── Constructeur ─────────────────────────────────────────────
    group('Constructeur', () {
      test('Valeurs par défaut correctes', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(card.userId, 'u1');
        expect(card.questionId, 'q1');
        expect(card.repetitions, 0);
        expect(card.easinessFactor, 2.5);
        expect(card.intervalDays, 0);
        expect(card.totalAttempts, 0);
        expect(card.correctAttempts, 0);
        expect(card.isLearning, isTrue);
        expect(card.lastReviewDate, isNull);
      });

      test('nextReviewDate par défaut = maintenant', () {
        final before = DateTime.now();
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        final after = DateTime.now();
        expect(card.nextReviewDate.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(card.nextReviewDate.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('nextReviewDate personnalisée est respectée', () {
        final custom = DateTime(2026, 12, 25);
        final card = ReviewCard(
          userId: 'u1',
          questionId: 'q1',
          nextReviewDate: custom,
        );
        expect(card.nextReviewDate, custom);
      });

      test('Tous les champs sont assignables via le constructeur', () {
        final card = createTestReviewCard(
          userId: 'alice',
          questionId: 'q42',
          repetitions: 3,
          easinessFactor: 2.7,
          intervalDays: 16,
          totalAttempts: 5,
          correctAttempts: 4,
          isLearning: false,
        );
        expect(card.userId, 'alice');
        expect(card.questionId, 'q42');
        expect(card.repetitions, 3);
        expect(card.easinessFactor, 2.7);
        expect(card.intervalDays, 16);
        expect(card.totalAttempts, 5);
        expect(card.correctAttempts, 4);
        expect(card.isLearning, isFalse);
      });
    });

    // ─── Stats dérivées ──────────────────────────────────────────
    group('Stats dérivées', () {
      test('successRate à 0 si aucune tentative', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        expect(card.successRate, 0.0);
      });

      test('successRate calcule le ratio correctAttempts/totalAttempts', () {
        final card = createTestReviewCard(
          totalAttempts: 10,
          correctAttempts: 7,
        );
        expect(card.successRate, closeTo(0.7, 0.001));
      });

      test('successRate ne dépasse pas 1.0', () {
        final card = createTestReviewCard(
          totalAttempts: 5,
          correctAttempts: 5,
        );
        expect(card.successRate, 1.0);
      });
    });

    // ─── isDue ───────────────────────────────────────────────────
    group('isDue', () {
      test('true si nextReviewDate dans le passé', () {
        final card = createTestReviewCard(
          nextReviewDate: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(card.isDue, isTrue);
      });

      test('false si nextReviewDate dans le futur', () {
        final card = createTestReviewCard(
          nextReviewDate: DateTime.now().add(const Duration(days: 3)),
        );
        expect(card.isDue, isFalse);
      });
    });

    // ─── daysOverdue ─────────────────────────────────────────────
    group('daysOverdue', () {
      test('0 si pas en retard', () {
        final card = createTestReviewCard(
          nextReviewDate: DateTime.now().add(const Duration(days: 3)),
        );
        expect(card.daysOverdue, 0);
      });

      test('nombre positif de jours si en retard', () {
        final card = createTestReviewCard(
          nextReviewDate: DateTime.now().subtract(const Duration(days: 5)),
        );
        expect(card.daysOverdue, greaterThanOrEqualTo(4));
        expect(card.daysOverdue, lessThanOrEqualTo(5));
      });
    });

    // ─── Cycle applyReview ───────────────────────────────────────
    group('Cycle applyReview complet', () {
      test('Séquence complète de 7 jours (3 succès + 1 échec + 3 succès)', () {
        final card = ReviewCard(userId: 'u1', questionId: 'q1');
        card.applyReview(5); // I=1, reps=1
        card.applyReview(5); // I=6, reps=2
        card.applyReview(5); // I=16, reps=3
        expect(card.repetitions, 3);
        expect(card.intervalDays, 16);

        card.applyReview(2); // FAILURE: reps=0, I=1
        expect(card.repetitions, 0);
        expect(card.intervalDays, 1);
        expect(card.isLearning, isTrue);

        card.applyReview(4); // I=1, reps=1 (reprend depuis le début)
        card.applyReview(4); // I=6, reps=2
        expect(card.repetitions, 2);
        expect(card.intervalDays, 6);

        // Total: 7 attempts, 6 correct
        expect(card.totalAttempts, 7);
        expect(card.correctAttempts, 6);
        expect(card.successRate, closeTo(0.857, 0.01));
      });
    });
  });
}
