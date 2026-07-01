// lib/screens/score/widgets/subject_breakdown_card.dart
// Carte de détail du score prédit pour une matière.
//
// Affichage :
//   - Nom matière + coefficient (ex: "Mathématiques (coef 4)")
//   - Note estimée en grand (ex: "14.5 / 20")
//   - Barre progression horizontale colorée
//   - P(L) moyen en petit
//   - Si pas couvert : badge "Pas encore évalué" + bouton "Commencer"
//   - Tap sur carte -> callback on onTap (navigate to révision)

import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../models/score_prediction.dart';
import '../../../theme/app_theme.dart';

/// Carte affichant le détail du score d'une matière.
class SubjectBreakdownCard extends StatelessWidget {
  final SubjectScore subject;
  final VoidCallback? onTap;

  const SubjectBreakdownCard({
    super.key,
    required this.subject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final noteColor = _noteColor(subject.noteEstimee);
    final isCovered = subject.covered;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(noteColor),
              const SizedBox(height: 12),
              if (isCovered) ...[
                _buildProgressBar(noteColor),
                const SizedBox(height: 10),
                _buildFooter(),
              ] else
                _buildUncoveredState(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header : matière + coef + note ──────────────────────────────
  Widget _buildHeader(Color noteColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.matiere,
                style: AppTextStyles.h3.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coef. ${subject.coefficient}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (subject.covered)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: noteColor,
                  ),
                  children: [
                    TextSpan(
                        text: subject.noteEstimee.toStringAsFixed(1)),
                    TextSpan(
                      text: ' / 20',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 28),
      ],
    );
  }

  // ─── Barre de progression colorée ────────────────────────────────
  Widget _buildProgressBar(Color noteColor) {
    return LinearPercentIndicator(
      percent: subject.notePercent,
      lineHeight: 8,
      animation: true,
      animationDuration: 800,
      barRadius: const Radius.circular(4),
      progressColor: noteColor,
      backgroundColor: noteColor.withOpacity(0.15),
      padding: EdgeInsets.zero,
    );
  }

  // ─── Footer : P(L) moyen + nb compétences ────────────────────────
  Widget _buildFooter() {
    final pLPercent = (subject.pLMoyen * 100).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Maitrise BKT : $pLPercent %',
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${subject.competencesCount} compet.',
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── Etat "non couvert" ──────────────────────────────────────────
  Widget _buildUncoveredState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.divider.withOpacity(0.6), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pas encore evaluee',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Commencer',
              style: AppTextStyles.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Couleur en fonction de la note.
  Color _noteColor(double note) {
    if (note < 8) return AppColors.error;
    if (note < 10) return AppColors.warning;
    if (note < 12) return AppColors.accent;
    if (note < 14) return AppColors.primaryLight;
    return AppColors.success;
  }
}
