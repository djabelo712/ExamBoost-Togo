// lib/widgets/states/empty_states/no_questions_empty.dart
// Empty state : aucune question disponible pour une matiere.
//
// Cas d'usage : ecran de revision avec une matiere qui n'a pas encore de
// questions dans le JSON (ex: matiere non couverte par le pipeline OCR).
//
// Bouton "Choisir une autre matiere" : navigue vers la liste des matieres.

import 'package:flutter/material.dart';

import '../empty_state.dart';

class NoQuestionsEmpty extends StatelessWidget {
  /// Callback du bouton "Choisir une autre matiere".
  /// Si null, le bouton est desactive.
  final VoidCallback? onChooseMatiere;

  /// Nom de la matiere (optionnel, insere dans la description pour le
  /// contexte).
  final String? matiere;

  const NoQuestionsEmpty({
    super.key,
    this.onChooseMatiere,
    this.matiere,
  });

  @override
  Widget build(BuildContext context) {
    final desc = matiere != null
        ? "Pas encore de questions pour « $matiere ». Reviens bientôt, "
            "notre équipe en ajoute régulièrement !"
        : "Pas encore de questions pour cette matière. Reviens bientôt !";

    return EmptyState(
      icon: Icons.inbox,
      title: 'Aucune question disponible',
      description: desc,
      actionLabel: 'Choisir une autre matière',
      onAction: onChooseMatiere,
    );
  }
}
