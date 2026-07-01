// lib/screens/search/widgets/filter_chips_bar.dart
// Barre horizontale scrollable affichant les filtres actifs sous forme de
// chips effacables.
//
// Comportement :
//   - 1 chip par filtre actif (matiere, examen, serie, annee, type, difficulte,
//     pointsMin, favoris, non-maitrise, keyword)
//   - Tap sur la croix d'un chip -> supprime ce filtre (callback)
//   - Chip "Effacer tout" a la fin si >= 2 filtres actifs
//   - Chip "+X filtres" qui ouvre le bottom sheet si trop de filtres
//     (au-dela de 3, on remplace les chips par un resume "+N filtres" pour
//     ne pas surcharger la barre)
//
// La barre est masquee s'il n'y a aucun filtre actif.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/search_filters.dart';

class FilterChipsBar extends StatelessWidget {
  const FilterChipsBar({
    super.key,
    required this.filters,
    required this.onFilterRemoved,
    required this.onClearAll,
    required this.onShowAllFilters,
  });

  final SearchFilters filters;

  /// Callback avec la cle du filtre a supprimer (chaine normalisee).
  /// Cles possibles : 'keyword', 'matiere', 'examen', 'serie', 'year',
  /// 'type', 'difficulty', 'pointsMin', 'onlyFavorites', 'onlyNotMastered'.
  final ValueChanged<String> onFilterRemoved;

  /// Callback pour effacer tous les filtres.
  final VoidCallback onClearAll;

  /// Callback pour ouvrir le FilterBottomSheet (lorsqu'on tap sur "+X filtres").
  final VoidCallback onShowAllFilters;

  /// Nombre max de chips affiches individuellement. Au-dela, on resume.
  static const int _maxIndividualChips = 3;

  @override
  Widget build(BuildContext context) {
    final labels = _buildChipDescriptors();
    if (labels.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: labels.length + (filters.activeFilterCount > _maxIndividualChips
            ? 1
            : (filters.activeFilterCount >= 2 ? 1 : 0)),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          if (i < labels.length) {
            final d = labels[i];
            return _FilterChip(
              label: d.label,
              icon: d.icon,
              onDeleted: () => onFilterRemoved(d.key),
            );
          }
          // Dernier element : soit "+X filtres", soit "Effacer tout".
          if (filters.activeFilterCount > _maxIndividualChips) {
            return ActionChip(
              label: Text(
                '+${filters.activeFilterCount - _maxIndividualChips} filtres',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
              backgroundColor: AppColors.primarySurface,
              side: const BorderSide(color: AppColors.primaryLight, width: 1),
              avatar: const Icon(Icons.more_horiz,
                  size: 16, color: AppColors.primary),
              onPressed: onShowAllFilters,
            );
          }
          return ActionChip(
            label: Text(
              'Effacer tout',
              style: AppTextStyles.label.copyWith(color: AppColors.error),
            ),
            backgroundColor: AppColors.error.withOpacity(0.08),
            side: BorderSide(color: AppColors.error.withOpacity(0.3), width: 1),
            avatar: const Icon(Icons.delete_outline,
                size: 16, color: AppColors.error),
            onPressed: onClearAll,
          );
        },
      ),
    );
  }

  /// Construit la liste des chips a afficher (au max _maxIndividualChips).
  List<_ChipDescriptor> _buildChipDescriptors() {
    final all = <_ChipDescriptor>[];
    if (filters.keyword != null && filters.keyword!.trim().isNotEmpty) {
      final k = filters.keyword!.trim();
      all.add(_ChipDescriptor(
        key: 'keyword',
        label: '"${k.length > 14 ? '${k.substring(0, 12)}...' : k}"',
        icon: Icons.search,
      ));
    }
    if (filters.matiere != null) {
      all.add(_ChipDescriptor(
        key: 'matiere',
        label: filters.matiere!,
        icon: Icons.menu_book,
      ));
    }
    if (filters.examen != null) {
      all.add(_ChipDescriptor(
        key: 'examen',
        label: filters.examen!,
        icon: Icons.school,
      ));
    }
    if (filters.serie != null) {
      all.add(_ChipDescriptor(
        key: 'serie',
        label: 'Serie ${filters.serie!}',
        icon: Icons.label_outline,
      ));
    }
    if (filters.yearFrom != null || filters.yearTo != null) {
      final from = filters.yearFrom ?? 2010;
      final to = filters.yearTo ?? 2024;
      all.add(_ChipDescriptor(
        key: 'year',
        label: '$from-$to',
        icon: Icons.event,
      ));
    }
    if (filters.type != null) {
      all.add(_ChipDescriptor(
        key: 'type',
        label: _typeLabel(filters.type!),
        icon: Icons.category,
      ));
    }
    if (filters.difficultyRange != null &&
        filters.difficultyRange != DifficultyRange.tous) {
      all.add(_ChipDescriptor(
        key: 'difficulty',
        label: filters.difficultyRange!.label,
        icon: Icons.speed,
      ));
    }
    if (filters.pointsMin != null) {
      all.add(_ChipDescriptor(
        key: 'pointsMin',
        label: '>= ${filters.pointsMin} pts',
        icon: Icons.star_outline,
      ));
    }
    if (filters.onlyFavorites == true) {
      all.add(_ChipDescriptor(
        key: 'onlyFavorites',
        label: 'Favoris',
        icon: Icons.favorite,
      ));
    }
    if (filters.onlyNotMastered == true) {
      all.add(_ChipDescriptor(
        key: 'onlyNotMastered',
        label: 'Non maitrise',
        icon: Icons.trending_up,
      ));
    }
    // Limiter a _maxIndividualChips : les suivants seront resumes dans "+X filtres".
    if (all.length > _maxIndividualChips) {
      return all.take(_maxIndividualChips).toList();
    }
    return all;
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
}

// ─── Modeles internes ─────────────────────────────────────────────────

class _ChipDescriptor {
  final String key;
  final String label;
  final IconData icon;
  const _ChipDescriptor({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onDeleted,
  });

  final String label;
  final IconData icon;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 14,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
