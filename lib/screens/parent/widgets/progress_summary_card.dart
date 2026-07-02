// lib/screens/parent/widgets/progress_summary_card.dart
// Carte résumé de progression utilisée dans l'onglet "Progression".
//
// Affiche :
//   - CircularPercentIndicator (score global enfant, vert Togo)
//   - Comparaison vs moyenne classe (chip +14 pts / -6 pts)
//   - 3 stats secondaires : temps révision 7 j, questions répondues, streak
//
// Cette carte est pensée pour être repliée en haut de l'onglet
// Progression, au-dessus du line chart et de la liste des matières.

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';
import '../services/parent_service.dart';

class ProgressSummaryCard extends StatelessWidget {
  final Child child;

  const ProgressSummaryCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ecart = child.ecartClasse;
    final ecartColor = ecart >= 0 ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadowColor(context),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── En-tête : nom enfant + classe ────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AdaptiveColors.primarySurface(context),
                child: Text(
                  child.initiales,
                  style: TextStyle(
                    color: AdaptiveColors.primary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.nomComplet,
                      style: AppTextStyles.h3.copyWith(
                          color: AdaptiveColors.textPrimary(context)),
                    ),
                    Text(
                      '${child.classe} · ${child.etablissement}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AdaptiveColors.textSecondary(context),
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── Cercle score + comparaison classe ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularPercentIndicator(
                radius: 56,
                lineWidth: 10,
                percent: (child.scoreGlobal / 100).clamp(0.0, 1.0),
                center: Text(
                  '${child.scoreGlobal}%',
                  style: AppTextStyles.h2.copyWith(
                      color: AdaptiveColors.textPrimary(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
                progressColor: AdaptiveColors.primary(context),
                backgroundColor: AdaptiveColors.surfaceVariant(context),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 800,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comparaison classe',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AdaptiveColors.textSecondary(context),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${ecart >= 0 ? '+' : ''}$ecart',
                          style: AppTextStyles.h2.copyWith(
                              color: ecartColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'pts',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: ecartColor),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      ecart >= 0
                          ? 'Au-dessus de la moyenne de la classe '
                              '(${child.moyenneClasse}%).'
                          : 'En dessous de la moyenne de la classe '
                              '(${child.moyenneClasse}%).',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AdaptiveColors.textSecondary(context),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ─── 3 stats secondaires ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  context,
                  icon: Icons.timer_outlined,
                  value: _formatMinutes(child.tempsRevisionMinutes7j),
                  label: '7 derniers jours',
                  color: AppColors.info,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AdaptiveColors.divider(context)),
              Expanded(
                child: _miniStat(
                  context,
                  icon: Icons.quiz_outlined,
                  value: '${child.totalQuestionsAnswered}',
                  label: 'Questions',
                  color: AppColors.primary,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AdaptiveColors.divider(context)),
              Expanded(
                child: _miniStat(
                  context,
                  icon: Icons.local_fire_department_outlined,
                  value: '${child.streakDays} j',
                  label: 'Streak',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
              color: AdaptiveColors.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
              color: AdaptiveColors.textSecondary(context), fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Formate un nombre de minutes en "Xh Ymin" ou "Ymin".
  String _formatMinutes(int total) {
    if (total < 60) return '${total}min';
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}
