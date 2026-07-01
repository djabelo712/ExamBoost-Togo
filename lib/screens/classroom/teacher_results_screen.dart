// lib/screens/classroom/teacher_results_screen.dart
// Ecran enseignant : resultats detailles d'une session classe terminee.
//
// Affiche :
//   - Podium top 3 (anime)
//   - Classement complet (tous les eleves)
//   - Stats par question : % reussite, temps moyen
//   - Bouton "Exporter resultats" (CSV genere cote client)
//   - Bouton "Recommencer une session"

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import 'models/classroom_player.dart';
import 'models/classroom_session.dart';
import 'services/classroom_socket_service.dart';
import 'widgets/podium_widget.dart';
import 'teacher_create_screen.dart';

class TeacherResultsScreen extends StatelessWidget {
  final String sessionCode;

  const TeacherResultsScreen({super.key, required this.sessionCode});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ClassroomSocketService>();
    final results = service.results;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resultats de la session'),
        automaticallyImplyLeading: false,
      ),
      body: results == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tete session
                  _buildSessionHeader(results),
                  const SizedBox(height: 16),
                  // Podium
                  PodiumWidget(podium: results.podium),
                  const SizedBox(height: 16),
                  // Stats globales
                  _buildGlobalStats(results),
                  const SizedBox(height: 16),
                  // Classement complet
                  _buildFullLeaderboard(results, service),
                  const SizedBox(height: 16),
                  // Stats par question
                  if (results.questionStats.isNotEmpty)
                    _buildQuestionStats(results),
                  const SizedBox(height: 24),
                  // Actions
                  _buildActions(context, results),
                ],
              ),
            ),
    );
  }

  // ─── En-tete session ───────────────────────────────────────────
  Widget _buildSessionHeader(ClassroomSessionResults results) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          const Text(
            'Session terminee',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Code : $sessionCode',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (results.endedAt != null)
            Text(
              'Terminee le ${_formatDate(results.endedAt)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // ─── Stats globales ────────────────────────────────────────────
  Widget _buildGlobalStats(ClassroomSessionResults results) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            label: 'Participants',
            value: '${results.totalPlayers}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.quiz,
            label: 'Questions',
            value: '${results.totalQuestions}',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            label: 'Score max',
            value: results.leaderboard.isNotEmpty
                ? '${results.leaderboard.first.score}'
                : '0',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  // ─── Classement complet ────────────────────────────────────────
  Widget _buildFullLeaderboard(results, ClassroomSocketService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Classement complet', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          if (results.leaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucun eleve n\'a participe.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            )
          else
            ...results.leaderboard.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return _LeaderboardRow(
                rank: i + 1,
                name: p.name,
                score: p.score,
                answeredCount: p.answeredCount,
                total: results.totalQuestions,
                isMe: p.id == service.playerId,
              );
            }),
        ],
      ),
    );
  }

  // ─── Stats par question ────────────────────────────────────────
  Widget _buildQuestionStats(ClassroomSessionResults results) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text('Statistiques par question',
                  style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          ...results.questionStats.map((s) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Question ${s.questionId}',
                          style: AppTextStyles.body,
                        ),
                      ),
                      Text(
                        '${(s.successRate * 100).toInt()}% de reussite',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _successColor(s.successRate),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: s.successRate,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _successColor(s.successRate),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.correctCount}/${s.answeredCount} reponses correctes '
                    '- temps moyen : ${s.averageTimeSeconds.toStringAsFixed(1)}s',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────
  Widget _buildActions(BuildContext context, ClassroomSessionResults results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportCsv(context, results),
                icon: const Icon(Icons.download),
                label: const Text('Exporter (CSV)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Retour a la creation
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const TeacherCreateScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Recommencer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            context.read<ClassroomSocketService>().disconnect();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.home),
          label: const Text('Retour a l\'accueil'),
        ),
      ],
    );
  }

  // ─── Export CSV ────────────────────────────────────────────────
  Future<void> _exportCsv(
      BuildContext context, ClassroomSessionResults results) async {
    final lines = <String>[
      'Rang,Nom,Score,Reponses correctes,Total questions',
    ];
    for (var i = 0; i < results.leaderboard.length; i++) {
      final p = results.leaderboard[i];
      // Echappe les virgules dans le nom
      final name = p.name.replaceAll(',', ';');
      lines.add(
        '${i + 1},$name,${p.score},${p.answeredCount},${results.totalQuestions}',
      );
    }
    final csv = lines.join('\n');

    // Tentative 1 : sauvegarde dans le dossier documents
    String? savedPath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/resultats_$sessionCode.csv');
      await file.writeAsString(csv);
      savedPath = file.path;
    } catch (_) {
      savedPath = null;
    }

    if (!context.mounted) return;

    // Tentative 2 : copier dans le presse-papier (always available)
    await Clipboard.setData(ClipboardData(text: csv));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(savedPath != null
            ? 'CSV sauvegarde : $savedPath (et copie dans le presse-papier)'
            : 'CSV copie dans le presse-papier'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────
  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _successColor(double rate) {
    if (rate >= 0.7) return AppColors.success;
    if (rate >= 0.4) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Carte stat ─────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.label,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Ligne du classement ────────────────────────────────────────────
class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final int answeredCount;
  final int total;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.answeredCount,
    required this.total,
    required this.isMe,
  });

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primarySurface : null,
        borderRadius: BorderRadius.circular(8),
        border: isMe
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _rankColor(),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: rank <= 3 ? Colors.black : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name (toi)' : name,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$answeredCount / $total reponses',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '$score pts',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
