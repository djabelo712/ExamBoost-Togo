// lib/screens/favorites/notes_screen.dart
// Page "Mes notes" : liste de toutes les notes personnelles de l'eleve,
// avec filtres par categorie + par matiere, et bouton "Exporter".
//
// Structure :
//   - Header : titre + compteur + bouton "Exporter"
//   - Filtres : chips par categorie (Toutes / A revoir / Compris /
//               Astuces / Questions prof) PUIS chips par matiere.
//   - Liste   : ListView.builder de NoteCard
//   - Etat vide : illustration + texte + CTA implicite
//
// L'export genere un texte ASCII de toutes les notes (avec enonce de
// la question associee) que l'eleve peut partager via la partage natif
// (Share.sheet, clipboard, etc.). En V1 on se contente d'un dialog
// affichant le texte + bouton "Copier".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/question.dart';
import '../../providers/user_provider.dart';
import '../../services/question_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';
import 'models/question_note.dart';
import 'services/favorites_service.dart';
import 'widgets/note_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  /// Filtre categorie selectionne. 'all' = toutes.
  String _categoryFilter = 'all';

  /// Filtre matiere selectionne. 'all' = toutes.
  String _matiereFilter = 'all';

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

    final allNotes = favService.getAllNotes(userId);

    // ─── Application des filtres ──────────────────────────────────
    var filtered = allNotes.where((n) {
      if (_categoryFilter != 'all' && n.category != _categoryFilter) {
        return false;
      }
      if (_matiereFilter != 'all') {
        final q = questionService.getById(n.questionId);
        if (q == null || q.matiere != _matiereFilter) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: 'Mes favoris',
            onPressed: () => context.go('/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exporter',
            onPressed: filtered.isEmpty
                ? null
                : () => _showExportDialog(context, userId),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: filtered.isEmpty
            ? _buildEmptyState(context, hasNotes: allNotes.isNotEmpty)
            : _buildList(context, filtered, userId, questionService),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<QuestionNote> notes,
    String userId,
    QuestionService questionService,
  ) {
    return CustomScrollView(
      slivers: [
        // ─── Compteur ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                children: [
                  TextSpan(
                    text: '${notes.length}',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const TextSpan(text: ' note'),
                  TextSpan(text: notes.length > 1 ? 's' : ''),
                  const TextSpan(text: ' affichee'),
                  TextSpan(text: notes.length > 1 ? 's' : ''),
                ],
              ),
            ),
          ),
        ),

        // ─── Filtres categorie ──────────────────────────────────────
        SliverToBoxAdapter(child: _buildCategoryFilters()),
        // ─── Filtres matiere ────────────────────────────────────────
        SliverToBoxAdapter(child: _buildMatiereFilters()),

        // ─── Liste des NoteCard ─────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final note = notes[i];
              final q = questionService.getById(note.questionId);
              return NoteCard(note: note, userId: userId, question: q);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final cats = [
      const _CategoryFilter(id: 'all', label: 'Toutes', color: AppColors.textSecondary),
      ...NoteCategory.all.map((c) =>
          _CategoryFilter(id: c.id, label: c.label, color: c.color)),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (var i = 0; i < cats.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _FilterChipColored(
              label: cats[i].label,
              color: cats[i].color,
              selected: _categoryFilter == cats[i].id,
              onTap: () => setState(() => _categoryFilter = cats[i].id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatiereFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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

  void _showExportDialog(BuildContext context, String userId) {
    final favService =
        Provider.of<FavoritesService>(context, listen: false);
    final questionService =
        Provider.of<QuestionService>(context, listen: false);
    final text = favService.exportNotesAsText(
      userId,
      questionLabelResolver: (qid) {
        final q = questionService.getById(qid ?? '');
        return q?.enonce;
      },
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exporter mes notes'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copier'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notes copiees dans le presse-papier'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Etat vide. [hasNotes] permet de differencier "aucune note creee"
  /// (CTA revision) de "aucune note ne correspond aux filtres" (reset).
  Widget _buildEmptyState(BuildContext context, {required bool hasNotes}) {
    return ListView(
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
                  color: AppColors.accentSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 56,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                hasNotes
                    ? 'Aucune note ne correspond a tes filtres'
                    : "Tu n'as pas encore de notes",
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  hasNotes
                      ? 'Essaie d\'elargir tes filtres pour voir plus de notes.'
                      : 'Ajoute des notes personnalisees sur les questions '
                        'pour memoriser tes astuces.',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              if (hasNotes)
                OutlinedButton.icon(
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Reinitialiser les filtres'),
                  onPressed: () => setState(() {
                    _categoryFilter = 'all';
                    _matiereFilter = 'all';
                  }),
                )
              else
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

/// Wrapper interne pour les filtres de categorie.
class _CategoryFilter {
  final String id;
  final String label;
  final Color color;
  const _CategoryFilter({
    required this.id,
    required this.label,
    required this.color,
  });
}

/// Chip de filtre matiere (style sobre).
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

/// Chip de filtre categorie (style colore).
class _FilterChipColored extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipColored({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
