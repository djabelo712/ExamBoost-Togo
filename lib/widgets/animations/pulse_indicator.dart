// lib/widgets/animations/pulse_indicator.dart
// Point pulse (style " live " / " recording " / " online ").
//
// Animation : scale 1.0 -> 1.5 -> 1.0 en boucle avec opacity 1.0 -> 0.3 -> 1.0.
//
// Utilisation :
//   // Indicateur " en direct " (rouge)
//   Row(children: [
//     PulseIndicator(),
//     SizedBox(width: 6),
//     Text('EN DIRECT', style: AppTextStyles.label),
//   ])
//
//   // Indicateur " online " (vert)
//   PulseIndicator(color: AppColors.success, size: 10)
//
//   // Sans animation (statique)
//   PulseIndicator(animate: false)

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PulseIndicator extends StatefulWidget {
  /// Couleur du point (defaut : rouge " live ").
  final Color color;

  /// Taille du point (diametre en px). Defaut 8.
  final double size;

  /// Activer l'animation de pulsation. Defaut true.
  final bool animate;

  /// Duree d'un cycle de pulsation (1.0 -> 1.5 -> 1.0).
  final Duration duration;

  const PulseIndicator({
    super.key,
    this.color = AppColors.error,
    this.size = 8,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: widget.duration,
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller ??= AnimationController(
        vsync: this,
        duration: widget.duration,
      )..repeat(reverse: true);
    } else if (!widget.animate && oldWidget.animate) {
      _controller?.stop();
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Taille du widget : on reserve 2x la taille pour laisser de la place
    // a l'animation de scale (sinon le point peut etre clip).
    final widgetSize = widget.size * 2;

    if (!widget.animate || _controller == null) {
      return SizedBox(
        width: widgetSize,
        height: widgetSize,
        child: Center(
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        // t va de 0 a 1 puis 1 a 0 (reverse)
        final t = _controller!.value;
        // Scale 1.0 -> 1.5
        final scale = 1.0 + 0.5 * t;
        // Opacity 1.0 -> 0.3
        final opacity = 1.0 - 0.7 * t;

        return SizedBox(
          width: widgetSize,
          height: widgetSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo en arriere-plan (scale + opacity variables)
              Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Point central fixe (toujours plein)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
