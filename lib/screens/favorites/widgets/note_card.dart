// lib/screens/favorites/widgets/note_card.dart
// Carte affichant une note personnelle dans la liste NotesScreen.
//
// Layout :
//   - Bande coloree a gauche (selon la categorie de la note).
//   - Texte de la note (max 4 lignes en resume, expandable via tap).
//   - Date "il y a 3 jours" (format relatif humain).
//   - Extrait de la question associee (recuperee via QuestionService.getById).
//   - Tap : ouvre la question en revision (route /revision/<matiere>).
//   - Long press : menu (Modifier, Supprimer).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/question.dart';
import '../../../services/question_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_router.dart';
import '../models/question_note.dart';
import '../services/favorites_service.dart';
import 'note_editor_sheet.dart';

class NoteCard extends StatelessWidget {
  final QuestionNote note;
  final String userId;

  /// Question associee a la note. Peut etre null si la question a ete
  /// supprimee de la banque entre-temps (auquel cas on affiche l'ID).
  final Question? question;

  const NoteCard({
    super.key,
    required this.note,
    required this.userId,
    required this.question,
  });

  /// Format relatif : "il y a 3 jours", "il y a 2 h", "a l'instant".
  String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inSeconds < 60) return 'a l\'instant';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'il y a $m min';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'il y a $h h';
    }
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) {
      final j = diff.inDays;
      return 'il y a $j jours';
    }
    if (diff.inDays < 30) {
      final sem = (diff.inDays / 7).floor();
      return 'il y a $sem sem.';
    }
    // Au-dela, on affiche la date brute JJ/MM/AAAA.
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max).trim()}...';
  }

  void _openEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorSheet(
        questionId: note.questionId,
        userId: userId,
        existingNote: note,
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final service = Provider.of<FavoritesService>(context, listen: false);
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
                'Actions sur la note',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openEditor(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Supprimer'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer la note ?'),
                    content: const Text('Cette action est irreversible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await service.deleteNote(userId, note.questionId);
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
    final cat = NoteCategory.byId(note.category);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showContextMenu(context),
        onTap: () {
          // Si la question est connue, on ouvre la revision de sa matiere.
          if (question != null) {
            context.go(
              '${AppRoutes.revision}/${Uri.encodeComponent(question!.matiere)}',
            );
          }
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Bande coloree gauche ──────────────────────────────
              Container(
                width: 6,
                color: cat.color,
              ),

              // ─── Corps de la carte ─────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tete : icone + label categorie + date relative
                      Row(
                        children: [
                          Icon(cat.icon, size: 14, color: cat.color),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cat.color,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _relativeDate(note.updatedAt),
                            style: AppTextStyles.bodySmall
                                .copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Texte de la note
                      Text(
                        note.content,
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Extrait de la question associee
                      if (question != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.link,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Question :',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${question!.matiere} - ${question!.examen}${question!.annee != null ? " ${question!.annee}" : ""}',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _truncate(question!.enonce, 80),
                                style: AppTextStyles.bodySmall
                                    .copyWith(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Question introuvable dans la banque.
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                size: 14,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Question introuvable (ID: ${note.questionId})',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
