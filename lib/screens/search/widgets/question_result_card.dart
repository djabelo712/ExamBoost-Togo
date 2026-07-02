// lib/screens/search/widgets/question_result_card.dart
// Carte d'affichage d'une question dans les resultats de recherche.
//
// Contenu :
//   - Ligne superieure : badge matiere (couleur selon matiere) + badge examen/annee
//   - Enonce (extrait max 3 lignes, overflow ellipsis)
//   - Chips meta : chapitre, type, difficulte, points
//   - Barre d'actions : bouton "Reviser" (vers /revision/<matiere>) +
//     bouton favori (cœur, toggle via callback Agent AN) +
//     bouton "Voir details" (ouvre bottom sheet)
//
// Tap sur la carte -> ouvre QuestionDetailBottomSheet (callback).
// Tap sur "Reviser" -> navigue vers revision avec cette question forcee
//   (passe via callback — l'ecran parent gere la navigation go_router).

import 'package:flutter/material.dart';

import '../../../models/question.dart';
import '../../../theme/app_theme.dart';

class QuestionResultCard extends StatelessWidget {
  const QuestionResultCard({
    super.key,
    required this.question,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onRevise,
  });

  final Question question;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onRevise;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Ligne superieure : matiere + examen/annee ─────────
              Row(
                children: [
                  _MatiereBadge(matiere: question.matiere),
                  const SizedBox(width: 8),
                  _ExamenBadge(
                    examen: question.examen,
                    serie: question.serie,
                    annee: question.annee,
                  ),
                  const Spacer(),
                  // Bouton favori (cœur)
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.error : AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onFavoriteToggle,
                    tooltip: isFavorite
                        ? 'Retirer des favoris'
                        : 'Ajouter aux favoris',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ─── Enonce (extrait max 3 lignes) ───────────────────────
              Text(
                question.enonce,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // ─── Chips meta ──────────────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MetaChip(
                    label: question.chapitre,
                    icon: Icons.book_outlined,
                    color: AppColors.info,
                  ),
                  _MetaChip(
                    label: _typeLabel(question.type),
                    icon: Icons.category_outlined,
                    color: AppColors.accent,
                  ),
                  _MetaChip(
                    label: _difficulteLabel(question),
                    icon: Icons.speed,
                    color: _difficulteColor(question),
                  ),
                  if (question.points != null)
                    _MetaChip(
                      label: '${question.points} pts',
                      icon: Icons.star_outline,
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // ─── Boutons d'action ────────────────────────────────────
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onRevise,
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('Reviser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 36),
                      textStyle:
                          AppTextStyles.button.copyWith(fontSize: 13),
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                      textStyle:
                          AppTextStyles.button.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(QuestionType t) {
    return switch (t) {
      QuestionType.calcul => 'Calcul',
      QuestionType.ouvert => 'Ouvert',
      QuestionType.qcm => 'QCM',
      QuestionType.vraiFaux => 'Vrai/Faux',
      QuestionType.redaction => 'Redaction',
    };
  }

  String _difficulteLabel(Question q) {
    return switch (q.difficulte) {
      DifficulteNiveau.facile => 'Facile',
      DifficulteNiveau.moyen => 'Moyen',
      DifficulteNiveau.difficile => 'Difficile',
    };
  }

  Color _difficulteColor(Question q) {
    return switch (q.difficulte) {
      DifficulteNiveau.facile => AppColors.facile,
      DifficulteNiveau.moyen => AppColors.moyen,
      DifficulteNiveau.difficile => AppColors.difficile,
    };
  }
}

// ─── Badges et chips internes ─────────────────────────────────────────

class _MatiereBadge extends StatelessWidget {
  const _MatiereBadge({required this.matiere});
  final String matiere;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        matiere,
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExamenBadge extends StatelessWidget {
  const _ExamenBadge({
    required this.examen,
    required this.serie,
    required this.annee,
  });

  final String examen;
  final String? serie;
  final int? annee;

  @override
  Widget build(BuildContext context) {
    final label = StringBuffer(examen);
    if (serie != null) label.write(' $serie');
    if (annee != null) label.write(' $annee');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toString(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: color, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
