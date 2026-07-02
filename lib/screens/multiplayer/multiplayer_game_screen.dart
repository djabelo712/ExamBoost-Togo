// lib/screens/multiplayer/multiplayer_game_screen.dart
// Écran principal de la partie multijoueur.
//
// Affiche :
//   - Barre de progression des questions (X / Y)
//   - Question synchronisée avec timer 30s
//   - Score live de chaque joueur (panneau latéral ou en haut)
//   - Indicateur "X a répondu"
//   - Chat live (suspendu pendant qu'on répond)
//
// Pendant qu'un joueur répond à une question :
//   - le chat est désactivé (enabled = false)
//   - les choix sont cliquables
//   - le timer décompte
//
// Après réponse :
//   - on attend que tous aient répondu (ou timeout)
//   - le service passe automatiquement à la question suivante
//   - à la fin, on navigue vers MultiplayerResultsScreen
//
// Écoute le service via ListenableBuilder pour rebuild sur chaque tick.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/multiplayer_player.dart';
import 'models/multiplayer_room.dart';
import 'multiplayer_results_screen.dart';
import 'services/multiplayer_socket_service.dart';
import 'widgets/live_chat_widget.dart';
import 'widgets/synchronized_question.dart';

class MultiplayerGameScreen extends StatefulWidget {
  const MultiplayerGameScreen({super.key});

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<MultiplayerSocketService>();
      svc.addListener(_onServiceChanged);
    });
  }

  @override
  void dispose() {
    final svc = context.read<MultiplayerSocketService>();
    svc.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    final svc = context.read<MultiplayerSocketService>();
    // Si la partie est terminée, navigue vers les résultats.
    if (svc.room?.status == MultiplayerRoomStatus.ended) {
      svc.removeListener(_onServiceChanged);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MultiplayerResultsScreen()),
      );
    }
  }

  Future<bool> _onWillPop() async {
    // Confirmation avant de quitter une partie en cours.
    final svc = context.read<MultiplayerSocketService>();
    if (svc.room?.status == MultiplayerRoomStatus.ended) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text(
          'Ta progression sera perdue et tu seras déconnecté de la room.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Rester'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (shouldLeave == true) {
      svc.leaveRoom();
    }
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onWillPop,
          ),
          title: ListenableBuilder(
            listenable: context.read<MultiplayerSocketService>(),
            builder: (context, _) {
              final svc = context.read<MultiplayerSocketService>();
              final qNum = svc.currentQuestionNumber;
              final total = svc.totalQuestions;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Question $qNum/$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Barre de progression
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0.0 : qNum / total,
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            ListenableBuilder(
              listenable: context.read<MultiplayerSocketService>(),
              builder: (context, _) {
                final svc = context.read<MultiplayerSocketService>();
                final me = svc.me;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${me?.score ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: context.read<MultiplayerSocketService>(),
            builder: (context, _) {
              final svc = context.read<MultiplayerSocketService>();
              final room = svc.room;
              if (room == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  // ── Bandeau "X a répondu" (en haut, sous l'AppBar)
                  _AnsweredStatusBar(),
                  // ── Liste horizontale des scores live
                  _LiveScoresStrip(),
                  // ── Question synchronisée
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SynchronizedQuestion(
                        question: svc.currentQuestion!,
                        timeRemaining: svc.timeRemaining,
                        timeLimit: svc.timeLimit,
                        hasAnswered: svc.hasAnsweredCurrent,
                        selectedIndex: _getSelectedIndex(svc),
                        showResult: svc.hasAnsweredCurrent &&
                            (svc.allAnswered || svc.timeRemaining == 0),
                        onAnswer: (i) => svc.sendAnswer(selectedIndex: i),
                      ),
                    ),
                  ),
                  // ── Chat live (suspendu pendant la réponse)
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: LiveChatWidget(
                        messages: svc.chatMessages,
                        localPlayerId: svc.playerId,
                        enabled: svc.hasAnsweredCurrent ||
                            room.status != MultiplayerRoomStatus.playing,
                        onSend: (text) =>
                            svc.sendChatMessage(text: text),
                        title: 'Chat live',
                      ),
                    ),
                  ),
                  // ── Bouton "Passer" (hôte) ou "En attente..."
                  if (svc.isHost && svc.allAnswered) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () => svc.nextQuestion(),
                          icon: const Icon(Icons.skip_next),
                          label: const Text('Passer à la suivante'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Récupère l'index sélectionné par le joueur local (s'il a répondu).
  /// On ne stocke pas directement cet index dans le service, mais on le
  /// récupère depuis `_lastAnswerResult` si disponible.
  int? _getSelectedIndex(MultiplayerSocketService svc) {
    if (svc.lastAnswerResult != null) {
      return svc.lastAnswerResult!.selectedIndex;
    }
    return null;
  }
}

// ─── Bandeau "X / Y ont répondu" ────────────────────────────────────
class _AnsweredStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = context.read<MultiplayerSocketService>();
    final room = svc.room;
    if (room == null) return const SizedBox.shrink();

    final connected = room.players
        .where((p) => p.status != MultiplayerPlayerStatus.disconnected)
        .length;
    final answered = room.players.where((p) => p.hasAnswered).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primarySurface,
      child: Row(
        children: [
          Icon(Icons.how_to_reg, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            '$answered / $connected ont répondu',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Mini avatars de ceux qui ont répondu
          SizedBox(
            height: 24,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: room.players.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, i) {
                final p = room.players[i];
                final hasAnswered = p.hasAnswered;
                return Tooltip(
                  message: '${p.name} ${hasAnswered ? "a répondu" : "en cours..."}',
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasAnswered
                          ? p.avatarColor
                          : AppColors.surfaceVariant,
                      border: Border.all(
                        color: hasAnswered
                            ? AppColors.success
                            : AppColors.divider,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: hasAnswered
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 12)
                        : Text(
                            p.initials,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bandeau horizontal des scores live ─────────────────────────────
class _LiveScoresStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = context.read<MultiplayerSocketService>();
    final room = svc.room;
    if (room == null) return const SizedBox.shrink();

    // Trie par score décroissant.
    final sorted = [...room.players]
      ..sort((a, b) => b.score.compareTo(a.score));

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = sorted[i];
          final isLocal = p.id == svc.playerId;
          final rank = i + 1;
          return _LiveScoreChip(
            player: p,
            rank: rank,
            isLocal: isLocal,
            isAnswered: p.hasAnswered,
          );
        },
      ),
    );
  }
}

class _LiveScoreChip extends StatelessWidget {
  final MultiplayerPlayer player;
  final int rank;
  final bool isLocal;
  final bool isAnswered;

  const _LiveScoreChip({
    required this.player,
    required this.rank,
    required this.isLocal,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLocal
            ? AppColors.accent.withOpacity(0.10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLocal ? AppColors.accent : AppColors.divider,
          width: isLocal ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rang
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFD700)
                  : rank == 2
                      ? const Color(0xFFC0C0C0)
                      : rank == 3
                          ? const Color(0xFFCD7F32)
                          : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: rank <= 3 ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.avatarColor,
              border: Border.all(
                color: isAnswered ? AppColors.success : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              player.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Nom + score
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLocal ? 'Moi' : player.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${player.score} pts',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
