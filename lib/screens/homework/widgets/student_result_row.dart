// lib/screens/homework/widgets/student_result_row.dart
// Ligne résultat élève pour le tableau enseignant (résultats classe).
//
// Affiche pour chaque élève :
//   - avatar initiales (couleur matière),
//   - nom + classe,
//   - note /20 (couleur sémantique),
//   - temps passé,
//   - badge "EN RETARD" si soumis après deadline,
//   - badge "NON RENDU" si pas soumis.
//
// Tap → ouvre le détail des réponses de l'élève (dialog).

import 'package:flutter/material.dart';

import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';
import '../models/homework.dart';
import '../models/homework_submission.dart';

class StudentResultRow extends StatelessWidget {
  final Homework homework;
  final HomeworkSubmission? soumission;

  /// Couleur matière (pour l'avatar).
  final Color? avatarColor;

  /// Action au tap (ex: ouvrir le détail des réponses).
  final VoidCallback? onTap;

  const StudentResultRow({
    super.key,
    required this.homework,
    this.soumission,
    this.avatarColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRendu = soumission != null && soumission!.termine;
    final note = isRendu
        ? (soumission!.score / homework.pointsTotal) * 20
        : 0.0;
    final enRetard = isRendu && soumission!.isEnRetard(homework);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Avatar initiales
              _buildAvatar(context),
              const SizedBox(width: 12),

              // Nom + classe
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRendu
                          ? soumission!.nomComplet
                          : '(non soumis)',
                      style: AppTextStyles.body.copyWith(
                        color: AdaptiveColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          isRendu ? soumission!.classe : '-',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AdaptiveColors.textSecondary(context),
                            fontSize: 11,
                          ),
                        ),
                        if (enRetard) ...[
                          const SizedBox(width: 6),
                          _MiniBadge(
                            label: 'EN RETARD',
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Temps
              if (isRendu) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      soumission!.tempsLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AdaptiveColors.textSecondary(context),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'temps',
                      style: TextStyle(
                        color: AdaptiveColors.textSecondary(context),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],

              // Note /20
              _buildNote(context, isRendu, note),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final color = avatarColor ?? AppColors.primary;
    final initiales = isRendu ? soumission!.initiales : '--';
    return CircleAvatar(
      radius: 18,
      backgroundColor:
          color.withOpacity(0.15),
      child: Text(
        initiales,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNote(BuildContext context, bool isRendu, double note) {
    if (!isRendu) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'NON RENDU',
          style: TextStyle(
            color: AppColors.error,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    final noteColor = _noteColor(note);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: noteColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            note.toStringAsFixed(1),
            style: TextStyle(
              color: noteColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '/ 20',
            style: TextStyle(
              color: noteColor,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Color _noteColor(double note) {
    if (note >= 14) return AppColors.success;
    if (note >= 10) return AppColors.warning;
    return AppColors.error;
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
