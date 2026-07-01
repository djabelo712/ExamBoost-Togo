// lib/screens/badges/widgets/badge_card.dart
// Carte badge pour la grille de collection.
// 3 états visuels :
//   - Débloqué   : icône pleine couleur + titre + niveau + date
//   - En cours   : icône semi-transparente + barre progression
//   - Verrouillé : icône grisée + overlay lock + "???"

import 'package:flutter/material.dart';

import '../../../models/badge.dart';
import '../../../theme/app_theme.dart';
import 'badge_progress_bar.dart';

/// Mode d'affichage d'une carte badge.
enum BadgeCardState { unlocked, inProgress, locked }

class BadgeCard extends StatelessWidget {
  const BadgeCard({
    super.key,
    required this.badge,
    this.userBadge,
    this.onTap,
  });

  /// Badge (catalogue constant).
  final Badge badge;

  /// État de progression de l'élève (null si jamais touché).
  final UserBadge? userBadge;

  /// Callback appelé au tap sur la carte.
  final VoidCallback? onTap;

  /// Détermine l'état d'affichage à partir du UserBadge.
  BadgeCardState get state {
    if (badge.isUnlocked(userBadge)) {
      return BadgeCardState.unlocked;
    }
    if (userBadge != null && userBadge!.progress > 0) {
      return BadgeCardState.inProgress;
    }
    return BadgeCardState.locked;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state == BadgeCardState.unlocked
                  ? badge.color.withOpacity(0.4)
                  : AppColors.divider,
              width: state == BadgeCardState.unlocked ? 1.5 : 1,
            ),
            boxShadow: state == BadgeCardState.unlocked
                ? [
                    BoxShadow(
                      color: badge.color.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 8),
              _buildTitle(),
              const SizedBox(height: 2),
              _buildLevel(),
              const SizedBox(height: 6),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Icône centrale (dépend de l'état) ────────────────────────

  Widget _buildIcon() {
    switch (state) {
      case BadgeCardState.unlocked:
        return _UnlockedIcon(badge: badge);
      case BadgeCardState.inProgress:
        return _InProgressIcon(badge: badge);
      case BadgeCardState.locked:
        return const _LockedIcon();
    }
  }

  Widget _buildTitle() {
    final isLocked = state == BadgeCardState.locked;
    return Text(
      badge.title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isLocked ? AppColors.textDisabled : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLevel() {
    final isLocked = state == BadgeCardState.locked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.surfaceVariant
            : badge.level.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isLocked ? '???' : badge.level.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isLocked
              ? AppColors.textDisabled
              : badge.level.color,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    switch (state) {
      case BadgeCardState.unlocked:
        // Date de déblocage en petit
        final d = userBadge!.unlockedAt!;
        return Text(
          '${d.day}/${d.month}/${d.year}',
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        );
      case BadgeCardState.inProgress:
        return BadgeProgressBar(
          badge: badge,
          userBadge: userBadge,
          compact: true,
        );
      case BadgeCardState.locked:
        return const Text(
          'Verrouillé',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.textDisabled,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }
}

// ─── Variantes d'icône par état ──────────────────────────────────

class _UnlockedIcon extends StatelessWidget {
  const _UnlockedIcon({required this.badge});
  final Badge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            badge.color.withOpacity(0.9),
            badge.color,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: badge.color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        badge.iconData,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _InProgressIcon extends StatelessWidget {
  const _InProgressIcon({required this.badge});
  final Badge badge;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: badge.color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: badge.color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Icon(
          badge.iconData,
          color: badge.color,
          size: 22,
        ),
      ),
    );
  }
}

class _LockedIcon extends StatelessWidget {
  const _LockedIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.help_outline,
            color: AppColors.textDisabled,
            size: 24,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: AppColors.surface,
              child: Icon(
                Icons.lock,
                size: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
