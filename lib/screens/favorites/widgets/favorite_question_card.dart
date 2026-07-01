// lib/screens/favorites/widgets/favorite_question_card.dart
// Carte affichant une question favorite dans la liste FavoritesScreen.
//
// Layout :
//   - Ligne superieure : extrait de l'enonce (60 caracteres) + icone
//     coeur rouge plein (tap = retirer des favoris) + icone note (si
//     une note existe, tap = ouvrir NoteEditorSheet).
//   - Ligne inferieure : chips matiere + examen + annee + bouton
//     "Reviser" (rouute /revision/<matiere encodee>).
//   - Long press : menu contextuel (Retirer des favoris, Ajouter une
//     note, Voir details).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/question.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_router.dart';
import '../models/favorite_question.dart';
import '../models/question_note.dart';
import '../services/favorites_service.dart';
import 'note_editor_sheet.dart';

class FavoriteQuestionCard extends StatelessWidget {
  final FavoriteQuestion favorite;
  final Question question;
  final String userId;

  /// Callback optionnel pour ouvrir les details de la question
  /// (laissée a la discretion du parent : navigation vers revision,
  /// ouverture d'une bottom sheet de details, etc.).
  final VoidCallback? onShowDetails;

  const FavoriteQuestionCard({
    super.key,
    required this.favorite,
    required this.question,
    required this.userId,
    this.onShowDetails,
  });

  String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max).trim()}...';
  }

  void _openNoteEditor(BuildContext context, {QuestionNote? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorSheet(
        questionId: question.id,
        userId: userId,
        existingNote: existing,
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final service = Provider.of<FavoritesService>(context, listen: false);
    final existing = service.getNote(userId, question.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Actions',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Retirer des favoris'),
              onTap: () {
                Navigator.pop(sheetCtx);
                service.toggleFavorite(userId, question.id);
              },
            ),
            ListTile(
              leading: Icon(
                existing == null ? Icons.note_add : Icons.edit,
                color: AppColors.primary,
              ),
              title: Text(existing == null
                  ? 'Ajouter une note'
                  : 'Modifier la note'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openNoteEditor(context, existing: existing);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Voir les details'),
              onTap: () {
                Navigator.pop(sheetCtx);
                if (onShowDetails != null) {
                  onShowDetails!();
                } else {
                  // Par defaut : ouvrir la revision de cette matiere.
                  context.go(
                    '${AppRoutes.revision}/${Uri.encodeComponent(question.matiere)}',
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FavoritesService>(context);
    final existing = service.getNote(userId, question.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showContextMenu(context),
        onTap: () => context.go(
          '${AppRoutes.revision}/${Uri.encodeComponent(question.matiere)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Ligne 1 : extrait enonce + actions ───────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _truncate(question.enonce, 60),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Icône coeur rouge plein = tap pour retirer.
                  IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.error),
                    tooltip: 'Retirer des favoris',
                    onPressed: () =>
                        service.toggleFavorite(userId, question.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    splashRadius: 18,
                  ),
                  // Icone note (bleu si note existante, gris sinon).
                  IconButton(
                    icon: Icon(
                      existing == null
                          ? Icons.note_add_outlined
                          : Icons.sticky_note_2,
                      color: existing == null
                          ? AppColors.textSecondary
                          : AppColors.info,
                    ),
                    tooltip: existing == null
                        ? 'Ajouter une note'
                        : 'Modifier la note',
                    onPressed: () =>
                        _openNoteEditor(context, existing: existing),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    splashRadius: 18,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ─── Ligne 2 : chips meta + bouton Reviser ────────────
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MetaChip(
                    label: question.matiere,
                    color: AppColors.primary,
                    background: AppColors.primarySurface,
                  ),
                  _MetaChip(
                    label: question.examen,
                    color: AppColors.accent,
                    background: AppColors.accentSurface,
                  ),
                  if (question.annee != null)
                    _MetaChip(
                      label: '${question.annee}',
                      color: AppColors.textSecondary,
                      background: AppColors.surfaceVariant,
                    ),
                  if (existing != null)
                    _MetaChip(
                      label: NoteCategory.byId(existing.category).label,
                      color: NoteCategory.byId(existing.category).color,
                      background: NoteCategory.byId(existing.category).color
                          .withOpacity(0.12),
                      icon: NoteCategory.byId(existing.category).icon,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ─── Bouton "Reviser" ──────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text('Reviser'),
                  onPressed: () => context.go(
                    '${AppRoutes.revision}/${Uri.encodeComponent(question.matiere)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Petit chip meta avec couleur de fond + texte colore.
class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const _MetaChip({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
