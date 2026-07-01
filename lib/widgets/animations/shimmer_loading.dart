// lib/widgets/animations/shimmer_loading.dart
// Skeleton shimmer pendant les chargements.
//
// Effet : degrade qui se deplace de gauche a droite en boucle (shimmer
// classique Material Design). A utiliser autour d'un Container placeholder
// de couleur `AppColors.surfaceVariant` qui a la meme forme que le widget
// reel a charger.
//
// Utilisation :
//   ShimmerLoading(
//     isLoading: _isLoading,
//     child: Container(
//       width: 200,
//       height: 20,
//       decoration: BoxDecoration(
//         color: AppColors.surfaceVariant,
//         borderRadius: BorderRadius.circular(4),
//       ),
//     ),
//   )
//
// Plusieurs placeholders en cascade :
//   ShimmerLoading(
//     isLoading: _isLoading,
//     child: Column(
//       children: [
//         _buildSkeletonLine(width: 180),
//         _buildSkeletonLine(width: 140),
//         _buildSkeletonLine(width: 200),
//       ],
//     ),
//   )

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ShimmerLoading extends StatefulWidget {
  /// Widget enfant. Quand isLoading est true, un effet shimmer est applique
  /// par-dessus via un ShaderMask. Quand isLoading est false, l'enfant est
  /// affiche tel quel (sans animation).
  final Widget child;

  /// Active ou desactive le shimmer.
  final bool isLoading;

  /// Couleur de base du shimmer (defaut : surfaceVariant).
  final Color baseColor;

  /// Couleur de la " vague " qui traverse (defaut : surface = blanc).
  final Color highlightColor;

  /// Duree d'un cycle complet gauche -> droite.
  final Duration period;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor = AppColors.surfaceVariant,
    this.highlightColor = AppColors.surface,
    this.period = const Duration(milliseconds: 1200),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    );
    if (widget.isLoading) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            // Le degrade se deplace de gauche (-1) a droite (+1) en fonction
            // de la valeur du controller (0..1).
            final dx = _controller.value * 2 - 1; // -1..1
            return LinearGradient(
              begin: Alignment(dx - 0.5, 0),
              end: Alignment(dx + 0.5, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      // ColorFilter en blanc pour que le shader remplace la couleur native
      // du child : on veut un rendu uni (placeholder).
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.surfaceVariant,
          BlendMode.srcATop,
        ),
        child: widget.child,
      ),
    );
  }
}
