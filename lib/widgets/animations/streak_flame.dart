// lib/widgets/animations/streak_flame.dart
// Flamme animee pour indiquer le streak de l'eleve (jours consecutifs).
//
// Comportement selon le nombre de jours :
//   0-2 jours  : gris (pas de flamme, juste icone)
//   3-6 jours  : orange petit feu
//   7-29 jours : orange vif + animation pulsation
//   30+ jours  : rouge + grosses flammes + etincelles
//
// Animation : flamme qui oscille (scale 1.0 -> 1.1 -> 1.0) en boucle,
//             etincelles qui montent si 30+ jours.
//
// Utilisation :
//   StreakFlame(days: 12, size: 32)
//   StreakFlame(days: user.streak, size: 48)

import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StreakFlame extends StatelessWidget {
  /// Nombre de jours consecutifs. 0 = pas de streak.
  final int days;

  /// Taille du widget carre. Valeurs typiques : 24, 32, 48, 64.
  final double size;

  const StreakFlame({
    super.key,
    required this.days,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    // Cas 1 : pas de streak (0-2 jours) -> icone grise sans animation
    if (days <= 2) {
      return Icon(
        Icons.local_fire_department_outlined,
        size: size,
        color: AppColors.textDisabled,
      );
    }

    // Cas 2-4 : flamme animee. La couleur et l'intensite dependent du streak.
    final flameColor = _flameColor(days);
    final isHot = days >= 30; // grosses flammes + etincelles
    final pulseScale = days >= 7 ? 1.1 : 1.05; // pulsation plus marquee au-delà de 7j

    return _AnimatedFlame(
      size: size,
      color: flameColor,
      pulseScale: pulseScale,
      isHot: isHot,
      days: days,
    );
  }

  /// Couleur de la flamme selon l'intensite du streak.
  Color _flameColor(int days) {
    if (days >= 30) return AppColors.error; // rouge
    if (days >= 7) return AppColors.accent; // orange vif
    return AppColors.accentLight; // orange clair (3-6 jours)
  }
}

// ─────────────────────────────────────────────────────────────────────
// Flame animée (StatefulWidget pour le AnimationController)
// ─────────────────────────────────────────────────────────────────────

class _AnimatedFlame extends StatefulWidget {
  final double size;
  final Color color;
  final double pulseScale;
  final bool isHot; // 30+ jours : etincelles + grosses flammes
  final int days;

  const _AnimatedFlame({
    required this.size,
    required this.color,
    required this.pulseScale,
    required this.isHot,
    required this.days,
  });

  @override
  State<_AnimatedFlame> createState() => _AnimatedFlameState();
}

class _AnimatedFlameState extends State<_AnimatedFlame>
    with TickerProviderStateMixin {
  late final AnimationController _flameController;
  late final AnimationController _sparkController;

  @override
  void initState() {
    super.initState();
    // Flamme : oscillation 1.2s en boucle (scale 1.0 -> pulseScale -> 1.0)
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Etincelles : 2s en boucle (utilise uniquement si isHot)
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.isHot) _sparkController.repeat();
  }

  @override
  void dispose() {
    _flameController.dispose();
    _sparkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Etincelles (seulement si streak >= 30)
          if (widget.isHot)
            AnimatedBuilder(
              animation: _sparkController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _SparksPainter(
                    progress: _sparkController.value,
                    color: widget.color,
                  ),
                );
              },
            ),

          // Flamme principale (oscillation scale)
          AnimatedBuilder(
            animation: _flameController,
            builder: (context, child) {
              // Courbe en cloche pour un mouvement plus naturel
              final t = Curves.easeInOut.transform(_flameController.value);
              final scale = 1.0 + (widget.pulseScale - 1.0) * t;
              return Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: child,
              );
            },
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _FlamePainter(
                color: widget.color,
                isHot: widget.isHot,
              ),
            ),
          ),

          // Nombre de jours en bas (style badge)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.days}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size * 0.28,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Painter de la flamme : goutte ovale avec degradé vertical
// ─────────────────────────────────────────────────────────────────────

class _FlamePainter extends CustomPainter {
  final Color color;
  final bool isHot;

  _FlamePainter({required this.color, required this.isHot});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Chemin en forme de flamme : pointe en haut, base arrondie en bas.
    final path = Path();
    // Pointe haute legerement decalee pour effet "flamme qui danse"
    final tipDx = isHot ? w * 0.06 : 0.0;
    path.moveTo(w / 2 + tipDx, h * 0.05); // pointe
    path.cubicTo(
      w * 0.95, h * 0.35,
      w * 0.85, h * 0.85,
      w / 2, h * 0.95,
    );
    path.cubicTo(
      w * 0.15, h * 0.85,
      w * 0.05, h * 0.35,
      w / 2 + tipDx, h * 0.05,
    );
    path.close();

    // Degradé vertical : couleur principale -> couleur plus claire en haut
    final rect = Rect.fromLTWH(0, 0, w, h);
    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        color,
        Color.lerp(color, Colors.yellow, 0.5)!,
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Contour leger pour definir la flamme sur fond clair
    final strokePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, strokePaint);

    // Coeur clair de la flamme (petit ovale jaune au centre-bas)
    final coreRect = Rect.fromCenter(
      center: Offset(w / 2, h * 0.70),
      width: w * 0.25,
      height: h * 0.30,
    );
    final corePaint = Paint()..color = Colors.yellowAccent.withOpacity(0.7);
    canvas.drawOval(coreRect, corePaint);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isHot != isHot;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Painter des etincelles : 6 petits points qui montent
// ─────────────────────────────────────────────────────────────────────

class _SparksPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  _SparksPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    // 6 etincelles distribuees en angle
    for (int i = 0; i < 6; i++) {
      // Chaque etincelle a un decalage de phase different
      final phase = (progress + i / 6) % 1.0;
      // Position : partent du centre, montent en spirale
      final angle = i * (pi / 3) + phase * 0.5;
      final radius = phase * w * 0.6;
      final x = w / 2 + cos(angle) * radius * 0.3;
      final y = h * 0.5 - phase * h * 0.6; // montent vers le haut

      // Opacite : fade in puis fade out
      final opacity = sin(phase * pi);
      paint.color = color.withOpacity(opacity * 0.9);

      // Taille : diminue avec la phase
      final r = (w * 0.05) * (1 - phase * 0.5);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
