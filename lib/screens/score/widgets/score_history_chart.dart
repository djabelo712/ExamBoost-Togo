// lib/screens/score/widgets/score_history_chart.dart
// LineChart fl_chart affichant l'évolution du score prédit sur 3 mois.
//
// Affichage :
//   - Axe X : dates (mois, environ 1 point par semaine max)
//   - Axe Y : score /20 (0-20)
//   - Points à chaque prédiction
//   - Ligne pointillée horizontale à 10/20 (seuil d'admissibilité)
//   - Aire semi-transparente sous la courbe (effet visuel)
//   - Si pas d'historique : message "Pas encore d'historique"

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/score_prediction.dart';
import '../../../theme/app_theme.dart';

/// LineChart d'évolution du score prédit sur 3 mois.
class ScoreHistoryChart extends StatelessWidget {
  final List<ScorePrediction> history;

  const ScoreHistoryChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return _buildEmptyState();
    }
    return _buildChart();
  }

  // ─── Etat vide ───────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.show_chart,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'Pas encore d\'historique',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reviens dans 2 semaines pour voir ta progression '
              'sur le graphique.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── LineChart fl_chart ──────────────────────────────────────────
  Widget _buildChart() {
    final spots = _buildSpots();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Evolution sur 3 mois',
                  style: AppTextStyles.h3.copyWith(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Score BEPC/BAC predit dans le temps',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.divider.withOpacity(0.6),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _bottomInterval(),
                        getTitlesWidget: (value, meta) =>
                            _bottomTitleWidget(value),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            value.toInt().toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 20,
                  lineBarsData: [
                    // Ligne principale + aire semi-transparente dessous
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      preventCurveOverShooting: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.10),
                        applyCutOffY: false,
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primaryDark,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.spotIndex;
                          if (index < 0 ||
                              index >= history.length) {
                            return null;
                          }
                          final p = history[index];
                          return LineTooltipItem(
                            '${p.scoreGlobal.toStringAsFixed(1)}/20\n'
                            '${_formatDate(p.predictedAt)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      // Ligne pointillée de moyenne (10/20)
                      HorizontalLine(
                        y: 10,
                        color: AppColors.warning.withOpacity(0.6),
                        strokeWidth: 1.5,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(
                              right: 8, bottom: 4),
                          style: AppTextStyles.label.copyWith(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                          labelResolver: (_) => 'Moyenne 10',
                        ),
                      ),
                    ],
                  ),
                ),
                duration: const Duration(milliseconds: 600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Construction des points (X = index temps, Y = score) ────────
  List<FlSpot> _buildSpots() {
    // On utilise l'index relatif pour éviter les gaps trop larges
    // entre deux prédictions éloignées dans le temps.
    // L'axe X est "virtuel" (0..N-1), on affiche les dates en bas.
    return history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.scoreGlobal);
    }).toList();
  }

  // ─── Titres axe X (dates) ────────────────────────────────────────
  double _bottomInterval() {
    final n = history.length;
    if (n <= 4) return 1;
    if (n <= 8) return 2;
    return (n / 4).ceilToDouble();
  }

  Widget _bottomTitleWidget(double value) {
    final index = value.toInt();
    if (index < 0 || index >= history.length) {
      return const SizedBox.shrink();
    }
    final date = history[index].predictedAt;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        _formatShortDate(date),
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'jan', 'fev', 'mar', 'avr', 'mai', 'juin',
      'juil', 'aout', 'sep', 'oct', 'nov', 'dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
