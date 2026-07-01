# lib/screens/stats/

Pages de statistiques détaillées par compétence pour ExamBoost Togo.

## Contenu du dossier

```
lib/screens/stats/
├── subject_detail_screen.dart         # Page détail MATIÈRE (/stats/:matiere)
├── competence_detail_screen.dart      # Page détail COMPÉTENCE (/stats/competence/:id)
├── services/
│   └── subject_stats_service.dart      # Service local (computeCompetenceStats, ...)
├── widgets/
│   ├── competence_card.dart            # Carte compétence (P(L), statut, progression)
│   ├── mastery_radar_chart.dart        # Radar chart fl_chart (6-8 axes = chapitres)
│   ├── subject_timeline.dart           # Timeline 30 jours (GitHub-like, 30 cases)
│   ├── recommendation_card.dart        # Carte reco auto (3 types : rouge/orange/bleu)
│   └── comparison_chart.dart           # 3 barres horizontales : Top 10% / Moy / Toi
└── README.md
```

## Routes à ajouter dans `lib/utils/app_router.dart`

L'agent principal doit ajouter ces 2 routes au `GoRouter` :

```dart
import '../screens/stats/subject_detail_screen.dart';
import '../screens/stats/competence_detail_screen.dart';

// Dans routes: [...]
GoRoute(
  path: '/stats/:matiere',
  name: 'stats_subject',
  pageBuilder: (context, state) {
    final matiere = state.pathParameters['matiere'] ?? 'Math%C3%A9matiques';
    return buildPageWithTransition(
      child: SubjectDetailScreen(
        matiere: Uri.decodeComponent(matiere),
      ),
      type: TransitionType.slideRight,
    );
  },
),
GoRoute(
  path: '/stats/competence/:competenceId',
  name: 'stats_competence',
  pageBuilder: (context, state) {
    final competenceId = state.pathParameters['competenceId'] ?? '';
    return buildPageWithTransition(
      child: CompetenceDetailScreen(
        competenceId: Uri.decodeComponent(competenceId),
      ),
      type: TransitionType.slideRight,
    );
  },
),
```

Et dans la classe `AppRoutes` :

```dart
static const String statsSubject    = '/stats';
static const String statsCompetence = '/stats/competence';
```

## Navigation depuis le Dashboard

Dans `lib/screens/dashboard/dashboard_screen.dart`, la section "Progression par matière"
(`_buildMatiereProgress`) effectue actuellement `context.go('/revision/...')` au tap.
Pour ouvrir la page de stats détaillées à la place, remplacer le `onTap` du `InkWell`
par :

```dart
onTap: () => context.go(
  '/stats/${Uri.encodeComponent(e.key)}',
),
```

Idem pour les chips de matières (s'il y en a) — l'idée est d'utiliser `/stats/<matiere>`
comme porte d'entrée, et de garder `/revision/<matiere>` accessible depuis les boutons
d'action de la page de stats (bouton "Réviser" en haut + boutons "Réviser" sur chaque
CompetenceCard).

## Dépendances requises

Toutes déjà présentes dans `pubspec.yaml` :

| Dépendance         | Version  | Rôle                                  |
|--------------------|----------|---------------------------------------|
| `fl_chart`         | ^0.68.0  | RadarChart (mastery_radar_chart.dart) |
| `percent_indicator`| ^4.2.3   | CircularPercentIndicator / Linear     |
| `hive_flutter`     | ^1.1.0   | Lecture AppUser + ReviewCard          |
| `provider`         | ^6.1.2   | UserProvider + QuestionService        |
| `go_router`        | ^13.2.0  | Navigation /stats/...                 |
| `shared_preferences`| ^2.2.3  | (via UserProvider) current_user_id    |

Aucune nouvelle dépendance à ajouter.

## Architecture

### SubjectStatsService

Service local sans état (stateless), instancié directement dans les écrans.
Méthodes principales :

- `computeSubjectStats({matiere, user, questionService, userCards})` → `SubjectStats`
- `computeCompetenceStats({competenceId, user, questionService, userCards})` → `CompetenceStats?`
- `getCompetenceHistory({competenceId, questionService, userCards, limit})` → `List<CompetenceHistoryEntry>`
- `getTimeline30Jours(userCards)` → `List<DayActivity>` (30 jours chronologiques)
- `getClassroomComparison(pLUtilisateur)` → `ClassroomComparison` (mock)

