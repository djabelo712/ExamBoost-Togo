// lib/widgets/states/loading_skeleton.dart
// Skeleton shimmer generique reutilisable pour tous les ecrans ExamBoost.
//
// Fournit :
//   - ShimmerBox : un Container placeholder avec effet shimmer anime.
//   - LoadingSkeleton : liste de N cartes skeletons (defaut : 3).
//
// Utilisation de base :
//   LoadingSkeleton(itemCount: 5)  // 5 cartes shimmer standard
//
// Utilisation avancee (custom child) :
//   LoadingSkeleton(
//     itemCount: 1,
//     child: Column(
//       children: [
//         ShimmerBox(width: double.infinity, height: 24),
//         SizedBox(height: 12),
//         ShimmerBox(width: 200, height: 16),
//       ],
//     ),
//   )
//
// Compatibilite dark mode : ShimmerBox utilise AdaptiveColors.surfaceVariant
// et AdaptiveColors.surface comme couleurs de base/highlight du shimmer,
// calculees a l'execution selon Theme.of(context).brightness.

import 'package:flutter/material.dart';

import '../../theme/adaptive_colors.dart';
import '../animations/shimmer_loading.dart';

/// Box individuelle avec effet shimmer anime.
///
/// Equivalent d'un Container avec couleur surfaceVariant, wrappe dans
/// [ShimmerLoading] pour ajouter l'effet de vague lumineuse qui traverse.
///
/// Utilisation :
///   ShimmerBox(width: double.infinity, height: 24, borderRadius: 8)
class ShimmerBox extends StatelessWidget {
  /// Largeur. Passer `double.infinity` pour prendre toute la largeur
  /// disponible (typique pour les lignes de texte placeholder).
  final double width;

  /// Hauteur.
  final double height;

  /// Rayon des coins. Defaut : 4 (legèrement arrondi pour un look "texte").
  /// Passer 12+ pour les cartes, 999 pour les cercles (avatars).
  final double borderRadius;

  /// Marge autour de la box (optionnel).
  final EdgeInsetsGeometry margin;

  /// Si true, la box est ronde (cercle). Plus simple que de passer
  /// borderRadius: 999 avec width == height.
  final bool circular;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
    this.margin = EdgeInsets.zero,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AdaptiveColors.surfaceVariant(context);
    final highlightColor = AdaptiveColors.surface(context);

    final shape = circular
        ? const CircleBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          );

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ShimmerLoading(
        isLoading: true,
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          decoration: ShapeDecoration(
            color: baseColor,
            shape: shape,
          ),
        ),
      ),
    );
  }
}

/// Liste de N skeletons "carte standard" avec effet shimmer.
///
/// Par defaut, chaque item fait ~80px de haut avec une ligne de titre
/// (200px) et une ligne de sous-titre (140px). Pour un rendu personnalise,
/// passer un [child] unique (itemCount sera ignore).
///
/// Utilisation :
///   LoadingSkeleton(itemCount: 5)
class LoadingSkeleton extends StatelessWidget {
  /// Nombre d'items skeleton a afficher. Defaut : 3.
  final int itemCount;

  /// Si fourni, remplace les skeletons standards par ce widget.
  /// Typiquement utilise pour reproduire la forme exacte d'un ecran :
  ///   LoadingSkeleton(
  ///     itemCount: 1,
  ///     child: DashboardSkeletonContent(),
  ///   )
  final Widget? child;

  /// Espacement vertical entre les items. Defaut : 12.
  final double spacing;

  /// Padding horizontal autour de la liste. Defaut : 16.
  final EdgeInsetsGeometry padding;

  const LoadingSkeleton({
    super.key,
    this.itemCount = 3,
    this.child,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  }) : assert(itemCount >= 1, 'itemCount doit etre >= 1');

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Padding(padding: padding, child: child!);
    }

    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(itemCount, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == itemCount - 1 ? 0 : spacing,
            ),
            child: const _SkeletonCardItem(),
          );
        }),
      ),
    );
  }
}

/// Carte skeleton standard : 2 lignes (titre + sous-titre) avec icone a gauche.
class _SkeletonCardItem extends StatelessWidget {
  const _SkeletonCardItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Row(
        children: [
          // Icone placeholder (cercle)
          const ShimmerBox(
            width: 40,
            height: 40,
            circular: true,
          ),
          const SizedBox(width: 12),
          // Textes placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 200, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 140, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
