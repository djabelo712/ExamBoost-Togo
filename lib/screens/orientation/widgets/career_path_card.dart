// lib/screens/orientation/widgets/career_path_card.dart
// Carte compacte d'un career path (métier) — affichée dans la liste
// dépliée d'une filière.
//
// Chaque carte contient :
//   - Titre + description courte
//   - Évolution de carrière
//   - Salaire début / senior
//   - Secteurs d'emploi (chips)
//   - Demande marché (étoiles)
//   - Potentiel international (chip)

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/career_path.dart';

class CareerPathCard extends StatelessWidget {
  const CareerPathCard({
    super.key,
    required this.career,
  });

  final CareerPath career;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── En-tête : titre + demande ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.work_outline,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      career.titre,
                      style: AppTextStyles.h3.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    _DemandStars(count: career.demandeStars),
                  ],
                ),
              ),
              _InternationalChip(
                level: career.potentielInternational,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ─── Description ───────────────────────────────────────────
          Text(
            career.description,
            style: AppTextStyles.body.copyWith(fontSize: 12.5),
          ),

          const SizedBox(height: 8),

          // ─── Évolution ─────────────────────────────────────────────
          if (career.evolution.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.trending_flat,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    career.evolution,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ─── Salaire ───────────────────────────────────────────────
          _InfoLine(
            icon: Icons.payments_outlined,
            label: 'Salaire',
            value: career.salaireLabel,
          ),
          _InfoLine(
            icon: Icons.login,
            label: 'Entrée',
            value: career.niveauEntree,
          ),

          const SizedBox(height: 6),

          // ─── Secteurs d'emploi ─────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: career.secteurs
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        s,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 6),

          // ─── Compétences clés ──────────────────────────────────────
          if (career.competencesCles.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: career.competencesCles
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Sous-composants
// ════════════════════════════════════════════════════════════════════

class _DemandStars extends StatelessWidget {
  const _DemandStars({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Demande : ',
          style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5),
        ),
        for (var i = 0; i < 5; i++)
          Icon(
            i < count ? Icons.star : Icons.star_border,
            size: 11,
            color: AppColors.accent,
          ),
      ],
    );
  }
}

class _InternationalChip extends StatelessWidget {
  const _InternationalChip({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (level) {
      case 'fort':
        color = AppColors.success;
        label = 'Monde';
        break;
      case 'faible':
        color = AppColors.textSecondary;
        label = 'Local';
        break;
      default:
        color = AppColors.info;
        label = 'Sous-région';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          SizedBox(
            width: 64,
            child: Text(
              '$label :',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body
                  .copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
