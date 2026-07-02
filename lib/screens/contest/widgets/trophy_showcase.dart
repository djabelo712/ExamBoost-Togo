// lib/screens/contest/widgets/trophy_showcase.dart
// Vitrine des trophees gagnes par une ecole lors des concours precedents.
//
// Affiche les trophees sous forme de grille horizontale de cartes :
//   - Icone medaille (or/argent/bronze) avec couleur contextuelle.
//   - Titre du concours remporte.
//   - Date (mois + annee).
//   - Points cumules par l'ecole pendant ce concours.
//
// Si la liste est vide, affiche un etat vide encourageant
// ("Aucun trophee pour le moment -- participe au concours en cours !").
//
// La vitrine est utilisee a deux endroits :
//   - Sur l'ecran d'accueil du concours (carte "Mon ecole").
//   - Sur l'ecran de detail d'une ecole (classement).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/contest.dart';

class TrophyShowcase extends StatelessWidget {
  final List<ContestTrophy> trophees;
  final bool compact; // mode compact : hauteur reduite, 3 items visibles
  final String? title;

  const TrophyShowcase({
    super.key,
    required this.trophees,
    this.compact = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 4),
              Text(
                title!,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (trophees.isEmpty)
          _buildEmptyState()
        else
          SizedBox(
            height: compact ? 88 : 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: trophees.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return _TrophyCard(
                  trophee: trophees[i],
                  compact: compact,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 20,
            color: AppColors.textDisabled,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aucun trophee pour le moment. '
              'Participe au concours en cours pour decrocher la premiere '
              'medaille de ton ecole !',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte d'un trophee individuel ───────────────────────────────────

class _TrophyCard extends StatelessWidget {
  final ContestTrophy trophee;
  final bool compact;

  const _TrophyCard({required this.trophee, required this.compact});

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(trophee.tier);
    final tierLabel = _tierLabel(trophee.tier);

    return Container(
      width: compact ? 130 : 140,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                tierLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _formatMois(trophee.date),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            trophee.contestTitre,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              '${trophee.pointsEcole} pts',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Couleur selon le tier (or/argent/bronze).
  static Color _tierColor(TrophyTier tier) {
    switch (tier) {
      case TrophyTier.or:
        return const Color(0xFFFFB300);
      case TrophyTier.argent:
        return const Color(0xFF78909C);
      case TrophyTier.bronze:
        return const Color(0xFFB8693B);
    }
  }

  /// Libelle court du tier ("Or", "Argent", "Bronze").
  static String _tierLabel(TrophyTier tier) {
    switch (tier) {
      case TrophyTier.or:
        return 'Or';
      case TrophyTier.argent:
        return 'Argent';
      case TrophyTier.bronze:
        return 'Bronze';
    }
  }

  /// Formate la date en "MMM yyyy" (ex: "dec 2025").
  static String _formatMois(DateTime d) {
    const mois = [
      '', 'jan', 'fev', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aou', 'sep', 'oct', 'nov', 'dec',
    ];
    return '${mois[d.month]} ${d.year}';
  }
}
