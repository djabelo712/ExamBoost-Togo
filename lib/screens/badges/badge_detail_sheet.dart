// lib/screens/badges/badge_detail_sheet.dart
// Bottom sheet affichant les détails d'un badge.
//
// Contenu :
//   - Grande icône badge au centre (avec glow si débloqué)
//   - Titre + niveau (Bronze/Argent/Or en couleur métallique)
//   - Description complète (ou "???" si verrouillé et sans progression)
//   - Date de déblocage (si débloqué)
//   - XP gagnées
//   - Pour les badges à 3 niveaux : liste des 3 niveaux avec statut
//   - Bouton "Partager" (UI only — génère un texte de partage)

import 'package:flutter/material.dart';

import '../../models/badge.dart';
import '../../theme/app_theme.dart';
import 'widgets/badge_progress_bar.dart';

class BadgeDetailSheet extends StatelessWidget {
  const BadgeDetailSheet({
    super.key,
    required this.badge,
    required this.userBadge,
    required this.allUserBadges,
  });

  /// Badge courant (celui sur lequel l'élève a tapé).
  final Badge badge;

  /// État de progression de l'élève pour ce badge.
  final UserBadge? userBadge;

  /// Tous les UserBadge (pour afficher le statut des autres niveaux).
  final Map<String, UserBadge> allUserBadges;

  /// Ouvre le bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Badge badge,
    required UserBadge? userBadge,
    required Map<String, UserBadge> allUserBadges,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BadgeDetailSheet(
        badge: badge,
        userBadge: userBadge,
        allUserBadges: allUserBadges,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked(userBadge);
    final isInProgress =
        !isUnlocked && (userBadge?.progress ?? 0) > 0;
    final isLocked = !isUnlocked && !isInProgress;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Poignée ───────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ─── Grande icône ──────────────────────────────────────
            _BigBadgeIcon(
              badge: badge,
              isUnlocked: isUnlocked,
              isInProgress: isInProgress,
            ),
            const SizedBox(height: 16),

            // ─── Titre + niveau ────────────────────────────────────
            Text(
              badge.title,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: badge.level.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: badge.level.color.withOpacity(0.4),
                ),
              ),
              child: Text(
                'Niveau ${badge.level.label}',
                style: TextStyle(
                  color: badge.level.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Description ───────────────────────────────────────
            Text(
              isLocked ? '???' : badge.description,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: isLocked
                    ? AppColors.textDisabled
                    : AppColors.textSecondary,
                fontStyle: isLocked ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 20),

            // ─── Stats (date, XP) si débloqué ──────────────────────
            if (isUnlocked) ...[
              _StatsRow(badge: badge, userBadge: userBadge!),
              const SizedBox(height: 20),
            ],

            // ─── Progression si en cours ───────────────────────────
            if (isInProgress) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue pour débloquer !',
                      style: AppTextStyles.label.copyWith(
                        color: badge.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BadgeProgressBar(
                      badge: badge,
                      userBadge: userBadge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Niveaux (si famille multi-niveaux) ────────────────
            _LevelsSection(
              badge: badge,
              allUserBadges: allUserBadges,
            ),

            // ─── Boutons d'action ──────────────────────────────────
            if (isUnlocked) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareBadge(context),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Partager'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Bouton "Partager" — UI only.
  /// Pour une vraie intégration : utiliser share_plus ou RepaintBoundary
  /// pour générer un PNG du badge + texte.
  void _shareBadge(BuildContext context) {
    final text =
        'J\'ai débloqué le badge "${badge.title}" (${badge.level.label}) '
        'sur ExamBoost Togo ! +${badge.xpReward} XP';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Copier',
          onPressed: () {
            // Pour l'instant UI only — brancher clipboard.copy(text)
            // + share_plus pour le partage natif.
          },
        ),
      ),
    );
  }
}

// ─── Sous-composants ─────────────────────────────────────────────

class _BigBadgeIcon extends StatelessWidget {
  const _BigBadgeIcon({
    required this.badge,
    required this.isUnlocked,
    required this.isInProgress,
  });

  final Badge badge;
  final bool isUnlocked;
  final bool isInProgress;

  @override
  Widget build(BuildContext context) {
    final size = 96.0;

    if (isUnlocked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: badge.level.gradient,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: badge.color.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          badge.iconData,
          color: Colors.white,
          size: 48,
        ),
      );
    }

    if (isInProgress) {
      return Opacity(
        opacity: 0.7,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: badge.color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: badge.color.withOpacity(0.6),
              width: 2,
            ),
          ),
          child: Icon(
            badge.iconData,
            color: badge.color,
            size: 44,
          ),
        ),
      );
    }

    // Verrouillé
    return Container(
      width: size,
      height: size,
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
            size: 44,
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surface,
              child: Icon(
                Icons.lock,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.badge, required this.userBadge});
  final Badge badge;
  final UserBadge userBadge;

  @override
  Widget build(BuildContext context) {
    final d = userBadge.unlockedAt!;
    final dateStr =
        'Débloqué le ${d.day}/${d.month}/${d.year} à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '+${badge.xpReward} XP',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_available,
                  color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelsSection extends StatelessWidget {
  const _LevelsSection({
    required this.badge,
    required this.allUserBadges,
  });

  final Badge badge;
  final Map<String, UserBadge> allUserBadges;

  @override
  Widget build(BuildContext context) {
    final levels = Badges.levelsOf(badge.group);
    if (levels.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tous les niveaux',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...levels.map((lvl) => _LevelRow(
              badge: lvl,
              userBadge: allUserBadges[lvl.id],
              isCurrent: lvl.id == badge.id,
            )),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.badge,
    required this.userBadge,
    required this.isCurrent,
  });

  final Badge badge;
  final UserBadge? userBadge;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked(userBadge);
    final isInProgress = !isUnlocked && (userBadge?.progress ?? 0) > 0;

    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (isUnlocked) {
      statusIcon = Icons.check_circle;
      statusColor = AppColors.success;
      statusText = 'Débloqué';
    } else if (isInProgress) {
      statusIcon = Icons.trending_up;
      statusColor = badge.color;
      statusText = badge.progressText(userBadge);
    } else {
      statusIcon = Icons.lock_outline;
      statusColor = AppColors.textDisabled;
      statusText = 'Verrouillé';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? badge.level.color.withOpacity(0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(color: badge.level.color.withOpacity(0.4))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: badge.level.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.iconData,
              color: badge.level.color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.level.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: badge.level.color,
                  ),
                ),
                Text(
                  'Seuil : ${badge.requiredValue} ${badge.progressLabel}'.trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
