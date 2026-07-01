// lib/screens/search/widgets/filter_bottom_sheet.dart
// BottomSheet complet avec tous les filtres de recherche.
//
// Sections :
//   1. Matiere (ChoiceChip single-select — 6 matieres du programme togolais)
//   2. Examen (ChoiceChip single-select — BEPC, BAC1, BAC2, Probatoire)
//   3. Serie (ChoiceChip single-select — A, B, C, D, F ; visible si BAC)
//   4. Annee (RangeSliders yearFrom / yearTo — 2010-2024)
//   5. Type de question (ChoiceChip single-select — 5 types)
//   6. Difficulte (ChoiceChip single-select — Tous/Facile/Moyen/Difficile)
//   7. Points minimum (Slider 1-5)
//   8. Favoris / Non-maitrise (Switch)
//
// Boutons bas :
//   - "Effacer tous les filtres" (gauche, rouge)
//   - "Appliquer (X resultats)" (droite, vert — X = preview en live)
//
// Comportement :
//   - Le bottom sheet est stateful : on garde une copie locale des filtres
//     pendant l'edition. Les callbacks onFiltersChanged mettent a jour
//     l'aperçu en temps reel (resultCount).
//   - "Appliquer" ferme le bottom sheet en renvoyant les filtres finaux.
//   - "Effacer" reinitialise a SearchFilters.empty.
//
// Affichage : showModalBottomSheet avec isScrollControlled=true pour occuper
// 80% de la hauteur. Le contenu est scrollable.

import 'package:flutter/material.dart';

import '../../../models/question.dart';
import '../../../theme/app_theme.dart';
import '../models/search_filters.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.previewCounter,
    required this.matieres,
    required this.examens,
    required this.series,
    required this.yearRange,
  });

  final SearchFilters initialFilters;

  /// Fonction qui calcule le nombre de resultats pour des filtres donnes
  /// (live update pendant l'edition). Recoit les filtres locaux et
  /// retourne un int.
  final int Function(SearchFilters) previewCounter;

  /// Listes disponibles pour les ChoiceChips (remplies par SearchService).
  final List<String> matieres;
  final List<String> examens;
  final List<String> series;

  /// Annee min/max pour les sliders (rempli par SearchService.yearRange).
  final ({int min, int max}) yearRange;

  /// Affiche le bottom sheet et attend le retour des filtres finaux.
  /// Retourne null si l'utilisateur annule (tap sur l'arriere-plan).
  static Future<SearchFilters?> show(
    BuildContext context, {
    required SearchFilters initialFilters,
    required int Function(SearchFilters) previewCounter,
    required List<String> matieres,
    required List<String> examens,
    required List<String> series,
    required ({int min, int max}) yearRange,
  }) {
    return showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FilterBottomSheet(
        initialFilters: initialFilters,
        previewCounter: previewCounter,
        matieres: matieres,
        examens: examens,
        series: series,
        yearRange: yearRange,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SearchFilters _local;
  int _previewCount = 0;

  @override
  void initState() {
    super.initState();
    _local = widget.initialFilters;
    _previewCount = widget.previewCounter(_local);
  }

  void _update(SearchFilters newFilters) {
    setState(() {
      _local = newFilters;
      _previewCount = widget.previewCounter(_local);
    });
  }

  void _clearAll() {
    setState(() {
      _local = SearchFilters.empty;
      _previewCount = widget.previewCounter(_local);
    });
  }

  void _apply() => Navigator.of(context).pop(_local);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Column(
        children: [
          // ─── Poignee + titre ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Filtres de recherche', style: AppTextStyles.h3),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        'Tout effacer',
                        style: AppTextStyles.button
                            .copyWith(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ─── Contenu scrollable ────────────────────────────────────
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16).copyWith(
                bottom: mediaQuery.viewInsets.bottom + 100,
              ),
              children: [
                _Section(
                  title: 'Matiere',
                  icon: Icons.menu_book,
                  child: _ChoiceChipRow(
                    options: widget.matieres,
                    selected: _local.matiere,
                    onSelected: (m) => _update(
                        _local.copyWith(matiere: m, clearMatiere: m == null)),
                  ),
                ),
                _Section(
                  title: 'Examen',
                  icon: Icons.school,
                  child: _ChoiceChipRow(
                    options: widget.examens,
                    selected: _local.examen,
                    onSelected: (e) => _update(_local.copyWith(
                      examen: e,
                      clearExamen: e == null,
                      // Reset serie si on change d'examen ou si on deselectionne
                      clearSerie: e != _local.examen,
                    )),
                  ),
                ),
                // Section serie : visible uniquement si un examen BAC est selectionne
                if (_isBacSelected) ...[
                  _Section(
                    title: 'Serie',
                    icon: Icons.label_outline,
                    child: _ChoiceChipRow(
                      options: widget.series,
                      selected: _local.serie,
                      onSelected: (s) => _update(_local.copyWith(
                          serie: s, clearSerie: s == null)),
                    ),
                  ),
                ],
                _Section(
                  title: 'Annee',
                  icon: Icons.event,
                  child: _YearRangeSelector(
                    min: widget.yearRange.min,
                    max: widget.yearRange.max,
                    from: _local.yearFrom,
                    to: _local.yearTo,
                    onChanged: (from, to) => _update(
                        _local.copyWith(yearFrom: from, yearTo: to)),
                  ),
                ),
                _Section(
                  title: 'Type de question',
                  icon: Icons.category,
                  child: _ChoiceChipRow(
                    options: const [
                      'Calcul',
                      'Ouvert',
                      'QCM',
                      'Vrai/Faux',
                      'Redaction'
                    ],
                    selected: _typeLabel(_local.type),
                    onSelected: (t) => _update(_local.copyWith(
                        type: _typeFromLabel(t), clearType: t == null)),
                  ),
                ),
                _Section(
                  title: 'Difficulte',
                  icon: Icons.speed,
                  child: _ChoiceChipRow(
                    options: const [
                      'Tous niveaux',
                      'Facile',
                      'Moyen',
                      'Difficile'
                    ],
                    selected: _local.difficultyRange?.label,
                    onSelected: (d) {
                      final newRange = DifficultyRange.values
                          .firstWhere((r) => r.label == d, orElse: () => DifficultyRange.tous);
                      _update(_local.copyWith(
                          difficultyRange: newRange == DifficultyRange.tous
                              ? null
                              : newRange));
                    },
                  ),
                ),
                _Section(
                  title: 'Points minimum',
                  icon: Icons.star_outline,
                  child: _PointsMinSlider(
                    value: _local.pointsMin,
                    onChanged: (v) => _update(
                        _local.copyWith(pointsMin: v, clearPointsMin: v == null)),
                  ),
                ),
                _Section(
                  title: 'Filtres speciaux',
                  icon: Icons.star,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Mes favoris uniquement'),
                        subtitle: const Text(
                            'Restreint aux questions marquees favorites',
                            style: AppTextStyles.bodySmall),
                        value: _local.onlyFavorites == true,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => _update(_local.copyWith(
                            onlyFavorites: v ? true : null,
                            clearOnlyFavorites: !v)),
                      ),
                      SwitchListTile(
                        title: const Text('Questions non maitrises'),
                        subtitle: const Text(
                            'Cache les questions deja maitrises (P(L) >= 0.85)',
                            style: AppTextStyles.bodySmall),
                        value: _local.onlyNotMastered == true,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => _update(_local.copyWith(
                            onlyNotMastered: v ? true : null,
                            clearOnlyNotMastered: !v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // ─── Boutons bas ───────────────────────────────────────────
          _BottomButtons(
            resultCount: _previewCount,
            onApply: _apply,
            onClear: _clearAll,
          ),
        ],
      ),
    );
  }

  bool get _isBacSelected {
    final e = _local.examen;
    if (e == null) return false;
    return e.startsWith('BAC') || e == 'Probatoire';
  }

  String? _typeLabel(QuestionType? t) {
    if (t == null) return null;
    return switch (t) {
      QuestionType.calcul => 'Calcul',
      QuestionType.ouvert => 'Ouvert',
      QuestionType.qcm => 'QCM',
      QuestionType.vraiFaux => 'Vrai/Faux',
      QuestionType.redaction => 'Redaction',
    };
  }

  QuestionType? _typeFromLabel(String? label) {
    if (label == null) return null;
    return switch (label) {
      'Calcul' => QuestionType.calcul,
      'Ouvert' => QuestionType.ouvert,
      'QCM' => QuestionType.qcm,
      'Vrai/Faux' => QuestionType.vraiFaux,
      'Redaction' => QuestionType.redaction,
      _ => null,
    };
  }
}

// ─── Composants internes ──────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChoiceChipRow extends StatelessWidget {
  const _ChoiceChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return ChoiceChip(
          label: Text(o),
          selected: isSelected,
          onSelected: (sel) => onSelected(sel ? o : null),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          backgroundColor: AppColors.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        );
      }).toList(),
    );
  }
}

