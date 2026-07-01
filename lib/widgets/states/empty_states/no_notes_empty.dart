// lib/widgets/states/empty_states/no_notes_empty.dart
// Empty state : aucune note personnelle.
//
// Cas d'usage : onglet "Notes" du profil.
//
// Bouton "Voir mes questions" : navigue vers l'historique de questions
// revisees (pour permettre d'ajouter une note sur une question passe).

import 'package:flutter/material.dart';

import '../empty_state.dart';

class NoNotesEmpty extends StatelessWidget {
  /// Callback du bouton "Voir mes questions".
  final VoidCallback? onViewQuestions;

  const NoNotesEmpty({
    super.key,
    this.onViewQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.note_add,
      title: 'Aucune note pour le moment',
      description: "Ajoute des notes personnalisées sur les questions "
          "pour mémoriser tes astuces.",
      actionLabel: 'Voir mes questions',
      onAction: onViewQuestions,
    );
  }
}
