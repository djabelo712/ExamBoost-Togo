// lib/screens/classroom/student_results_screen.dart
// Ecran eleve : resultats finaux apres une session classe.
//
// Affiche :
//   - Podium final (top 3)
//   - Sa propre place + score
//   - Classement complet
//   - Bouton "Revoir mes reponses" (delegue : ouvre une boite de dialogue
//     avec le detail des questions / reponses - non implante completement
//     car les reponses attendues ne sont pas toutes renvoyees par le WS)
//   - Bouton "Quitter"

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import 'models/classroom_player.dart';
import 'models/classroom_session.dart';
import 'services/classroom_socket_service.dart';
import 'widgets/podium_widget.dart';

class StudentResultsScreen extends StatelessWidget {
  final String sessionCode;
  final String playerName;

  const StudentResultsScreen({
    super.key,
    required this.sessionCode,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ClassroomSocketService>();
    return StudentResultsView(
      service: service,
      sessionCode: sessionCode,
      playerName: playerName,
    );
  }
}

/// Vue resultats partagee entre StudentResultsScreen (route dediee) et
/// StudentLiveQuizScreen (etat "results" inline). Permet de reutiliser
/// le meme rendu sans dupliquer le code.
class StudentResultsView extends StatelessWidget {
  final ClassroomSocketService service;
  final String sessionCode;
  final String playerName;

  const StudentResultsView({
    super.key,
    required this.service,
    required this.sessionCode,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final results = service.results;
    final me = service.me;

    // Determine mon rang
    int? myRank;
    if (results != null) {
      for (var i = 0; i < results.leaderboard.length; i++) {
        if (results.leaderboard[i].id == service.playerId) {
          myRank = i + 1;
          break;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tete
          Container(
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
                const Icon(Icons.emoji_events,
                    color: Colors.white, size: 40),
                const SizedBox(height: 8),
                const Text(
                  'Session terminee !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code : $sessionCode',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Podium
          if (results != null && results.podium.isNotEmpty)
            PodiumWidget(podium: results.podium)
          else if (service.players.isNotEmpty)
            PodiumWidget(podium: service.players.take(3).toList())
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucun resultat disponible'),
            ),

          const SizedBox(height: 16),

          // Ma place
          if (me != null)
            _MyResultCard(
              player: me,
              rank: myRank,
              totalPlayers:
                  results?.totalPlayers ?? service.players.length,
              totalQuestions:
                  results?.totalQuestions ?? service.totalQuestions,
            ),
          const SizedBox(height: 16),

          // Classement complet
          if (results != null && results.leaderboard.isNotEmpty)
            _FullLeaderboard(
              leaderboard: results.leaderboard,
              currentUserId: service.playerId,
            )
          else if (service.players.isNotEmpty)
            _FullLeaderboard(
              leaderboard: service.players
                  .where((p) => p.role == PlayerRole.student)
                  .toList()
                ..sort((a, b) => b.score.compareTo(a.score)),
              currentUserId: service.playerId,
            ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAnswersDialog(context),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Revoir mes reponses'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exit(context),
                  icon: const Icon(Icons.home, size: 18),
                  label: const Text('Quitter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnswersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mes reponses'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (service.lastAnswerResult != null) ...[
                ListTile(
                  leading: Icon(
                    service.lastAnswerResult!.correct
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: service.lastAnswerResult!.correct
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  title: Text(
                      'Question ${service.currentQuestionNum}: '
                      '${service.lastAnswerResult!.correct ? "Correct" : "Incorrect"}'),
                  subtitle: Text(
                      '+${service.lastAnswerResult!.pointsEarned} pts'),
                ),
                if (service.lastAnswerResult!.expectedAnswer != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Reponse attendue : '
                      '${service.lastAnswerResult!.expectedAnswer}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                if (service.lastAnswerResult!.explanation != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Explication : ${service.lastAnswerResult!.explanation}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ] else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Detail des reponses disponible uniquement pour la '
                      'derniere question (le serveur ne renvoie pas '
                      'l\'historique complet).'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _exit(BuildContext context) {
    // Deconnecte le service puis remonte a la racine
    final s = service;
    s.disconnect();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ─── Carte "mon resultat" ──────────────────────────────────────────
class _MyResultCard extends StatelessWidget {
  final ClassroomPlayer player;
  final int? rank;
  final int totalPlayers;
  final int totalQuestions;

  const _MyResultCard({
    required this.player,
    required this.rank,
    required this.totalPlayers,
    required this.totalQuestions,
  });

  String _rankLabel() {
    if (rank == null) return '-';
    if (rank == 1) return '1er';
    return '${rank}e';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              player.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ton resultat',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.score} points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.answeredCount}/$totalQuestions reponses - '
                  '${_rankLabel()} / $totalPlayers',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                _rankLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '/ $totalPlayers',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Classement complet ────────────────────────────────────────────
class _FullLeaderboard extends StatelessWidget {
  final List<ClassroomPlayer> leaderboard;
  final String currentUserId;

  const _FullLeaderboard({
    required this.leaderboard,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
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
          ...leaderboard.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final isMe = p.id == currentUserId;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primarySurface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isMe
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '#${i + 1}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isMe ? '${p.name} (toi)' : p.name,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${p.score}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
