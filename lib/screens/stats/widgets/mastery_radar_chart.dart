// lib/screens/stats/widgets/mastery_radar_chart.dart
// Radar chart (fl_chart) des compétences d'une matière.
//
// - 6-8 axes (chapitres principaux de la matière).
// - Chaque axe = un chapitre, valeur = P(L) moyen du chapitre (0-100%).
// - Surface colorée en vert Togo semi-transparent (AppColors.primary.withOpacity(0.3)).
// - Bordure : vert Togo pleine.
// - Points : vert foncé aux sommets.
// - Titres axes : noms courts des chapitres.
//
// Si la matière a plus de 8 compétences, on agrège par chapitre (moyenne
// pondérée par nb questions) puis on garde les 8 premiers. Si moins de 3,
// on affiche un état vide (radar non pertinent).

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../services/subject_stats_service.dart';

class MasteryRadarChart extends StatelessWidget {
  final List<CompetenceStats> competences;
  final double size; // diamètre utile (largeur / hauteur du widget)

  const MasteryRadarChart({
    super.key,
    required this.competences,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    // ─── Agréger par chapitre (au cas où plusieurs compétences partagent
    // un même libellé de chapitre — peu probable mais défensif).
    final byChapitre = <String, List<CompetenceStats>>{};
    for (final c in competences) {
      byChapitre.putIfAbsent(c.chapitre, () => []).add(c);
    }
    final chapitres = byChapitre.entries.toList()
      ..sort((a, b) {
        // Tri par P(L) moyen décroissant (les plus forts d'abord)
        final aAvg = _avg(a.value);
        final bAvg = _avg(b.value);
        return bAvg.compareTo(aAvg);
      });

    // Limiter à 8 axes maximum
    final chapitresAffiches = chapitres.take(8).toList();
    final nbAxes = chapitresAffiches.length;

    if (nbAxes < 3) {
      return _buildEmptyState();
    }

    final valeurs = chapitresAffiches
        .map((e) => _avg(e.value) * 100)
        .toList(); // 0..100

    return SizedBox(
      width: double.infinity,
      height: size,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.primary.withOpacity(0.30),
              borderColor: AppColors.primary,
              borderWidth: 2.5,
              entryRadius: 4,
              dataEntries: valeurs
                  .map((v) => RadarEntry(value: v.clamp(0.0, 100.0)))
                  .toList(),
            ),
          ],
          radarBackgroundColor: AppColors.primarySurface.withOpacity(0.18),
          radarBorderData: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
          tickBorderData: BorderSide(
            color: AppColors.divider.withOpacity(0.6),
            width: 0.8,
          ),
          gridBorderData: BorderSide(
            color: AppColors.divider.withOpacity(0.6),
            width: 0.8,
          ),
          tickCount: 4,
          ticksTextStyle: AppTextStyles.bodySmall.copyWith(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
          titleTextStyle: AppTextStyles.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titlePositionPercentageOffset: 0.18,
          getTitle: (index, angle) {
            final libelle = _libelleCourt(chapitresAffiches[index].key);
            return RadarChartTitle(text: libelle);
          },
          // Tactile désactivé par défaut (lecture seule — pas besoin
          // d'interactions tactiles sur le radar, les détails sont dans
          // la liste des CompetenceCard juste en dessous).
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  double _avg(List<CompetenceStats> list) {
    if (list.isEmpty) return 0;
    final sum = list.fold<double>(0.0, (a, c) => a + c.pL);
    return sum / list.length;
  }

  /// Raccourcit le nom d'un chapitre pour qu'il tienne sur l'axe du radar.
  /// On garde au max 16 caractères + "...".
  String _libelleCourt(String chapitre) {
    if (chapitre.length <= 16) return chapitre;
    return '${chapitre.substring(0, 15)}...';
  }

  Widget _buildEmptyState() {
    return SizedBox(
      width: double.infinity,
      height: size,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radar,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 10),
            Text(
              'Pas assez de données pour afficher le radar.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Révise au moins 3 chapitres différents.',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
