// lib/screens/classroom/widgets/player_list_widget.dart
// Liste des joueurs connectes a une session classe.
//
// Affiche pour chaque joueur :
//   - un avatar avec ses initiales (colore selon rang si classement)
//   - son nom
//   - son score
//   - un indicateur de statut (connecte / a repondu / en attente)
//
// Variante compacte : [PlayerListWidget.compact] pour l'enseignant
// (liste horizontale scrollable d'avatars).

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/classroom_player.dart';

class PlayerListWidget extends StatelessWidget {
  final List<ClassroomPlayer> players;
  final String? currentUserId;
  final bool showScore;
  final bool showStatus;
  final bool compact;
  final Widget? emptyState;

  const PlayerListWidget({
    super.key,
    required this.players,
    this.currentUserId,
    this.showScore = false,
    this.showStatus = true,
    this.compact = false,
    this.emptyState,
  });

  /// Variante compacte : liste horizontale scrollable d'avatars.
  const PlayerListWidget.compact({
    super.key,
    required this.players,
    this.currentUserId,
    this.emptyState,
  })  : showScore = false,
        showStatus = false,
        compact = true;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return emptyState ??
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.people_outline,
                    size: 48, color: AppColors.textDisabled),
                const SizedBox(height: 8),
                Text(
                  'En attente de joueurs...',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
    }

    if (compact) {
      return SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: players.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => _PlayerAvatar(
            player: players[i],
            isMe: players[i].id == currentUserId,
            size: 56,
            showStatus: false,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: players.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _PlayerTile(
        player: players[i],
        rank: i + 1,
        isMe: players[i].id == currentUserId,
        showScore: showScore,
        showStatus: showStatus,
      ),
    );
  }
}

// ─── Tuile individuelle ─────────────────────────────────────────────
class _PlayerTile extends StatelessWidget {
  final ClassroomPlayer player;
  final int rank;
  final bool isMe;
  final bool showScore;
  final bool showStatus;

  const _PlayerTile({
    required this.player,
    required this.rank,
    required this.isMe,
    required this.showScore,
    required this.showStatus,
  });

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.surfaceVariant;
    }
  }

  Color _statusColor() {
    switch (player.status) {
      case PlayerStatus.answered:
        return AppColors.success;
      case PlayerStatus.disconnected:
        return AppColors.textDisabled;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel() {
    switch (player.status) {
      case PlayerStatus.answered:
        return 'A repondu';
      case PlayerStatus.disconnected:
        return 'Deconnecte';
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileColor = isMe
        ? AppColors.primarySurface
        : Theme.of(context).cardTheme.color ?? AppColors.surface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rang
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
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          _PlayerAvatar(
            player: player,
            isMe: isMe,
            size: 36,
            showStatus: false,
          ),
          const SizedBox(width: 10),
          // Nom + statut
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${player.name} (toi)' : player.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showStatus)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _statusColor(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Score
          if (showScore)
            Text(
              '${player.score}',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Avatar avec initiales ──────────────────────────────────────────
class _PlayerAvatar extends StatelessWidget {
  final ClassroomPlayer player;
  final bool isMe;
  final double size;
  final bool showStatus;

  const _PlayerAvatar({
    required this.player,
    required this.isMe,
    required this.size,
    required this.showStatus,
  });

  Color _avatarColor() {
    // Couleur deterministe depuis l'ID
    final hash = player.id.hashCode;
    final palette = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      AppColors.warning,
      const Color(0xFF8E24AA),
      const Color(0xFF00897B),
      const Color(0xFFE53935),
      const Color(0xFF6D4C41),
    ];
    return palette[hash.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor();
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isMe
                ? Border.all(color: AppColors.primary, width: 2.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            player.initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.36,
            ),
          ),
        ),
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: player.status == PlayerStatus.answered
                    ? AppColors.success
                    : player.status == PlayerStatus.disconnected
                        ? AppColors.textDisabled
                        : AppColors.warning,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
