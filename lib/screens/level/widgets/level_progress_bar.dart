// lib/screens/level/widgets/level_progress_bar.dart
// Barre de progression vers le niveau suivant.
//
// Affiche :
//   - Le niveau actuel en grand à gauche
//   - Une barre animée (LinearProgressIndicator) colorée selon le niveau
//   - Le texte "120 / 500 XP" à droite
//   - Le niveau suivant en petit à droite de la barre
//
// Utilisé dans LevelScreen (en-tête) et LevelUpDialog (récap fin).
//
// Usage :
//   LevelProgressBar(cumulativeXp: 1200)
//   LevelProgressBar(cumulativeXp: 127500, compact: true)

import 'package:flutter/material.dart';

import '../../../services/level_service.dart';
import '../../../theme/app_theme.dart';

class LevelProgressBar extends StatelessWidget {
  const LevelProgressBar({
    super.key,
    required this.cumulativeXp,
    this.compact = false,
    this.showLevelNumbers = true,
  });

  /// XP cumulé total de l'élève (depuis UserLevel.totalXp).
  final int cumulativeXp;

  /// Mode compact (cartes plus petites, pour embedding).
  final bool compact;

  /// Afficher les numéros de niveau de part et d'autre de la barre.
  final bool showLevelNumbers;

  @override
  Widget build(BuildContext context) {
    final currentLevel = LevelService.levelFromXp(cumulativeXp);
    final isMax = currentLevel >= LevelService.maxLevel;
    final progress = LevelService.progressToNextLevel(cumulativeXp);
    final xpIntoLevel = LevelService.xpIntoCurrentLevel(cumulativeXp);
    final xpSpan = LevelService.xpForCurrentLevelSpan(cumulativeXp);
    final color = _colorForLevel(currentLevel);

    if (compact) {
      return _buildCompact(
        currentLevel: currentLevel,
        isMax: isMax,
        progress: progress,
        xpIntoLevel: xpIntoLevel,
        xpSpan: xpSpan,
        color: color,
      );
    }
    return _buildDetailed(
      currentLevel: currentLevel,
      isMax: isMax,
      progress: progress,
      xpIntoLevel: xpIntoLevel,
      xpSpan: xpSpan,
      color: color,
    );
  }

  // ─── Mode détaillé (LevelScreen en-tête) ──────────────────────

  Widget _buildDetailed({
    required int currentLevel,
    required bool isMax,
    required double progress,
    required int xpIntoLevel,
    required int xpSpan,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLevelNumbers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LevelBadge(level: currentLevel, color: color),
                if (!isMax)
                  Text(
                    'Niveau ${currentLevel + 1}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 1),
                    ),
                    child: Text(
                      'Niveau maximum',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 6 : 10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: compact ? 8 : 14,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMax
                  ? '$cumulativeXp XP cumulé'
                  : '$xpIntoLevel / $xpSpan XP',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isMax)
              Text(
                '${LevelService.xpToNextLevel(cumulativeXp)} XP '
                'avant niveau ${currentLevel + 1}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Text(
                '${(progress * 100).round()} %',
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Mode compact (embedding dans d'autres cartes) ────────────

  Widget _buildCompact({
    required int currentLevel,
    required bool isMax,
    required double progress,
    required int xpIntoLevel,
    required int xpSpan,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Niv. $currentLevel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              isMax ? 'MAX' : '$xpIntoLevel/$xpSpan',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ─── Couleur du niveau (gradient vert → orange → or) ─────────

  /// Couleur associée à un niveau pour la barre de progression.
  /// Niveaux 1-10 : vert Togo (débutant).
  /// Niveaux 11-25 : orange (intermédiaire).
  /// Niveaux 26-40 : violet (avancé).
  /// Niveaux 41-50 : or (expert / légende).
  static Color _colorForLevel(int level) {
    if (level <= 10) return AppColors.primary;
    if (level <= 25) return AppColors.accent;
    if (level <= 40) return const Color(0xFF7B1FA2);
    return const Color(0xFFFFB300);
  }
}

// ─── Pastille de niveau ────────────────────────────────────────────

/// Petite pastille ronde affichant le numéro de niveau avec sa couleur.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            'Niveau $level',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
