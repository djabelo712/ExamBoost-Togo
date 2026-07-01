// lib/screens/badges/widgets/badge_progress_bar.dart
// Barre de progression vers un badge (état "en cours").
// Affiche "5 / 7 jours" + barre colorée à la couleur du badge.

import 'package:flutter/material.dart';

import '../../../models/badge.dart';
import '../../../theme/app_theme.dart';

class BadgeProgressBar extends StatelessWidget {
  const BadgeProgressBar({
    super.key,
    required this.badge,
    required this.userBadge,
    this.compact = false,
  });

  /// Badge dont on veut afficher la progression.
  final Badge badge;

  /// État de progression de l'élève (peut être null si jamais touché).
  final UserBadge? userBadge;

  /// Mode compact (carte grille) ou détaillé (bottom sheet).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = userBadge?.progress ?? 0;
    final clamped = progress.clamp(0, badge.requiredValue);
    final percent = badge.requiredValue == 0
        ? 1.0
        : (clamped / badge.requiredValue).clamp(0.0, 1.0);

    if (compact) {
      return _buildCompact(percent, clamped);
    }
    return _buildDetailed(percent, clamped);
  }

  // ─── Mode compact (carte grille 3 colonnes) ────────────────────

  Widget _buildCompact(double percent, int current) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 4,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(badge.color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          badge.progressText(userBadge),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── Mode détaillé (bottom sheet) ──────────────────────────────

  Widget _buildDetailed(double percent, int current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              badge.progressText(userBadge),
              style: AppTextStyles.label.copyWith(
                color: badge.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(badge.color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(percent * 100).round()} %',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}
