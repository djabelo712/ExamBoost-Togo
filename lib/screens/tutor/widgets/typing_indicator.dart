// lib/screens/tutor/widgets/typing_indicator.dart
// Animation "le tuteur écrit..." — 3 points sautillants dans une bulle à gauche.
//
// Animation : chaque point est décalé de 0.2s et suit une courbe en cloche
// (taille max à t=0.5). La couleur varie du vert pâle au vert primary.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.label = 'Le tuteur écrit'});

  final String label;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primarySurface,
            child: const Icon(Icons.smart_toy,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Chaque dot est décalé de 0.2s
        final t = (_controller.value + index * 0.2) % 1.0;
        // Courbe en cloche : taille max à t=0.5
        final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs());
        return Transform.translate(
          offset: Offset(0, -3 * scale),
          child: Container(
            width: 8 * scale,
            height: 8 * scale,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.4 + 0.6 * scale),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
