// lib/models/user_level.dart
// Modèle de progression méta-gamification : niveau (1-50) + XP cumulé.
//
// Persistance Hive :
//   - Box<UserLevel> "user_level" (clé = userId).
//   - Un seul UserLevel par élève (créé à la volée au premier gain d'XP).
//
// Système de niveaux (détails dans lib/services/level_service.dart) :
//   - Niveau 1 = niveau de départ (0 XP cumulé).
//   - XP cumulé requis pour ACHIEVER le niveau N = 100 * N * (N+1) / 2.
//     Exemples : N1 = 100 XP, N5 = 1500 XP, N10 = 5500 XP, N50 = 127500 XP.
//   - Donc : niveau 1 → 2 nécessite 100 XP, niveau 5 → 6 nécessite 1500 XP, etc.
//   - Niveau 50 = niveau maximum (plafond).
//
// Pour générer l'adaptateur Hive :
//   dart run build_runner build --delete-conflicting-outputs
// Puis enregistrer UserLevelAdapter dans main.dart.

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'user_level.g.dart';

// ─── Énumération des sources d'XP ──────────────────────────────────

/// Source d'un gain d'XP. Utilisée pour les stats, l'historique et
/// l'animation "+X XP" qui peut s'adapter selon la source.
///
/// Les valeurs d'XP associées sont définies dans [LevelService] (constantes)
/// pour garder la logique métier au même endroit.
///
/// NB : typeId 14 choisi pour éviter tout conflit avec les typeId déjà
/// utilisés (0-13, 17-20) et pour ne pas empiéter sur la plage 21+ que
/// l'Agent BQ a réservée pour la future migration Homework/HomeworkSubmission.
@HiveType(typeId: 14)
enum XpSource {
  @HiveField(0)
  questionCorrecte, // +10 XP — réponse correcte en révision

  @HiveField(1)
  simulationCompletee, // +50 XP — simulation d'examen terminée

  @HiveField(2)
  badgeBronze, // +100 XP — badge Bronze débloqué

  @HiveField(3)
  badgeArgent, // +250 XP — badge Argent débloqué

  @HiveField(4)
  badgeOr, // +500 XP — badge Or débloqué

  @HiveField(5)
  streak7j, // +200 XP — bonus streak 7 jours

  @HiveField(6)
  streak30j, // +1000 XP — bonus streak 30 jours

  @HiveField(7)
  devoirRendu, // +30 XP — devoir rendu (mode classe)

  @HiveField(8)
  conversationTuteur; // +5 XP — échange avec le tuteur IA

  /// Libellé lisible (affiché dans l'historique XP).
  String get label => switch (this) {
        questionCorrecte => 'Question correcte',
        simulationCompletee => 'Simulation complétée',
        badgeBronze => 'Badge Bronze',
        badgeArgent => 'Badge Argent',
        badgeOr => 'Badge Or',
        streak7j => 'Bonus streak 7 jours',
        streak30j => 'Bonus streak 30 jours',
        devoirRendu => 'Devoir rendu',
        conversationTuteur => 'Conversation tuteur',
      };

  /// Icône Material associée à la source (animation +X XP, historique).
  IconData get icon => switch (this) {
        questionCorrecte => Icons.check_circle_outline,
        simulationCompletee => Icons.timer,
        badgeBronze => Icons.emoji_events_outlined,
        badgeArgent => Icons.emoji_events_outlined,
        badgeOr => Icons.emoji_events,
        streak7j => Icons.local_fire_department_outlined,
        streak30j => Icons.local_fire_department,
        devoirRendu => Icons.assignment_turned_in_outlined,
        conversationTuteur => Icons.chat_bubble_outline,
      };

  /// Couleur d'accent pour l'animation +X XP (cohérent avec badges).
  Color get color => switch (this) {
        questionCorrecte => const Color(0xFF2E7D32), // Vert succès
        simulationCompletee => const Color(0xFFD97700), // Orange Togo
        badgeBronze => const Color(0xFFCD7F32), // Bronze
        badgeArgent => const Color(0xFF9E9E9E), // Argent
        badgeOr => const Color(0xFFFFB300), // Or
        streak7j => const Color(0xFFEF6C00), // Orange foncé
        streak30j => const Color(0xFFE65100), // Orange brûlé
        devoirRendu => const Color(0xFF1565C0), // Bleu info
        conversationTuteur => const Color(0xFF7B1FA2), // Violet tuteur
      };
}

// ─── Modèle UserLevel (persisté Hive) ──────────────────────────────

/// État de progression méta-gamification d'un élève.
///
/// Persisté dans la Hive box "user_level" (clé = userId).
/// Un seul UserLevel par élève — créé à la volée au premier gain d'XP.
///
/// [totalXp] est l'XP cumulé depuis le début. Les champs [xpThisWeek] et
/// [xpThisMonth] sont des compteurs roulants remis à zéro aux frontières
/// semaine (lundi 00:00) et mois (1er 00:00). Les frontières sont stockées
/// dans [weekStart] / [monthStart] pour détecter le franchissement.
///
/// NB : typeId 15 (cf. commentaire XpSource ci-dessus pour la stratégie
/// d'allocation des typeIds).
@HiveType(typeId: 15)
class UserLevel extends HiveObject {
  /// Identifiant de l'élève (clé Hive).
  @HiveField(0)
  String userId;

  /// XP cumulé total depuis l'inscription. Sert au calcul du niveau.
  @HiveField(1)
  int totalXp;

  /// Date du dernier gain d'XP (pour afficher "il y a X min").
  @HiveField(2)
  DateTime? lastXpGainAt;

  /// Date de la dernière montée de niveau (pour animation "Nouveau niveau !").
  @HiveField(3)
  DateTime? lastLevelUpAt;

  /// IDs des récompenses débloquées (clés de [LevelRewards.all]).
  /// Évite de recalculer le déblocage à chaque ouverture d'écran.
  @HiveField(4)
  List<String> unlockedRewardIds;

  /// XP gagnée cette semaine (reset chaque lundi 00:00).
  @HiveField(5)
  int xpThisWeek;

  /// Lundi 00:00 de la semaine en cours (permet de détecter le changement
  /// de semaine au prochain gain d'XP).
  @HiveField(6)
  DateTime? weekStart;

  /// XP gagnée ce mois-ci (reset le 1er de chaque mois à 00:00).
  @HiveField(7)
  int xpThisMonth;

  /// 1er du mois en cours à 00:00 (permet de détecter le changement de mois).
  @HiveField(8)
  DateTime? monthStart;

  UserLevel({
    required this.userId,
    this.totalXp = 0,
    this.lastXpGainAt,
    this.lastLevelUpAt,
    List<String>? unlockedRewardIds,
    this.xpThisWeek = 0,
    this.weekStart,
    this.xpThisMonth = 0,
    this.monthStart,
  }) : unlockedRewardIds = unlockedRewardIds ?? [];

  // ─── Helpers dérivés (lecture seule) ───────────────────────────

  /// Vrai si l'élève a déjà gagné au moins 1 XP (utilisé pour l'état vide).
  bool get hasStarted => totalXp > 0;

  /// Vrai si l'élève a déjà débloqué au moins une récompense.
  bool get hasAnyReward => unlockedRewardIds.isNotEmpty;

  /// Vrai si la récompense [rewardId] est déjà débloquée.
  bool hasReward(String rewardId) => unlockedRewardIds.contains(rewardId);

  /// Marque une récompense comme débloquée (idempotent).
  void markRewardUnlocked(String rewardId) {
    if (!unlockedRewardIds.contains(rewardId)) {
      unlockedRewardIds.add(rewardId);
    }
  }
}
