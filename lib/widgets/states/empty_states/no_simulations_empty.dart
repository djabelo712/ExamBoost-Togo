// lib/widgets/states/empty_states/no_simulations_empty.dart
// Empty state : aucune simulation terminee.
//
// Cas d'usage : onglet "Simulations" / historique des examens blancs.
//
// Bouton "Demarrer une simulation" : ouvre le choix de matiere / duree
// pour lancer un examen blanc.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../empty_state.dart';

class NoSimulationsEmpty extends StatelessWidget {
  /// Callback du bouton "Demarrer une simulation".
  final VoidCallback? onStartSimulation;

  const NoSimulationsEmpty({
    super.key,
    this.onStartSimulation,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.timer_off,
      iconColor: AppColors.accent, // orange (examen)
      title: 'Aucune simulation terminée',
      description: "Lance ta première simulation pour voir ton niveau !",
      actionLabel: 'Démarrer une simulation',
      onAction: onStartSimulation,
    );
  }
}
