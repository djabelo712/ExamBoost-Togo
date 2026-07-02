// lib/screens/classroom/widgets/podium_widget.dart
// Podium final anime pour le top 3 d'une session classe.
//
// Affichage :
//   - 1er au centre (plus haut), 2e a gauche, 3e a droite
//   - Les eleves montent sur le podium un par un (animation sequentielle)
//   - Couleurs or / argent / bronze
//   - Confetti optionnel (delegate a l'ecran parent via [showConfetti])
//
// Usage :
//   PodiumWidget(podium: results.podium)

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/classroom_player.dart';

class PodiumWidget extends StatefulWidget {
  final List<ClassroomPlayer> podium;
  final bool autoAnimate;

  const PodiumWidget({
    super.key,
    required this.podium,
    this.autoAnimate = true,
  });

  @override
  State<PodiumWidget> createState() => _PodiumWidgetState();
}

class _PodiumWidgetState extends State<PodiumWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thirdAnim;
  late Animation<double> _secondAnim;
  late Animation<double> _firstAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _thirdAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.33, curve: Curves.easeOutBack),
    );
    _secondAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.33, 0.66, curve: Curves.easeOutBack),
    );
    _firstAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 1.0, curve: Curves.easeOutBack),
    );
    if (widget.autoAnimate) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.podium.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 8),
            Text('Aucun participant', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    final first =
        widget.podium.isNotEmpty ? widget.podium[0] : null;
    final second =
        widget.podium.length > 1 ? widget.podium[1] : null;
    final third =
        widget.podium.length > 2 ? widget.podium[2] : null;

    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Fond decorative
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accentSurface,
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          // Podiums
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2e place
              Expanded(
                child: second != null
                    ? _PodiumStep(
                        player: second,
                        rank: 2,
                        height: 130,
                        color: const Color(0xFFC0C0C0), // Argent
                        animation: _secondAnim,
                      )
                    : const SizedBox(),
              ),
              // 1er place
              Expanded(
                child: first != null
                    ? _PodiumStep(
                        player: first,
                        rank: 1,
                        height: 180,
                        color: const Color(0xFFFFD700), // Or
                        animation: _firstAnim,
                        isWinner: true,
                      )
                    : const SizedBox(),
              ),
              // 3e place
              Expanded(
                child: third != null
                    ? _PodiumStep(
                        player: third,
                        rank: 3,
                        height: 100,
                        color: const Color(0xFFCD7F32), // Bronze
                        animation: _thirdAnim,
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Une marche du podium ───────────────────────────────────────────
class _PodiumStep extends StatelessWidget {
  final ClassroomPlayer player;
  final int rank;
  final double height;
  final Color color;
  final Animation<double> animation;
  final bool isWinner;

  const _PodiumStep({
    required this.player,
    required this.rank,
    required this.height,
    required this.color,
    required this.animation,
    this.isWinner = false,
  });

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
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Translation verticale : commence sous le podium, monte a 0
        final offset = (1.0 - animation.value) * 200.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + couronne
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (isWinner)
                Positioned(
                  top: -18,
                  child: Icon(Icons.emoji_events,
                      color: color, size: 28),
                ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  player.initials,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            player.name,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            '${player.score} pts',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          // Marche du podium
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withOpacity(0.75)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_rankIcon(), color: Colors.white, size: 36),
                const SizedBox(height: 6),
                Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
