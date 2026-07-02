// lib/widgets/figures/svg_figure.dart
// Widget de rendu d'une figure SVG inline issue de [FiguresLibrary].
//
// Dépendance : flutter_svg 2.0.10+1 (déjà présent dans pubspec.yaml).
// Le SVG est résolu via son `figureId` auprès de [FiguresLibrary].
//
// Usage typique dans une carte de question :
// ```dart
// if (question.figureId != null)
//   Padding(
//     padding: const EdgeInsets.only(bottom: 12),
//     child: SvgFigure(figureId: question.figureId!, width: 220),
//   ),
// ```

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'figures_library.dart';

/// Affiche une figure SVG identifiée par sa clé dans [FiguresLibrary].
///
/// - Si [figureId] n'existe pas dans la bibliothèque, un placeholder gris
///   "Figure introuvable" est affiché (pas de crash).
/// - Si [width] / [height] sont nuls, le SVG prend la taille naturelle de son
///   viewBox (souvent une bonne option pour les figures aux ratios variés).
/// - [tint] permet de teinter toute la figure dans une couleur unique (utile
///   en dark mode — applique un `ColorFilter.mode(tint, BlendMode.srcIn)`).
/// - [semanticLabel] est exposé pour l'accessibilité (lecteurs d'écran).
class SvgFigure extends StatelessWidget {
  /// Identifiant de la figure dans [FiguresLibrary].
  final String figureId;

  /// Largeur d'affichage (null = taille naturelle du viewBox).
  final double? width;

  /// Hauteur d'affichage (null = taille naturelle du viewBox).
  final double? height;

  /// Couleur de teinte optionnelle (applique un ColorFilter srcIn sur tout le SVG).
  final Color? tint;

  /// Étiquette sémantique pour les lecteurs d'écran.
  final String? semanticLabel;

  /// Marge interne optionnelle autour de la figure (utile pour l'isoler dans
  /// une carte). Defaults à 0.
  final EdgeInsetsGeometry padding;

  /// Alignement de la figure dans son conteneur.
  final AlignmentGeometry alignment;

  /// Filtre de clip : si vrai, la figure ne dépasse pas de son bounding box.
  final bool clipToSize;

  const SvgFigure({
    super.key,
    required this.figureId,
    this.width,
    this.height,
    this.tint,
    this.semanticLabel,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
    this.clipToSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final svg = FiguresLibrary.getFigure(figureId);

    // Figure inconnue — on retourne un placeholder discret plutôt que de crasher.
    if (svg == null) {
      return Container(
        width: width ?? 200,
        height: height ?? 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 28,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 6),
            Text(
              'Figure introuvable',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            Text(
              '« $figureId »',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
      );
    }

    // Figure trouvée — on délègue à flutter_svg.
    Widget picture = SvgPicture.string(
      svg,
      width: width,
      height: height,
      alignment: alignment,
      fit: BoxFit.contain,
      clipBehavior: clipToSize ? Clip.hardEdge : Clip.none,
      colorFilter:
          tint != null ? ColorFilter.mode(tint!, BlendMode.srcIn) : null,
      semanticsLabel: semanticLabel ?? 'Figure géométrique : $figureId',
    );

    if (padding == EdgeInsets.zero) {
      return picture;
    }

    return Padding(padding: padding, child: picture);
  }
}
