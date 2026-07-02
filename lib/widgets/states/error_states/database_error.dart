// lib/widgets/states/error_states/database_error.dart
// Error state : erreur de base de donnees (Hive / SQLite).
//
// Cas d'usage : impossible d'ouvrir une Hive box, adapter non enregistre,
// corruption de donnees,erreur de lecture SQLite...
//
// Comportement :
//   - Bouton "Reessayer" : relance l'operation
//   - Lien "Signaler le bug" : ouvre l'ecran de support / email

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../error_state.dart';

class DatabaseError extends StatelessWidget {
  /// Callback du bouton "Reessayer".
  final VoidCallback? onRetry;

  /// Callback du lien "Signaler le bug".
  final VoidCallback? onReportBug;

  /// Code erreur technique (ex: "HIVE_ADAPTER_NOT_REGISTERED",
  /// "DB_READ_FAILED"). Affiche en gris petit sous le message.
  final String? errorCode;

  const DatabaseError({
    super.key,
    this.onRetry,
    this.onReportBug,
    this.errorCode,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.storage,
      iconColor: AppColors.error, // rouge (erreur bloquante)
      message: 'Erreur de base de données',
      description: "Impossible d'accéder à tes données. Réessaie ou "
          "redémarre l'app.",
      onRetry: onRetry,
      retryLabel: 'Réessayer',
      errorCode: errorCode,
      secondaryActionLabel: onReportBug != null ? 'Signaler le bug' : null,
      onSecondaryAction: onReportBug,
    );
  }
}
