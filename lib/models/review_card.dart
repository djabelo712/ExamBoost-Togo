// lib/models/review_card.dart
// Carte de révision SRS (SM-2) — une entrée par (élève × question)

import 'package:hive/hive.dart';

part 'review_card.g.dart';

@HiveType(typeId: 2)
class ReviewCard extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String questionId;

  // ─── Paramètres SM-2 ──────────────────────────────────────────
  @HiveField(2)
  int repetitions; // n : nombre de répétitions réussies

  @HiveField(3)
  double easinessFactor; // EF : facteur d'aisance (init 2.5)

  @HiveField(4)
  int intervalDays; // I(n) : intervalle en jours

  @HiveField(5)
  DateTime nextReviewDate; // Date de la prochaine révision

  @HiveField(6)
  DateTime? lastReviewDate;

  @HiveField(7)
  int totalAttempts;

  @HiveField(8)
  int correctAttempts;

  @HiveField(9)
  bool isLearning; // true = en cours d'apprentissage initial

  ReviewCard({
    required this.userId,
    required this.questionId,
    this.repetitions = 0,
    this.easinessFactor = 2.5,
    this.intervalDays = 0,
    DateTime? nextReviewDate,
    this.lastReviewDate,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.isLearning = true,
  }) : nextReviewDate = nextReviewDate ?? DateTime.now();

  /// Appliquer l'algorithme SM-2 après une réponse
  /// [q] : qualité de la réponse (0-5)
  void applyReview(int q) {
    assert(q >= 0 && q <= 5, 'Le score q doit être entre 0 et 5');

    totalAttempts++;
    lastReviewDate = DateTime.now();

    if (q >= 3) {
      // ─── Réponse correcte ─────────────────────────────────────
      correctAttempts++;
      if (repetitions == 0) {
        intervalDays = 1;
      } else if (repetitions == 1) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * easinessFactor).floor();
      }
      repetitions++;
      isLearning = false;
    } else {
      // ─── Réponse incorrecte (q < 3) ───────────────────────────
      repetitions = 0;
      intervalDays = 1;
      isLearning = true;
    }

    // ─── Mise à jour du facteur d'aisance ─────────────────────
    easinessFactor = easinessFactor +
        (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));

    // Contrainte plancher EF >= 1.3
    if (easinessFactor < 1.3) easinessFactor = 1.3;

    // ─── Planifier la prochaine révision ──────────────────────
    nextReviewDate = DateTime.now().add(Duration(days: intervalDays));
  }

  /// Taux de réussite en pourcentage
  double get successRate =>
      totalAttempts == 0 ? 0.0 : correctAttempts / totalAttempts;

  /// La carte est due pour révision si la date est passée
  bool get isDue => DateTime.now().isAfter(nextReviewDate);

  /// Retard en jours (0 si pas en retard)
  int get daysOverdue {
    final now = DateTime.now();
    if (now.isBefore(nextReviewDate)) return 0;
    return now.difference(nextReviewDate).inDays;
  }
}

/// Grille de qualité SM-2 pour l'affichage UI
enum SrsQuality {
  echec0(0, 'Oublié', 'Je n\'avais aucun souvenir'),
  echec1(1, 'Très difficile', 'La réponse est revenue après'),
  echec2(2, 'Difficile', 'Erreur mais réponse semblait facile'),
  correct3(3, 'Correct', 'Réponse juste mais difficile à trouver'),
  correct4(4, 'Bien', 'Réponse correcte avec légère hésitation'),
  parfait5(5, 'Parfait', 'Réponse immédiate et sûre');

  const SrsQuality(this.value, this.label, this.description);
  final int value;
  final String label;
  final String description;
}
