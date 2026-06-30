// lib/services/srs_service.dart
// Service de Répétition Espacée — algorithme SM-2
// Gère la sélection des cartes dues et la planification des révisions

import 'dart:math' show exp;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/review_card.dart';
import '../models/question.dart';
import '../utils/app_logger.dart';

class SrsService {
  static const String _boxName = 'review_cards';
  late Box<ReviewCard> _box;

  Future<void> init() async {
    _box = await Hive.openBox<ReviewCard>(_boxName);
    AppLogger.info('SrsService initialisé — ${_box.length} cartes chargées');
  }

  // ─── Clé de stockage ─────────────────────────────────────────
  String _key(String userId, String questionId) => '${userId}_$questionId';

  // ─── Obtenir ou créer une carte ───────────────────────────────
  ReviewCard getOrCreate(String userId, String questionId) {
    final key = _key(userId, questionId);
    if (_box.containsKey(key)) {
      return _box.get(key)!;
    }
    final card = ReviewCard(
      userId: userId,
      questionId: questionId,
      nextReviewDate: DateTime.now(),
    );
    _box.put(key, card);
    return card;
  }

  // ─── Enregistrer une réponse ──────────────────────────────────
  Future<ReviewCard> recordAnswer({
    required String userId,
    required String questionId,
    required int quality, // 0-5
  }) async {
    final card = getOrCreate(userId, questionId);
    card.applyReview(quality);
    await card.save();

    AppLogger.debug(
      'Réponse enregistrée — Q:$questionId q=$quality '
      'EF=${card.easinessFactor.toStringAsFixed(2)} '
      'I=${card.intervalDays}j '
      'next=${card.nextReviewDate.toIso8601String().substring(0, 10)}',
    );

    return card;
  }

  // ─── Cartes dues pour révision ────────────────────────────────
  List<ReviewCard> getDueCards(String userId, {int limit = 20}) {
    final now = DateTime.now();
    final due = _box.values
        .where((c) =>
            c.userId == userId &&
            (c.nextReviewDate.isBefore(now) || c.nextReviewDate.isAtSameMomentAs(now)))
        .toList();

    // Trier : cartes en retard en premier, puis nouvelles cartes
    due.sort((a, b) {
      if (a.isLearning && !b.isLearning) return -1;
      if (!a.isLearning && b.isLearning) return 1;
      return a.nextReviewDate.compareTo(b.nextReviewDate);
    });

    return due.take(limit).toList();
  }

  // ─── Statistiques de session ──────────────────────────────────
  SrsStats getStats(String userId) {
    final allCards = _box.values.where((c) => c.userId == userId).toList();
    final now = DateTime.now();

    return SrsStats(
      totalCards: allCards.length,
      dueToday: allCards.where((c) => c.isDue).length,
      mastered: allCards.where((c) => !c.isLearning && c.successRate >= 0.8).length,
      learning: allCards.where((c) => c.isLearning).length,
      newCards: allCards.where((c) => c.totalAttempts == 0).length,
      dueIn7Days: allCards
          .where((c) => c.nextReviewDate.isBefore(now.add(const Duration(days: 7))))
          .length,
    );
  }

  // ─── Sélectionner la meilleure question selon IRT ─────────────
  /// Retourne la question dont la difficulté b est la plus proche de theta
  Question? selectBestQuestion({
    required List<Question> availableQuestions,
    required double thetaUser,
  }) {
    if (availableQuestions.isEmpty) return null;

    Question? best;
    double bestDistance = double.infinity;

    for (final q in availableQuestions) {
      final b = q.irtB ?? 0.0;
      final distance = (b - thetaUser).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = q;
      }
    }
    return best;
  }

  // ─── Estimation du score à l'examen ──────────────────────────
  /// Probabilité IRT P(réponse correcte) pour un élève de niveau theta
  double irtProbability({
    required double theta,
    required double a,
    required double b,
    double c = 0.0,
  }) {
    final exponent = -1.7 * a * (theta - b);
    return c + (1 - c) * (1 / (1 + _exp(exponent)));
  }

  double _exp(double x) {
    if (x > 500) return double.infinity;
    if (x < -500) return 0.0;
    return exp(x);
  }
}

class SrsStats {
  final int totalCards;
  final int dueToday;
  final int mastered;
  final int learning;
  final int newCards;
  final int dueIn7Days;

  const SrsStats({
    required this.totalCards,
    required this.dueToday,
    required this.mastered,
    required this.learning,
    required this.newCards,
    required this.dueIn7Days,
  });
}
