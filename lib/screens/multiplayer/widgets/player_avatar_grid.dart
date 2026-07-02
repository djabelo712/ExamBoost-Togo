// lib/screens/multiplayer/widgets/player_avatar_grid.dart
// Grille d'avatars des joueurs connectés à une room.
//
// Affiche jusqu'à 6 joueurs (max par room) sous forme de grille 3x2.
// Chaque avatar montre :
//   - initiales dans un cercle coloré
//   - nom du joueur
//   - statut (prêt / pas prêt / a répondu / déconnecté)
//   - badge "hôte" si applicable
//   - score live pendant la partie (si showScores = true)
//
// Les slots vides (joueurs manquants) sont affichés en pointillés.
//
// Usage :
//   PlayerAvatarGrid(players: room.players, maxPlayers: 6, showScores: true)

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/multiplayer_player.dart';
import '../models/multiplayer_room.dart';

class PlayerAvatarGrid extends StatelessWidget {
  final List<MultiplayerPlayer> players;
  final int maxPlayers;
  final bool showScores;
  final String? localPlayerId;

  const PlayerAvatarGrid({
    super.key,
    required this.players,
    this.maxPlayers = MultiplayerRoom.maxPlayers,
    this.showScores = false,
    this.localPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    // On génère maxPlayers cellules : les joueurs présents + slots vides.
    final cells = <Widget>[];
    for (var i = 0; i < maxPlayers; i++) {
      if (i < players.length) {
        cells.add(
          _PlayerAvatarCell(
            player: players[i],
            showScore: showScores,
            isLocal: players[i].id == localPlayerId,
          ),
        );
      } else {
        cells.add(const _EmptySlotCell());
      }
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: cells,
    );
  }
}

// ─── Cellule d'un joueur connecté ───────────────────────────────────
class _PlayerAvatarCell extends StatelessWidget {
  final MultiplayerPlayer player;
  final bool showScore;
  final bool isLocal;

  const _PlayerAvatarCell({
    required this.player,
    required this.showScore,
    required this.isLocal,
  });

  Color get _statusColor {
    switch (player.status) {
      case MultiplayerPlayerStatus.answered:
        return AppColors.success;
      case MultiplayerPlayerStatus.disconnected:
        return AppColors.textDisabled;
      case MultiplayerPlayerStatus.connected:
        return player.isReady ? AppColors.success : AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (player.status) {
      case MultiplayerPlayerStatus.answered:
        return 'A répondu';
      case MultiplayerPlayerStatus.disconnected:
        return 'Déconnecté';
      case MultiplayerPlayerStatus.connected:
        return player.isReady ? 'Prêt' : 'Pas prêt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocal ? AppColors.accent : AppColors.divider,
          width: isLocal ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar avec badge hôte + statut
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: player.avatarColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  player.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              // Pastille de statut
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
              // Couronne hôte
              if (player.isHost)
                Positioned(
                  top: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Hôte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isLocal ? 'Moi' : player.name,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          if (showScore) ...[
            Text(
              '${player.score} pts',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ] else ...[
            Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Slot vide (en attente d'un joueur) ─────────────────────────────
class _EmptySlotCell extends StatelessWidget {
  const _EmptySlotCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            color: AppColors.textDisabled,
            size: 32,
          ),
          const SizedBox(height: 6),
          Text(
            'En attente',
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
