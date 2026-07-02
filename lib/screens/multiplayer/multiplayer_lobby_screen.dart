// lib/screens/multiplayer/multiplayer_lobby_screen.dart
// Salle d'attente (lobby) avant le démarrage de la partie.
//
// Affiche :
//   - Le code de la room en grand (partageable)
//   - La grille des joueurs connectés (max 6)
//   - Le chat pré-partie
//   - Le bouton "Prêt" pour le joueur local
//   - Le bouton "Démarrer" pour l'hôte (activé si tous prêts)
//
// Écoute le MultiplayerSocketService via ListenableBuilder pour
// rebuild automatiquement quand l'état change (joueurs qui rejoignent,
// messages de chat, statut prêt).
//
// À l'appui sur "Démarrer" par l'hôte, le service passe en statut
// playing et on navigue vers MultiplayerGameScreen (pushReplacement).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/multiplayer_room.dart';
import 'multiplayer_game_screen.dart';
import 'services/multiplayer_socket_service.dart';
import 'widgets/live_chat_widget.dart';
import 'widgets/player_avatar_grid.dart';
import 'widgets/room_code_display.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() =>
      _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  @override
  void initState() {
    super.initState();
    // Écoute les changements d'état pour naviguer vers le game quand
    // la partie démarre (l'hôte appuie sur "Démarrer").
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
    if (svc.room?.status == MultiplayerRoomStatus.playing) {
      // Partie démarrée : navigue vers le game (remplace le lobby).
      svc.removeListener(_onServiceChanged);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MultiplayerGameScreen()),
      );
    }
  }

  void _shareCode() {
    final svc = context.read<MultiplayerSocketService>();
    final code = svc.room?.code ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code à partager : $code'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _leave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la room ?'),
        content: const Text(
          'Tu vas quitter la salle d\'attente. Les autres joueurs '
          'pourront continuer sans toi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<MultiplayerSocketService>().leaveRoom();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leave,
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Salle d\'attente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'En attente des joueurs...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Code room
                  RoomCodeDisplay(
                    code: room.code,
                    onShare: _shareCode,
                  ),
                  const SizedBox(height: 16),

                  // Infos room (matière, mode, nb questions)
                  _RoomInfoBar(room: room),
                  const SizedBox(height: 16),

                  // Joueurs connectés
                  _SectionTitle(
                    title: 'Joueurs connectés',
                    subtitle:
                        '${room.players.length}/${MultiplayerRoom.maxPlayers}',
                    icon: Icons.group,
                  ),
                  const SizedBox(height: 10),
                  PlayerAvatarGrid(
                    players: room.players,
                    maxPlayers: MultiplayerRoom.maxPlayers,
                    localPlayerId: svc.playerId,
                  ),
                  const SizedBox(height: 16),

                  // Statut "prêt"
                  _ReadyStatusCard(room: room),
                  const SizedBox(height: 16),

                  // Boutons d'action
                  _ActionButtons(room: room),
                  const SizedBox(height: 16),

                  // Chat pré-partie
                  SizedBox(
                    height: 280,
                    child: LiveChatWidget(
                      messages: room.chatMessages,
                      localPlayerId: svc.playerId,
                      onSend: (text) =>
                          svc.sendChatMessage(text: text),
                      title: 'Chat pré-partie',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Titre de section ───────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bandeau d'infos room (matière, mode, questions) ────────────────
class _RoomInfoBar extends StatelessWidget {
  final MultiplayerRoom room;

  const _RoomInfoBar({required this.room});

  String get _modeLabel =>
      room.isCompetitive ? 'Compétitif' : 'Coopératif';

  Color get _modeColor =>
      room.isCompetitive ? AppColors.primary : AppColors.accent;

  IconData get _modeIcon =>
      room.isCompetitive ? Icons.flag : Icons.handshake;

  @override
  Widget build(BuildContext context) {
    final subject = MultiplayerSubject.byId(room.matiere);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _InfoChip(
              icon: Icons.book_outlined,
              label: subject.label,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              icon: Icons.format_list_numbered,
              label: '${room.nbQuestions} Q',
              color: AppColors.info,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              icon: _modeIcon,
              label: _modeLabel,
              color: _modeColor,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              icon: Icons.timer_outlined,
              label: '30s/Q',
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte de statut "prêt" ─────────────────────────────────────────
class _ReadyStatusCard extends StatelessWidget {
  final MultiplayerRoom room;

  const _ReadyStatusCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final readyCount =
        room.players.where((p) => p.isReady || p.isHost).length;
    final total = room.players.length;
    final allReady = room.allReady;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: allReady ? AppColors.success : AppColors.divider,
          width: allReady ? 1.5 : 1,
        ),
      ),
      color: allReady ? AppColors.success.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              allReady ? Icons.check_circle : Icons.hourglass_top,
              color: allReady ? AppColors.success : AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allReady
                        ? 'Tous prêts !'
                        : 'En attente des joueurs...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: allReady
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$readyCount/$total joueurs prêts',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Mini barre de progression
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(
                value: total == 0 ? 0.0 : readyCount / total,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  allReady ? AppColors.success : AppColors.warning,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Boutons d'action ───────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final MultiplayerRoom room;

  const _ActionButtons({required this.room});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<MultiplayerSocketService>();
    final isHost = svc.isHost;
    final me = svc.me;
    final myReady = me?.isReady ?? false;
    final allReady = room.allReady;

    return Row(
      children: [
        // Bouton "Prêt" (tous les joueurs y compris l'hôte)
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => svc.toggleReady(),
              icon: Icon(
                myReady ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
              ),
              label: Text(
                myReady ? 'Prêt' : 'Pas prêt',
                style: const TextStyle(fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: myReady ? AppColors.success : AppColors.textSecondary,
                side: BorderSide(
                  color: myReady ? AppColors.success : AppColors.divider,
                  width: 1.5,
                ),
                backgroundColor: myReady
                    ? AppColors.success.withOpacity(0.06)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton "Démarrer" (hôte uniquement)
        Expanded(
          child: SizedBox(
            height: 50,
            child: isHost
                ? ElevatedButton.icon(
                    onPressed: allReady ? () => svc.startGame() : null,
                    icon: const Icon(Icons.play_arrow, size: 22),
                    label: const Text(
                      'Démarrer',
                      style: TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.textDisabled.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : Tooltip(
                    message: 'Seul l\'hôte peut démarrer la partie',
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline, size: 18),
                      label: const Text('Hôte requis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant,
                        foregroundColor: AppColors.textDisabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
