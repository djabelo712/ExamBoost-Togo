// lib/screens/stats/widgets/competence_card.dart
// Carte d'affichage d'une compétence dans la liste (SubjectDetailScreen section 2).
//
// Affiche :
//   - Nom du chapitre (en gras)
//   - P(L) en grand (couleur sémantique)
//   - Badge statut (Maîtrisée / En cours / Fragile / Non évaluée)
//   - Barre de progression horizontale
//   - X questions répondues / taux de réussite
//   - Dernière révision ("il y a 3 jours")
//   - Temps moyen par question
//   - Bouton "Réviser" -> /revision/<matiere>
//   - Tap sur la carte -> /stats/competence/<competenceId>

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../theme/app_theme.dart';
import '../services/subject_stats_service.dart';

class CompetenceCard extends StatelessWidget {
  final CompetenceStats stats;
  final String userId; // pour navigation éventuelle

  const CompetenceCard({
    super.key,
    required this.stats,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final couleurStatut = _couleurStatut(stats.statut);
    final couleurPL = _couleurPL(stats.pL);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(
            '/stats/competence/${Uri.encodeComponent(stats.competenceId)}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Ligne 1 : chapitre + badge statut ─────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        stats.chapitre,
                        style: AppTextStyles.h3.copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatutBadge(stats.statut, couleurStatut),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Ligne 2 : P(L) grand + barre progression ──────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stats.pLPourcent}%',
                            style: AppTextStyles.h2.copyWith(
                              color: couleurPL,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'P(L)',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearPercentIndicator(
                            padding: EdgeInsets.zero,
                            lineHeight: 10,
                            percent: stats.pL.clamp(0.0, 1.0),
                            progressColor: couleurPL,
                            backgroundColor: couleurPL.withOpacity(0.12),
                            barRadius: const Radius.circular(6),
                            animation: true,
                            animationDuration: 700,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Taux de réussite : ${stats.tauxReussitePourcent}%',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ─── Ligne 3 : métadonnées en chips ───────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMetaChip(
                      icon: Icons.question_answer_outlined,
                      label:
                          '${stats.questionsRepondues}/${stats.questionsTotal} questions',
                    ),
                    _buildMetaChip(
                      icon: Icons.timer_outlined,
                      label:
                          '${stats.tempsMoyenSecondes}s en moyenne',
                    ),
                    _buildMetaChip(
                      icon: Icons.history,
                      label: _formatDerniereRevision(stats.derniereRevision),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Ligne 4 : action Réviser ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go(
                        '/revision/${Uri.encodeComponent(stats.matiere)}',
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Réviser'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sous-composants ──────────────────────────────────────────

  Widget _buildStatutBadge(String statut, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3), width: 1),
      ),
      child: Text(
        statut,
        style: AppTextStyles.label.copyWith(
          color: couleur,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── Helpers couleur ──────────────────────────────────────────

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'Maîtrisée':
        return AppColors.success;
      case 'En cours':
        return AppColors.warning;
      case 'Fragile':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _couleurPL(double pL) {
    if (pL >= 0.85) return AppColors.success;
    if (pL >= 0.5) return AppColors.warning;
    if (pL > 0.0) return AppColors.error;
    return AppColors.textDisabled;
  }

  String _formatDerniereRevision(DateTime? date) {
    if (date == null) return 'Jamais révisé';
    final maintenant = DateTime.now();
    final diff = maintenant.difference(date);
    if (diff.inHours < 1) return 'Révisé à l\'instant';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    final jours = diff.inDays;
    if (jours == 0) return 'Aujourd\'hui';
    if (jours == 1) return 'Hier';
    if (jours < 7) return 'Il y a $jours jours';
    if (jours < 30) return 'Il y a ${(jours / 7).floor()} sem.';
    if (jours < 365) return 'Il y a ${(jours / 30).floor()} mois';
    return 'Il y a plus d\'un an';
  }
}
