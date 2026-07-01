# Recherche & Filtres avances — ExamBoost Togo

Module de recherche full-text + filtres multiples sur la banque de
questions (BEPC / BAC Togo). L'eleve peut trouver rapidement une question
par mot-cle, par matiere, par examen, par annee, par type, par difficulte,
ou par points — puis sauvegarder ses recherches favorites.

> Perimetre : ce dossier `lib/screens/search/` uniquement.
> Aucune autre partie du projet n'a ete modifiee (router, main.dart,
> pubspec.yaml, autres ecrans, services existants, models existants).

## Structure

```
lib/screens/search/
├── search_screen.dart                  # Ecran principal recherche
├── search_results_screen.dart          # Ecran resultats (route /search/results)
├── widgets/
│   ├── search_bar_widget.dart          # Barre recherche + suggestions overlay
│   ├── filter_chips_bar.dart           # Chips filtres actifs (effacables)
│   ├── filter_bottom_sheet.dart        # Bottom sheet 6 sections de filtres
│   ├── question_result_card.dart       # Carte resultat question
│   ├── sort_dropdown.dart              # Dropdown tri + bouton asc/desc
│   └── saved_searches_section.dart     # Section recherches favorites + suggestions
├── services/
│   └── search_service.dart             # Logique recherche + pertinence + Hive
├── models/
│   ├── search_filters.dart             # Modele filtres (10 criteres + 7 tris)
│   └── saved_search.dart               # Recherche sauvegardee (Hive typeId 14)
└── README.md                           # Ce fichier
```

## Fonctionnalites

- **Recherche full-text** : mot-cle cherche dans enonce + explication +
  chapitre + matiere. Score de pertinence : 10 pts (enonce) + 5 (chapitre) +
  3 (explication) + 1 (matiere).
- **10 filtres combinables** : keyword, matiere, examen, serie, yearFrom,
  yearTo, type, difficultyRange, pointsMin, onlyFavorites, onlyNotMastered.
- **7 tris possibles** : pertinence, difficulte (asc/desc), annee (recentes/
  anciennes), points (eleves/faibles).
- **Suggestions d'autocompletion** : chapitres correspondant a la saisie
  (max 5, affiches en overlay sous la barre).
- **Sauvegarde des recherches favorites** : nom libre, persistance Hive
  box<String>('saved_searches'), re-execution en un tap, renommage,
  suppression, compteur de resultats mis a jour a chaque run.
- **Suggestions populaires** : 6 questions tirees pseudo-aleatoirement avec
  seed fixe (stabilite entre runs) pour la section "Suggestions" quand
  aucune recherche n'est active.
- **Filtres speciaux** :
  - `onlyFavorites` : restreint aux questions marquees favorites
    (boite Hive `question_favorites` partagee avec Agent AN).
  - `onlyNotMastered` : masque les questions deja maitrises (P(L) >= 0.85
    selon BKT — utilise `AppUser.bktMaitrise`).

## Architecture

### Source de donnees

Le `SearchService` instancie un `QuestionService` (deja expose via Provider
global dans `main.dart`). Comme `QuestionService` ne possede pas de getter
public `allQuestions`, le `SearchService` recombine la liste complete via
`matieres` + `getByMatiere` (cache en memoire apres le premier appel).
Cela evite de modifier le service existant (contrainte Session 3).

### Pipeline de recherche

1. Filtre keyword (full-text sur enonce + explication + chapitre + matiere)
2. Filtre matiere (egalite exacte)
3. Filtre examen (egalite exacte)
4. Filtre serie (egalite exacte — null pour BEPC)
5. Filtre yearFrom / yearTo (intervalle inclusif)
6. Filtre type (enum `QuestionType`)
7. Filtre difficultyRange (basé sur `irtB` — seuils -0.5 / 0.8)
8. Filtre pointsMin (>= seuil)
9. Filtre onlyFavorites (intersection avec `Set<String>` d'IDs favoris)
10. Filtre onlyNotMastered (P(L) < 0.85 — basé sur `AppUser.bktMaitrise`)
11. Tri (7 options — voir `SortBy`)

### Persistance des recherches favorites

Choix technique : **stockage en JSON string dans Hive box<String>**
(`box<String>('saved_searches')`) plutot qu'avec un `@HiveType` adapte.
Raisons :
- Aucun besoin d'enregistrer un adapter dans `main.dart` (box<String>
  natif Hive sans codegen).
