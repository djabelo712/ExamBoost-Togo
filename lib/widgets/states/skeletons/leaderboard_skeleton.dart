// lib/widgets/states/skeletons/leaderboard_skeleton.dart
// Skeleton qui reproduit la forme du classement (leaderboard) pendant le
// chargement.
//
// Le classement communautaire affiche typiquement :
//   - Top 3 (podium) en grand avec avatar + nom + score
//   - Liste des autres eleves (lignes avatar + nom + score)
//
// Ce skeleton reproduit cette structure :
//   - Podium : 3 cartes en row (2nd | 1er | 3e), la 1ere plus haute
//   - Liste : 7 lignes standard avatar + nom + score

import 'package:flutter/material.dart';

import '../../../theme/adaptive_colors.dart';
import '../loading_skeleton.dart';

class LeaderboardSkeleton extends StatelessWidget {
  /// Nombre de lignes standard (hors podium). Defaut : 7.
  final int itemCount;

  /// Padding autour du skeleton. Defaut : 16.
  final EdgeInsetsGeometry padding;

  const LeaderboardSkeleton({
    super.key,
    this.itemCount = 7,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: Column(
        children: [
          // ─── Podium Top 3 (2e | 1er | 3e) ─────────────────────────
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(child: _PodiumSkeleton(heightFactor: 0.75)),
                const SizedBox(width: 8),
                const Expanded(child: _PodiumSkeleton(heightFactor: 1.0)),
                const SizedBox(width: 8),
                const Expanded(child: _PodiumSkeleton(heightFactor: 0.60)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Lignes standard (4e a 10e) ───────────────────────────
          Column(
            children: List.generate(itemCount, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i == itemCount - 1 ? 0 : 10),
                child: const _LeaderboardRowSkeleton(),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PodiumSkeleton extends StatelessWidget {
  final double heightFactor;
  const _PodiumSkeleton({required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          ShimmerBox(
            width: 56,
            height: 56,
            circular: true,
          ),
          const SizedBox(height: 8),
          // Nom
          const ShimmerBox(width: 70, height: 12, borderRadius: 4),
          const SizedBox(height: 6),
          // Score
          ShimmerBox(
            width: 50,
            height: 16 * heightFactor,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRowSkeleton extends StatelessWidget {
  const _LeaderboardRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Row(
        children: [
          // Rang (numero)
          const ShimmerBox(width: 20, height: 14, borderRadius: 4),
          const SizedBox(width: 12),
          // Avatar
          const ShimmerBox(width: 36, height: 36, circular: true),
          const SizedBox(width: 12),
          // Nom
          Expanded(
            child: ShimmerBox(
              width: 140,
              height: 14,
              borderRadius: 4,
            ),
          ),
          const SizedBox(width: 12),
          // Score
          const ShimmerBox(width: 50, height: 16, borderRadius: 4),
        ],
      ),
    );
  }
}
