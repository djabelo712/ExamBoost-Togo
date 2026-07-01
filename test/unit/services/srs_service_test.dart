// test/unit/services/srs_service_test.dart
// Tests for SrsService (recordAnswer, getDueCards, getStats,
// selectBestQuestion, irtProbability).
//
// The full IRT formula is exhaustively tested in
// test/unit/algorithms/irt_test.dart. Here we focus on the service-level
// behavior (Hive-backed CRUD, filtering, stats, selection).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:examboost_togo/models/question.dart';
import 'package:examboost_togo/models/review_card.dart';
import 'package:examboost_togo/services/srs_service.dart';

import '../../helpers/test_helpers.dart';

void main() {
  // ─── Hive setup for the whole test suite ──────────────────────
  late SrsService service;
  late Directory tempDir;

  setUpAll(() {
    tempDir = initHiveForTests();
  });

  setUp(() async {
    // Each test gets a fresh box.
    if (Hive.isBoxOpen('review_cards')) {
      await Hive.box<ReviewCard>('review_cards').clear();
    } else {
      await Hive.openBox<ReviewCard>('review_cards');
    }
    service = SrsService();
    await service.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ─── recordAnswer ─────────────────────────────────────────────
  group('recordAnswer', () {
    test('Crée une nouvelle carte si elle n\'existe pas', () async {
      final card = await service.recordAnswer(
        userId: 'u1',
        questionId: 'q1',
        quality: 5,
      );
      expect(card.userId, 'u1');
      expect(card.questionId, 'q1');
      expect(card.repetitions, 1);
      expect(card.intervalDays, 1);
      expect(card.totalAttempts, 1);
    });

    test('Met à jour la carte existante', () async {
      await service.recordAnswer(userId: 'u1', questionId: 'q1', quality: 5);
      final card = await service.recordAnswer(
        userId: 'u1',
        questionId: 'q1',
        quality: 5,
      );
      expect(card.repetitions, 2);
      expect(card.intervalDays, 6);
      expect(card.totalAttempts, 2);
    });

    test('Qualité 0 reset les repetitions', () async {
      await service.recordAnswer(userId: 'u1', questionId: 'q1', quality: 5);
      await service.recordAnswer(userId: 'u1', questionId: 'q1', quality: 5);
      final card = await service.recordAnswer(
        userId: 'u1',
        questionId: 'q1',
        quality: 0,
      );
      expect(card.repetitions, 0);
      expect(card.intervalDays, 1);
      expect(card.isLearning, isTrue);
    });

    test('Plusieurs users ont des cartes indépendantes', () async {
      await service.recordAnswer(userId: 'alice', questionId: 'q1', quality: 5);
      await service.recordAnswer(userId: 'bob', questionId: 'q1', quality: 0);

      final aliceCard = await service.recordAnswer(
        userId: 'alice', questionId: 'q1', quality: 5);
      final bobCard = await service.recordAnswer(
        userId: 'bob', questionId: 'q1', quality: 5);

      expect(aliceCard.repetitions, 2); // alice had 1 success + 1 success
      expect(bobCard.repetitions, 1); // bob had 1 fail + 1 success (reps=1)
    });

    test('Persiste dans la Hive box', () async {
      await service.recordAnswer(userId: 'u1', questionId: 'q1', quality: 5);
      // Re-init the service to simulate an app restart.
      final newService = SrsService();
      await newService.init();
      final card = newService.getOrCreate('u1', 'q1');
      expect(card.repetitions, 1);
    });
  });

  // ─── getOrCreate ──────────────────────────────────────────────
  group('getOrCreate', () {
    test('Retourne une nouvelle carte si absente', () {
      final card = service.getOrCreate('u1', 'q1');
      expect(card.userId, 'u1');
      expect(card.questionId, 'q1');
      expect(card.repetitions, 0);
    });

    test('Retourne la même carte au second appel', () {
      final c1 = service.getOrCreate('u1', 'q1');
      c1.applyReview(5);
      final c2 = service.getOrCreate('u1', 'q1');
      expect(identical(c1, c2), isTrue);
      expect(c2.repetitions, 1);
    });

    test('Users différents ont des cartes différentes', () {
      final c1 = service.getOrCreate('alice', 'q1');
      final c2 = service.getOrCreate('bob', 'q1');
      expect(identical(c1, c2), isFalse);
      expect(c1.userId, 'alice');
      expect(c2.userId, 'bob');
    });
  });

  // ─── getDueCards ──────────────────────────────────────────────
  group('getDueCards', () {
    test('Retourne vide si aucune carte pour cet user', () {
      expect(service.getDueCards('unknown'), isEmpty);
    });

    test('Retourne les cartes dues (nextReviewDate <= now)', () async {
      // A fresh recordAnswer sets nextReviewDate to now + 1 day, so the card
      // is NOT due immediately. We need to backdate it.
      await service.recordAnswer(userId: 'u1', questionId: 'q1', quality: 5);
      // Manually backdate to make it due.
      final card = service.getOrCreate('u1', 'q1');
      card.nextReviewDate = DateTime.now().subtract(const Duration(hours: 1));
      await card.save();

      final due = service.getDueCards('u1');
      expect(due.length, 1);
      expect(due.first.questionId, 'q1');
    });

    test('Filtre par userId', () async {
      await service.recordAnswer(userId: 'alice', questionId: 'q1', quality: 5);
      await service.recordAnswer(userId: 'bob', questionId: 'q2', quality: 5);
      // Backdate both.
      service.getOrCreate('alice', 'q1')
        ..nextReviewDate = DateTime.now().subtract(const Duration(hours: 1));
      service.getOrCreate('bob', 'q2')
        ..nextReviewDate = DateTime.now().subtract(const Duration(hours: 1));

      final aliceDue = service.getDueCards('alice');
      expect(aliceDue.length, 1);
      expect(aliceDue.first.userId, 'alice');
    });

    test('Limite le nombre de résultats', () async {
      for (int i = 0; i < 10; i++) {
        await service.recordAnswer(
            userId: 'u1', questionId: 'q$i', quality: 5);
        service.getOrCreate('u1', 'q$i')
          ..nextReviewDate = DateTime.now().subtract(const Duration(hours: 1));
      }
      final due = service.getDueCards('u1', limit: 5);
      expect(due.length, 5);
    });

    test('Cartes en learning apparaissent en premier', () async {
      // Card A: not learning (success).
      await service.recordAnswer(userId: 'u1', questionId: 'qA', quality: 5);
      service.getOrCreate('u1', 'qA')
        ..nextReviewDate = DateTime.now().subtract(const Duration(hours: 1));
      // Card B: learning (failure).
      await service.recordAnswer(userId: 'u1', questionId: 'qB', quality: 0);

      final due = service.getDueCards('u1');
      expect(due.length, greaterThanOrEqualTo(2));
      // B (learning) should come before A (not learning).
      final bIndex = due.indexWhere((c) => c.questionId == 'qB');
      final aIndex = due.indexWhere((c) => c.questionId == 'qA');
      expect(bIndex, lessThan(aIndex));
    });
  });

  // ─── getStats ─────────────────────────────────────────────────
  group('getStats', () {
    test('Retourne des zéros si aucune carte', () {
      final stats = service.getStats('unknown');
      expect(stats.totalCards, 0);
      expect(stats.dueToday, 0);
      expect(stats.mastered, 0);
      expect(stats.learning, 0);
      expect(stats.newCards, 0);
      expect(stats.dueIn7Days, 0);
    });

    test('Compte correctement les cartes par catégorie', () async {
      // New card (never answered).
      service.getOrCreate('u1', 'qNew');

      // Learning card (failure).
      await service.recordAnswer(userId: 'u1', questionId: 'qLearn', quality: 0);

      // Mastered card (multiple successes).
      await service.recordAnswer(userId: 'u1', questionId: 'qMaster', quality: 5);
      await service.recordAnswer(userId: 'u1', questionId: 'qMaster', quality: 5);
      await service.recordAnswer(userId: 'u1', questionId: 'qMaster', quality: 5);

      final stats = service.getStats('u1');
      expect(stats.totalCards, 3);
      expect(stats.newCards, 1); // qNew
      expect(stats.learning, greaterThanOrEqualTo(1)); // qLearn
      // qMaster is not learning and has successRate 1.0 (>=0.8) → mastered
      expect(stats.mastered, greaterThanOrEqualTo(1));
    });

    test('dueToday ne compte que les cartes en retard', () async {
      await service.recordAnswer(userId: 'u1', questionId: 'qDue', quality: 5);
      service.getOrCreate('u1', 'qDue')
        ..nextReviewDate = DateTime.now().subtract(const Duration(days: 1));

      await service.recordAnswer(userId: 'u1', questionId: 'qNotDue', quality: 5);
      // qNotDue has nextReviewDate = now + 1 day (not due).

      final stats = service.getStats('u1');
      expect(stats.dueToday, 1);
    });

    test('dueIn7Days compte les cartes dues dans la semaine', () async {
      await service.recordAnswer(userId: 'u1', questionId: 'qSoon', quality: 5);
      service.getOrCreate('u1', 'qSoon')
        ..nextReviewDate = DateTime.now().add(const Duration(days: 3));

      await service.recordAnswer(userId: 'u1', questionId: 'qLater', quality: 5);
      service.getOrCreate('u1', 'qLater')
        ..nextReviewDate = DateTime.now().add(const Duration(days: 30));

      final stats = service.getStats('u1');
      expect(stats.dueIn7Days, 1); // only qSoon
    });
  });

  // ─── selectBestQuestion ───────────────────────────────────────
  group('selectBestQuestion', () {
    test('Retourne null si liste vide', () {
      final best = service.selectBestQuestion(
        availableQuestions: [],
        thetaUser: 0.0,
      );
      expect(best, isNull);
    });

    test('Retourne la question dont irtB est le plus proche de theta', () {
      final questions = [
        createTestQuestion(id: 'q1', irtB: -2.0),
        createTestQuestion(id: 'q2', irtB: 0.5),
        createTestQuestion(id: 'q3', irtB: 2.0),
      ];
      final best = service.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: 0.5,
      );
      expect(best!.id, 'q2');
    });

    test('Avec theta négatif, sélectionne la question facile', () {
      final questions = [
        createTestQuestion(id: 'q1', irtB: -1.5),
        createTestQuestion(id: 'q2', irtB: 0.0),
        createTestQuestion(id: 'q3', irtB: 1.5),
      ];
      final best = service.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: -1.0,
      );
      expect(best!.id, 'q1');
    });

    test('Avec theta positif, sélectionne la question difficile', () {
      final questions = [
        createTestQuestion(id: 'q1', irtB: -1.5),
        createTestQuestion(id: 'q2', irtB: 0.0),
        createTestQuestion(id: 'q3', irtB: 1.5),
      ];
      final best = service.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: 2.0,
      );
      expect(best!.id, 'q3');
    });

    test('irtB null est traité comme 0.0', () {
      final questions = [
        createTestQuestion(id: 'q1', irtB: null),
        createTestQuestion(id: 'q2', irtB: 2.0),
      ];
      final best = service.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: 0.0,
      );
      expect(best!.id, 'q1');
    });

    test('En cas d\'égalité de distance, prend la première', () {
      final questions = [
        createTestQuestion(id: 'q1', irtB: -1.0),
        createTestQuestion(id: 'q2', irtB: 1.0),
      ];
      final best = service.selectBestQuestion(
        availableQuestions: questions,
        thetaUser: 0.0,
      );
      // Both have distance 1.0; first wins.
      expect(best!.id, 'q1');
    });
  });

  // ─── irtProbability (smoke only; full tests in irt_test.dart) ──
  group('irtProbability (smoke)', () {
    test('P = 0.5 quand theta = b (c=0)', () {
      final p = service.irtProbability(theta: 0, a: 1, b: 0, c: 0);
      expect(p, closeTo(0.5, 0.01));
    });

    test('P augmente avec theta', () {
      final p1 = service.irtProbability(theta: -1, a: 1, b: 0, c: 0);
      final p2 = service.irtProbability(theta: 1, a: 1, b: 0, c: 0);
      expect(p2, greaterThan(p1));
    });
  });
}
