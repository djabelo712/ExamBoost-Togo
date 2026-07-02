// lib/widgets/states/error_states/network_error.dart
// Error state : pas de connexion Internet.
//
// Cas d'usage : ecran qui necessite un fetch reseau (classement communautaire,
// sync cloud, predictions backend...) et qui echoue car l'appareil est
// hors-ligne.
//
// Comportement :
//   - Bouton "Reessayer" : relance le fetch
//   - Lien "Continuer hors-ligne" : ferme l'ecran ou bascule en mode cache
//
// Note : ExamBoost etant offline-first, beaucoup d'ecrans continuent a
// fonctionner sans reseau. Ce state est reserve aux fonctionnalites qui
// exigent vraiment Internet (classement temps reel, sync, support).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../error_state.dart';

class NetworkError extends StatelessWidget {
  /// Callback du bouton "Reessayer".
  final VoidCallback? onRetry;

  /// Callback du lien "Continuer hors-ligne".
  final VoidCallback? onContinueOffline;

  const NetworkError({
    super.key,
    this.onRetry,
    this.onContinueOffline,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.wifi_off,
      iconColor: AppColors.warning, // orange (non bloquant)
      message: 'Pas de connexion Internet',
      description: "ExamBoost fonctionne hors-ligne, mais certaines "
          "fonctionnalités nécessitent Internet.",
      onRetry: onRetry,
      retryLabel: 'Réessayer',
      secondaryActionLabel: onContinueOffline != null
          ? 'Continuer hors-ligne'
          : null,
      onSecondaryAction: onContinueOffline,
    );
  }
}
