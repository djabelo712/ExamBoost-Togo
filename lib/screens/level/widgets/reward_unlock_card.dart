// lib/screens/level/widgets/reward_unlock_card.dart
// Carte représentant une récompense (débloquée ou verrouillée).
//
// 2 états visuels :
//   - Débloquée   : icône pleine couleur + titre + description + check vert
//   - Verrouillée : icône grisée + overlay lock + niveau requis
//
// Utilisée dans :
//   - RewardsScreen (liste principale)
//   - LevelUpDialog (récompense fraîchement débloquée)
//
// Usage :
//   RewardUnlockCard(reward: reward, unlocked: true)
//   RewardUnlockCard(reward: reward, unlocked: false, showLevelRequirement: true)

import 'package:flutter/material.dart';

import '../../../models/level_reward.dart';
import '../../../theme/app_theme.dart';

class RewardUnlockCard extends StatelessWidget {
  const RewardUnlockCard({
    super.key,
    required this.reward,
    required this.unlocked,
    this.showLevelRequirement = true,
    this.compact = false,
    this.onTap,
  });

  /// Récompense (catalogue constant).
  final LevelReward reward;

  /// Vrai si la récompense est déjà débloquée par l'élève.
  final bool unlocked;

  /// Afficher le badge "Niveau X requis" (état verrouillé).
  final bool showLevelRequirement;

  /// Mode compact (pour embedding dans LevelUpDialog).
  final bool compact;

  /// Callback de tap (optionnel).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            border: Border.all(
              color: unlocked
                  ? reward.color.withOpacity(0.4)
                  : AppColors.divider,
              width: unlocked ? 1.5 : 1,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: reward.color.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              SizedBox(width: compact ? 10 : 14),
              Expanded(child: _buildContent()),
              if (unlocked) _buildCheck(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Icône (dépend de l'état) ────────────────────────────────

  Widget _buildIcon() {
    if (unlocked) {
      return Container(
        width: compact ? 44 : 56,
        height: compact ? 44 : 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              reward.color.withOpacity(0.9),
              reward.color,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: reward.color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          reward.iconData,
          color: Colors.white,
          size: compact ? 22 : 28,
        ),
      );
    }

    // Verrouillé : icône grisée + petit lock en superposition.
    return Container(
      width: compact ? 44 : 56,
      height: compact ? 44 : 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            reward.iconData,
            color: AppColors.textDisabled,
            size: compact ? 22 : 28,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: AppColors.surface,
              child: const Icon(
                Icons.lock_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Contenu textuel ─────────────────────────────────────────

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          reward.title,
          style: TextStyle(
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          reward.description,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            height: 1.4,
            color: unlocked
                ? AppColors.textSecondary
                : AppColors.textDisabled,
          ),
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _buildMeta(),
      ],
    );
  }

  // ─── Badge catégorie ou niveau requis ────────────────────────

  Widget _buildMeta() {
    if (!unlocked && showLevelRequirement) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline,
                size: 11, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              'Niveau ${reward.requiredLevel} requis',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: reward.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reward.category.icon, size: 11, color: reward.color),
          const SizedBox(width: 4),
          Text(
            unlocked
                ? 'Débloqué au niveau ${reward.requiredLevel}'
                : reward.category.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: reward.color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Check "débloqué" ────────────────────────────────────────

  Widget _buildCheck() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }
}
