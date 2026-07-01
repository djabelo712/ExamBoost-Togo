// lib/screens/classroom/widgets/live_leaderboard.dart
// Classement temps reel des joueurs.
//
// Affiche :
//   - le top 3 en grand avec podium mini (or / argent / bronze)
//   - le reste en liste compacte
//   - met a jour l'ordre avec une animation (AnimatedList implicite)
//
// Le widget ne gere pas l'etat : il recoit la liste deja triee par
// l'ecran parent (le service expose ``players``).

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/classroom_player.dart';

class LiveLeaderboard extends StatelessWidget {
  final List<ClassroomPlayer> players;
  final String? currentUserId;
  final String title;

  const LiveLeaderboard({
    super.key,
    required this.players,
    this.currentUserId,
    this.title = 'Classement en direct',
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 8),
            Text('Aucun joueur pour le moment',
                style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    final sorted = List<ClassroomPlayer>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));

    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3),
              const Spacer(),
              Text('${sorted.length} joueur(s)',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        if (top3.isNotEmpty) _buildTop3(top3),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Suite du classement',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 4),
          ...rest.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return _LeaderboardTile(
              player: p,
              rank: i + 4,
              isMe: p.id == currentUserId,
            );
          }),
        ],
      ],
    );
  }

  // ─── Top 3 en grand ────────────────────────────────────────────
  Widget _buildTop3(List<ClassroomPlayer> top3) {
    // Ordre affichage : 2e | 1er | 3e (podium visuel)
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            Expanded(child: _PodiumSlot(player: second, rank: 2, height: 90))
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 8),
          if (first != null)
            Expanded(child: _PodiumSlot(player: first, rank: 1, height: 120))
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 8),
          if (third != null)
            Expanded(child: _PodiumSlot(player: third, rank: 3, height: 70))
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

// ─── Slot du podium top 3 ───────────────────────────────────────────
class _PodiumSlot extends StatelessWidget {
  final ClassroomPlayer player;
  final int rank;
  final double height;

  const _PodiumSlot({
    required this.player,
    required this.rank,
    required this.height,
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

  IconData _rankIcon() {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      default:
        return Icons.shield;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _rankColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            player.initials,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          player.name,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${player.score} pts',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        // Marche du podium
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_rankIcon(), color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tuile joueur (rangs 4+) ────────────────────────────────────────
class _LeaderboardTile extends StatelessWidget {
  final ClassroomPlayer player;
  final int rank;
  final bool isMe;

  const _LeaderboardTile({
    required this.player,
    required this.rank,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primarySurface
            : Theme.of(context).cardTheme.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: isMe ? Border.all(color: AppColors.primary, width: 1.5) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isMe ? '${player.name} (toi)' : player.name,
              style: AppTextStyles.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${player.score}',
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
