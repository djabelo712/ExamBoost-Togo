// lib/screens/favorites/widgets/note_editor_sheet.dart
// Bottom sheet pour creer ou editer une note personnelle sur une question.
//
// Layout :
//   - AppBar : "Ajouter une note" / "Modifier la note"
//   - TextField multiligne (max 500 caracteres, compteur visible)
//   - Section "Categorie" : 4 ChoiceChip colores (yellow/green/blue/pink)
//   - Bouton "Supprimer" (si edit d'une note existante)
//   - Bouton "Sauvegarder" (disabled si texte vide)
//   - Bouton "Annuler"
//
// Usage :
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (_) => NoteEditorSheet(
//       questionId: question.id,
//       userId: userProvider.currentUserId,
//       existingNote: service.getNote(userId, questionId),
//     ),
//   );

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../models/question_note.dart';
import '../services/favorites_service.dart';

class NoteEditorSheet extends StatefulWidget {
  final String questionId;
  final String userId;

  /// Si non null, on est en mode "edition" (prefill + bouton supprimer).
  /// Si null, on est en mode "creation".
  final QuestionNote? existingNote;

  const NoteEditorSheet({
    super.key,
    required this.questionId,
    required this.userId,
    this.existingNote,
  });

  /// Convenience : true si on edite une note existante.
  bool get isEditing => existingNote != null;

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  static const int _maxChars = 500;

  late final TextEditingController _controller;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingNote?.content ?? '');
    _selectedCategory = widget.existingNote?.category ?? 'yellow';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave => _controller.text.trim().isNotEmpty;

  Future<void> _save() async {
    final service = Provider.of<FavoritesService>(context, listen: false);
    await service.saveNote(
      userId: widget.userId,
      questionId: widget.questionId,
      content: _controller.text,
      color: _selectedCategory,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    // Confirmation avant suppression (destructif).
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la note ?'),
        content: const Text(
          'Cette action est irreversible. Tu pourras recreer une note '
          'plus tard si besoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final service = Provider.of<FavoritesService>(context, listen: false);
    await service.deleteNote(widget.userId, widget.questionId);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // Padding bottom pour ne pas etre cache par le clavier.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // AppBar integrée (BottomSheet n'a pas d'AppBar native).
          body: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Poignée de drag ─────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ─── En-tête (titre + bouton fermer) ────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Icon(
                        widget.isEditing
                            ? Icons.edit_note
                            : Icons.note_add,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.isEditing
                              ? 'Modifier la note'
                              : 'Ajouter une note',
                          style: AppTextStyles.h3,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(false),
                        tooltip: 'Annuler',
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ─── Corps scrollable ────────────────────────────────
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    children: [
                      // TextField multiligne + compteur.
                      TextField(
                        controller: _controller,
                        maxLength: _maxChars,
                        maxLines: 6,
                        minLines: 4,
                        autofocus: !widget.isEditing,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText:
                              'Ecris ton astuce, ta remarque, ta question...\n'
                              'Ex : "Factoriser d\'abord par x-2 avant developpement."',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // ─── Section "Categorie" ─────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Categorie',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: NoteCategory.all.map((cat) {
                          final selected = _selectedCategory == cat.id;
                          return _CategoryChip(
                            category: cat,
                            selected: selected,
                            onTap: () =>
                                setState(() => _selectedCategory = cat.id),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // ─── Barre d'actions bas ─────────────────────────────
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      if (widget.isEditing) ...[
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          label: const Text('Supprimer',
                              style: TextStyle(color: AppColors.error)),
                          onPressed: _delete,
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Sauvegarder'),
                        onPressed: _canSave ? _save : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.divider,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ChoiceChip colore pour la selection de categorie.
class _CategoryChip extends StatelessWidget {
  final NoteCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? category.color : category.color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? category.color
                  : category.color.withOpacity(0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 16,
                color: selected ? Colors.white : category.color,
              ),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : category.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
