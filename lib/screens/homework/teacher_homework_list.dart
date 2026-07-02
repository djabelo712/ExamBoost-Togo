// lib/screens/homework/teacher_homework_list.dart
// Liste des devoirs créés par l'enseignant (avec stats agrégées).
//
// Pour chaque devoir :
//   - carte avec statut (publié/clos/archivé),
//   - taux de rendu (% élèves ayant soumis),
//   - moyenne classe sur 20,
//   - tap → ouvre teacher_homework_results.dart (rapport classe détaillé).
//
// Bouton flottant "+" → ouvre teacher_homework_create.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../models/homework.dart';
import '../services/homework_service.dart';
import 'teacher_homework_create.dart';
import 'teacher_homework_results.dart';
import 'widgets/homework_card.dart';

class TeacherHomeworkList extends StatelessWidget {
  const TeacherHomeworkList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes devoirs'),
        actions: [
          IconButton(
            tooltip: 'Statistiques globales',
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => _showGlobalStats(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createHomework(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau devoir'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<HomeworkService>(
        builder: (context, service, _) {
          final homeworks = service.getHomeworksForCurrentEnseignant();

          if (homeworks.isEmpty) {
            return _buildEmptyState(context);
          }

          // Tri : deadline la plus proche en premier
          homeworks.sort((a, b) => a.dateLimit.compareTo(b.dateLimit));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: homeworks.length,
            itemBuilder: (context, index) {
              final hw = homeworks[index];
              final stats = service.getStatsForHomework(hw.id);
              return Column(
                children: [
                  HomeworkCard(
                    homework: hw,
                    nbRendus: stats.nbRendus,
                    effectif: stats.effectifClasse,
                    onTap: () => _voirResultats(context, hw.id),
                  ),
                  // Mini-stats sous la carte
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Row(
                      children: [
                        _miniStat(
                          context,
                          icon: Icons.star_outline,
                          label: 'Moyenne',
                          value: '${stats.moyenne20.toStringAsFixed(1)}/20',
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        _miniStat(
                          context,
                          icon: Icons.check_circle_outline,
                          label: 'Rendus',
                          value: '${stats.tauxRendu.round()}%',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _miniStat(
                          context,
                          icon: Icons.warning_amber_outlined,
                          label: 'Manqués',
                          value: '${stats.nbManques}',
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─── Mini stat (sous chaque carte) ──────────────────────────
  Widget _miniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: AdaptiveColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdaptiveColors.divider(context)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AdaptiveColors.textSecondary(context),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── État vide ──────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: AdaptiveColors.textSecondary(context)),
            const SizedBox(height: 16),
            Text(
              'Aucun devoir créé pour l\'instant.',
              style: AppTextStyles.h2.copyWith(
                color: AdaptiveColors.textPrimary(context),
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Touche le bouton "+" pour créer ton premier devoir '
              'et l\'assigner à une classe.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createHomework(context),
              icon: const Icon(Icons.add),
              label: const Text('Créer un devoir'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats globales (dialog) ────────────────────────────────
  void _showGlobalStats(BuildContext context) {
    final service = context.read<HomeworkService>();
    final homeworks = service.getHomeworksForCurrentEnseignant();

    int totalRendus = 0;
    int totalEffectif = 0;
    double sumMoyennes = 0;
    int nbAvecRendus = 0;

    for (final hw in homeworks) {
      final stats = service.getStatsForHomework(hw.id);
      totalRendus += stats.nbRendus;
      totalEffectif += stats.effectifClasse;
      if (stats.nbRendus > 0) {
        sumMoyennes += stats.moyenne20;
        nbAvecRendus++;
      }
    }

    final tauxGlobal = totalEffectif > 0
        ? (totalRendus / totalEffectif) * 100
        : 0.0;
    final moyenneGlobal =
        nbAvecRendus > 0 ? sumMoyennes / nbAvecRendus : 0.0;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Statistiques globales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statLine('Devoirs publiés', '${homeworks.length}'),
            _statLine('Élèves ciblés (total)', '$totalEffectif'),
            _statLine(
                'Rendus reçus', '$totalRendus (${tauxGlobal.round()}%)'),
            _statLine('Moyenne tous devoirs',
                '${moyenneGlobal.toStringAsFixed(1)}/20'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(
            value,
            style: AppTextStyles.body
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─── Navigation ─────────────────────────────────────────────
  void _createHomework(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeacherHomeworkCreate()),
    );
  }

  void _voirResultats(BuildContext context, String homeworkId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherHomeworkResults(homeworkId: homeworkId),
      ),
    );
  }
}
