// lib/screens/level/widgets/level_up_dialog.dart
// Dialog plein écran affiché quand l'élève monte de niveau.
//
// Animation (≈ 2,2 s) :
//   1. Fond noir semi-transparent qui fade in
//   2. Particules dorées qui explosent depuis le centre (CustomPaint)
//   3. Texte "NIVEAU SUPÉRIEUR !" qui fade in
//   4. Numéro de niveau qui count up de previousLevel → newLevel
//   5. Barre de progression vers le niveau suivant qui se remplit
//   6. Carte récompense (si une récompense a été débloquée à ce niveau)
//   7. Bouton "Continuer" qui apparaît
//
// À appeler après [LevelService.addXp] si [XpGainResult.leveledUp] est vrai :
//   final result = await levelService.addXpQuestionCorrecte(userId);
//   XpGainAnimation.show(context, amount: result.amount, source: result.source);
//   if (result.leveledUp) {
//     await LevelUpDialog.show(context, result: result);
//   }

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/level_reward.dart';
import '../../../services/level_service.dart';
import '../../../theme/app_theme.dart';
import 'level_progress_bar.dart';
import 'reward_unlock_card.dart';

class LevelUpDialog extends StatefulWidget {
  const LevelUpDialog({
    super.key,
    required this.result,
    this.onContinue,
  });

  /// Résultat du gain d'XP qui a déclenché la montée de niveau.
  final XpGainResult result;

  /// Callback optionnel appelé quand l'élève tape "Continuer".
  /// Si null, le bouton se contente de fermer le dialog.
  final VoidCallback? onContinue;