class _YearRangeSelector extends StatelessWidget {
  const _YearRangeSelector({
    required this.min,
    required this.max,
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final int min;
  final int max;
  final int? from;
  final int? to;
  final void Function(int? from, int? to) onChanged;

  @override
  Widget build(BuildContext context) {
    final start = from ?? min;
    final end = to ?? max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$start - $end',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        RangeSlider(
          values: RangeValues(start.toDouble(), end.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min).clamp(1, 50),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primarySurface,
          labels: RangeLabels('$start', '$end'),
          onChanged: (v) {
            final newFrom = v.start.round();
            final newTo = v.end.round();
            // Si on revient aux bornes par defaut, on deselectionne (null).
            onChanged(
              newFrom == min ? null : newFrom,
              newTo == max ? null : newTo,
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$min', style: AppTextStyles.bodySmall),
            Text('$max', style: AppTextStyles.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _PointsMinSlider extends StatelessWidget {
  const _PointsMinSlider({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value == null ? 'Tous les points' : '>= $value points',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: (value ?? 1).toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primarySurface,
          label: '${value ?? 1}',
          onChanged: (v) {
            final newV = v.round();
            onChanged(newV == 1 ? null : newV);
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 pt', style: AppTextStyles.bodySmall),
            Text('5 pts', style: AppTextStyles.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _BottomButtons extends StatelessWidget {
  const _BottomButtons({
    required this.resultCount,
    required this.onApply,
    required this.onClear,
  });

  final int resultCount;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Effacer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                      color: AppColors.error.withOpacity(0.5), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  'Appliquer ($resultCount)',
                  style: AppTextStyles.button.copyWith(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
