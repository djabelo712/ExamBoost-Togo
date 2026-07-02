// lib/widgets/animations/progress_ring.dart
// Anneau de progression circulaire anime.
//
// Animation : l'anneau se remplit progressivement de 0 a `progress`
// sur `animationDuration` avec courbe easeOutCubic.
//
// Utilisation :
//   ProgressRing(
//     progress: 0.78,
//     size: 120,
//     strokeWidth: 8,
//     child: Text('78%'),
//   )
//
// Pour le score final d'une session de revision :
//   ProgressRing(
//     progress: taux / 100,
//     size: 160,
//     strokeWidth: 12,
//     color: AppColors.success,
//     child: CountUpText(
//       value: taux,
//       suffix: '%',
//       style: AppTextStyles.h1,
//     ),
//   )

import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ProgressRing extends StatefulWidget {
  /// Progression cible entre 0.0 et 1.0.
  final double progress;

  /// Taille du widget carre (diametre de l'anneau).
  final double size;

  /// Epaisseur du trait de l'anneau.
  final double strokeWidth;

  /// Couleur de l'anneau (defaut : AppColors.primary).
  final Color? color;

  /// Couleur du fond de l'anneau (track). Si null, derive de `color`.
  final Color? trackColor;

  /// Contenu affiche au centre de l'anneau (texte, icone, etc.).
  final Widget? child;

  /// Duree de l'animation de remplissage.
  final Duration animationDuration;

  /// Courbe d'animation.
  final Curve curve;

  /// Borne arrondie des extremites du trait.
  final StrokeCap strokeCap;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 6,
    this.color,
    this.trackColor,
    this.child,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.curve = Curves.easeOutCubic,
    this.strokeCap = StrokeCap.round,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la progression change, on relance l'animation depuis la valeur actuelle.
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.color ?? AppColors.primary;
    final trackColor = widget.trackColor ?? ringColor.withOpacity(0.15);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau (CustomPaint pour eviter la dependance percent_indicator)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: _animation.value,
                  color: ringColor,
                  trackColor: trackColor,
                  strokeWidth: widget.strokeWidth,
                  strokeCap: widget.strokeCap,
                ),
              );
            },
          ),
          // Contenu central (texte, icone, etc.)
          if (widget.child != null)
            Padding(
              padding: EdgeInsets.all(widget.strokeWidth),
              child: Center(child: widget.child),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Painter : arc circulaire (commence en haut, sens horaire)
// ─────────────────────────────────────────────────────────────────────

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final StrokeCap strokeCap;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.strokeCap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // 1. Track (cercle complet en gris clair)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Arc de progression (commence en haut, sens horaire)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;

    // -pi/2 = en haut ; on parcourt progress * 2*pi dans le sens horaire.
    final sweepAngle = progress * 2 * pi;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2, // startAngle (en haut)
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
