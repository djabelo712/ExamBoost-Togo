// lib/screens/search/widgets/sort_dropdown.dart
// Dropdown de tri des resultats + bouton inverse-ordre (asc/desc).
//
// Affiche le nombre total de resultats a gauche, le dropdown de tri au
// centre, et un bouton "asc/desc" a droite.
//
// Le tri "Pertinence" n'a pas de bouton asc/desc (toujours descendant).
// Pour les autres tris, le bouton est actif et bascule sortAscending.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/search_filters.dart';

class SortDropdown extends StatelessWidget {
  const SortDropdown({
    super.key,
    required this.filters,
    required this.resultCount,
    required onSortChanged,
  }) : _onSortChanged = onSortChanged;

  final SearchFilters filters;
  final int resultCount;
  final ValueChanged<SearchFilters> _onSortChanged;

  void _setSortBy(SortBy newSort) {
    // Quand on change de critere, on reinitialise sortAscending a la valeur
    // par defaut du nouveau critere.
    _onSortChanged(filters.copyWith(
      sortBy: newSort,
      sortAscending: newSort.defaultAscending,
    ));
  }

  void _toggleAscending() {
    if (filters.sortBy == SortBy.relevance) return; // ignore pour pertinence
    _onSortChanged(filters.copyWith(
      sortAscending: !filters.sortAscending,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.background,
      child: Row(
        children: [
          // Nombre de resultats
          Text(
            '$resultCount resultat${resultCount > 1 ? 's' : ''}',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Dropdown de tri
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortBy>(
                value: filters.sortBy,
                items: SortBy.values
                    .map(
                      (s) => DropdownMenuItem<SortBy>(
                        value: s,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortIcon(s),
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.label,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) _setSortBy(v);
                },
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppColors.textSecondary),
                style: AppTextStyles.bodySmall,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (filters.sortBy != SortBy.relevance) ...[
            const SizedBox(width: 8),
            _AscendingToggle(
              ascending: filters.sortAscending,
              onPressed: _toggleAscending,
            ),
          ],
        ],
      ),
    );
  }

  IconData _sortIcon(SortBy s) {
    return switch (s) {
      SortBy.relevance => Icons.auto_awesome,
      SortBy.difficultyAsc => Icons.trending_up,
      SortBy.difficultyDesc => Icons.trending_down,
      SortBy.yearNewest => Icons.calendar_today,
      SortBy.yearOldest => Icons.history,
      SortBy.pointsHigh => Icons.star,
      SortBy.pointsLow => Icons.star_border,
    };
  }
}

class _AscendingToggle extends StatelessWidget {
  const _AscendingToggle({
    required this.ascending,
    required this.onPressed,
  });

  final bool ascending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                ascending ? 'Asc' : 'Desc',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
