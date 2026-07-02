// lib/screens/contest/contest_history_screen.dart
// Ecran : historique des concours inter-ecoles passes.
//
// Affiche la liste des 6 derniers concours mensuels termines, tries par
// date (du plus recent au plus ancien). Pour chaque concours :
//   - Banniere thematique (couleur degrade).
//   - Titre + matiere + periode.
//   - Ecole gagnante + medaille d'or.
//   - Points cumules par l'ecole gagnante.
//   - Bouton "Voir le detail" qui pousse ContestDetailsScreen.
//
// Le service est passe en parametre depuis ContestHomeScreen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/contest.dart';
import 'services/contest_service.dart';
import 'contest_details_screen.dart';

class ContestHistoryScreen extends StatelessWidget {
  final ContestService service;

  const ContestHistoryScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: service,
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ContestService>();
    final passes = service.pastContests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Concours passes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body:
          passes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: passes.length,
                itemBuilder: (context, i) {
                  return _PastContestCard(
                    contest: passes[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ContestDetailsScreen(
                                service: service,
                                contestId: passes[i].id,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text(
            'Aucun concours passe pour le moment.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Carte d'un concours passe ───────────────────────────────────────

class _PastContestCard extends StatelessWidget {
  final Contest contest;
  final VoidCallback onTap;

  const _PastContestCard({required this.contest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Couleur thematique selon la matiere (mock : cycle de couleurs).
    final gradient = _gradientForMatiere(contest.matiere);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // ─── Banniere thematique ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              contest.titre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_outlined,
                                  size: 11,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  contest.matiere,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Date de fin
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatMois(contest.dateFin),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TERMINE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Section ecole gagnante + stats ───────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Medaille or
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB300),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gagnant',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              contest.ecoleGagnanteNom ?? 'Non determine',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Points
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${contest.pointsActuels}',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'pts cumules',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Bouton "Voir le detail" ─────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${contest.nbEcolesParticipantes} ecoles participantes',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Voir le detail',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gradient thematique selon la matiere (cycle de couleurs).
  static List<Color> _gradientForMatiere(String matiere) {
    // Palette de 6 gradients distincts.
    const palettes = [
      [Color(0xFF006837), Color(0xFF004A26)], // vert maths
      [Color(0xFF1565C0), Color(0xFF0D47A1)], // bleu svt
      [Color(0xFF6A1B9A), Color(0xFF4527A0)], // violet philo
      [Color(0xFFD97700), Color(0xFFE65100)], // orange physique
      [Color(0xFFAD1457), Color(0xFF880E4F)], // rose histoire-geo
      [Color(0xFF00838F), Color(0xFF006064)], // teal anglais
    ];
    final h = matiere.hashCode.abs();
    return palettes[h % palettes.length];
  }

  /// Formate la date de fin en "MMMM yyyy" (ex: "fevrier 2026").
  static String _formatMois(DateTime d) {
    const mois = [
      '', 'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre',
    ];
    return '${mois[d.month]} ${d.year}';
  }
}
