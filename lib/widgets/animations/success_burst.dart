// lib/widgets/animations/success_burst.dart
// Explosion de succes quand l'eleve a une bonne reponse.
//
// 4 types d'effets :
//   - correct   : petites etoiles jaunes qui explosent vers l'exterieur (1s)
//   - mastered  : anneau vert qui s'etend + check au centre (1.5s)
//   - perfect   : confettis + anneau + etoiles (2s)
//   - levelup   : cercle qui monte + texte "NIVEAU SUPERIEUR !" (2s)
//
// Utilisation (apres une bonne reponse dans revision_screen) :
//   OverlayEntry? entry;
//   entry = OverlayEntry(builder: (_) => Positioned.fill(
//     child: SuccessBurst(type: SuccessType.correct, onComplete: () => entry?.remove()),
//   ));
//   Overlay.of(context).insert(entry);
//
// Ou dans un Stack simple :
//   Stack(children: [
//     ...,
//     SuccessBurst(type: SuccessType.mastered),
//   ]);

import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'confetti_animation.dart';

/// Type de succes -> déclenche un effet visuel different.
enum SuccessType {
  /// Bonne reponse simple : etoiles jaunes qui explosent (1s)
  correct,

  /// Carte maitrisee : anneau vert + check au centre (1.5s)
  mastered,

  /// Reponse parfaite (no mistakes) : confettis + anneau + etoiles (2s)
  perfect,

  /// Passage de niveau : cercle qui monte + texte (2s)
  levelup,
}

class SuccessBurst extends StatefulWidget {
  final SuccessType type;
  final VoidCallback? onComplete;

  const SuccessBurst({
    super.key,
    this.type = SuccessType.correct,
    this.onComplete,
  });

  @override
  State<SuccessBurst> createState() => _SuccessBurstState();
}

class _SuccessBurstState extends State<SuccessBurst>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = _durationFor(widget.type);
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  Duration _durationFor(SuccessType type) {
    switch (type) {
      case SuccessType.correct:
        return const Duration(milliseconds: 1000);
      case SuccessType.mastered:
        return const Duration(milliseconds: 1500);
      case SuccessType.perfect:
        return const Duration(milliseconds: 2000);
      case SuccessType.levelup:
        return const Duration(milliseconds: 2000);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: _buildLayers(),
      ),
    );
  }

  List<Widget> _buildLayers() {
    switch (widget.type) {
      case SuccessType.correct:
        return [_StarsBurst(controller: _controller)];

      case SuccessType.mastered:
        return [
          _ExpandingRing(controller: _controller),
          _CheckMark(controller: _controller),
        ];

      case SuccessType.perfect:
        // Combine confettis + anneau + etoiles
        return [
          // Confettis en arriere-plan (explosion centre)
          Positioned.fill(
            child: ConfettiAnimation(
              particleCount: 60,
              duration: const Duration(milliseconds: 2000),
              shouldExplode: true,
              colors: const [
                AppColors.primary,
                AppColors.accent,
                Colors.white,
                AppColors.info,
                AppColors.warning,
              ],
            ),
          ),
          _ExpandingRing(controller: _controller),
          _StarsBurst(controller: _controller, color: AppColors.warning),
        ];

      case SuccessType.levelup:
        return [
          _LevelUpOverlay(controller: _controller),
        ];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Etoiles qui explosent vers l'exterieur
// ─────────────────────────────────────────────────────────────────────

class _StarsBurst extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _StarsBurst({required this.controller, this.color = const Color(0xFFFFC107)});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _StarsBurstPainter(
            progress: controller.value,
            color: color,
          ),
        );
      },
    );
  }
}

class _StarsBurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StarsBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    // 8 etoiles distribuees en cercle
    const count = 8;
    final paint = Paint()..color = color;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi;
      final r = progress * maxRadius;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;

      // Opacite : visible jusqu'à 70% puis fade out
      final opacity = progress < 0.7 ? 1.0 : (1 - (progress - 0.7) / 0.3);
      paint.color = color.withOpacity(opacity.clamp(0.0, 1.0));

      // Taille decroissante
      final starSize = (1 - progress * 0.5) * 8.0;

      canvas.save();
      canvas.translate(x, y);
      _drawStar(canvas, paint, starSize, rotation: progress * pi + angle);
      canvas.restore();
    }
  }

  /// Dessine une etoile a 5 branches centree sur l'origine.
  void _drawStar(Canvas canvas, Paint paint, double radius, {double rotation = 0}) {
    const points = 5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.4;
      final a = rotation + (i / (points * 2)) * 2 * pi - pi / 2;
      final x = cos(a) * r;
      final y = sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarsBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────
// Anneau qui s'etend depuis le centre
// ─────────────────────────────────────────────────────────────────────

class _ExpandingRing extends StatelessWidget {
  final AnimationController controller;

  const _ExpandingRing({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ExpandingRingPainter(
            progress: controller.value,
            color: AppColors.success,
          ),
        );
      },
    );
  }
}

class _ExpandingRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ExpandingRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    // easeOut : l'anneau s'etend vite puis ralentit
    final t = Curves.easeOutCubic.transform(progress);
    final radius = t * maxRadius;
    // Epaisseur decroissante
    final strokeWidth = 8.0 * (1 - progress);
    if (strokeWidth <= 0) return;

    // Opacite fade out
    final opacity = (1 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpandingRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────
// Check mark qui se dessine au centre
// ─────────────────────────────────────────────────────────────────────

class _CheckMark extends StatelessWidget {
  final AnimationController controller;

  const _CheckMark({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Le check apparait avec un petit scale + fade in differe
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Apparait a 30% de l'animation
        final t = (controller.value / 0.4).clamp(0.0, 1.0);
        final scale = 0.5 + 0.5 * Curves.easeOutBack.transform(t);
        final opacity = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Level up : cercle qui monte + texte
// ─────────────────────────────────────────────────────────────────────

class _LevelUpOverlay extends StatelessWidget {
  final AnimationController controller;

  const _LevelUpOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Phase 1 (0-0.5) : cercle qui monte + scale
        // Phase 2 (0.5-1.0) : texte qui apparait + reste
        final circlePhase = (controller.value / 0.5).clamp(0.0, 1.0);
        final textPhase = ((controller.value - 0.4) / 0.4).clamp(0.0, 1.0);

        // Le cercle monte de +40px et grossit de 1.0 -> 1.5
        final dy = -40 * Curves.easeOut.transform(circlePhase);
        final circleScale = 1.0 + 0.5 * circlePhase;

        // Fade out du cercle en phase 2
        final circleOpacity =
            controller.value < 0.6 ? 1.0 : (1 - (controller.value - 0.6) / 0.4);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Cercle qui monte
            Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: circleScale,
                child: Opacity(
                  opacity: circleOpacity.clamp(0.0, 1.0),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent,
                          AppColors.warning,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            // Texte "NIVEAU SUPERIEUR !" qui apparait
            if (textPhase > 0)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Opacity(
                  opacity: textPhase,
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * Curves.easeOutBack.transform(textPhase),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'NIVEAU SUPERIEUR !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
