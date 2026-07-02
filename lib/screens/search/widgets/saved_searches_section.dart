// lib/screens/search/widgets/saved_searches_section.dart
// Section "Recherches sauvegardees" + "Suggestions" affichee sur l'ecran
// de recherche quand aucune recherche n'est active.
//
// Contenu :
//   1. Section "Recherches sauvegardees" :
//      - Pour chaque SavedSearch : card avec nom + chips resume filtres +
//        nb resultats + date. Tap -> execute la recherche (callback).
//        Long press -> menu contextuel (renommer, supprimer).
//      - Si vide : message "Aucune recherche sauvegardee. Lance une recherche
//        et touche l'etoile pour la garder sous la main."
//
//   2. Section "Suggestions" :
//      - 6 questions "populaires" (tirage pseudo-aleatoire avec seed fixe
//        pour stabilite entre les runs — voir SearchService.getPopularQuestions)
//      - Tap sur une question -> ouvre QuestionDetailBottomSheet (callback)
//
// Le widget est stateful pour charger la liste des SavedSearch (async Hive)
// au initState.

import 'package:flutter/material.dart';

import '../../../models/question.dart';
import '../../../theme/app_theme.dart';
import '../models/saved_search.dart';

class SavedSearchesSection extends StatefulWidget {
  const SavedSearchesSection({
    super.key,
    required this.savedSearchesFetcher,
    required this.popularQuestions,
    required this.onRunSavedSearch,
    required this.onRenameSavedSearch,
    required this.onDeleteSavedSearch,
    required this.onQuestionTap,
  });

  /// Retourne la liste des recherches sauvegardees (depuis SearchService).
  final Future<List<SavedSearch>> Function() savedSearchesFetcher;

  /// Liste de questions populaires pre-chargees par SearchService.
  final List<Question> popularQuestions;

  /// Callback quand l'utilisateur tap sur une recherche sauvegardee.
  final ValueChanged<SavedSearch> onRunSavedSearch;

  /// Callback pour renommer une recherche (apres dialogue).
  /// Recoit la SavedSearch a renommer et le nouveau nom.
  final void Function(SavedSearch saved, String newName) onRenameSavedSearch;

  /// Callback pour supprimer une recherche.
  final ValueChanged<SavedSearch> onDeleteSavedSearch;

  /// Callback quand l'utilisateur tap sur une question populaire.
  final ValueChanged<Question> onQuestionTap;

  @override
  State<SavedSearchesSection> createState() => _SavedSearchesSectionState();
}

class _SavedSearchesSectionState extends State<SavedSearchesSection> {
  List<SavedSearch>? _saved;

  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    try {
      final list = await widget.savedSearchesFetcher();
      if (mounted) setState(() => _saved = list);
    } catch (_) {
      if (mounted) setState(() => _saved = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSavedSearches,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ─── Section 1 : Recherches sauvegardees ─────────────────
          _SectionHeader(
            title: 'Recherches sauvegardees',
            icon: Icons.star,
            iconColor: AppColors.accent,
          ),
          const SizedBox(height: 10),
          _buildSavedSearches(),
          const SizedBox(height: 28),

          // ─── Section 2 : Suggestions ──────────────────────────────
          _SectionHeader(
            title: 'Suggestions populaires',
            icon: Icons.local_fire_department,
            iconColor: AppColors.difficile,
          ),
          const SizedBox(height: 10),
          _buildPopularQuestions(),
        ],
      ),
    );
  }

  Widget _buildSavedSearches() {
    if (_saved == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_saved!.isEmpty) {
      return _EmptyHint(
        icon: Icons.star_border,
        message:
            'Aucune recherche sauvegardee. Lance une recherche et touche '
            'le bouton etoile en bas pour la garder sous la main.',
      );
    }
    return Column(
      children: _saved!.map((s) {
        return _SavedSearchCard(
          saved: s,
          onTap: () => widget.onRunSavedSearch(s),
          onLongPress: () => _showActionsMenu(s),
        );
      }).toList(),
    );
  }

  Widget _buildPopularQuestions() {
    if (widget.popularQuestions.isEmpty) {
      return const _EmptyHint(
        icon: Icons.inbox,
        message: 'Aucune question disponible pour le moment.',
      );
    }
    return Column(
      children: widget.popularQuestions.map((q) {
        return _PopularQuestionTile(
          question: q,
          onTap: () => widget.onQuestionTap(q),
        );
      }).toList(),
    );
  }

  void _showActionsMenu(SavedSearch saved) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                saved.name,
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Renommer'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(saved);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Supprimer',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteDialog(saved);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(SavedSearch saved) {
    final controller = TextEditingController(text: saved.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer la recherche'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                widget.onRenameSavedSearch(saved, newName);
                Navigator.pop(ctx);
                // Optimistic : on met a jour local apres callback.
                setState(() {
                  final i = _saved?.indexWhere((s) => s.id == saved.id);
                  if (i != null && i >= 0 && _saved != null) {
                    _saved![i] = saved.copyWith(name: newName);
                  }
                });
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(SavedSearch saved) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la recherche ?'),
        content: Text(
          'Veux-tu vraiment supprimer "${saved.name}" ? Cette action est '
          'irreversible.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.onDeleteSavedSearch(saved);
              Navigator.pop(ctx);
              setState(() {
                _saved?.removeWhere((s) => s.id == saved.id);
              });
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ─── Composants internes ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.h3.copyWith(fontSize: 16)),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textDisabled),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SavedSearchCard extends StatelessWidget {
  const _SavedSearchCard({
    required this.saved,
    required this.onTap,
    required this.onLongPress,
  });

  final SavedSearch saved;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.accent, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      saved.name,
                      style: AppTextStyles.h3.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${saved.resultCount}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'res.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (saved.filterLabels.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: saved.filterLabels.take(4).map((l) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.primary, fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 6),
              Text(
                'Cree le ${saved.createdAt.day.toString().padLeft(2, '0')}/${saved.createdAt.month.toString().padLeft(2, '0')}/${saved.createdAt.year}',
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 11, color: AppColors.textDisabled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularQuestionTile extends StatelessWidget {
  const _PopularQuestionTile({required this.question, required this.onTap});

  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.book_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          question.matiere,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (question.annee != null)
                          Text(
                            '${question.examen} ${question.annee}',
                            style: AppTextStyles.bodySmall
                                .copyWith(fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.enonce,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
