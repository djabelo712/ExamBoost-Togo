// lib/widgets/states/empty_states/no_search_results_empty.dart
// Empty state : aucun resultat de recherche.
//
// Cas d'usage : ecran de recherche de questions / matieres / chapitres
// avec une requete qui ne retourne rien.
//
// Bouton "Effacer les filtres" : reinitialise la recherche.

import 'package:flutter/material.dart';

import '../empty_state.dart';

class NoSearchResultsEmpty extends StatelessWidget {
  /// Callback du bouton "Effacer les filtres".
  final VoidCallback? onClearFilters;

  /// Requete de recherche (optionnelle, inseree dans la description).
  final String? query;

  const NoSearchResultsEmpty({
    super.key,
    this.onClearFilters,
    this.query,
  });

  @override
  Widget build(BuildContext context) {
    final desc = query != null && query!.isNotEmpty
        ? "Aucun résultat pour « $query ». Essaie d'autres mots-clés "
            "ou retire des filtres."
        : "Essaie d'autres mots-clés ou retire des filtres.";

    return EmptyState(
      icon: Icons.search_off,
      title: 'Aucun résultat',
      description: desc,
      actionLabel: 'Effacer les filtres',
      onAction: onClearFilters,
    );
  }
}