### Modèles de données

Définis directement dans `subject_stats_service.dart` (pas de `@HiveType` — ce sont
des DTOs purs, non persistés) :

- `CompetenceStats` : agrégats d'une compétence (pL, statut, nb questions, taux
  réussite, dernière révision, temps moyen, nb consécutives correctes)
- `SubjectStats` : agrégats d'une matière (liste de CompetenceStats + 3 recommandations)
- `Recommendation` : reco auto-générée (type, titre, description, cibles)
- `RecommendationType` : enum 3 valeurs (prioriteFaiblesse / streak / quickWin)
- `DayActivity` : 1 jour de la timeline (date + nb questions)
- `ClassroomComparison` : 3 valeurs (top10 / moyenne / toi) + nb élèves anonymes
- `CompetenceHistoryEntry` : 1 entrée d'historique pour la page compétence

### Sémantique des statuts

| Statut         | Condition                            | Couleur  |
|----------------|--------------------------------------|----------|
| Maîtrisée      | P(L) >= 0.85                          | success  |
| En cours       | 0.5 <= P(L) < 0.85                    | warning  |
| Fragile        | P(L) < 0.5 et questions répondues > 0 | error    |
| Non évaluée    | P(L) == 0 et aucune réponse           | secondary|

## Mocks / limites connues

| Aspect                  | Statut        | Note                                                       |
|-------------------------|---------------|------------------------------------------------------------|
| Comparaison vs classe   | Mock          | Top 10% = 85%, Moyenne = 58%, 247 élèves anonymes          |
| Temps moyen par question| Mock estimé   | ReviewCard ne persiste pas les durées — estimation         |
|                         |               | reproductible 15-45s via `questionId.hashCode`             |
| Historique détaillé     | Synthétique   | ReviewCard ne stocke pas l'historique des tentatives —     |
|                         |               | on synthétise une entrée par carte (dernière interaction)  |
| Qualité SM-2 historique | Estimée       | Déduite de `successRate` (5=95%, 4=75%, 3=50%, 2=25%, 1>0) |
| Réponses consécutives   | Heuristique   | `correctAttempts.clamp(0, 5)` quand carte non "isLearning" |

### Branchement futur (backend FastAPI)

Quand le backend exposera `/stats/classroom/anonymous` (retournant top10 / moyenne /
nb_eleves pour une matière donnée), remplacer `_mockTop10` / `_mockMoyenneClasse` /
`_mockNbEleves` par un appel HTTP `dio.get(...)`.

Quand `ReviewCard` sera étendu avec `List<int> durationsMs` (durée par tentative),
remplacer `_estimerTempsTotalSecondes` par une vraie somme.

## Tests rapides (curl-style, manuel)

1. Naviguer vers `/stats/Math%C3%A9matiques` (URL-encodé) — la page doit charger
   les 6 sections.
2. Taper une `CompetenceCard` — doit ouvrir `/stats/competence/<competenceId>`.
3. Vérifier que le radar chart s'affiche (si < 3 chapitres disponibles, l'état
   vide s'affiche à la place — c'est attendu).
4. Vérifier que la timeline a bien 30 cases et que les tooltips s'affichent
   au survol (desktop) ou tap (mobile).
5. Taper "Exporter mes progrès" — une boîte de dialogue affiche le JSON
   sélectionnable.

## Conventions de code

- Flutter 3.44+, Material 3, Provider (pas de Riverpod ici).
- Pas d'emojis.
- Commentaires en français.
- Style cohérent avec `dashboard_screen.dart` (méthodes privées `_buildXxx()`,
  `_cardDecoration()` réutilisé, `AppColors` / `AppTextStyles` partout).
- État de chargement + état d'erreur + état vide gérés sur les 2 écrans.
- `addPostFrameCallback` dans `initState` pour éviter d'accéder au `Provider`
  pendant le build.
- `RefreshIndicator` sur les 2 écrans pour recharger les données.
- Try/catch sur toutes les ouvertures de Hive boxes (l'adaptateur `ReviewCard`
  peut ne pas être enregistré si `build_runner` n'a pas tourné — l'écran reste
  fonctionnel avec `_cards = []`).
