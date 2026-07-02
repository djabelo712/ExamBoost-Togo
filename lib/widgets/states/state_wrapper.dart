// lib/widgets/states/state_wrapper.dart
// Wrapper qui gere les 4 etats possibles d'un ecran avec donnees :
//   - loading  : skeleton shimmer pendant le chargement
//   - empty    : etat vide (pas de donnees)
//   - error    : etat d'erreur (reseau, DB...)
//   - loaded   : contenu reel
//
// Au lieu d'ecrire a chaque fois :
//   if (_loading) return LoadingSkeleton();
//   if (_error != null) return ErrorState(message: _error);
//   if (_data.isEmpty) return EmptyState(...);
//   return MyContent();
//
// On ecrit :
//   StateWrapper(
//     state: _state,
//     loaded: MyContent(),
//     loading: DashboardSkeleton(),
//     empty: NoProgressEmpty(),
//     error: NetworkError(onRetry: _loadData),
//   )
//
// Avantages :
//   - Centralise la logique des 4 etats (lisibilite, moins de bugs).
//   - Fournit des fallbacks genériques si loading/empty/error ne sont pas
//     fournis (DefaultLoadingSkeleton, DefaultEmptyState, DefaultErrorState).
//   - Permet a l'agent wiring de migrer les ecrans existants sans casser
//     les comportements (il suffit d'envelopper le body dans StateWrapper).

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'empty_state.dart';
import 'loading_skeleton.dart';
import 'error_state.dart';

/// Etat possible d'un widget qui charge des donnees.
enum WidgetState {
  /// En cours de chargement (afficher un skeleton shimmer).
  loading,

  /// Aucune donnee (afficher un etat vide avec CTA).
  empty,

  /// Erreur de chargement (afficher un etat d'erreur avec retry).
  error,

  /// Donnees chargees avec succes (afficher le contenu reel).
  loaded,
}

class StateWrapper<T> extends StatelessWidget {
  /// Etat courant du widget.
  final WidgetState state;

  /// Widget a afficher quand state == WidgetState.loaded.
  final Widget loaded;

  /// Widget a afficher quand state == WidgetState.loading.
  /// Si null, utilise [DefaultLoadingSkeleton].
  final Widget? loading;

  /// Widget a afficher quand state == WidgetState.empty.
  /// Si null, utilise [DefaultEmptyState].
  final Widget? empty;

  /// Widget a afficher quand state == WidgetState.error.
  /// Si null, utilise [DefaultErrorState] avec [errorMessage] et [onRetry].
  final Widget? error;

  /// Message d'erreur transmis a [DefaultErrorState] si [error] est null.
  final String? errorMessage;

  /// Callback de retry transmis a [DefaultErrorState] si [error] est null.
  final VoidCallback? onRetry;

  const StateWrapper({
    super.key,
    required this.state,
    required this.loaded,
    this.loading,
    this.empty,
    this.error,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case WidgetState.loading:
        return loading ?? const DefaultLoadingSkeleton();
      case WidgetState.empty:
        return empty ?? const DefaultEmptyState();
      case WidgetState.error:
        return error ??
            DefaultErrorState(
              message: errorMessage,
              onRetry: onRetry,
            );
      case WidgetState.loaded:
        return loaded;
    }
  }
}

/// Skeleton par defaut : 4 cartes standards avec effet shimmer.
///
/// Suffisant pour la plupart des ecrans de liste (favoris, notes,
/// simulations...). Pour les ecrans complexes (dashboard, leaderboard),
/// preferer les skeletons dedies dans skeletons/.
class DefaultLoadingSkeleton extends StatelessWidget {
  final int itemCount;

  const DefaultLoadingSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(itemCount: itemCount);
  }
}

/// Empty state par defaut : icone inbox + texte generique.
///
/// Pour les vrais ecrans, preferer les wrappers dedies dans empty_states/
/// qui fournissent un message et un CTA specifiques au contexte.
class DefaultEmptyState extends StatelessWidget {
  const DefaultEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.inbox_outlined,
      title: 'Rien à afficher pour le moment',
      description: "Reviens plus tard ou déclenche une action pour voir "
          "du contenu apparaître ici.",
    );
  }
}

/// Error state par defaut : icone error_outline + bouton "Reessayer".
class DefaultErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const DefaultErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      message: message ?? 'Une erreur est survenue',
      description: "Une erreur inattendue s'est produite. Réessaie ou "
          "contacte le support si le problème persiste.",
      onRetry: onRetry,
      secondaryActionLabel: onRetry == null ? null : 'Contacter le support',
      onSecondaryAction: null, // Pas de support wire par defaut
    );
  }
}
