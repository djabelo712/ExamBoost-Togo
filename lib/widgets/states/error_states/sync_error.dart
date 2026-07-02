// lib/widgets/states/error_states/sync_error.dart
// Error state : synchronisation cloud impossible.
//
// Cas d'usage : le SyncService (Agent AC) n'arrive pas a pousser les actions
// en file d'attente vers le backend, ou la pull echoue.
//
// Comportement :
//   - Bouton "Forcer la sync" : declenche syncNow() manuellement
//   - Lien "Voir le statut" : ouvre l'ecran de settings sync
//     (lib/screens/settings/sync_settings_screen.dart)
//
// Note : cet etat est NON bloquant — les donnees restent disponibles
// localement (offline-first). L'icone est orange (warning) plutot que rouge.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../error_state.dart';

class SyncError extends StatelessWidget {
  /// Callback du bouton "Forcer la sync".
  final VoidCallback? onForceSync;

  /// Callback du lien "Voir le statut".
  final VoidCallback? onViewStatus;

  const SyncError({
    super.key,
    this.onForceSync,
    this.onViewStatus,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.cloud_off,
      iconColor: AppColors.warning, // orange (non bloquant)
      message: 'Synchronisation impossible',
      description: "Tes données seront synchronisées quand le réseau "
          "sera de retour.",
      onRetry: onForceSync,
      retryLabel: 'Forcer la sync',
      secondaryActionLabel: onViewStatus != null ? 'Voir le statut' : null,
      onSecondaryAction: onViewStatus,
    );
  }
}
