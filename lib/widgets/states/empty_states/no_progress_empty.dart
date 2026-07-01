// lib/widgets/states/empty_states/no_progress_empty.dart
// Empty state : pas encore de progression.
//
// Cas d'usage : dashboard pour un nouvel utilisateur sans BKT ni ReviewCard.
//
// Bouton "Demarrer ma premiere revision" : navigue vers la revision de la
// matiere par defaut (Mathematiques).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../empty_state.dart';

class NoProgressEmpty extends StatelessWidget {
  /// Callback du bouton "Demarrer ma premiere revision".
  final VoidCallback? onStartFirstRevision;

  const NoProgressEmpty({
    super.key,
    this.onStartFirstRevision,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.trending_up,
      iconColor: AppColors.primary,
      title: 'Pas encore de progression',
      description: "Commence à réviser pour voir tes statistiques "
          "apparaître ici.",
      actionLabel: 'Démarrer ma première révision',
      onAction: onStartFirstRevision,
    );
  }
}
