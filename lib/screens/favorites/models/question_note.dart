// lib/screens/favorites/models/question_note.dart
// Model Hive : note personnelle ajoutee par un eleve sur une question.
//
// Une entree = (id, userId, questionId, content, createdAt, updatedAt, color).
// La note est unique par couple (userId, questionId) : la re-edition ecrase
// le contenu existant (voir FavoritesService.saveNote).
//
// Le champ `color` est une categorie visuelle (chaine) parmi :
//   - 'yellow' : "A revoir" (default)
//   - 'green'  : "Compris"
//   - 'blue'   : "Astuce"
//   - 'pink'   : "Question pour le prof"
// On stocke une chaine plutot qu'un enum pour permettre l'extension future
// (nouvelles categories) sans casser la compatibilite Hive.
//
// TypeId 16 (reserve pour ce modele).

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'question_note.g.dart';

@HiveType(typeId: 16)
class QuestionNote extends HiveObject {
  /// Identifiant UUID v4 de la note (genere a la creation).
  @HiveField(0)
  final String id;

  /// Identifiant de l'eleve proprietaire de la note.
  @HiveField(1)
  final String userId;

  /// Identifiant de la question associee.
  @HiveField(2)
  final String questionId;

  /// Texte libre de la note (max 500 caracteres cote UI).
  /// Mutable : modifie a chaque edition dans NoteEditorSheet.
  @HiveField(3)
  String content;

  /// Date de creation (jamais modifiee).
  @HiveField(4)
  final DateTime createdAt;

  /// Date de derniere modification (utilisee pour le tri "Plus recents"
  /// dans NotesScreen).
  @HiveField(5)
  DateTime updatedAt;

  /// Categorie visuelle : 'yellow' | 'green' | 'blue' | 'pink'.
  /// Voir NoteCategoryHelper pour la correspondance couleur/label.
  @HiveField(6)
  String? color;

  QuestionNote({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.color = 'yellow',
  });

  /// Raccourci : couleur categorielle normalisee (jamais null).
  String get category => (color == null || color!.isEmpty) ? 'yellow' : color!;
}

/// Helper pour les categories de notes.
/// Centralise la correspondance (id, label, couleur Material, icone).
/// Permet de garder une source de verite unique entre NoteEditorSheet,
/// NoteCard et NotesScreen.
class NoteCategory {
  final String id;
  final String label;
  final Color color;
  final IconData icon;

  const NoteCategory._({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
  });

  static const NoteCategory yellow = NoteCategory._(
    id: 'yellow',
    label: 'A revoir',
    color: Color(0xFFF57C00), // AppColors.warning
    icon: Icons.visibility_outlined,
  );

  static const NoteCategory green = NoteCategory._(
    id: 'green',
    label: 'Compris',
    color: Color(0xFF2E7D32), // AppColors.success
    icon: Icons.check_circle_outline,
  );

  static const NoteCategory blue = NoteCategory._(
    id: 'blue',
    label: 'Astuce',
    color: Color(0xFF1565C0), // AppColors.info
    icon: Icons.lightbulb_outline,
  );

  static const NoteCategory pink = NoteCategory._(
    id: 'pink',
    label: 'Question pour le prof',
    color: Color(0xFFD81B60),
    icon: Icons.help_outline,
  );

  /// Liste ordonnee des categories (l'ordre defini l'affichage dans
  /// NoteEditorSheet et le filtre de NotesScreen).
  static const List<NoteCategory> all = [
    yellow,
    green,
    blue,
    pink,
  ];

  /// Recupere la categorie par id, avec fallback sur 'yellow'.
  static NoteCategory byId(String? id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return yellow;
  }
}
