// lib/screens/search/search_screen.dart
// Ecran principal de recherche & filtres avances ExamBoost Togo.
//
// Layout (de haut en bas) :
//   - AppBar : titre "Rechercher" + bouton "Favoris" (voir recherches
//     sauvegardees — affiche un badge si > 0)
//   - SearchBarWidget (sticky) : barre de recherche + bouton "Filtres"
//     + suggestions d'autocompletion (chapitres)
//   - FilterChipsBar (sticky, masque si 0 filtre actif) : chips effacables
//   - SortDropdown (sticky, masque si pas de resultats) : dropdown tri + asc/desc
//   - Corps :
//     * Si recherche active (keyword ou filtre actif) -> liste resultats
//       (ListView.builder avec QuestionResultCard). Etat vide si 0.
//     * Sinon -> SavedSearchesSection (recherches favorites + suggestions)
//   - FAB "Sauvegarder cette recherche" (etoile) — visible si >= 1 filtre actif
//
// Donnees :
//   - SearchService instancie localement avec QuestionService (Provider)
//   - Set<String> _favoriteIds charge depuis Hive box "question_favorites"
//     (boite simple key=questionId value='1' — wiring a finaliser avec Agent AN)
//   - Map<String,double> _maitriseMap charge depuis AppUser (UserProvider)
//     pour le filtre onlyNotMastered
//
// Navigation sortante :
//   - /revision/<matiere> via context.go quand on tap "Reviser" sur une card
//   - QuestionDetailBottomSheet quand on tap une card ou une suggestion
//   - FilterBottomSheet.show() pour ouvrir tous les filtres

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/question.dart';
import '../../providers/user_provider.dart';
import '../../services/question_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';
import '../favorites/services/favorites_service.dart';
import 'models/saved_search.dart';
import 'models/search_filters.dart';
import 'services/search_service.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/question_result_card.dart';
import 'widgets/saved_searches_section.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/sort_dropdown.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchService _searchService;

  SearchFilters _filters = SearchFilters.empty;
  List<Question> _results = const [];
  bool _hasRunSearch = false;

  Set<String> _favoriteIds = <String>{};
  Map<String, double> _maitriseMap = <String, double>{};
  List<Question> _popularQuestions = const [];

  @override
  void initState() {
    super.initState();
    final qs = context.read<QuestionService>();
    _searchService = SearchService(questionService: qs);
    _loadAuxData();
    _popularQuestions = _searchService.getPopularQuestions(limit: 6);
  }

  /// Charge les favoris (via FavoritesService de l'Agent AN) et la map de
  /// maitrise (depuis l'utilisateur courant). Wraps try/catch pour rester
  /// robuste meme si Agent AN n'a pas encore ete wire dans main.dart.
  Future<void> _loadAuxData() async {
    // Recupere l'userId courant (depuis UserProvider ou fallback 'user_demo').
    String userId = 'user_demo';
    try {
      final userProvider = context.read<UserProvider>();
      userId = userProvider.currentUserId;
    } catch (_) {
      // UserProvider absent — fallback 'user_demo'.
    }
    // Favoris — on prefere FavoritesService (Agent AN) si disponible.
    try {
      final favService = context.read<FavoritesService>();
      final ids = favService.getFavoriteIds(userId).toSet();
      if (mounted) setState(() => _favoriteIds = ids);
    } catch (_) {
      // FavoritesService pas encore enregistre comme Provider — favoris
      // restent vides (filtre onlyFavorites retournera liste vide).
    }
    // Maitrise BKT depuis l'utilisateur courant.
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;
      if (user != null && mounted) {
        setState(() => _maitriseMap = Map<String, double>.from(user.bktMaitrise));
      }
    } catch (_) {
      // UserProvider absent — maitrise vide.
    }
  }

  void _runSearch() {
    final results = _searchService.search(
      _filters,
      favoriteIds: _favoriteIds,
      maitriseMap: _maitriseMap,
    );
    setState(() {
      _results = results;
      _hasRunSearch = _filters.hasActiveFilters || (_filters.keyword?.isNotEmpty ?? false);
    });
  }

  void _onKeywordChanged(String value) {
    setState(() {
      _filters = _filters.copyWith(
        keyword: value.isEmpty ? null : value,
        clearKeyword: value.isEmpty,
      );
    });
    // Recherche live (debounce implicite via le listener du TextField).
    _runSearch();
  }

  void _onKeywordSubmitted(String value) {
    _runSearch();
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
    // Calcule un apercu live pendant l'edition.
    final yearRange = _searchService.yearRange;
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
      yearRange: yearRange,
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
      // Re-synchronise avec la source de verite (au cas ou toggleFavorite
      // aurait refuse pour une raison metier).
      if (mounted) {
        setState(() => _favoriteIds = favService.getFavoriteIds(userId).toSet());
      }
    } catch (_) {
      // FavoritesService ou UserProvider indisponible — la persistance
      // est ignoree, l'UI reste coherente pour la session courante.
    }
  }

  void _showQuestionDetails(Question q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _QuestionDetailSheet(question: q),
    );
  }

  void _navigateToRevision(Question q) {
    context.go(
      '${AppRoutes.revision}/${Uri.encodeComponent(q.matiere)}',
    );
  }

  Future<void> _saveCurrentSearch() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sauvegarder cette recherche'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom de la recherche',
            hintText: 'ex : Mes Maths BEPC 2020-2023',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _searchService.saveSearch(
      name: name,
      filters: _filters,
      resultCount: _results.length,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recherche "$name" sauvegardee'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _runSavedSearch(SavedSearch saved) {
    setState(() => _filters = saved.filters);
    _runSearch();
    // Met a jour le compteur de resultats pour cette recherche.
    _searchService.updateResultCount(saved.id, _results.length);
  }

  Future<void> _renameSavedSearch(SavedSearch saved, String newName) async {
    // Le widget SavedSearchesSection gere deja le dialogue localement ;
    // ici on persiste le nouveau nom dans Hive via SearchService.
    await _searchService.renameSearch(saved.id, newName);
  }

  Future<void> _deleteSavedSearch(SavedSearch saved) async {
    await _searchService.deleteSearch(saved.id);
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSearch =
        _filters.hasActiveFilters || (_filters.keyword?.isNotEmpty ?? false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline),
            tooltip: 'Recherches sauvegardees',
            onPressed: () {
              // Bascule vers la section sauvegardees en effacant la recherche
              // active.
              setState(() {
                _filters = SearchFilters.empty;
                _results = const [];
                _hasRunSearch = false;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Barre de recherche (sticky) ──────────────────────────
          SearchBarWidget(
            onChanged: _onKeywordChanged,
            onSubmitted: _onKeywordSubmitted,
            onFilterButtonPressed: _openFilterSheet,
            suggestionsFetcher: _searchService.getKeywordSuggestions,
            initialText: _filters.keyword,
          ),
          // ─── Chips filtres actifs (sticky) ────────────────────────
          FilterChipsBar(
            filters: _filters,
            onFilterRemoved: _onFilterRemoved,
            onClearAll: _onClearAllFilters,
            onShowAllFilters: _openFilterSheet,
          ),
          // ─── Dropdown de tri (sticky si resultats) ────────────────
          if (hasActiveSearch)
            SortDropdown(
              filters: _filters,
              resultCount: _results.length,
              onSortChanged: _onSortChanged,
            ),
          // ─── Corps ────────────────────────────────────────────────
          Expanded(
            child: hasActiveSearch
                ? _buildResultsBody()
                : SavedSearchesSection(
                    savedSearchesFetcher: _searchService.getAllSavedSearches,
                    popularQuestions: _popularQuestions,
                    onRunSavedSearch: _runSavedSearch,
                    onRenameSavedSearch: _renameSavedSearch,
                    onDeleteSavedSearch: _deleteSavedSearch,
                    onQuestionTap: _showQuestionDetails,
                  ),
          ),
        ],
      ),
      // ─── FAB : sauvegarder la recherche (si filtres actifs) ───────
      floatingActionButton: hasActiveSearch && _filters.hasActiveFilters
          ? FloatingActionButton.extended(
              onPressed: _saveCurrentSearch,
              icon: const Icon(Icons.star_outline),
              label: const Text('Sauvegarder'),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  // ─── Corps des resultats ─────────────────────────────────────────────

  Widget _buildResultsBody() {
    if (_results.isEmpty) {
      return _buildEmptyResults();
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
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
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'Aucun resultat',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Essaie de modifier tes filtres ou ton mot-cle. '
              'Tu peux aussi effacer un filtre avec la croix sur son chip.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _onClearAllFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reinitialiser les filtres'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BottomSheet detail question ──────────────────────────────────────

class _QuestionDetailSheet extends StatelessWidget {
  const _QuestionDetailSheet({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Column(
        children: [
          // Poignee
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // En-tete
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _DetailChip(label: question.matiere, color: AppColors.primary),
                      _DetailChip(
                        label:
                            '${question.examen}${question.serie != null ? ' ${question.serie}' : ''}${question.annee != null ? ' ${question.annee}' : ''}',
                        color: AppColors.accent,
                      ),
                      _DetailChip(label: _typeLabel(question.type), color: AppColors.info),
                      if (question.points != null)
                        _DetailChip(label: '${question.points} pts', color: AppColors.warning),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Contenu scrollable
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Text('Enonce', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(question.enonce, style: AppTextStyles.questionText),
                const SizedBox(height: 20),
                Text('Chapitre', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(question.chapitre, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Text('Reponse', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    question.reponse,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (question.explication != null) ...[
                  const SizedBox(height: 20),
                  Text('Explication',
                      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(question.explication!, style: AppTextStyles.body),
                ],
                if (question.choix != null && question.choix!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Choix',
                      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  ...question.choix!.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 6, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(c, style: AppTextStyles.body)),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
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
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
