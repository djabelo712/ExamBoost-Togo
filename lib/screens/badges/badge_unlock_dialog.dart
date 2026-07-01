// lib/screens/badges/badge_unlock_dialog.dart
// Dialog plein écran affiché quand un nouveau badge est débloqué.
//
// Animation (≈ 1,8 s) :
//   1. Fond noir semi-transparent qui fade in
//   2. Particules dorées qui explosent depuis le centre (CustomPaint)
//   3. Icône badge qui scale 0 → 1,2 → 1,0 (easeOutBack) avec glow doré
//   4. "BADGE DÉBLOQUÉ !" qui fade in
//   5. Titre du badge + niveau qui slide up
//   6. "+250 XP" qui slide up
//   7. Boutons "Cool !" et "Partager" qui apparaissent
//
// À appeler après BadgeService.checkAndUnlock() :
//   if (nouveauxBadges.isNotEmpty) {
//     await BadgeUnlockDialog.show(context, nouveauxBadges.last);
//   }

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/badge.dart';
import '../../theme/app_theme.dart';

class BadgeUnlockDialog extends StatefulWidget {
  const BadgeUnlockDialog({
    super.key,
    required this.badge,
    this.onShare,
  });

  /// Badge fraîchement débloqué.
  final Badge badge;

  /// Callback optionnel pour le bouton "Partager".
  /// Si null, le bouton affiche un SnackBar informatif.
  final VoidCallback? onShare;

  /// Ouvre le dialog en plein écran.
  static Future<void> show(
    BuildContext context, {
    required Badge badge,
    VoidCallback? onShare,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => BadgeUnlockDialog(badge: badge, onShare: onShare),
    );
  }

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _glowController;

  // ─── Animations composites ────────────────────────────────────
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeRotation;
  late final Animation<double> _particles;
  late final Animation<double> _bgFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _levelFade;
  late final Animation<double> _xpFade;
  late final Animation<Offset> _xpSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    // ─── Contrôleur principal (1,8 s) ────────────────────────────
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    // ─── Contrôleur glow (boucle infinie, 1,2 s) ────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Curves
    const easeOutBack = Curves.easeOutBack;
    const easeOut = Curves.easeOut;
    const easeIn = Curves.easeIn;

