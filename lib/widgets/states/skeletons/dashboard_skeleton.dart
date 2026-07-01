// lib/widgets/states/skeletons/dashboard_skeleton.dart
// Skeleton qui reproduit la forme du Dashboard pendant le chargement.
//
// Le dashboard (lib/screens/dashboard/dashboard_screen.dart) est compose de :
//   1. Header : avatar + prenom + date + streak
//   2. Score global : grand cercle (CircularPercentIndicator) + prediction BEPC
//   3. Progression par matiere : 3-5 lignes avec LinearPercentIndicator
//   4. Heatmap chapitres faibles : 5 lignes
//   5. Stats SRS : 3 cartes en row
//   6. Activite 7 jours : graphique LineChart
//   7. Actions rapides : 2 boutons en row
//
// Ce skeleton reproduit la structure generale (header + 4 stats + cercle +
// 3 lignes matieres + rectangle graphique). Les sections les plus details
// (heatmap, stats SRS) sont simulees par des blocs plus simples pour rester
// lisibles pendant le chargement.

import 'package:flutter/material.dart';

import '../../../theme/adaptive_colors.dart';
import '../loading_skeleton.dart';

class DashboardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const DashboardSkeleton({
    super.key,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. Header : avatar + prenom + date ───────────────────
          Row(
            children: [
              const ShimmerBox(width: 56, height: 56, circular: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 180, height: 18, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 120, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── 2. Score global : grand cercle + prediction ──────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AdaptiveColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdaptiveColors.divider(context)),
            ),
            child: Row(
              children: [
                const ShimmerBox(width: 100, height: 100, circular: true),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 140, height: 16, borderRadius: 4),
                      SizedBox(height: 10),
                      ShimmerBox(width: 200, height: 14, borderRadius: 4),
                      SizedBox(height: 10),
                      ShimmerBox(width: 160, height: 14, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── 3. Progression par matiere : 3 lignes ────────────────
          const _SectionHeader(),
          const SizedBox(height: 12),
          const _MatiereRowSkeleton(),
          const SizedBox(height: 10),
          const _MatiereRowSkeleton(),
          const SizedBox(height: 10),
          const _MatiereRowSkeleton(),
          const SizedBox(height: 24),

          // ─── 4. Stats SRS : 3 cartes en row ───────────────────────
          const _SectionHeader(),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _StatCardSkeleton()),
              SizedBox(width: 10),
              Expanded(child: _StatCardSkeleton()),
              SizedBox(width: 10),
              Expanded(child: _StatCardSkeleton()),
            ],
          ),
          const SizedBox(height: 24),

          // ─── 5. Activite 7 jours : rectangle graphique ────────────
          const _SectionHeader(),
          const SizedBox(height: 12),
          Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdaptiveColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdaptiveColors.divider(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 100, height: 14, borderRadius: 4),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    _BarSkeleton(height: 40),
                    SizedBox(width: 12),
                    _BarSkeleton(height: 70),
                    SizedBox(width: 12),
                    _BarSkeleton(height: 55),
                    SizedBox(width: 12),
                    _BarSkeleton(height: 90),
                    SizedBox(width: 12),
                    _BarSkeleton(height: 65),
                    SizedBox(width: 12),
                    _BarSkeleton(height: 80),
                    SizedBox(width: 12),
                    _BarSkeleton(height: 100),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return const ShimmerBox(width: 160, height: 18, borderRadius: 4);
  }
}

class _MatiereRowSkeleton extends StatelessWidget {
  const _MatiereRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 36, height: 36, circular: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(
                  width: double.infinity,
                  height: 6,
                  borderRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Column(
        children: const [
          ShimmerBox(width: 40, height: 40, circular: true),
          SizedBox(height: 10),
          ShimmerBox(width: 50, height: 16, borderRadius: 4),
          SizedBox(height: 6),
          ShimmerBox(width: 30, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

class _BarSkeleton extends StatelessWidget {
  final double height;
  const _BarSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: 16,
      height: height,
      borderRadius: 4,
    );
  }
}