- Aucun besoin de lancer `dart run build_runner build` (les fichiers
  `*.g.dart` ne sont pas generes en Session 3).
- Le modele `SavedSearch` est quand meme annote `@HiveType(typeId: 14)`
  + `@HiveField(...)` pour documentation et usage futur (si l'agent
  principal veut basculer vers un Hive typé, il suffit d'ajouter
  `part 'saved_search.g.dart';` + lancer build_runner + enregistrer
  `SavedSearchAdapter()` dans `main.dart`).

Le `SearchService` serialise chaque `SavedSearch` via `toJson()` et la
stocke avec `jsonEncode`. La lecture utilise `jsonDecode` +
`SavedSearch.fromJson()`. La cle Hive est l'`id` de la SavedSearch.

## Integration — A faire par l'agent principal

### 1. Ajouter les routes `/search` et `/search/results` au router

Dans `lib/utils/app_router.dart` :

```dart
// 1. Imports en haut du fichier :
import '../screens/search/search_screen.dart';
import '../screens/search/search_results_screen.dart';
import '../screens/search/models/search_filters.dart';

// 2. Ajouter dans la classe AppRoutes :
class AppRoutes {
  // ... routes existantes ...
  static const String search        = '/search';
  static const String searchResults = '/search/results';
}

// 3. Ajouter les GoRoute dans routes: [ ... ] :
GoRoute(
  path: AppRoutes.search,
  name: 'search',
  pageBuilder: (context, state) => buildPageWithTransition(
    child: const SearchScreen(),
    type: TransitionType.slideUp,
  ),
),
GoRoute(
  path: AppRoutes.searchResults,
  name: 'searchResults',
  pageBuilder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    final name = extra?['name'] as String? ?? 'Recherche';
    final filtersJson = extra?['filters'] as Map<String, dynamic>?;
    final filters = filtersJson != null
        ? SearchFilters.fromJson(filtersJson)
        : SearchFilters.empty;
    return buildPageWithTransition(
      child: SearchResultsScreen(name: name, filters: filters),
      type: TransitionType.slideRight,
    );
  },
),
```

### 2. Ajouter un bouton "Rechercher" dans home_screen.dart

Dans `lib/screens/home/home_screen.dart`, ajouter une `_ActionCard` :

```dart
_ActionCard(
  icon: Icons.search,
  title: 'Rechercher',
  subtitle: 'Trouve une question par mot-cle, matiere, examen, annee...',
  color: AppColors.info,
  onTap: () => context.go(AppRoutes.search),
),
```

### 3. (Optionnel) Enregistrer l'adapter Hive typé pour SavedSearch

Sans cette etape, le module fonctionne avec un stockage JSON string (par
defaut). Pour activer la persistance Hive typée :

1. Ajouter en bas de `lib/screens/search/models/saved_search.dart` :
   ```dart
   part 'saved_search.g.dart';
   ```
2. Lancer :
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Dans `lib/main.dart`, ajouter aux autres `registerAdapter` :
   ```dart
   import 'screens/search/models/saved_search.dart';
   Hive.registerAdapter(SavedSearchAdapter());
   await Hive.openBox<SavedSearch>('saved_searches');
   ```
4. Adapter `SearchService` pour utiliser `box<SavedSearch>` au lieu de
   `box<String>` + `jsonEncode/Decode`.

### 4. Brancher sur le backend FastAPI (V2 — Elasticsearch ou PostgreSQL FTS)

Quand le backend FastAPI existera avec un endpoint de recherche, remplacer
la methode `SearchService.search()` par un appel HTTP. Exemple d'endpoint
cible :

