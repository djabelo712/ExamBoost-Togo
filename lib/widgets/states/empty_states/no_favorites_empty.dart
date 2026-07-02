// lib/widgets/states/empty_states/no_favorites_empty.dart
// Empty state : aucun favori.
//
// Cas d'usage : onglet "Favoris" du profil ou de l'ecran de revision.
//
// Bouton "Commencer a reviser" : navigue vers la selection de matiere.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../empty_state.dart';

class NoFavoritesEmpty extends StatelessWidget {
  /// Callback du bouton "Commencer a reviser".
  final VoidCallback? onStartRevision;

  const NoFavoritesEmpty({
    super.key,
    this.onStartRevision,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.favorite_border,
      iconColor: AppColors.error, // rouge leger pour le coeur
      title: "Tu n'as pas encore de favoris",
      description: "Tap sur le cœur d'une question pendant ta révision "
          "pour l'ajouter ici.",
      actionLabel: 'Commencer à réviser',
      onAction: onStartRevision,
    );
  }
}
