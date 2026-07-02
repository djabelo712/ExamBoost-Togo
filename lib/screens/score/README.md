# Score officiel BEPC/BAC — Module MEPST

Service + UI de prédiction du score officiel BEPC/BAC selon les
coefficients du **Ministère togolais de l'Enseignement Primaire,
Secondaire et Technique (MEPST)**.

C'est le **différenciateur #1** d'ExamBoost vs Khan Academy / Afrilearn :
nous pondérons par les coefficients officiels du Togo, pas générique.

## Fichiers du module

```
lib/models/
  examen_coefficients.dart        # Coefficients officiels BEPC + BAC A/B/C/D/F
  score_prediction.dart           # Modeles ScorePrediction + SubjectScore

lib/services/
  score_calculator.dart           # Calcul pur (BKT + coef -> score /20)
  score_predictor.dart            # Orchestrateur + persistance historique Hive

lib/screens/score/
  score_prediction_screen.dart    # Page principale
  widgets/
    score_gauge.dart              # Jauge circulaire geante 0-20
    subject_breakdown_card.dart   # Carte detail par matiere
    coefficient_table.dart        # Tableau coefficients officiels
    score_history_chart.dart      # LineChart evolution 3 mois
```

## Algorithme

Pipeline de calcul du score prédit :

1. Pour chaque matière de l'examen, on collecte les compétences BKT
   déjà mesurées chez l'élève (depuis `user.bktMaitrise`).
2. On calcule le P(L) moyen de la matière.
3. On convertit P(L) → note /20 (calibrage : P(L) = 0.5 → 10/20,
   P(L) = 0.85 → 17/20, P(L) = 1 → 20/20).
4. On pondère par le coefficient officiel MEPST de la matière.
5. `scoreGlobal = Σ (note × coef) / Σ coef` sur les matières couvertes.
6. Indice de confiance : combine couverture du programme + nb questions
   répondues.
7. Recommandation pédagogique contextuelle selon score + couverture.

## Coefficients MEPST (à valider officiellement)

Les coefficients sont **basés sur la pratique commune BEPC/BAC en
Afrique francophone** (Côte d'Ivoire, Sénégal, Burkina, Mali) et
constituent un point de départ réaliste en attendant la validation
officielle MEPST.

### BEPC (Brevet d'Études du Premier Cycle)

| Matière                              | Coef. |
| ------------------------------------ | ----: |
| Mathématiques                        | 4     |
| Français                             | 4     |
| Sciences Physiques                   | 3     |
| Sciences de la Vie et de la Terre    | 3     |
| Histoire-Géographie                  | 3     |
| Anglais                              | 2     |
| Éducation Physique et Sportive       | 1     |
| Travaux Manuels                      | 1     |
| **Total**                            | **21** |

### BAC série C (Mathématiques et Physique)

| Matière                              | Coef. |
| ------------------------------------ | ----: |
| Mathématiques                        | 6     |
| Sciences Physiques                   | 6     |
| Sciences de la Vie et de la Terre    | 2     |
| Français                             | 2     |
| Philosophie                          | 2     |
| Anglais                              | 2     |
| Histoire-Géographie                  | 1     |
| Travaux Pratiques                    | 2     |
| **Total**                            | **23** |

### BAC série D (Sciences naturelles)

| Matière                              | Coef. |
| ------------------------------------ | ----: |
| Sciences de la Vie et de la Terre    | 6     |
| Sciences Physiques                   | 5     |
| Mathématiques                        | 4     |
| Français                             | 2     |
| Philosophie                          | 2     |
| Anglais                              | 2     |
| Histoire-Géographie                  | 1     |
| **Total**                            | **22** |

### BAC série A (Littéraire)

| Matière                              | Coef. |
| ------------------------------------ | ----: |
| Français                             | 6     |
| Philosophie                          | 5     |
| Anglais                              | 4     |
| Histoire-Géographie                  | 4     |
| Mathématiques                        | 2     |
| Sciences Physiques                   | 2     |
| Sciences de la Vie et de la Terre    | 2     |
| **Total**                            | **25** |

### BAC série B (Sciences économiques)

| Matière                              | Coef. |
| ------------------------------------ | ----: |
| Économie                             | 6     |
| Mathématiques                        | 5     |
| Histoire-Géographie                  | 4     |
| Français                             | 3     |
| Philosophie                          | 3     |
| Anglais                              | 3     |
| Sciences Physiques                   | 2     |
| **Total**                            | **26** |

### BAC série F (Technique)

| Matière                              | Coef. |
| ------------------------------------ | ----: |
| Technologie                          | 6     |
| Mathématiques                        | 5     |
| Sciences Physiques                   | 4     |
| Français                             | 2     |
| Philosophie                          | 2     |
| Anglais                              | 2     |
| **Total**                            | **21** |

## Intégration au router (à faire par l'agent wiring)

Ajouter la route `/score-prediction` dans `lib/utils/app_router.dart` :

```dart
import '../screens/score/score_prediction_screen.dart';

// Dans la liste routes de AppRouter.router :
GoRoute(
  path: '/score-prediction',
  name: 'score-prediction',
  builder: (context, state) => ScorePredictionScreen(
    initialPrediction:
        state.extra is ScorePrediction ? state.extra as ScorePrediction : null,
  ),
),

// Et dans AppRoutes :
static const String scorePrediction = '/score-prediction';
```

Puis appeler depuis n'importe quel écran :

```dart
context.go(AppRoutes.scorePrediction);
// ou avec une prédiction déjà calculée :
context.go(
  AppRoutes.scorePrediction,
  extra: alreadyComputedPrediction,
);
```

## Appel depuis Dashboard

Pour afficher la prédiction depuis `dashboard_screen.dart` :

```dart
import '../../services/score_predictor.dart';
import '../score/score_prediction_screen.dart';

// Dans une méthode async (ex: initState ou tap sur carte "Voir prédiction") :
Future<void> _openScorePrediction() async {
  final user = _user!; // AppUser courant
  final prediction = await ScorePredictor.instance.predictForUser(user);
  if (!mounted) return;
  context.go('/score-prediction', extra: prediction);
}
```

Remplacer le mock actuel `_predictedBepcScore(user)` dans
`_buildScoreCard` par un vrai appel à `ScorePredictor.instance.predictForUser`
pour aligner le score affiché sur le module MEPST officiel.

## Persistance historique Hive

L'historique des prédictions est stocké dans une Hive box
`score_predictions` (box<String> contenant du JSON sérialisé).
Pas besoin d'adapter Hive généré par `build_runner`.

- **Box** : `score_predictions`
- **Clé** : `history_<userId>` (ex: `history_user_demo`)
- **Valeur** : JSON String d'une `List<Map<String, dynamic>>`
- **Rétention** : 90 jours (3 mois) — purge automatique à chaque save
- **Dédoublonnage** : si une nouvelle prédiction est faite moins de
  1 minute après la précédente, on remplace au lieu d'ajouter

Pour visualiser la box en dev :

```dart
final box = await Hive.openBox<String>('score_predictions');
final raw = box.get('history_user_demo');
print(raw); // JSON string
```

Pour vider l'historique d'un utilisateur (RGPD / reset) :

```dart
await ScorePredictor.instance.clearHistory('user_demo');
```

## Calibrage P(L) → note

La transformation P(L) → note /20 est **non-linéaire** pour refléter
la réalité pédagogique :

| P(L)    | Note /20 | Interprétation        |
| ------- | -------: | --------------------- |
| 0.0     | 0        | Rien maîtrisé         |
| 0.25    | 5        | Très fragile          |
| 0.50    | 10       | Moyenne               |
| 0.75    | 15       | Bon                   |
| 0.85    | 17       | Maîtrise (seuil BKT)  |
| 1.00    | 20       | Excellence            |

Au-dessus de P(L) = 0.5, on applique `note = 10 + (P(L) - 0.5) * 20`
(linéaire vers 20). En dessous, `note = P(L) * 20` (linéaire vers 0).

Ce calibrage est empirique et devra être ajusté sur les données
réelles des premiers cohortes d'élèves togolais (seuil de passage
observé, distribution des notes réelles BEPC).

