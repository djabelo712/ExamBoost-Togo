// lib/screens/score/widgets/score_gauge.dart
// Jauge circulaire géante affichant le score prédit sur 20.
//
// Affichage :
//   - Anneau circulaire coloré (rouge < 8, orange 8-10, jaune 10-12,
//     vert clair 12-14, vert 14+)
//   - Score au centre (ex: "12.5 / 20")
//   - Badge "Admissible" si score >= 10
//   - Animations : remplissage progressif de l'anneau

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../models/score_prediction.dart';
import '../../../theme/app_theme.dart';

/// Jauge circulaire géante affichant le score prédit.
class ScoreGauge extends StatefulWidget {
  final ScorePrediction prediction;
  final double size;

  /// Si true, anime le remplissage de l'anneau au montage.
  final bool animate;

  const ScoreGauge({
    super.key,
    required this.prediction,
    this.size = 220,
    this.animate = true,
  });

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    // Score normalisé 0-1 (sur 20)
    final target = (widget.prediction.scoreGlobal / 20.0).clamp(0.0, 1.0);
    _progress = Tween<double>(begin: 0.0, end: target)
        .animate(CurvedAnimation(
            parent: _controller, curve: Curves.easeOutCubic));
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.prediction.scoreGlobal;
    final color = _scoreColor(score);
    final isPassing = widget.prediction.isPassing;

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final currentScore = _progress.value * 20.0;
        return CircularPercentIndicator(
          radius: widget.size / 2,
          lineWidth: 16,
          percent: _progress.value,
          animation: false, // gérée par AnimationController
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: color,
          backgroundColor: color.withOpacity(0.12),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentScore.toStringAsFixed(1),
                style: AppTextStyles.h1.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '/ 20',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildPassingBadge(isPassing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassingBadge(bool isPassing) {
    final color = isPassing ? AppColors.success : AppColors.error;
    final icon = isPassing ? Icons.check_circle : Icons.warning;
    final label = isPassing ? 'Admissible' : 'Sous la moyenne';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Couleur de l'anneau en fonction du score.
  ///   < 8     : rouge (préoccupant)
  ///   8-10    : orange (sous moyenne)
  ///   10-12   : jaune (moyenne fragile)
  ///   12-14   : vert clair (bon)
  ///   >= 14   : vert (très bon)
  Color _scoreColor(double score) {
    if (score < 8) return AppColors.error;
    if (score < 10) return AppColors.warning;
    if (score < 12) return AppColors.accent;
    if (score < 14) return AppColors.primaryLight;
    return AppColors.success;
  }
}
