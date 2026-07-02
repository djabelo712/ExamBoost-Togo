// lib/screens/orientation/widgets/filiere_card.dart
// Carte d'une filière recommandée — affiche le % de match, l'icône,
// la description courte, les universités, le salaire moyen et les raisons.
//
// Variantes :
//   - Dépliable (Expandable) : on tape pour voir les détails (universités,
//     durée, compétences clés, débouchés, carrière).
//   - Compacte : seulement en-tête + % match + 1 ligne description.
//
// Couleurs :
//   - Match fort (>=75%) : bordure verte + chip vert
//   - Match à explorer (60-74%) : bordure orange + chip orange
//   - Match faible (<60%) : bordure neutre + chip gris

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/filiere.dart';
import '../services/orientation_service.dart';
import 'career_path_card.dart';

class FiliereCard extends StatefulWidget {
  const FiliereCard({
    super.key,
    required this.recommendation,
    this.rank,
    this.initiallyExpanded = false,
  });

  final FiliereRecommendation recommendation;

  /// Rang dans le top (1, 2, 3, ...). Affiché en badge si non null.
  final int? rank;

  /// Vrai pour afficher la carte dépliée par défaut.
  final bool initiallyExpanded;

  @override
  State<FiliereCard> createState() => _FiliereCardState();
}

class _FiliereCardState extends State<FiliereCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final filiere = rec.filiere;
    final matchColor = rec.isForte
        ? AppColors.success
        : rec.isAExplorer
            ? AppColors.accent
            : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: matchColor.withOpacity(rec.isForte ? 0.6 : 0.3),
          width: rec.isForte ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── En-tête (toujours visible) ────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─ Rang (si fourni) ─
                  if (widget.rank != null) ...[
                    _RankBadge(rank: widget.rank!),
                    const SizedBox(width: 10),
                  ],
                  // ─ Icône filière ─
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      filiere.icon,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ─ Nom + description courte ─
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filiere.nom,
                          style: AppTextStyles.h3.copyWith(fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${filiere.diplome} - ${filiere.duree}',
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // ─ % match ─
                  _MatchBadge(
                    percent: rec.matchPercent,
                    color: matchColor,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // ─── Corps (visible si expanded) ───────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description complète
                  Text(
                    filiere.description,
                    style: AppTextStyles.body.copyWith(fontSize: 13.5),
                  ),

                  const SizedBox(height: 12),

                  // ─ Raisons du match ─
                  if (rec.raisons.isNotEmpty) ...[
                    Text(
                      'Pourquoi cette recommandation ?',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...rec.raisons.map((r) => _ReasonItem(text: r)),
                    const SizedBox(height: 12),
                  ],

                  // ─ Caractéristiques (chips) ─
                  _InfoRow(
                    icon: Icons.school_outlined,
                    label: 'Universités',
                    value: filiere.universites.join(', '),
                  ),
                  if (filiere.universitesCedeao.isNotEmpty)
                    _InfoRow(
                      icon: Icons.public,
                      label: 'CEDEAO',
                      value: filiere.universitesCedeao.join(', '),
                    ),
                  _InfoRow(
                    icon: Icons.attach_money,
                    label: 'Salaire moyen',
                    value: filiere.salaireLabel,
                  ),
                  _InfoRow(
                    icon: Icons.timeline,
                    label: 'Séries BAC conseillées',
                    value: filiere.seriesRecommandees.isEmpty
                        ? 'Toutes'
                        : filiere.seriesRecommandees.join(', '),
                  ),
                  _InfoRow(
                    icon: Icons.stars_outlined,
                    label: 'Sélectivité',
                    value: '${filiere.difficulteAdmission}/5'
                        '${filiere.selective ? ' (concours)' : ''}',
                  ),

                  const SizedBox(height: 12),

                  // ─ Compétences clés ─
                  Text(
                    'Compétences clés attendues',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: filiere.competencesCles
                        .map((c) => _SkillChip(label: c))
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  // ─ Débouchés ─
                  Text(
                    'Débouchés principaux',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: filiere.debouches
                        .map((d) => _DebouchChip(label: d))
                        .toList(),
                  ),

                  // ─ Career paths ─
                  if (rec.careers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Carrières possibles (${rec.careers.length})',
                      style: AppTextStyles.h3.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...rec.careers.map(
                      (c) => CareerPathCard(career: c),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Sous-composants
// ════════════════════════════════════════════════════════════════════

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isTop1 = rank == 1;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isTop1 ? AppColors.accent : AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isTop1 ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.percent, required this.color});
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        '${percent.round()}%',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ReasonItem extends StatelessWidget {
  const _ReasonItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.check_circle,
                size: 12, color: AppColors.success),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body
                  .copyWith(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall
            .copyWith(fontSize: 11, color: AppColors.primary),
      ),
    );
  }
}

class _DebouchChip extends StatelessWidget {
  const _DebouchChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
      ),
    );
  }
}
