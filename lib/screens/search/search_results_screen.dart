// lib/screens/search/search_results_screen.dart
// Ecran de resultats de recherche dedie — utilise pour re-executer une
// recherche sauvegardee via une route dediee (state.extra).
//
// Différences avec search_screen.dart :
//   - Pas de FAB "Sauvegarder" (la recherche est deja sauvegardee)
//   - Pas de section "Recherches sauvegardees" / "Suggestions"
//   - AppBar avec bouton retour + titre = nom de la recherche
//   - Filtres en lecture seule (chips desactives, bottom sheet accessible
//     mais pas de sauvegarde)
//
// Usage depuis une autre partie de l'app :
//   context.go(AppRoutes.searchResults, extra: {
//     'name': 'Mes Maths BEPC 2020-2023',
//     'filters': savedSearch.filters.toJson(),
//   });
//
// En attendant le wiring du router par l'agent principal, cet ecran est
// accessible via le constructeur direct (cf README.md section Integration).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/question.dart';
import '../../providers/user_provider.dart';
import '../../services/question_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';
import '../favorites/services/favorites_service.dart';
import 'models/search_filters.dart';
import 'services/search_service.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/question_result_card.dart';
import 'widgets/sort_dropdown.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.name,
    required this.filters,
  });

  /// Nom affiche dans l'AppBar (typiquement : savedSearch.name).
  final String name;

  /// Filtres a appliquer (typiquement : savedSearch.filters).
  final SearchFilters filters;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final SearchService _searchService;
  late SearchFilters _filters;
  List<Question> _results = const [];
  Set<String> _favoriteIds = <String>{};
  Map<String, double> _maitriseMap = <String, double>{};

  @override
  void initState() {
    super.initState();
    final qs = context.read<QuestionService>();
    _searchService = SearchService(questionService: qs);
    _filters = widget.filters;
    _loadAuxDataAndRun();
  }

  Future<void> _loadAuxDataAndRun() async {
    // Recupere l'userId courant (depuis UserProvider ou fallback 'user_demo').
    String userId = 'user_demo';
    try {
      final userProvider = context.read<UserProvider>();
      userId = userProvider.currentUserId;
    } catch (_) {}
    // Favoris via FavoritesService (Agent AN) si disponible.
    try {
      final favService = context.read<FavoritesService>();
      _favoriteIds = favService.getFavoriteIds(userId).toSet();
    } catch (_) {
      // FavoritesService pas enregistre — favoris vides pour cette session.
    }
    // Maitrise BKT depuis l'utilisateur courant.
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;
      if (user != null) {
        _maitriseMap = Map<String, double>.from(user.bktMaitrise);
      }
    } catch (_) {}
    if (mounted) _runSearch();
  }

  void _runSearch() {
    final results = _searchService.search(
      _filters,
      favoriteIds: _favoriteIds,
      maitriseMap: _maitriseMap,
    );
    setState(() => _results = results);
  }

  void _onFilterRemoved(String key) {
    setState(() {
      switch (key) {
        case 'keyword':
          _filters = _filters.copyWith(clearKeyword: true);
          break;
        case 'matiere':
          _filters = _filters.copyWith(clearMatiere: true);
          break;
        case 'examen':
          _filters = _filters.copyWith(clearExamen: true);
          break;
        case 'serie':
          _filters = _filters.copyWith(clearSerie: true);
          break;
        case 'year':
          _filters = _filters.copyWith(clearYearFrom: true, clearYearTo: true);
          break;
        case 'type':
          _filters = _filters.copyWith(clearType: true);
          break;
        case 'difficulty':
          _filters = _filters.copyWith(clearDifficulty: true);
          break;
        case 'pointsMin':
          _filters = _filters.copyWith(clearPointsMin: true);
          break;
        case 'onlyFavorites':
          _filters = _filters.copyWith(clearOnlyFavorites: true);
          break;
        case 'onlyNotMastered':
          _filters = _filters.copyWith(clearOnlyNotMastered: true);
          break;
      }
    });
    _runSearch();
  }

  void _onClearAllFilters() {
    setState(() {
      _filters = SearchFilters.empty.copyWith(sortBy: _filters.sortBy);
    });
    _runSearch();
  }

  Future<void> _openFilterSheet() async {
    int previewCounter(SearchFilters f) => _searchService
        .search(f, favoriteIds: _favoriteIds, maitriseMap: _maitriseMap)
        .length;
    final result = await FilterBottomSheet.show(
      context,
      initialFilters: _filters,
      previewCounter: previewCounter,
      matieres: _searchService.availableMatieres,
      examens: _searchService.availableExamens,
      series: _searchService.availableSeries,
      yearRange: _searchService.yearRange,
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
      _runSearch();
    }
  }

  void _onSortChanged(SearchFilters newFilters) {
    setState(() => _filters = newFilters);
    _runSearch();
  }

  void _showQuestionDetails(Question q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MinimalDetailSheet(question: q),
    );
  }

  void _navigateToRevision(Question q) {
    context.go(
      '${AppRoutes.revision}/${Uri.encodeComponent(q.matiere)}',
    );
  }

  Future<void> _toggleFavorite(Question q) async {
    // Mise a jour optimiste de l'UI.
    setState(() {
      if (_favoriteIds.contains(q.id)) {
        _favoriteIds.remove(q.id);
      } else {
        _favoriteIds.add(q.id);
      }
    });
    // Persistance via FavoritesService (Agent AN) si disponible.
    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUserId;
      final favService = context.read<FavoritesService>();
      await favService.toggleFavorite(userId, q.id);
      if (mounted) {
        setState(() => _favoriteIds = favService.getFavoriteIds(userId).toSet());
      }
    } catch (_) {
      // FavoritesService ou UserProvider indisponible — UI reste coherente
      // pour la session.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          FilterChipsBar(
            filters: _filters,
            onFilterRemoved: _onFilterRemoved,
            onClearAll: _onClearAllFilters,
            onShowAllFilters: _openFilterSheet,
          ),
          SortDropdown(
            filters: _filters,
            resultCount: _results.length,
            onSortChanged: _onSortChanged,
          ),
          Expanded(
            child: _results.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 32),
                    itemCount: _results.length,
                    itemBuilder: (ctx, i) {
                      final q = _results[i];
                      return QuestionResultCard(
                        question: q,
                        isFavorite: _favoriteIds.contains(q.id),
                        onTap: () => _showQuestionDetails(q),
                        onFavoriteToggle: () => _toggleFavorite(q),
                        onRevise: () => _navigateToRevision(q),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'Aucun resultat pour cette recherche',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalDetailSheet extends StatelessWidget {
  const _MinimalDetailSheet({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(question.matiere,
                  style: AppTextStyles.label.copyWith(color: AppColors.primary)),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text(question.enonce, style: AppTextStyles.questionText),
                const SizedBox(height: 16),
                Text('Reponse',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(question.reponse,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                if (question.explication != null) ...[
                  const SizedBox(height: 16),
                  Text('Explication',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(question.explication!, style: AppTextStyles.body),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
