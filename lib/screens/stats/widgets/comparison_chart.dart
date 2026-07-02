// lib/screens/stats/widgets/comparison_chart.dart
// Comparaison vs classe (anonymisée) — 3 barres horizontales.
//
// - "Top 10%" : moyenne P(L) du top 10% des élèves (mock 85%).
// - "Moyenne classe" : moyenne tous élèves (mock 58%).
// - "Toi" : ta moyenne P(L) (réelle).
// Couleurs : or / gris / vert Togo.
// Valeurs en % à droite. Note sous le graphique :
// "Comparaison basée sur X élèves anonymes" (mock 247 pour démo).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../services/subject_stats_service.dart';

class ComparisonChart extends StatelessWidget {
  final ClassroomComparison comparison;

  const ComparisonChart({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBar(
          label: 'Top 10%',
          valeur: comparison.top10Pourcent,
          couleur: const Color(0xFFD4A017), // or
          icone: Icons.emoji_events,
        ),
        const SizedBox(height: 12),
        _buildBar(
          label: 'Moyenne classe',
          valeur: comparison.moyenneClasse,
          couleur: AppColors.textSecondary,
          icone: Icons.groups,
        ),
        const SizedBox(height: 12),
        _buildBar(
          label: 'Toi',
          valeur: comparison.toi,
          couleur: AppColors.primary,
          icone: Icons.person,
          gras: true,
        ),
        const SizedBox(height: 14),
        // ─── Note ────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.info_outline,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Comparaison basée sur ${comparison.nombreElevesAnonymes} '
                'élèves anonymes (données de démo).',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBar({
    required String label,
    required double valeur, // 0..1
    required Color couleur,
    required IconData icone,
    bool gras = false,
  }) {
    final pourcent = (valeur * 100).clamp(0, 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 14, color: couleur),
            const SizedBox(width: 6),
            Text(
              label,
              style: (gras ? AppTextStyles.h3 : AppTextStyles.body).copyWith(
                fontSize: 14,
                fontWeight: gras ? FontWeight.w700 : FontWeight.w500,
                color: gras ? couleur : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$pourcent%',
              style: AppTextStyles.h3.copyWith(
                fontSize: 16,
                color: couleur,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ─── Barre horizontale ────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: valeur.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: couleur.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(couleur),
          ),
        ),
      ],
    );
  }
}
