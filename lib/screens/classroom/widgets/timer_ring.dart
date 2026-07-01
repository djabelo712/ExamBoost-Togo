// lib/screens/classroom/widgets/timer_ring.dart
// Anneau timer circulaire qui se vide pour le decompte temps reel.
//
// Comportement :
//   - Anneau (ProgressRing) qui se vide de 100% -> 0%
//   - Temps restant en secondes au centre (gros chiffre)
//   - Couleur qui change selon le temps restant :
//       vert   > 20s
//       jaune  10-20s
//       orange 5-10s
//       rouge  < 5s
//   - Vibration + bip aux 5 dernieres secondes (callback onLastSeconds)
//
// Usage :
//   TimerRing(
//     timeRemaining: service.timeRemaining,
//     timeLimit: service.timeLimit,
//     size: 120,
//   )

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

class TimerRing extends StatefulWidget {
  /// Temps restant en secondes.
  final int timeRemaining;

  /// Temps total de la question (pour le ratio).
  final int timeLimit;

  /// Diametre de l'anneau.
  final double size;

  /// Epaisseur du trait.
  final double strokeWidth;

  /// Appele a chaque seconde des 5 dernieres (vibration + bip).
  final VoidCallback? onTickLastSeconds;

  /// Si true, desactive la vibration (mode silencieux).
  final bool silent;

  const TimerRing({
    super.key,
    required this.timeRemaining,
    required this.timeLimit,
    this.size = 120,
    this.strokeWidth = 10,
    this.onTickLastSeconds,
    this.silent = false,
  });

  @override
  State<TimerRing> createState() => _TimerRingState();
}

class _TimerRingState extends State<TimerRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _lastShown = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant TimerRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detection du passage dans les 5 dernieres secondes
    if (widget.timeRemaining != oldWidget.timeRemaining &&
        widget.timeRemaining != _lastShown) {
      _lastShown = widget.timeRemaining;
      if (widget.timeRemaining <= 5 && widget.timeRemaining > 0) {
        _pulseController.forward(from: 0);
        if (!widget.silent) {
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.click);
        }
        widget.onTickLastSeconds?.call();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _colorFor(int seconds) {
    if (seconds > 20) return AppColors.success;
    if (seconds > 10) return AppColors.warning;
    if (seconds > 5) return AppColors.accent;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.timeLimit <= 0
        ? 0.0
        : (widget.timeRemaining / widget.timeLimit).clamp(0.0, 1.0);
    final color = _colorFor(widget.timeRemaining);
    final isUrgent = widget.timeRemaining <= 5 && widget.timeRemaining > 0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isUrgent ? 1.0 + 0.05 * _pulseController.value : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anneau de fond
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: widget.strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color.withOpacity(0.15),
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
            // Anneau de progression (qui se vide)
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: ratio,
                strokeWidth: widget.strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: Colors.transparent,
                strokeCap: StrokeCap.round,
              ),
            ),
            // Temps restant au centre
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.timeRemaining}',
                  style: TextStyle(
                    fontSize: widget.size * 0.32,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: widget.size * 0.04),
                Text(
                  'secondes',
                  style: AppTextStyles.label.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
