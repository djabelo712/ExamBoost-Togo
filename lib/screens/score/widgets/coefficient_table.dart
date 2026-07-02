// lib/screens/score/widgets/coefficient_table.dart
// Tableau des coefficients officiels MEPST par matière.
//
// Affichage :
//   - En-tête : Matière | Coef. | Note estimée | Score pondéré
//   - Une ligne par matière
//   - Total en bas (score global prédit)
//   - Note : "Source : Programme officiel MEPST Togo"

import 'package:flutter/material.dart';

import '../../../models/score_prediction.dart';
import '../../../theme/app_theme.dart';

/// Tableau récapitulatif des coefficients officiels MEPST.
class CoefficientTable extends StatelessWidget {
  final ScorePrediction prediction;

  const CoefficientTable({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final subjects = prediction.subjectsSortedByCoefDesc;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Coefficients officiels MEPST',
                  style: AppTextStyles.h3.copyWith(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Source : Programme officiel MEPST Togo (a valider)',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _buildHeaderRow(),
            const Divider(height: 12),
            ...subjects.map(_buildSubjectRow),
            const Divider(height: 16, thickness: 1.5),
            _buildTotalRow(),
          ],
        ),
      ),
    );
  }

  // ─── En-tête du tableau ──────────────────────────────────────────
  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: const [
          Expanded(
            flex: 4,
            child: Text(
              'Matiere',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Coef.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Note /20',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Pondere',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ligne d'une matière ─────────────────────────────────────────
  Widget _buildSubjectRow(SubjectScore subject) {
    final noteLabel = subject.covered
        ? subject.noteEstimee.toStringAsFixed(1)
        : '—';
    final pondereLabel = subject.covered
        ? (subject.noteEstimee * subject.coefficient).toStringAsFixed(1)
        : '—';
    final noteColor = subject.covered
        ? _noteColor(subject.noteEstimee)
        : AppColors.textDisabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              subject.matiere,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: subject.covered
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${subject.coefficient}',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              noteLabel,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: noteColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              pondereLabel,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: subject.covered
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ligne de total ──────────────────────────────────────────────
  Widget _buildTotalRow() {
    final scoreColor = _noteColor(prediction.scoreGlobal);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'TOTAL (sur ${prediction.totalCoefficient})',
              style: AppTextStyles.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${prediction.coveredCoefficient}/${prediction.totalCoefficient}',
              style: AppTextStyles.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              prediction.scoreGlobal.toStringAsFixed(1),
              style: AppTextStyles.h3.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scoreColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '/ 20',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _noteColor(double note) {
    if (note < 8) return AppColors.error;
    if (note < 10) return AppColors.warning;
    if (note < 12) return AppColors.accent;
    if (note < 14) return AppColors.primaryLight;
    return AppColors.success;
  }
}
