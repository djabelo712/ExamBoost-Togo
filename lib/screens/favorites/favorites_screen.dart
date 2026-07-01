// lib/screens/favorites/favorites_screen.dart
// Page "Mes favoris" : liste des questions marquees comme favorites
// par l'eleve, avec filtres par matiere + tri multi-criteres.
//
// Structure :
//   - Header : titre + compteur + bouton "Tout reviser"
//   - Filtres : chips horizontaux (Toutes matieres + 6 matieres Togo)
//   - Tri     : DropdownButton (Plus recents / Plus anciens / Par
//               matiere / Par difficulte)
//   - Liste   : ListView.builder de FavoriteQuestionCard
//   - Etat vide : illustration + texte + CTA "Commencer a reviser"
//
// La page ecoute FavoritesService via Provider : toute modification
// (ajout/retrait de favori depuis un autre ecran) declenche un rebuild.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/question.dart';
import '../../providers/user_provider.dart';
import '../../services/question_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';
import 'models/favorite_question.dart';
import 'services/favorites_service.dart';
import 'widgets/favorite_question_card.dart';

/// Critere de tri disponible dans le dropdown.
enum _SortMode {
  recent('Plus recents'),
  ancient('Plus anciens'),
  matiere('Par matiere'),
  difficulte('Par difficulte');

  final String label;
  const _SortMode(this.label);
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  /// Filtre matiere selectionne. 'all' = toutes.
  String _matiereFilter = 'all';

  _SortMode _sortMode = _SortMode.recent;

  /// Liste fixe des matieres affichees dans les filtres (couvre le
  /// programme BEPC/BAC togolais). Si une question porte une matiere
  /// hors liste, elle reste affichee avec le filtre "Toutes".
  static const List<String> _matiereFilters = [
    'Mathematiques',
    'Francais',
    'Sciences Physiques',
    'SVT',
    'Histoire-Geographie',
    'Anglais',
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.currentUserId;
    final favService = Provider.of<FavoritesService>(context);
    final questionService = Provider.of<QuestionService>(context);

    // Recupere les favoris + leurs questions associees.
    final favorites = favService.getFavorites(userId);
    final paires = <_FavPair>[];
    for (final fav in favorites) {
      final q = questionService.getById(fav.questionId);
      if (q != null) paires.add(_FavPair(fav, q));
    }

    // ─── Application des filtres ──────────────────────────────────
    var filtered = paires.where((p) {
      if (_matiereFilter == 'all') return true;
      return p.question.matiere == _matiereFilter;
    }).toList();

    // ─── Application du tri ───────────────────────────────────────
    switch (_sortMode) {
      case _SortMode.recent:
        filtered.sort((a, b) => b.favorite.addedAt.compareTo(a.favorite.addedAt));
        break;
      case _SortMode.ancient:
        filtered.sort((a, b) => a.favorite.addedAt.compareTo(b.favorite.addedAt));
        break;
      case _SortMode.matiere:
        filtered.sort((a, b) =>
            a.question.matiere.compareTo(b.question.matiere));
        break;
      case _SortMode.difficulte:
        // Ordre : facile < moyen < difficile (index de l'enum).
        filtered.sort((a, b) => a.question.difficulte.index
            .compareTo(b.question.difficulte.index));
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes favoris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notes_outlined),
            tooltip: 'Mes notes',
            onPressed: () => context.go('/notes'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: filtered.isEmpty
            ? _buildEmptyState(context)
            : _buildList(context, filtered, userId),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<_FavPair> paires, String userId) {
    return CustomScrollView(
      slivers: [
        // ─── Header (titre + compteur + bouton "Tout reviser") ─────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          children: [
                            TextSpan(
                              text: '${paires.length}',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const TextSpan(text: ' question'),
                            TextSpan(
                              text: paires.length > 1 ? 's' : '',
                            ),
                            const TextSpan(text: ' favorite'),
                            TextSpan(
                              text: paires.length > 1 ? 's' : '',
                            ),
                          ],
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Tout reviser'),
                      onPressed: () {
                        // Reviser la matiere du premier favori (ou
                        // Mathematiques par defaut si liste vide).
                        final matiere = paires.first.question.matiere;
                        context.go(
                          '${AppRoutes.revision}/${Uri.encodeComponent(matiere)}',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ─── Filtres matieres (chips scrollables horizontalement) ──
        SliverToBoxAdapter(
          child: _buildMatiereFilters(),
        ),

        // ─── Ligne de tri ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildSortRow(),
        ),

        // ─── Liste des cartes ──────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: paires.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final p = paires[i];
              return FavoriteQuestionCard(
                favorite: p.favorite,
                question: p.question,
                userId: userId,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatiereFilters() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'Toutes matieres',
            selected: _matiereFilter == 'all',
            onTap: () => setState(() => _matiereFilter = 'all'),
          ),
          ..._matiereFilters.map(
            (m) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: m,
                selected: _matiereFilter == m,
                onTap: () => setState(() => _matiereFilter = m),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(Icons.sort, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Trier par :',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<_SortMode>(
              value: _sortMode,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: _SortMode.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.label,
                            style: AppTextStyles.bodySmall),
                      ))
                  .toList(),
              onChanged: (m) {
                if (m != null) setState(() => _sortMode = m);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Etat vide : illustration + texte + bouton "Commencer a reviser".
  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      // ListView (et non Center) pour garder le RefreshIndicator actif.
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Tu n'as pas encore de favoris",
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Tap sur le coeur d'une question pendant ta revision "
                  'pour l\'ajouter ici.',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Commencer a reviser'),
                onPressed: () => context.go(
                  '${AppRoutes.revision}/${Uri.encodeComponent('Mathematiques')}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paire (FavoriteQuestion + Question) pour eviter les lookups repetes
/// lors du tri/filtre.
class _FavPair {
  final FavoriteQuestion favorite;
  final Question question;
  const _FavPair(this.favorite, this.question);
}

/// Chip de filtre matiere reutilisable.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
