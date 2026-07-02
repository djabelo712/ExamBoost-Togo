// lib/widgets/voice_answer_indicator.dart
// Indicateur visuel d'écoute : vague animée (style assistant vocal).
//
// Affiche plusieurs barres verticales qui montent et descendent avec des
// phases décalées, comme les assistants vocaux (Google Assistant, Siri).
// La couleur s'adapte (rouge pour signaler que le micro capte).
//
// Utilisation :
//   VoiceAnswerIndicator(color: AppColors.error, height: 36)
//
// Le widget s'anime tant qu'il est dans le widget tree. Pour l'arrêter,
// le parent doit le retirer (ConditionalBuilder / if isListening).

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Vague animée indiquant que le micro écoute.
///
/// 5 barres verticales animées avec des phases sinusoïdales décalées.
/// Hauteur variable (defaut 36 dp). Largeur auto (environ 60 dp).
class VoiceAnswerIndicator extends StatefulWidget {
  const VoiceAnswerIndicator({
    super.key,
    this.color = const Color(0xFFC62828),
    this.height = 36.0,
    this.barCount = 5,
  });

  /// Couleur des barres (rouge error par défaut pour signaler l'écoute).
  final Color color;

  /// Hauteur max des barres (en dp).
  final double height;

  /// Nombre de barres (5 par défaut, comme Google Assistant).
  final int barCount;

  @override
  State<VoiceAnswerIndicator> createState() => _VoiceAnswerIndicatorState();
}

class _VoiceAnswerIndicatorState extends State<VoiceAnswerIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = 4.0;
    final barSpacing = 6.0;
    final totalWidth = widget.barCount * barWidth +
        (widget.barCount - 1) * barSpacing;

    return SizedBox(
      width: totalWidth,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(totalWidth, widget.height),
            painter: _WaveformPainter(
              progress: _controller.value,
              color: widget.color,
              barCount: widget.barCount,
              barWidth: barWidth,
              barSpacing: barSpacing,
              maxHeight: widget.height,
            ),
          );
        },
      ),
    );
  }
}

/// Painter qui dessine les barres de la vague animée.
///
/// Chaque barre a une phase décalée et une hauteur calculée par :
///   h = minH + (maxH - minH) * (0.5 + 0.5 * sin(2*pi*(progress + i/4)))
///
/// Le décalage i/barCount fait que les barres montent et descendent en
/// cascade, donnant l'effet "vague" caractéristique.
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int barCount;
  final double barWidth;
  final double barSpacing;
  final double maxHeight;

  _WaveformPainter({
    required this.progress,
    required this.color,
    required this.barCount,
    required this.barWidth,
    required this.barSpacing,
    required this.maxHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final minH = maxHeight * 0.20; // 20% hauteur min (toujours visible)
    final maxH = maxHeight;

    for (int i = 0; i < barCount; i++) {
      // Phase décalée : chaque barre a un offset différent
      final phase = i / barCount;
      // Hauteur sinusoïdale : 0.5 + 0.5*sin(2π(t+phase)) → [0, 1]
      final wave = 0.5 + 0.5 * math.sin(2 * math.pi * (progress + phase));
      final h = minH + (maxH - minH) * wave;

      // Position x de la barre
      final x = i * (barWidth + barSpacing);
      // Position y (centrée verticalement)
      final y = (maxHeight - h) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.barCount != barCount ||
        oldDelegate.maxHeight != maxHeight;
  }
}