    // Fond : 0 → 0,3 s
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: easeOut)),
    );

    // Badge scale : 0,1 → 0,7 s (avec overshoot easeOutBack)
    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7, curve: easeOutBack)),
    );

    // Badge rotation : petit twist pour l'effet "explosion"
    _badgeRotation = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7, curve: easeOut)),
    );

    // Particules : 0,2 → 1,0 s (explosion + fade out)
    _particles = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: easeIn)),
    );

    // Titre "BADGE DÉBLOQUÉ !" : 0,4 → 0,8 s
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: easeOut)),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: easeOut)),
    );

    // Niveau : 0,6 → 1,0 s
    _levelFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: easeOut)),
    );

    // "+X XP" : 0,9 → 1,3 s
    _xpFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.9, 1.3, curve: easeOut)),
    );
    _xpSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.9, 1.3, curve: easeOut)),
    );

    // Boutons : 1,3 → 1,7 s
    _buttonsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(1.3, 1.7, curve: easeOut)),
    );

    // Glow pulse (boucle)
    _glowPulse = Tween<double>(begin: 0.4, end: 0.9).animate(_glowController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _share() {
    if (widget.onShare != null) {
      widget.onShare!();
      _close();
      return;
    }

    // UI only : on capture le messenger avant pop() car le context
    // sera détaché après fermeture du dialog.
    final messenger = ScaffoldMessenger.of(context);
    _close();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Partage à venir : "J\'ai débloqué ${widget.badge.title} '
          '(${widget.badge.level.label}) sur ExamBoost Togo !"',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _glowController]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // ─── Fond noir semi-transparent ────────────────────────
            Opacity(
              opacity: _bgFade.value,
              child: const SizedBox.expand(
                child: ColoredBox(color: Colors.black87),
              ),
            ),

            // ─── Particules (CustomPaint) ─────────────────────────
            if (_particles.value < 1.0)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlePainter(
                    progress: _particles.value,
                    color: widget.badge.level.color,
                  ),
                ),
              ),

            // ─── Contenu central ──────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge icône (scale + rotation + glow pulsé)
                    _buildBadgeIcon(),

                    const SizedBox(height: 32),

                    // "BADGE DÉBLOQUÉ !"
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: Text(
                          'BADGE DÉBLOQUÉ !',
                          style: TextStyle(
                            color: widget.badge.level.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: widget.badge.level.color
                                    .withOpacity(0.6),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Titre du badge
                    FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        widget.badge.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Niveau
                    FadeTransition(
                      opacity: _levelFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.badge.level.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.badge.level.color,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Niveau ${widget.badge.level.label}',
                          style: TextStyle(
                            color: widget.badge.level.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // +X XP
                    SlideTransition(
                      position: _xpSlide,
                      child: FadeTransition(
                        opacity: _xpFade,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Color(0xFFFFB300), size: 28),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.badge.xpReward} XP',
                              style: const TextStyle(
                                color: Color(0xFFFFB300),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Boutons
                    FadeTransition(
                      opacity: _buttonsFade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _share,
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: const Text('Partager'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white54, width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _close,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Cool !'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Icône badge avec scale + rotation + glow ─────────────────

  Widget _buildBadgeIcon() {
    final scale = _badgeScale.value == 0.0 ? 0.001 : _badgeScale.value;
    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: _badgeRotation.value,
        child: AnimatedBuilder(
          animation: _glowPulse,
          builder: (context, _) {
            return Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.badge.level.gradient,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  // Glow doré qui pulse
                  BoxShadow(
                    color: widget.badge.level.color
                        .withOpacity(_glowPulse.value),
                    blurRadius: 32 + 16 * _glowPulse.value,
                    spreadRadius: 4,
                  ),
                  // Glow couleur badge
                  BoxShadow(
                    color: widget.badge.color.withOpacity(0.5),
                    blurRadius: 48,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo interne
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                  ),
                  Icon(
                    widget.badge.iconData,
                    color: Colors.white,
                    size: 64,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── CustomPainter : explosion de particules ─────────────────────

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.color,
  });

  /// 0.0 → 1.0 (1.0 = particules disparues)
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.min(size.width, size.height) * 0.45; // rayon max d'explosion

    // 24 particules réparties sur 360°
    const particleCount = 24;
    final paint = Paint()..style = PaintingStyle.fill;

    // Couleurs alternées : couleur niveau + blanc + doré
    final colors = [
      color,
      Colors.white,
      const Color(0xFFFFB300),
      color.withOpacity(0.7),
    ];

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      // Distance = progress * maxRadius (explosion)
      final distance = progress * maxRadius;
      final dx = center.dx + math.cos(angle) * distance;
      final dy = center.dy + math.sin(angle) * distance;

      // Taille qui décroît avec le progress
      final baseSize = 4.0 + (i % 3) * 2.0;
      final sizeFactor = (1 - progress).clamp(0.0, 1.0);
      final radius = baseSize * sizeFactor;

      // Opacité qui décroît avec le progress
      final opacity = (1 - progress).clamp(0.0, 1.0);

      paint.color = colors[i % colors.length].withOpacity(opacity * 0.9);

      // Petites particules = cercles, parfois étoiles
      if (i % 4 == 0) {
        _drawStar(canvas, Offset(dx, dy), radius, paint);
      } else {
        canvas.drawCircle(Offset(dx, dy), radius, paint);
      }
    }

    // Anneau de choc qui s'étend et s'estompe
    final ringRadius = progress * maxRadius * 1.1;
    final ringOpacity = (1 - progress).clamp(0.0, 1.0) * 0.6;
    paint
      ..color = color.withOpacity(ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - progress).clamp(0.0, 1.0);
    canvas.drawCircle(center, ringRadius, paint);
  }

  /// Dessine une petite étoile à 4 branches.
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    if (radius < 0.5) return;
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.3);
    path.lineTo(center.dx + radius, center.dy);
    path.lineTo(center.dx + radius * 0.3, center.dy + radius * 0.3);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius * 0.3, center.dy + radius * 0.3);
    path.lineTo(center.dx - radius, center.dy);
    path.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
