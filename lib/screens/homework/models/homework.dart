// lib/screens/homework/models/homework.dart
// Modèle Devoir assigné par un enseignant ExamBoost.
//
// Un devoir est une sélection de questions (issues de la banque ou créées
// ad-hoc par le professeur) qu'un ou plusieurs classes doivent réaliser
// avant une date limite. Chaque devoir est noté sur un total de points
// (somme des points des questions).
//
// Le modèle est volontairement autonome par rapport au `Question` global
// (lib/models/question.dart) pour permettre :
//   - la sélection d'un sous-ensemble de questions par le prof,
//   - l'ajout de questions "libres" non présentes dans la banque,
//   - l'usage hors-ligne sans dépendre de Hive (persistance mock).
//
// A brancher plus tard sur un vrai backend FastAPI (POST /homeworks).

import 'package:flutter/material.dart';

/// Statut d'un devoir vu du côté élève.
enum HomeworkStatus {
  /// Pas encore commencé, deadline non dépassée.
  aFaire,

  /// Commencé mais pas terminé (l'élève peut reprendre).
  enCours,

  /// Terminé et soumis avant la deadline.
  rendu,

  /// Deadline dépassée sans soumission.
  manque,
}

/// Statut d'un devoir vu du côté enseignant (cycle de vie global).
enum HomeworkLifecycle {
  brouillon, // créé mais pas encore publié aux élèves
  publie, // visible par les élèves, deadline future
  clos, // deadline passée, corrections en cours
  archive, // corrigé, plus d'action possible
}

/// Question individuelle incluse dans un devoir.
///
/// Plus simple que le `Question` global : on ne garde que ce qui sert
/// pour l'évaluation (énoncé, choix QCM, bonne réponse, points,
/// explication pédagogique affichée à l'élève pendant l'auto-correction).
class HomeworkQuestion {
  final String id;
  final String enonce;

  /// QCM : liste des propositions. Ouvert/Calcul : null.
  final List<String>? choix;

  /// Index de la bonne réponse dans `choix` (QCM).
  /// Pour question ouverte : réponse attendue (chaîne libre, comparaison
  /// souple lors de l'auto-correction).
  final int? bonIndex;
  final String? bonneReponseOuverte;

  /// Barème (points). Par défaut 1 point.
  final int points;

  /// Explication affichée après réponse (auto-correction).
  final String? explication;

  /// Compétence associée (pour alimentation BKT plus tard).
  final String? competenceId;

  const HomeworkQuestion({
    required this.id,
    required this.enonce,
    this.choix,
    this.bonIndex,
    this.bonneReponseOuverte,
    this.points = 1,
    this.explication,
    this.competenceId,
  });

  /// true si la question est un QCM (choix + bon index).
  bool get isQcm => choix != null && choix!.isNotEmpty && bonIndex != null;

  /// Conversion en Map (pour export CSV / sérialisation JSON future).
  Map<String, dynamic> toMap() => {
        'id': id,
        'enonce': enonce,
        'choix': choix,
        'bon_index': bonIndex,
        'bonne_reponse_ouverte': bonneReponseOuverte,
        'points': points,
        'explication': explication,
        'competence_id': competenceId,
      };
}

/// Modèle principal d'un devoir.
class Homework {
  final String id;
  final String titre;
  final String description;
  final String matiere;

  /// Classes ciblées (ex : ['3e A', '3e B']).
  final List<String> classes;

  /// Enseignant qui a créé le devoir (id ou nom affichable).
  final String enseignantId;
  final String enseignantNom;

  /// Dates clés.
  final DateTime dateCreation;
  final DateTime dateLimit;

  /// Questions sélectionnées par l'enseignant.
  final List<HomeworkQuestion> questions;

  /// Cycle de vie global (côté enseignant).
  final HomeworkLifecycle lifecycle;

  /// Durée conseillée en minutes (information élève).
  final int dureeMinutes;

  const Homework({
    required this.id,
    required this.titre,
    required this.description,
    required this.matiere,
    required this.classes,
    required this.enseignantId,
    required this.enseignantNom,
    required this.dateCreation,
    required this.dateLimit,
    required this.questions,
    this.lifecycle = HomeworkLifecycle.publie,
    this.dureeMinutes = 30,
  });

  /// Total des points du devoir (somme des barèmes).
  int get pointsTotal =>
      questions.fold(0, (sum, q) => sum + q.points);

  /// Nombre de questions.
  int get nbQuestions => questions.length;

  /// true si la deadline est dépassée.
  bool get isDeadlineDepassee => DateTime.now().isAfter(dateLimit);

  /// Couleur sémantique associée à la matière (cohérence visuelle
  /// avec le reste de l'app : vert Maths, bleu Sciences, etc.).
  Color get matiereColor {
    switch (matiere) {
      case 'Mathématiques':
        return const Color(0xFF006837); // vert Togo
      case 'Français':
        return const Color(0xFFC62828); // rouge
      case 'Sciences Physiques':
        return const Color(0xFF1565C0); // bleu
      case 'SVT':
        return const Color(0xFF2E7D32); // vert clair
      case 'Histoire-Géographie':
        return const Color(0xFFD97700); // orange
      default:
        return const Color(0xFF757575); // gris
    }
  }

  /// Icône représentative de la matière.
  IconData get matiereIcon {
    switch (matiere) {
      case 'Mathématiques':
        return Icons.calculate_outlined;
      case 'Français':
        return Icons.menu_book_outlined;
      case 'Sciences Physiques':
        return Icons.science_outlined;
      case 'SVT':
        return Icons.biotech_outlined;
      case 'Histoire-Géographie':
        return Icons.public_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  /// Statut élève calculé à partir d'une soumission existante.
  HomeworkStatus statutPourEleve({bool? aRendu, bool? enCours}) {
    if (aRendu == true) return HomeworkStatus.rendu;
    if (isDeadlineDepassee) return HomeworkStatus.manque;
    if (enCours == true) return HomeworkStatus.enCours;
    return HomeworkStatus.aFaire;
  }

  /// Conversion en Map (export CSV / JSON future API).
  Map<String, dynamic> toMap() => {
        'id': id,
        'titre': titre,
        'description': description,
        'matiere': matiere,
        'classes': classes,
        'enseignant_id': enseignantId,
        'enseignant_nom': enseignantNom,
        'date_creation': dateCreation.toIso8601String(),
        'date_limit': dateLimit.toIso8601String(),
        'questions': questions.map((q) => q.toMap()).toList(),
        'lifecycle': lifecycle.name,
        'duree_minutes': dureeMinutes,
      };
}