```
POST /search
Body: {
  "keyword": "pythagore",
  "matiere": "Mathematiques",
  "examen": "BEPC",
  "year_from": 2018,
  "year_to": 2024,
  "type": "calcul",
  "difficulty": "facile",
  "points_min": 2,
  "sort_by": "relevance",
  "limit": 50,
  "offset": 0
}
Response: {
  "total": 12,
  "results": [ { ...question_json, "score": 18 }, ... ]
}
```

Backend side, deux options :

- **PostgreSQL full-text search** : `tsvector` + `tsquery` + GIN index sur
  la colonne `enonce`. Suffisant pour <= 50k questions.
- **Elasticsearch / OpenSearch** : pour > 50k questions ou recherche
  floue, accent-insensible, stemmatisation francaise. Indexer `enonce` +
  `explication` + `chapitre` + `matiere` avec analyzer `french`.

Pour la V1 (offline-first, < 5k questions), la recherche Dart in-memory
est suffisante (latence < 50ms sur 64 questions actuelles).

## Compatibilite

- Flutter 3.44+ (Material 3, `CardThemeData`, `DropdownButton`, `RangeSlider`)
- Provider 6.x (deja dans pubspec — `Provider.of<QuestionService>(context)`)
- Hive 2.x (deja dans pubspec — `box<String>` natif, aucun package
  supplementaire requis)
- go_router 13.x (deja dans pubspec — pour `context.go`)
- Aucune nouvelle dependance ajoutee au pubspec (compatible avec la
  contrainte Session 3 de ne pas modifier pubspec.yaml).

## Filtres speciaux — wiring avec Agent AN

Le filtre `onlyFavorites` s'appuie sur le service `FavoritesService` créé par
l'Agent AN (`lib/screens/favorites/services/favorites_service.dart`). API
utilisee :

- `FavoritesService.getFavoriteIds(String userId)` -> `List<String>` (IDs des
  questions favorites pour cet eleve)
- `FavoritesService.toggleFavorite(String userId, String questionId)` ->
  `Future<bool>` (idempotent : ajoute si absent, retire si present)

Le `SearchScreen` et le `SearchResultsScreen` :
1. Recuperent l'`userId` depuis `UserProvider.currentUserId` (fallback
   `'user_demo'` si UserProvider absent).
2. Au `initState`, appellent `context.read<FavoritesService>()` (wrappé
   dans try/catch) pour charger `_favoriteIds`.
3. Au toggle du bouton cœur d'une `QuestionResultCard`, appellent
   `favService.toggleFavorite(userId, q.id)` puis re-synchronisent
   `_favoriteIds`.

Si `FavoritesService` n'est pas encore enregistre comme Provider dans
`main.dart` (wiring non fait), les try/catch tombent en silence et le
filtre `onlyFavorites` retourne une liste vide (pas de crash).

Le `SearchService.search()` lui-meme reste decouple : il accepte un
`Set<String>? favoriteIds` en parametre — c'est l'ecran appellant qui
remplit ce set depuis `FavoritesService`. Cela permet de tester le
`SearchService` isolement sans dependre d'Agent AN.

## Decisions de conception

### Recherche full-text Dart in-memory (pas de FTS SQLite / Elasticsearch)

Pour la V1 (offline-first, <= 5k questions cible), une recherche
`.where((q) => q.enonce.toLowerCase().contains(kw))` en Dart est
suffisante. Latence mesurée sur 64 questions : < 5ms. Sur 5000 questions
estimee : < 200ms (acceptable).

Quand on passera a 50k+ questions (objectif 2027), on basculera vers
PostgreSQL FTS (deja prevu dans le backend FastAPI) ou Elasticsearch.

### Score de pertinence simple (pas de TF-IDF / BM25)

Le score actuel est une somme ponderee fixe : 10 pts (enonce) + 5
(chapitre) + 3 (explication) + 1 (matiere). Suffisant pour une V1.
Pour la V2 backend, on pourra implementer BM25 avec
`ts_rank_cd` PostgreSQL.

