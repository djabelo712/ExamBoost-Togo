// lib/screens/orientation/widgets/skill_radar_orientation.dart
// Radar chart (fl_chart) des 6 axes d'orientation de l'élève.
//
// Affiche sur 6 axes (Scientifique, Littéraire, Créatif, Social, Business,
// Leadership) les scores de l'élève (0-100). Utile pour visualiser le profil
// et le comparer visuellement avec la "forme" des filières recommandées.
//
// Si [filiereOverlay] est fourni, on superpose une 2e série (ligne pointillée
// orange) représentant le vecteur de poids de la filière (normalisé 0-100).
// Permet à l'élève de voir la "forme" attendue par la filière.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/filiere.dart';
import '../models/orientation_profile.dart';

class SkillRadarOrientation extends StatelessWidget {
  /// Profil de l'élève (doit contenir les 6 axes).
  final OrientationProfile profile;

  /// Diamètre utile (largeur = hauteur) du radar.
  final double size;

  /// Filière optionnelle à superposer (overlay en orange pointillé).
  final Filiere? filiereOverlay;

  const SkillRadarOrientation({
    super.key,
    required this.profile,
    this.size = 280,
    this.filiereOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final valeurs = OrientationAxes.all
        .map((a) => (profile.axes[a] ?? 0.0) * 100)
        .toList(growable: false);

    // Si l'overlay est fourni, on normalise ses poids sur 0-100
    // (le poids max devient 100).
    List<double>? overlay;
    if (filiereOverlay != null) {
      final raw = OrientationAxes.all
          .map((a) => filiereOverlay!.poidsAxes[a] ?? 0.0)
          .toList();
      final maxP = raw.reduce((a, b) => a > b ? a : b);
      overlay = maxP > 0
          ? raw.map((v) => (v / maxP) * 100).toList()
          : raw;
    }

    final dataSets = <RadarDataSet>[
      RadarDataSet(
        fillColor: AppColors.primary.withOpacity(0.30),
        borderColor: AppColors.primary,
        borderWidth: 2.5,
        entryRadius: 4,
        dataEntries: valeurs
            .map((v) => RadarEntry(value: v.clamp(0.0, 100.0)))
            .toList(),
      ),
      if (overlay != null)
        RadarDataSet(
          fillColor: AppColors.accent.withOpacity(0.10),
          borderColor: AppColors.accent,
          borderWidth: 2,
          entryRadius: 3,
          dataEntries: overlay
              .map((v) => RadarEntry(value: v.clamp(0.0, 100.0)))
              .toList(),
        ),
    ];

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: size,
          child: RadarChart(
            RadarChartData(
              dataSets: dataSets,
              radarBackgroundColor: AppColors.primarySurface.withOpacity(0.18),
              radarBorderData: BorderSide(
                color: AppColors.divider,
                width: 1,
              ),
              tickBorderData: BorderSide(
                color: AppColors.divider,
                width: 1,
              ),
              gridBorderData: BorderSide(
                color: AppColors.divider.withOpacity(0.5),
                width: 0.8,
              ),
              tickCount: 4,
              ticksTextStyle: const TextStyle(
                color: Colors.transparent,
                fontSize: 0,
              ),
              titleTextStyle: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              titlePositionPercentageOffset: 0.18,
              getTitle: (idx, angle) {
                final axe = OrientationAxes.all[idx];
                return RadarChartTitle(
                  text: OrientationAxes.labels[axe] ?? axe,
                  angle: 0,
                );
              },
            ),
          ),
        ),
        if (filiereOverlay != null) ...[
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(color: AppColors.primary, label: 'Ton profil'),
        const SizedBox(width: 16),
        _legendDot(
          color: AppColors.accent,
          label: 'Profil ${filiereOverlay!.nomCourt}',
          dashed: true,
        ),
      ],
    );
  }

  Widget _legendDot({
    required Color color,
    required String label,
    bool dashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.30),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
