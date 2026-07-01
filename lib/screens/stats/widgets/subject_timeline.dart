// lib/screens/stats/widgets/subject_timeline.dart
// Timeline d'activité matière (30 derniers jours), type "GitHub-like".
//
// - CustomPaint avec 30 cases (6 rows × 5 cols = 30 cases).
// - Chaque case = 1 jour, couleur selon nb questions répondues :
//     gris = 0
//     vert clair = 1-5
//     vert = 6-15
//     vert foncé = 16+
// - Tooltip au hover (Web/desktop) ou tap (mobile).
// - Légende "Moins" -> "Plus" en bas.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../services/subject_stats_service.dart';

class SubjectTimeline extends StatelessWidget {
  final List<DayActivity> activities; // 30 jours (chronologique ascendant)
  final double cellSize;
  final double spacing;

  const SubjectTimeline({
    super.key,
    required this.activities,
    this.cellSize = 20,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    final days = activities.length;
    // Layout : 6 rows × 5 cols = 30 cases (lues en colonnes premièrement).
    const cols = 5;
    final rows = (days / cols).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Grille ──────────────────────────────────────────────
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (int i = 0; i < days; i++)
              _buildCell(context, activities[i]),
          ],
        ),
        const SizedBox(height: 14),
        // ─── Légende "Moins -> Plus" ─────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Moins',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
            const SizedBox(width: 6),
            for (int i = 0; i < 4; i++) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _couleurPourNiveau(_niveauPourIndexLegend(i)),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              'Plus',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Construction d'une case ─────────────────────────────────

  Widget _buildCell(BuildContext context, DayActivity day) {
    final niveau = _niveauPourCompteur(day.questionsRepondues);
    final couleur = _couleurPourNiveau(niveau);
    final label = _labelTooltip(day);

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
      ),
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: couleur,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  // ─── Helpers couleur / niveau ────────────────────────────────

  /// 4 niveaux : 0 (rien), 1 (1-5), 2 (6-15), 3 (16+).
  int _niveauPourCompteur(int n) {
    if (n == 0) return 0;
    if (n <= 5) return 1;
    if (n <= 15) return 2;
    return 3;
  }

  /// Pour la légende (de 0 à 3).
  int _niveauPourIndexLegend(int i) => i;

  Color _couleurPourNiveau(int niveau) {
    switch (niveau) {
      case 0:
        return AppColors.surfaceVariant;
      case 1:
        return AppColors.primaryLight.withOpacity(0.55);
      case 2:
        return AppColors.primary;
      case 3:
        return AppColors.primaryDark;
      default:
        return AppColors.surfaceVariant;
    }
  }

  /// Texte du tooltip : "12 juin : 8 questions répondues".
  String _labelTooltip(DayActivity day) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    final m = months[day.date.month - 1];
    if (day.questionsRepondues == 0) {
      return '${day.date.day} $m : aucune question';
    }
    return '${day.date.day} $m : ${day.questionsRepondues} question'
        '${day.questionsRepondues > 1 ? "s" : ""} répondue'
        '${day.questionsRepondues > 1 ? "s" : ""}';
  }
}
