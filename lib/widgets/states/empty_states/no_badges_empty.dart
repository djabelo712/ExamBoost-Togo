// lib/widgets/states/empty_states/no_badges_empty.dart
// Empty state : aucun badge debloque.
//
// Cas d'usage : onglet "Badges" du profil.
//
// Bouton "Commencer a reviser" : navigue vers la selection de matiere
// (le streak de 7 jours est le 1er badge atteignable).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../empty_state.dart';

class NoBadgesEmpty extends StatelessWidget {
  /// Callback du bouton "Commencer a reviser".
  final VoidCallback? onStartRevision;

  const NoBadgesEmpty({
    super.key,
    this.onStartRevision,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.emoji_events_outlined,
      iconColor: AppColors.accent, // orange (trophee)
      title: 'Aucun badge débloqué',
      description: "Continue à réviser pour débloquer ton premier badge ! "
          "Le streak de 7 jours est un bon début.",
      actionLabel: 'Commencer à réviser',
      onAction: onStartRevision,
    );
  }
}
