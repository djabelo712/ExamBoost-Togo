// lib/screens/badges/widgets/badge_grid.dart
// Grille de badges (GridView 3 colonnes) avec gestion du tap.
// Le tap déclenche :
//   - badge débloqué ou en cours  → ouverture du bottom sheet détail
//   - badge verrouillé            → snackbar d'encouragement

import 'package:flutter/material.dart';

import '../../../models/badge.dart';
import '../../../theme/app_theme.dart';
import 'badge_card.dart';

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({
    super.key,
    required this.badges,
    required this.userBadges,
    this.onBadgeTap,
  });

  /// Badges à afficher (déjà filtrés par la page parent).
  final List<Badge> badges;

  /// Map badgeId → UserBadge (pour connaître la progression de chaque badge).
  final Map<String, UserBadge> userBadges;

  /// Callback personnalisé au tap. Si null, comportement par défaut :
  /// snackbar pour les verrouillés, onBadgeTap pour les autres.
  final void Function(Badge badge, UserBadge? userBadge)? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return _buildEmpty();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final ub = userBadges[badge.id];
        return BadgeCard(
          badge: badge,
          userBadge: ub,
          onTap: () => _handleTap(context, badge, ub),
        );
      },
    );
  }

  void _handleTap(
    BuildContext context,
    Badge badge,
    UserBadge? userBadge,
  ) {
    if (onBadgeTap != null) {
      onBadgeTap!(badge, userBadge);
      return;
    }

    // Comportement par défaut : snackbar pour les verrouillés.
    if (userBadge == null || !userBadge.isUnlocked && userBadge.progress == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Continue à utiliser ExamBoost pour découvrir ce badge !',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.textSecondary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text(
          'Aucun badge dans cette catégorie.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
