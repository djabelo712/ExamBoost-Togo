// lib/screens/contest/widgets/contribution_card.dart
// Carte "Ma contribution" affichant les points que l'eleve a apportes a
// son ecole pendant le concours en cours.
//
// Affiche :
//   - Total de points apportes (gros chiffre).
//   - Rang dans l'ecole (ex: "4e contributeur sur 87").
//   - Repartition par type (questions / simulations / badges / streak).
//     Chaque ligne : icone + libelle + nombre + points.
//   - Barre de part relative (estimation de la contribution au total de
//     l'ecole).
//
// Si showRecent = true, ajoute une liste des contributions recentes
// (les 5 dernieres actions creditees).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/contest_contribution.dart';

class ContributionCard extends StatelessWidget {
  final MyContributionSummary contribution;
  final bool showRecent;
  final VoidCallback? onTap;

  const ContributionCard({
    super.key,
    required this.contribution,
    this.showRecent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── En-tete : "Ma contribution" + icone ────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volunteer_activism,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ma contribution',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          contribution.ecoleNom,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Rang dans l'ecole
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${contribution.rangDansEcole}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'sur ${contribution.nbContributeursEcole}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Total de points ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${contribution.pointsTotaux}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'points pour mon ecole',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Repartition par type ───────────────────────────
              _BreakdownRow(
                type: ContributionType.question,
                count: contribution.nbQuestions,
              ),
              const SizedBox(height: 6),
              _BreakdownRow(
                type: ContributionType.simulation,
                count: contribution.nbSimulations,
              ),
              const SizedBox(height: 6),
              _BreakdownRow(
                type: ContributionType.badge,
                count: contribution.nbBadges,
              ),
              const SizedBox(height: 6),
              _BreakdownRow(
                type: ContributionType.streakBonus,
                count: contribution.nbBonusStreak,
              ),

              // ─── Contributions recentes (optionnel) ────────────
              if (showRecent && contribution.recentes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Contributions recentes',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...contribution.recentes
                          .take(5)
                          .map((c) => _RecentLine(contribution: c)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ligne de repartition par type ───────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  final ContributionType type;
  final int count;

  const _BreakdownRow({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    final points = count * type.points;

    return Row(
      children: [
        Icon(_iconFor(type), size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            type.libelle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          'x$count',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            '+$points pts',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(ContributionType t) {
    switch (t) {
      case ContributionType.question:
        return Icons.check_circle_outline;
      case ContributionType.simulation:
        return Icons.assignment_turned_in_outlined;
      case ContributionType.badge:
        return Icons.verified_outlined;
      case ContributionType.streakBonus:
        return Icons.local_fire_department_outlined;
    }
  }
}

// ─── Ligne "contribution recente" ────────────────────────────────────

class _RecentLine extends StatelessWidget {
  final ContestContribution contribution;

  const _RecentLine({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(_iconFor(contribution.type), size: 12, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              contribution.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+${contribution.points}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ContributionType t) {
    switch (t) {
      case ContributionType.question:
        return Icons.check_circle_outline;
      case ContributionType.simulation:
        return Icons.assignment_turned_in_outlined;
      case ContributionType.badge:
        return Icons.verified_outlined;
      case ContributionType.streakBonus:
        return Icons.local_fire_department_outlined;
    }
  }
}