## Indice de confiance

| Conditions                                   | Confiance | Couleur |
| -------------------------------------------- | ---------: | ------- |
| < 50 questions OU couverture < 30 %          | 0.20       | Rouge   |
| 50-200 questions OU couverture 30-70 %       | 0.50       | Orange  |
| > 200 questions ET couverture > 70 %         | 0.85       | Vert    |

## Recommandations contextuelles

Générées par `ScoreCalculator._generateRecommendation(score, coverage)` :

| Coverage | Score       | Message type                                            |
| -------- | ----------- | ------------------------------------------------------- |
| < 30 %   | —           | Continue à réviser pour avoir une prédiction fiable.   |
| —        | < 8         | Préoccupant. Concentre-toi sur les bases.              |
| —        | 8-10        | Sous la moyenne. Identifie tes chapitres faibles.      |
| —        | 10-12       | Approche la moyenne. Un effort sur les matières faibles. |
| —        | 12-14       | Bon score. Maintiens ton rythme.                        |
| —        | 14-16       | Très bon. Vise l'excellence.                            |
| —        | ≥ 16        | Excellent ! Maintiens et aide tes camarades.            |

## Limitations actuelles

1. **Coefficients à valider MEPST** : basés sur la pratique commune
   Afrique francophone. Une fois le document officiel récupéré,
   ajuster les Maps statiques dans `examen_coefficients.dart`.
2. **Matières non couvertes dans la banque actuelle** :
   Philosophie, EPS, Travaux Manuels, Travaux Pratiques, Économie,
   Technologie n'ont pas encore de questions dans `questions.json`.
   Ces matières sont donc systématiquement "non couvertes" dans la
   prédiction tant qu'aucune compétence n'est mesurée.
3. **Calibrage P(L) → note empirique** : à ajuster sur données réelles
   Togo après les premières cohortes.
4. **Bande de confiance simplifiée** : ±1 point dans le LineChart.
   Pour une vraie bande bayésienne, il faudrait propager l'incertitude
   du BKT (variance de P(L)) à travers la pondération.

## Dépendances

- `fl_chart: ^0.68.0` (déjà dans pubspec.yaml)
- `percent_indicator: ^4.2.3` (déjà dans pubspec.yaml)
- `hive: ^2.2.3` (déjà dans pubspec.yaml)
- `provider: ^6.1.2` (déjà dans pubspec.yaml)
- `go_router: ^13.2.0` (déjà dans pubspec.yaml)

Aucune nouvelle dépendance à ajouter à `pubspec.yaml`.

## Tests recommandés (prochaine étape)

- Test unitaire `score_calculator_test.dart` :
  - Score = 0 si aucune compétence mesurée
  - Score = 20 si P(L) = 1 sur toutes les matières
  - Pondération correcte (Maths coef 6 pèse plus que HG coef 1)
  - Confiance varie avec coverage + nb questions
- Test widget `score_prediction_screen_test.dart` :
  - Affichage correct avec prédiction initiale
  - États vides / erreur
  - Navigation vers révision au tap sur une matière
