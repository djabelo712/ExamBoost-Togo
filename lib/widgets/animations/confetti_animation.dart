// lib/widgets/animations/confetti_animation.dart
// Confettis pour célébrations (fin de session, déblocage badge, etc.)
//
// Implémentation 100% Flutter (CustomPaint + AnimationController), sans
// dépendance externe. Deux modes :
//   - shouldExplode = true  : explosion depuis le centre (cercle 360 deg)
//   - shouldExplode = false : pluie depuis le haut avec zigzag
//
// Physique : gravite (y += 0.3/frame), rotation aleatoire, vent leger.
// Couleurs par defaut : vert Togo + orange + blanc + bleu (palette app).
//
// Utilisation :
//   ConfettiAnimation(
//     duration: const Duration(seconds: 3),
//     shouldExplode: true,
//     onComplete: () => print('confettis finis'),
//   )

import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ConfettiAnimation extends StatefulWidget {
  /// Nombre de particules. Plus il y en a, plus l'effet est dense
  /// (mais attention au CPU sur smartphones bas de gamme).
  final int particleCount;

  /// Duree totale de l'animation avant fade out.
  final Duration duration;

  /// true = explosion depuis le centre, false = pluie depuis le haut.
  final bool shouldExplode;

  /// Couleurs des particules. Si null, palette par defaut Togo.
  final List<Color>? colors;

  /// Callback appele a la fin de l'animation (apres fade out).
  final VoidCallback? onComplete;

  const ConfettiAnimation({
    super.key,
    this.particleCount = 100,
    this.duration = const Duration(seconds: 3),
    this.shouldExplode = false,
    this.colors,
    this.onComplete,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  late final List<Color> _colors;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    _colors = widget.colors ??
        const [
          AppColors.primary, // vert Togo
          AppColors.accent, // orange
          Colors.white, // blanc
          AppColors.info, // bleu
        ];

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Les particules sont initialisees une seule fois ; leur position est
    // recalculee a chaque frame dans le CustomPainter en fonction de t.
    _particles = List.generate(widget.particleCount, (_) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 220; // vitesse radiale initiale
      return _ConfettiParticle(
        color: _colors[_rng.nextInt(_colors.length)],
        angle: angle,
        speed: speed,
        size: Size(
          6 + _rng.nextDouble() * 6, // largeur 6-12
          8 + _rng.nextDouble() * 8, // hauteur 8-16
        ),
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 12, // rad/s
        windPhase: _rng.nextDouble() * 2 * pi,
        // En mode pluie, on demarre distribue sur toute la largeur en haut.
        startX: widget.shouldExplode ? 0.0 : _rng.nextDouble(),
      );
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    // Demarrage differe pour laisser le build se faire.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
              shouldExplode: widget.shouldExplode,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Modele de particule (immutable, position recalculee dans le painter)
// ─────────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final Color color;
  final double angle; // direction initiale (mode explosion)
  final double speed; // vitesse radiale initiale (px/s)
  final Size size; // dimensions du rectangle
  final double rotation; // rotation initiale (rad)
  final double rotationSpeed; // vitesse de rotation (rad/s)
  final double windPhase; // phase du vent (oscillation horizontale)
  final double startX; // position X initiale en fraction de largeur (0..1)

  const _ConfettiParticle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.windPhase,
    required this.startX,
  });
}

// ─────────────────────────────────────────────────────────────────────
// Painter : calcule la position de chaque particule a l'instant t
// ─────────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress; // 0..1
  final bool shouldExplode;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.shouldExplode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out sur les 25% derniers pour une sortie douce.
    final fadeOpacity = progress < 0.75
        ? 1.0
        : (1.0 - ((progress - 0.75) / 0.25)).clamp(0.0, 1.0);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final tSeconds = progress * 3.0; // duree de reference 3s pour la physique

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      double x;
      double y;

      if (shouldExplode) {
        // Mouvement radial depuis le centre + gravite vers le bas.
        final r = p.speed * tSeconds;
        x = centerX + cos(p.angle) * r;
        // gravite : y = centerY + sin(angle)*r + 0.5*g*t^2
        y = centerY + sin(p.angle) * r + 0.5 * 250 * tSeconds * tSeconds;
        // vent leger oscillant
        x += sin(tSeconds * 2 + p.windPhase) * 20;
      } else {
        // Pluie : demarre en haut (x distribue), descend avec gravite.
        x = p.startX * size.width +
            sin(tSeconds * 3 + p.windPhase) * 30; // zigzag
        y = -20 + p.speed * tSeconds; // tombe depuis le haut
      }

      // Skip si hors cadre (optimisation)
      if (x < -50 || x > size.width + 50 || y > size.height + 50) continue;

      final rotation = p.rotation + p.rotationSpeed * tSeconds;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      paint.color = p.color.withOpacity(fadeOpacity);
      // Petit rectangle centre sur l'origine.
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size.width,
        height: p.size.height,
      );
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
