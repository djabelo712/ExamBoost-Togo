// lib/widgets/states/skeletons/list_skeleton.dart
// Skeleton generique pour les listes (favoris, notes, simulations, badges,
// search results...).
//
// Chaque ligne simule :
//   - petite icone (cercle) a gauche
//   - titre (rectangle long)
//   - sous-titre (rectangle plus court)
//
// Utilisation :
//   ListSkeleton(itemCount: 5)
//   ListSkeleton(itemCount: 3, leadingAvatar: true)
//
// Ce skeleton est equivalent au rendu standard de [LoadingSkeleton] mais
// expose plus d'options de personnalisation (avatar optionnel, titre
// largeur variable).

import 'package:flutter/material.dart';

import '../../../theme/adaptive_colors.dart';
import '../loading_skeleton.dart';

class ListSkeleton extends StatelessWidget {
  /// Nombre de lignes a afficher. Defaut : 5.
  final int itemCount;

  /// Si true, le leading est un cercle (avatar) au lieu d'une icone carree.
  final bool leadingAvatar;

  /// Afficher un trailing (chevron ou icone a droite). Defaut : false.
  final bool showTrailing;

  /// Espacement vertical entre les items. Defaut : 10.
  final double spacing;

  /// Padding autour de la liste. Defaut : 16.
  final EdgeInsetsGeometry padding;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.leadingAvatar = false,
    this.showTrailing = false,
    this.spacing = 10,
    this.padding = const EdgeInsets.all(16),
  }) : assert(itemCount >= 1, 'itemCount doit etre >= 1');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(itemCount, (i) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: i == itemCount - 1 ? 0 : spacing,
            ),
            child: _ListRowSkeleton(
              leadingAvatar: leadingAvatar,
              showTrailing: showTrailing,
              // Varier legerement la largeur du titre pour un effet naturel
              titleWidth: 180 + (i % 3) * 30,
              subtitleWidth: 120 + (i % 4) * 20,
            ),
          );
        }),
      ),
    );
  }
}

class _ListRowSkeleton extends StatelessWidget {
  final bool leadingAvatar;
  final bool showTrailing;
  final double titleWidth;
  final double subtitleWidth;

  const _ListRowSkeleton({
    required this.leadingAvatar,
    required this.showTrailing,
    required this.titleWidth,
    required this.subtitleWidth,
  });

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
          // Leading (icone ou avatar)
          if (leadingAvatar)
            const ShimmerBox(width: 44, height: 44, circular: true)
          else
            const ShimmerBox(width: 44, height: 44, borderRadius: 10),
          const SizedBox(width: 12),
          // Titre + sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: titleWidth,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: subtitleWidth,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          // Trailing (optionnel)
          if (showTrailing) ...[
            const SizedBox(width: 12),
            const ShimmerBox(width: 20, height: 20, circular: true),
          ],
        ],
      ),
    );
  }
}