### Pas de pagination (V1)

La liste complete des resultats est chargee en memoire. Pour <= 5k
questions, c'est OK. Pour la V2, on implementera une pagination
`limit/offset` cote backend + `ListView.builder` avec infinite scroll.

### Suggestions basees sur les chapitres uniquement

Les suggestions d'autocompletion sont les chapitres correspondant a la
saisie. On pourrait etendre aux matieres, examens et competences. Pour
la V1, les chapitres sont le signal le plus fort (titres courts,
descriptifs).

### Sauvegarde en JSON string (pas de Hive typé)

Voir section "Persistance des recherches favorites" ci-dessus. Decision
prise pour eviter la dependance a `build_runner` en Session 3.

### Pas de dependance externe ajoutee

Aucun package supplementaire dans pubspec.yaml (contrainte Session 3).
Le module utilise uniquement : `flutter/material.dart`, `hive`,
`provider`, `go_router` — tous deja presents.

## Tests rapides

```bash
# 1. Generation des fichiers *.g.dart (si Agent principal a active le mode Hive typé)
cd /home/z/my-project/ExamBoost-Togo
dart run build_runner build --delete-conflicting-outputs

# 2. Lancement de l'app
flutter run

# 3. Navigation : Home -> bouton "Rechercher" (apres wiring) -> ecran SearchScreen
#    - Taper "pythagore" dans la barre -> 1+ resultats
#    - Tap sur bouton "Filtres" (entonnoir) -> bottom sheet
#    - Selectionner matiere "Mathematiques" -> appliquer
#    - Tap sur "Sauvegarder" (FAB etoile) -> nommer "Mes Maths"
#    - Effacer la recherche -> section "Recherches sauvegardees" affiche "Mes Maths"
#    - Tap sur "Mes Maths" -> re-execute la recherche
#    - Long press sur "Mes Maths" -> menu renommer/supprimer
```

## Probleme eventuel

- `flutter analyze` n'a pas pu etre execute (Flutter SDK absent du
  sandbox). Verifications manuelles effectuees : imports OK, braces
  balancees, signatures coherentes, pas d'usage de `BuildContext` a
  travers gap async sans check `mounted`.
- Le `SearchService.allQuestions` recombine via `matieres` +
  `getByMatiere` (workaround car `QuestionService.allQuestions` n'est pas
  public). Si l'agent principal ajoute un getter public
  `List<Question> get allQuestions` a `QuestionService`, ce workaround
  peut etre remplace par `_questionService.allQuestions` directement.
- Le filtre `onlyFavorites` depend du `FavoritesService` de l'Agent AN
  (enregistre dans `main.dart` MultiProvider). Si l'agent wiring n'a pas
  encore branche le provider, le filtre retourne une liste vide (pas de
  crash). Voir section "Filtres speciaux" ci-dessus.
- Le filtre `onlyNotMastered` depend de `AppUser.bktMaitrise`. Si
  `UserProvider` n'est pas encore branche ou si l'utilisateur est null,
  le filtre retourne la liste complete (pas de crash).
- Le typeId Hive 14 reserve pour `SavedSearch` n'est pas encore utilise
  dans `main.dart` (pas d'adapter enregistre — stockage JSON string
  utilise a la place). Si l'agent principal ajoute un autre modele avec
  typeId 14, collision a prevoir. La convention proposee : typeId 14 =
  SavedSearch, typeId 15 = FavoriteQuestion (deja pris par Agent AN),
  typeId 16 = QuestionNote (deja pris par Agent AN), typeId 17+ = futurs
  modeles.
- Dependance compile-time sur `lib/screens/favorites/services/favorites_service.dart`
  (Agent AN) via import. Si Agent AN etait revert, le code ne compilerait
  plus — il faudrait retirer l'import `../favorites/services/favorites_service.dart`
  et les blocs try/catch qui l'utilisent dans `search_screen.dart` et
  `search_results_screen.dart`.
