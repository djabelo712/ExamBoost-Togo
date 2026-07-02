// lib/screens/multiplayer/multiplayer_results_screen.dart
// Écran de résultats finaux après une partie multijoueur.
//
// Affiche :
//   - Podium animé top 3 (or / argent / bronze)
//   - Classement complet (tous les joueurs)
//   - Stats par joueur (bonnes réponses, temps moyen, taux de réussite)
//   - En mode coopératif, score cumulé de l'équipe
//   - Bouton "Rejouer" et bouton "Quitter"
//
// Les résultats sont calculés depuis l'état du service (room.players
// triés par score décroissant). On n'a pas besoin de backend.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/multiplayer_player.dart';
import 'models/multiplayer_room.dart';
import 'services/multiplayer_socket_service.dart';
import 'widgets/podium_multiplayer.dart';

class MultiplayerResultsScreen extends StatelessWidget {
  const MultiplayerResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<MultiplayerSocketService>();
    final room = svc.room;
    if (room == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textDisabled),
              const SizedBox(height: 12),
              const Text('Aucune partie à afficher'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final results = MultiplayerRoomResults.fromRoom(room);
    final me = svc.me;
    final myRank = results.leaderboard.indexWhere((p) => p.id == svc.playerId) + 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Résultats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Partie terminée',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _leaveToHome(context),
            tooltip: 'Quitter',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Podium
              PodiumMultiplayer(podium: results.podium),
              const SizedBox(height: 16),

              // Carte "Mon résultat"
              if (me != null) ...[
                _MyResultCard(
                  rank: myRank,
                  player: me,
                  mode: room.mode,
                  teamScore: results.teamScore,
                  isCoop: room.isCooperative,
                ),
                const SizedBox(height: 16),
              ],

              // Mode coopératif : score équipe
              if (room.isCooperative) ...[
                _TeamScoreCard(
                  teamScore: results.teamScore,
                  totalQuestions: results.totalQuestions,
                  playerCount: room.players.length,
                ),
                const SizedBox(height: 16),
              ],

              // Classement complet
              _SectionTitle(
                title: 'Classement complet',
                icon: Icons.list_alt,
              ),
              const SizedBox(height: 10),
              ...results.leaderboard.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final p = entry.value;
                final isLocal = p.id == svc.playerId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RankRow(
                    rank: rank,
                    player: p,
                    isLocal: isLocal,
                    totalQuestions: results.totalQuestions,
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveToHome(context),
                      icon: const Icon(Icons.home),
                      label: const Text('Accueil'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _replay(context),
                      icon: const Icon(Icons.replay),
                      label: const Text('Rejouer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _leaveToHome(BuildContext context) {
    context.read<MultiplayerSocketService>().leaveRoom();
    Navigator.of(context)
        .popUntil((route) => route.isFirst);
  }

  void _replay(BuildContext context) {
    // Pour rejouer, on retourne à l'écran de création d'une nouvelle room.
    // On pourrait aussi réutiliser les mêmes paramètres (matière, mode),
    // mais pour la démo on retourne simplement à l'accueil multijoueur.
    context.read<MultiplayerSocketService>().leaveRoom();
    Navigator.of(context)
        .popUntil((route) => route.isFirst);
  }
}

// ─── Titre de section ───────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(fontSize: 16),
        ),
      ],
    );
  }
}

// ─── Carte "Mon résultat" ───────────────────────────────────────────
class _MyResultCard extends StatelessWidget {
  final int rank;
  final MultiplayerPlayer player;
  final MultiplayerMode mode;
  final int teamScore;
  final bool isCoop;

  const _MyResultCard({
    required this.rank,
    required this.player,
    required this.mode,
    required this.teamScore,
    required this.isCoop,
  });

  String get _rankLabel {
    switch (rank) {
      case 1:
        return '1er';
      case 2:
        return '2e';
      default:
        return '${rank}e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mon résultat',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 15,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rang
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rank == 1
                        ? const Color(0xFFFFD700)
                        : rank == 2
                            ? const Color(0xFFC0C0C0)
                            : rank == 3
                                ? const Color(0xFFCD7F32)
                                : AppColors.surfaceVariant,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _rankLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Stats principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: AppTextStyles.h3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${player.score} points',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Stats détaillées
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'Bonnes réponses',
                    value:
                        '${player.correctCount}/${player.answeredCount}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'Temps moyen',
                    value:
                        '${player.averageTimeSeconds.toStringAsFixed(1)}s',
                    icon: Icons.timer_outlined,
                    color: AppColors.info,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'Taux réussite',
                    value:
                        '${(player.successRate * 100).round()}%',
                    icon: Icons.percent,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Carte "Score équipe" (mode coopératif) ─────────────────────────
class _TeamScoreCard extends StatelessWidget {
  final int teamScore;
  final int totalQuestions;
  final int playerCount;

  const _TeamScoreCard({
    required this.teamScore,
    required this.totalQuestions,
    required this.playerCount,
  });

  @override
  Widget build(BuildContext context) {
    final maxPossible = totalQuestions * playerCount * 150; // 100 + bonus
    final percent = maxPossible == 0 ? 0.0 : teamScore / maxPossible;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.accent, width: 1),
      ),
      color: AppColors.accent.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Score de l\'équipe',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 15,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$teamScore',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'pts cumulés',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(percent * 100).round()}% du max',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$playerCount joueurs ont collaboré sur $totalQuestions questions.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ligne du classement complet ────────────────────────────────────
class _RankRow extends StatelessWidget {
  final int rank;
  final MultiplayerPlayer player;
  final bool isLocal;
  final int totalQuestions;

  const _RankRow({
    required this.rank,
    required this.player,
    required this.isLocal,
    required this.totalQuestions,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isLocal
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocal ? AppColors.primary : AppColors.divider,
          width: isLocal ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rang
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: rank <= 3 ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.avatarColor,
            ),
            alignment: Alignment.center,
            child: Text(
              player.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nom + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isLocal ? 'Moi' : player.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Hôte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 11, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text(
                      '${player.correctCount}/${player.answeredCount}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined,
                        size: 11, color: AppColors.info),
                    const SizedBox(width: 2),
                    Text(
                      '${player.averageTimeSeconds.toStringAsFixed(1)}s',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
