// lib/screens/stats/widgets/recommendation_card.dart
// Carte de recommandation auto-générée.
//
// 3 variantes selon RecommendationType :
//   - prioriteFaiblesse : rouge (ta plus grande faiblesse)
//   - streak            : orange (tu n'as pas révisé X depuis N jours)
//   - quickWin          : bleu (tu es à 78%, encore 2-3 questions)
//
// Icône contextuelle + titre + description + bouton "Appliquer".
// Le bouton "Appliquer" navigue vers /revision/<matiereCible>.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../services/subject_stats_service.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final String userId; // pour navigation éventuelle

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _palettePourType(recommendation.type);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Icône contextuelle ──────────────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                palette.icon,
                color: palette.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // ─── Texte ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.titre,
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 15,
                      color: palette.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ─── Bouton "Appliquer" ────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _appliquer(context),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Appliquer'),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.primary,
                        backgroundColor: palette.primary.withOpacity(0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Navigation "Appliquer" ──────────────────────────────────

  void _appliquer(BuildContext context) {
    // On redirige vers la révision de la matière ciblée.
    // (Une amélioration future : passer la competenceId en query param pour
    // pré-filtrer la session de révision sur ce chapitre précis.)
    context.go(
      '/revision/${Uri.encodeComponent(recommendation.matiereCible)}',
    );
  }

  // ─── Palette par type ────────────────────────────────────────

  _PaletteReco _palettePourType(RecommendationType type) {
    switch (type) {
      case RecommendationType.prioriteFaiblesse:
        return _PaletteReco(
          primary: AppColors.error,
          surface: const Color(0xFFFDECEC), // rouge très clair
          icon: Icons.priority_high,
        );
      case RecommendationType.streak:
        return _PaletteReco(
          primary: AppColors.accent,
          surface: AppColors.accentSurface,
          icon: Icons.schedule,
        );
      case RecommendationType.quickWin:
        return _PaletteReco(
          primary: AppColors.info,
          surface: const Color(0xFFE3F0FC), // bleu très clair
          icon: Icons.lightbulb_outline,
        );
    }
  }
}

/// Palette de couleurs associée à un type de recommandation.
class _PaletteReco {
  final Color primary;
  final Color surface;
  final IconData icon;

  const _PaletteReco({
    required this.primary,
    required this.surface,
    required this.icon,
  });
}
