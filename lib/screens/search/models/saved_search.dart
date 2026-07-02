// lib/screens/search/models/saved_search.dart
// Recherche sauvegardee (favorite) — persistee dans Hive box
// "saved_searches".
//
// Une SavedSearch est un raccourci nomme vers un ensemble de filtres
// (SearchFilters). L'eleve peut sauvegarder "Mes Maths BEPC 2020-2023" et
// re-executer la recherche en un tap.
//
// Persistance :
//   - typeId 14 reserve pour ce modele (cf plan Agent AM).
//   - En l'absence de build_runner (cf contraintes Session 3), on ne declare
//     PAS `part 'saved_search.g.dart';`. Les annotations @HiveType / @HiveField
//     sont conservees pour documentation et usage futur (si l'agent principal
//     veut generer l'adapter via build_runner).
//   - Le SearchService serialise chaque SavedSearch en JSON string et la
//     stocke dans Hive.box<String>('saved_searches'). Aucun enregistrement
//     d'adapter n'est necessaire dans main.dart (la box<String> ne requiert
//     pas d'adapter specifique).
//
// Pour activer la persistance Hive typée (alternative) :
//   1. Ajouter `part 'saved_search.g.dart';` en bas du fichier.
//   2. Lancer `dart run build_runner build --delete-conflicting-outputs`.
//   3. Dans main.dart : Hive.registerAdapter(SavedSearchAdapter());
//      await Hive.openBox<SavedSearch>('saved_searches');
//   4. Adapter le SearchService pour utiliser box<SavedSearch> au lieu de
//      box<String> avec JSON.

import 'package:hive/hive.dart';

import 'search_filters.dart';

@HiveType(typeId: 14)
class SavedSearch extends HiveObject {
  /// Identifiant unique (genere via timestamp + random suffix).
  @HiveField(0)
  final String id;

  /// Nom donne par l'eleve : "Mes Maths BEPC 2020-2023".
  @HiveField(1)
  final String name;

  /// Filtres complets (keyword + matiere + examen + ... + sortBy).
  /// Non-HiveField (classe non-HiveType) : serialise via toJson dans le
  /// storage JSON utilise par SearchService.
  final SearchFilters filters;

  /// Date de creation de la recherche sauvegardee.
  @HiveField(3)
  final DateTime createdAt;

  /// Nombre de resultats au dernier run (mis a jour par SearchService).
  /// Permet d'afficher "12 resultats" sur la card sans re-executer.
  @HiveField(4)
  int resultCount;

  SavedSearch({
    required this.id,
    required this.name,
    required this.filters,
    required this.createdAt,
    this.resultCount = 0,
  });

  /// Cree une copie avec champs modifies.
  SavedSearch copyWith({
    String? id,
    String? name,
    SearchFilters? filters,
    DateTime? createdAt,
    int? resultCount,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      name: name ?? this.name,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
      resultCount: resultCount ?? this.resultCount,
    );
  }

  /// Serialisation JSON (utilisee par SearchService pour Hive box<String>).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filters': filters.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'resultCount': resultCount,
      };

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      name: json['name'] as String,
      filters: SearchFilters.fromJson(
        Map<String, dynamic>.from(json['filters'] as Map),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      resultCount: (json['resultCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Raccourci vers les labels des filtres actifs (pour affichage rapide).
  List<String> get filterLabels => filters.activeFilterLabels;

  @override
  String toString() =>
      'SavedSearch(id: $id, name: $name, resultCount: $resultCount, '
      'filters: $filters)';
}
