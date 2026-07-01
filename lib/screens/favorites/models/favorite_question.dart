// lib/screens/favorites/models/favorite_question.dart
// Model Hive : question marquee comme favorite par un eleve.
//
// Une entree = (userId, questionId, addedAt). On garde la date d'ajout
// pour pouvoir trier les favoris par ordre chronologique.
//
// TypeId 15 (reserve pour ce modele — aucun conflit avec les autres
// HiveType deja declares dans le projet : 0=Question, 1=QuestionType,
// 2=ReviewCard, 3=AppUser, 5..13 autres models).

import 'package:hive/hive.dart';

part 'favorite_question.g.dart';

@HiveType(typeId: 15)
class FavoriteQuestion extends HiveObject {
  /// Identifiant de l'eleve (cle Hive box "users").
  @HiveField(0)
  final String userId;

  /// Identifiant de la question (cle dans la banque QuestionService).
  /// Format attendu : "TG-BEPC-MATHS-2022-Q01".
  @HiveField(1)
  final String questionId;

  /// Date a laquelle la question a ete marquee comme favorite.
  /// Sert au tri "Plus recents" dans FavoritesScreen.
  @HiveField(2)
  final DateTime addedAt;

  FavoriteQuestion({
    required this.userId,
    required this.questionId,
    required this.addedAt,
  });

  /// Cle metier unique (userId + questionId) pour dedoublonner cote UI.
  /// Note : Hive attribue sa propre cle auto-incrementee (key), on n'en
  /// depend pas pour la logique metier afin de pouvoir regenerer la box
  /// sans perte de donnees.
  String get businessKey => '${userId}__${questionId}';
}
