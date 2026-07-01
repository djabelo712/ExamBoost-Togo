// lib/widgets/states/skeletons/question_card_skeleton.dart
// Skeleton qui reproduit la forme de QuestionCard pendant le chargement.
//
// QuestionCard (lib/widgets/cards/question_card.dart) est compose de :
//   - Header : chip chapitre (gauche) + points (droite)
//   - Icone help_outline 32px
//   - Grande zone enonce (texte sur plusieurs lignes)
//   - Footer : indice "Appuyez sur Voir la reponse..."
//
// Ce skeleton reproduit cette structure avec des [ShimmerBox] pour simuler
// chaque zone, le tout wrappe dans une carte avec bordure verte (comme
// QuestionCard).
//
// Utilisation :
//   QuestionCardSkeleton()  // 1 carte
//   QuestionCardSkeleton(itemCount: 3)  // 3 cartes empilees (rare)

import 'package:flutter/material.dart';

import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';
import '../loading_skeleton.dart';

class QuestionCardSkeleton extends StatelessWidget {
  /// Nombre de cartes a empiler. Defaut : 1 (la plupart du temps on n'en
  /// affiche qu'une pendant le chargement de la 1ere question).
  final int itemCount;

  /// Padding autour de la carte. Defaut : 20 horizontal, 8 vertical.
  final EdgeInsetsGeometry padding;

  const QuestionCardSkeleton({
    super.key,
    this.itemCount = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(itemCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == itemCount - 1 ? 0 : 12),
            child: const _QuestionCardSkeletonItem(),
          );
        }),
      ),
    );
  }
}

class _QuestionCardSkeletonItem extends StatelessWidget {
  const _QuestionCardSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AdaptiveColors.primary(context).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header : chip chapitre (gauche) + points (droite) ─────
          Row(
            children: [
              ShimmerBox(
                width: 100,
                height: 24,
                borderRadius: 8,
              ),
              const Spacer(),
              const ShimmerBox(width: 40, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Icone help_outline (placeholder cercle) ──────────────
          const ShimmerBox(width: 32, height: 32, circular: true),
          const SizedBox(height: 12),

          // ─── Enonce : 4 lignes de largeurs decroissantes ──────────
          const ShimmerBox(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          const ShimmerBox(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          const ShimmerBox(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          const ShimmerBox(width: 220, height: 16, borderRadius: 4),
          const SizedBox(height: 24),

          // ─── Footer : indice (placeholder centre) ─────────────────
          Center(
            child: ShimmerBox(
              width: 240,
              height: 12,
              borderRadius: 4,
            ),
          ),
        ],
      ),
    );
  }
}