  /// Ouvre le dialog en plein écran.
  static Future<void> show(
    BuildContext context, {
    required XpGainResult result,
    VoidCallback? onContinue,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => LevelUpDialog(result: result, onContinue: onContinue),
    );
  }

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with TickerProviderStateMixin {
  // ─── Contrôleurs ──────────────────────────────────────────────
  late final AnimationController _controller;
  late final AnimationController _glowController;

  // ─── Animations composites ────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _particles;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _levelScale;
  late final Animation<double> _levelFade;
  late final Animation<int> _levelCount;
  late final Animation<double> _progressFade;
  late final Animation<double> _rewardFade;
  late final Animation<Offset> _rewardSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<double> _glowPulse;

  // Couleur du nouveau niveau (pour le glow + la barre).
  late final Color _levelColor;

  @override
  void initState() {
    super.initState();

    _levelColor = _colorForLevel(widget.result.newLevel);

    // ─── Contrôleur principal (2,2 s) ──────────────────────────
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // ─── Contrôleur glow (boucle infinie, 1,2 s) ───────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    const easeOutBack = Curves.easeOutBack;
    const easeOut = Curves.easeOut;
    const easeIn = Curves.easeIn;

    // Fond : 0 → 0,3 s
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.15, curve: easeOut),
      ),
    );

    // Particules : 0,2 → 1,2 s (explosion + fade out)
    _particles = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: easeIn),
      ),
    );

    // "NIVEAU SUPÉRIEUR !" : 0,4 → 0,9 s
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: easeOut),
      ),
    );

    // Numéro de niveau : scale + count up : 0,5 → 1,3 s
    _levelScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: easeOutBack),
      ),
    );
    _levelFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: easeOut),
      ),
    );
    _levelCount = IntTween(
      begin: widget.result.previousLevel,
      end: widget.result.newLevel,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.2, curve: easeOut),
      ),
    );

    // Barre de progression : 1,2 → 1,6 s
    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(1.2, 1.6, curve: easeOut),
      ),
    );

    // Récompense (si applicable) : 1,4 → 1,9 s
    _rewardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(1.4, 1.9, curve: easeOut),
      ),
    );
    _rewardSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(1.4, 1.9, curve: easeOut),
      ),
    );

    // Bouton "Continuer" : 1,7 → 2,1 s
    _buttonsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(1.7, 2.1, curve: easeOut),
      ),
    );

    // Glow pulse (boucle)
    _glowPulse =
        Tween<double>(begin: 0.4, end: 0.9).animate(_glowController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
    widget.onContinue?.call();
  }

  // ─── Couleur associée à un niveau (identique à LevelProgressBar) ──
  static Color _colorForLevel(int level) {
    if (level <= 10) return AppColors.primary;
    if (level <= 25) return AppColors.accent;
    if (level <= 40) return const Color(0xFF7B1FA2);
    return const Color(0xFFFFB300);
  }

  @override
  Widget build(BuildContext context) {
    final hasReward = widget.result.newlyUnlockedRewards.isNotEmpty;
    final reward = hasReward
        ? widget.result.newlyUnlockedRewards.first
        : null;
    final isMaxLevel = widget.result.newLevel >= LevelService.maxLevel;

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

            // ─── Particules ────────────────────────────────────────
            if (_particles.value < 1.0)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlePainter(
                    progress: _particles.value,
                    color: _levelColor,
                  ),
                ),
              ),

            // ─── Contenu central ──────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),

                      // "NIVEAU SUPÉRIEUR !"
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            isMaxLevel
                                ? 'NIVEAU MAXIMUM !'
                                : 'NIVEAU SUPÉRIEUR !',
                            style: TextStyle(
                              color: _levelColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: _levelColor.withOpacity(0.6),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Numéro de niveau géant (count up + scale + glow)
                      _buildLevelNumber(),

                      const SizedBox(height: 8),

                      // Sous-titre "Tu progresses !"
                      FadeTransition(
                        opacity: _titleFade,
                        child: const Text(
                          'Continue comme ça !',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Barre de progression vers le niveau suivant
                      FadeTransition(
                        opacity: _progressFade,
                        child: _buildProgressBar(),
                      ),

                      // Récompense (si applicable)
                      if (hasReward && reward != null) ...[
                        const SizedBox(height: 28),
                        SlideTransition(
                          position: _rewardSlide,
                          child: FadeTransition(
                            opacity: _rewardFade,
                            child: _buildRewardSection(reward),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Bouton "Continuer"
                      FadeTransition(
                        opacity: _buttonsFade,
                        child: ElevatedButton.icon(
                          onPressed: _close,
                          icon: const Icon(Icons.arrow_forward_rounded,
                              size: 18),
                          label: const Text('Continuer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _levelColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Numéro de niveau géant (count up + glow pulsé) ────────────

  Widget _buildLevelNumber() {
    final scale =
        _levelScale.value == 0.0 ? 0.001 : _levelScale.value;
    return Transform.scale(
      scale: scale,
      child: FadeTransition(
        opacity: _levelFade,
        child: AnimatedBuilder(
          animation: _glowPulse,
          builder: (context, _) {
            return Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _levelColor.withOpacity(0.9),
                    _levelColor,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _levelColor.withOpacity(_glowPulse.value),
                    blurRadius: 32 + 16 * _glowPulse.value,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo interne
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                  ),
                  // Numéro
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'NIVEAU',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: _levelCount,
                        builder: (context, _) {
                          return Text(
                            '${_levelCount.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          );
                        },
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

  // ─── Barre de progression (réutilisée depuis LevelProgressBar) ──

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: LevelProgressBar(
        cumulativeXp: widget.result.newTotalXp,
        showLevelNumbers: false,
      ),
    );
  }

  // ─── Section récompense ─────────────────────────────────────────

  Widget _buildRewardSection(LevelReward reward) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard,
                color: reward.color, size: 18),
            const SizedBox(width: 8),
            Text(
              'RÉCOMPENSE DÉBLOQUÉE',
              style: TextStyle(
                color: reward.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RewardUnlockCard(
          reward: reward,
          unlocked: true,
          showLevelRequirement: false,
        ),
      ],
    );
  }
}

// ─── CustomPainter : explosion de particules ───────────────────────

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
    final maxRadius = math.min(size.width, size.height) * 0.45;

    const particleCount = 28;
    final paint = Paint()..style = PaintingStyle.fill;

    // Couleurs alternées : couleur niveau + blanc + doré.
    final colors = [
      color,
      Colors.white,
      const Color(0xFFFFB300),
      color.withOpacity(0.7),
    ];

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = progress * maxRadius;
      final dx = center.dx + math.cos(angle) * distance;
      final dy = center.dy + math.sin(angle) * distance;

      final baseSize = 4.0 + (i % 3) * 2.0;
      final sizeFactor = (1 - progress).clamp(0.0, 1.0);
      final radius = baseSize * sizeFactor;

      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = colors[i % colors.length].withOpacity(opacity * 0.9);

      if (i % 4 == 0) {
        _drawStar(canvas, Offset(dx, dy), radius, paint);
      } else {
        canvas.drawCircle(Offset(dx, dy), radius, paint);
      }
    }

    // Anneau de choc
    final ringRadius = progress * maxRadius * 1.1;
    final ringOpacity = (1 - progress).clamp(0.0, 1.0) * 0.6;
    paint
      ..color = color.withOpacity(ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - progress).clamp(0.0, 1.0);
    canvas.drawCircle(center, ringRadius, paint);
  }

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
