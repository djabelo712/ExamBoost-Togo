// lib/widgets/states/error_states/generic_error.dart
// Error state : erreur inattendue (fallback).
//
// Cas d'usage : erreur non identifiee — exception non geree, parsing JSON
// corrompu, etat d'application incoherent...
//
// Comportement :
//   - Bouton "Reessayer" : relance l'operation
//   - Code erreur technique optionnel (affiche en gris petit)
//   - Lien "Contacter le support" : ouvre l'email support

import 'package:flutter/material.dart';

import '../error_state.dart';

class GenericError extends StatelessWidget {
  /// Callback du bouton "Reessayer".
  final VoidCallback? onRetry;

  /// Callback du lien "Contacter le support".
  final VoidCallback? onContactSupport;

  /// Message d'erreur specifique (si fourni). Sinon, message par defaut.
  final String? message;

  /// Description detaillee (si fournie). Sinon, description par defaut.
  final String? description;

  /// Code erreur technique (ex: "JSON_PARSE_ERROR", "NULL_POINTER").
  final String? errorCode;

  const GenericError({
    super.key,
    this.onRetry,
    this.onContactSupport,
    this.message,
    this.description,
    this.errorCode,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.error_outline,
      message: message ?? 'Une erreur est survenue',
      description: description ??
          "Erreur inattendue. Réessaie ou contacte le support si ça "
              "persiste.",
      onRetry: onRetry,
      retryLabel: 'Réessayer',
      errorCode: errorCode,
      secondaryActionLabel:
          onContactSupport != null ? 'Contacter le support' : null,
      onSecondaryAction: onContactSupport,
    );
  }
}
