// lib/screens/contest/widgets/contest_progress_widget.dart
// Widget affichant la progression collective vers l'objectif du concours.
//
// Affiche :
//   - Barre de progression horizontale (LinearProgressIndicator custom).
//   - Pourcentage atteint (ex: "63% de l'objectif").
//   - Points actuels / objectif (ex: "94 500 / 150 000 pts").
//   - Nombre de jours restants (ex: "16 jours restants").
//   - Nombre d'ecoles participantes + eleves actifs (en bas).
//
// Utilise Contest.ratioCollectif et Contest.joursRestants.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/contest.dart';

class ContestProgressWidget extends StatelessWidget {
  final Contest contest;
  final bool compact; // affichage reduit (sans stats secondaires)

  const ContestProgressWidget({
    super.key,
    required this.contest,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = contest.ratioCollectif;
    final pourcent = (ratio * 100).round();
    final joursRestants = contest.joursRestants;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── En-tete : titre + jours restants ──────────────────
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Objectif collectif national',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (contest.status == ContestStatus.enCours &&
                  joursRestants > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 11,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$joursRestants j restants',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Barre de progression ──────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // Piste (fond).
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Valeur (remplissage).
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ─── Pourcentage + points ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pourcent% de l\'objectif',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                '${_formatNb(contest.pointsActuels)} / '
                '${_formatNb(contest.objectifCollectif)} pts',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // ─── Stats secondaires (si non compact) ────────────────
          if (!compact) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
              _StatChip(
                icon: Icons.school_outlined,
                label: 'Ecoles',
                value: '${contest.nbEcolesParticipantes}',
                color: AppColors.info,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.group_outlined,
                label: 'Eleves actifs',
                value: '${contest.nbElevesActifs}',
                color: AppColors.accent,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.calendar_today_outlined,
                label: 'Periode',
                value: _periodeLabel(contest),
                color: AppColors.primary,
              ),
            ]),
          ],
        ],
      ),
    );
  }

  /// Formate un nombre avec espaces comme separateurs de milliers.
  /// Ex: 94500 -> "94 500".
  static String _formatNb(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Label court pour la periode (ex: "1-31 mars").
  static String _periodeLabel(Contest c) {
    const moisFr = [
      '', 'jan', 'fev', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aou', 'sep', 'oct', 'nov', 'dec',
    ];
    final m = moisFr[c.dateDebut.month];
    return '${c.dateDebut.day}-${c.dateFin.day} $m';
  }
}

// ─── Petite chip de statistique ──────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
