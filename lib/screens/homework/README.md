# Module Devoirs — ExamBoost Togo

Module "Devoirs" complet : un enseignant assigne des devoirs composés de
questions ExamBoost, les élèves les complètent à la maison, le système
auto-corrigée et produit un rapport enseignant agrégé par classe.

Périmètre : **100% mock local** (aucun backend). Les données résident
dans `HomeworkService` (ChangeNotifier). Aucune modification du router,
de `main.dart`, ni de `pubspec.yaml` — l'agent principal câblra les
routes et enregistrera le Provider lors du wiring final.

## Arborescence

```
lib/screens/homework/
├── homework_list_screen.dart          # Liste devoirs élève (3 onglets)
├── homework_detail_screen.dart        # Détail devoir + commencer
├── homework_session_screen.dart       # Faire le devoir (QCM / ouvert)
├── homework_results_screen.dart       # Résultats élève + auto-correction
├── teacher_homework_create.dart       # Enseignant crée devoir
├── teacher_homework_list.dart         # Enseignant liste devoirs + stats
├── teacher_homework_results.dart      # Enseignant résultats classe
├── widgets/
│   ├── homework_card.dart             # Carte devoir (élève ou enseignant)
│   ├── homework_progress.dart         # Barre + anneau + 3 KPI cards
│   └── student_result_row.dart        # Ligne résultat élève (pour prof)
├── services/
│   └── homework_service.dart          # Logique devoirs + mock data
├── models/
│   ├── homework.dart                  # Modèle Devoir + HomeworkQuestion
│   └── homework_submission.dart       # Soumission + HomeworkAnswer + Stats
└── README.md                          # Ce fichier
```

## Modèles

### `Homework` (homework.dart)
- `id`, `titre`, `description`, `matiere`
- `classes` (List<String>) : classes ciblées
- `enseignantId`, `enseignantNom`
- `dateCreation`, `dateLimit`
- `questions` (List<HomeworkQuestion>)
- `lifecycle` (brouillon / publie / clos / archive)
- `dureeMinutes` (info élève)
- Getters calculés : `pointsTotal`, `nbQuestions`, `isDeadlineDepassee`,
  `matiereColor`, `matiereIcon`, `statutPourEleve(...)`

### `HomeworkQuestion` (homework.dart)
Modèle simple (séparé de `Question` global) :
- `id`, `enonce`
- `choix` (List<String>? pour QCM), `bonIndex` (QCM)
- `bonneReponseOuverte` (String? pour question ouverte stricte)
- `points`, `explication`, `competenceId`
- Getter `isQcm`

### `HomeworkSubmission` (homework_submission.dart)
- `id`, `homeworkId`, `eleveId`, `eleveNom`, `elevePrenom`, `classe`
- `dateDebut`, `dateSoumission?`
- `enCours`, `termine` (flags)
- `reponses` (Map<String, HomeworkAnswer>)
- `score`, `tempsPasseSecondes`
- Getters : `isEnRetard(homework)`, `pourcentage`, `note20`,
  `nomComplet`, `initiales`, `tempsLabel`

### `HomeworkAnswer` (homework_submission.dart)
- `questionId`, `qcmIndex?`, `texteOuvert?`, `autoEvalueCorrect?`
- `isCorrect`, `pointsObtenus`

### `HomeworkClassStats` (homework_submission.dart)
- `effectifClasse`, `nbRendus`, `nbEnCours`, `nbManques`
- `moyenne20`, `tempsMoyenSecondes`
- `reussiteParQuestion` (Map<String, double>)

## Service — `HomeworkService` (ChangeNotifier)

### Côté élève
- `getHomeworksForCurrentEleve()` → filtre sur la classe "3e A"
- `getSoumissionForCurrentEleve(homeworkId)`
- `commencerHomework(homeworkId)` → crée une soumission "en cours"
- `enregistrerReponse(...)` → auto-correction QCM immédiate
- `soumettreHomework(...)` → fige la soumission, calcule score final

### Côté enseignant
- `getHomeworksForCurrentEnseignant()`
- `getSubmissionsForHomework(homeworkId)`
- `getEffectifForHomework(homeworkId)`
- `getStatsForHomework(homeworkId)` → `HomeworkClassStats`
- `creerDevoir(...)` → ajoute un devoir à la liste
- `exportCsv(homeworkId)` → CSV simple (prenom,nom,classe,score,note20,...)

## Mock data

- **5 devoirs** actifs :
  1. `hw_math_01` — Maths (Calcul littéral, 5 questions, deadline passée)
  2. `hw_fr_01` — Français (Figures de style, 4 questions, deadline +3j)
  3. `hw_sci_01` — Sciences Physiques (Électricité, 5 questions, deadline +7j)
  4. `hw_svt_01` — SVT (Digestion, 4 questions, deadline passée — manqué)
  5. `hw_hist_01` — Histoire-Géo (Indépendance Togo, 5 questions, deadline passée)

- **30 élèves** répartis sur 3 classes : 3e A (12), 3e B (10), Terminale C (8)
  - L'élève courant ("Moi Élève", classe 3e A) a un statut démontrant
    chacun des 4 cas : rendu (math), en cours (fr), à faire (sci),
    manqué (svt), rendu (hist).

- **Soumissions pré-remplies** générées par un RNG déterministe (seed=42)
  pour reproductibilité des démos : ~70% rendus, ~15% en cours, ~15%
  manqués. 10% des rendus sont "en retard" (soumis après deadline).

## Flux élève

1. `HomeworkListScreen` — 3 onglets (À faire / Terminés / Manqués)
   → tap → `HomeworkDetailScreen`
2. `HomeworkDetailScreen` — header couleur matière, méta-info,
   aperçu questions, CTA adapté au statut :
   - À faire → "Commencer le devoir"
   - En cours → "Reprendre (X/N répondues)"
   - Rendu → "Voir mes résultats"
   - Manqué → "Faire en auto-correction (deadline dépassée)"
3. `HomeworkSessionScreen` — QCM (radio-list) ou question ouverte
   (TextField), barre progression "Question X/N", timer, boutons
   Précédent/Suivant/Terminer. Confirmation avant soumission finale.
4. `HomeworkResultsScreen` — score circulaire %, note /20, temps,
   badge retard, feedback motivant (phrase clé "Tu progresses en
   {matière} ! Continue !"), correction détaillée question par
   question (ta réponse / bonne réponse / explication).

## Flux enseignant

1. `TeacherHomeworkList` — FAB "Nouveau devoir", cartes avec mini-stats
   (moyenne / taux rendu / manqués), bouton stats globales (dialog).
2. `TeacherHomeworkCreate` — 3 sections :
   - Infos générales (titre, description, matière)
   - Cible & deadline (classes multi-sélection, date picker, durée)
   - Questions (banque mock par matière + création QCM manuelle)
3. `TeacherHomeworkResults` — header avec 3 KPI cards (rendus / en
   cours / manqués) + 3 stats globales (moyenne / temps moyen / taux
   rendu). 2 onglets :
   - **Élèves** : tableau triable (nom / classe / note / temps),
     filtre par classe, tap → dialog détail élève.
   - **Questions** : analyse par item (% réussite, barre, label
     "Bien maîtrisée / Fragile / À retravailler", correction).
   Bouton export CSV (copie dans presse-papier + aperçu dialog).

## Style & cohérence

- Couleurs : `AppColors` (vert Togo #006837, orange #D97700) +
  `AdaptiveColors` pour le dark mode.
- Typographies : `AppTextStyles` (h1/h2/h3/body/bodySmall/label/button).
- Material 3, Provider pattern, `Consumer<HomeworkService>`.
- Commentaires en français, aucun emoji dans le code source.
- Style homogène avec `admin_dashboard_screen.dart` (KPI cards,
  TabBar, écrans avec sections `_buildXxx()`) et `revision_screen.dart`
  (barre progression, dialog quitter, feedback motivant).

## Wiring (à faire par l'agent principal)

### 1. `pubspec.yaml`
Aucune dépendance à ajouter (Material + Provider déjà présents).

### 2. `lib/main.dart` — enregistrer le Provider
```dart
MultiProvider(
  providers: [
    // ... providers existants ...
    ChangeNotifierProvider<HomeworkService>(
      create: (_) => HomeworkService(),
    ),
  ],
  child: ...
)
```

### 3. `lib/utils/app_router.dart` — ajouter les routes
```dart
GoRoute(
  path: '/homework',
  builder: (context, state) => const HomeworkListScreen(),
),
GoRoute(
  path: '/homework/:id',
  builder: (context, state) =>
      HomeworkDetailScreen(homeworkId: state.pathParameters['id']!),
),
GoRoute(
  path: '/teacher/homework',
  builder: (context, state) => const TeacherHomeworkList(),
),
// Les sous-écrans (session, results, create, teacher_results)
// utilisent Navigator.push() interne — pas besoin de routes GoRouter.
```

### 4. `lib/screens/home/home_screen.dart` — cartes d'accès
Ajouter 2 cartes dans la home :
- "Mes devoirs" → `/homework` (côté élève)
- "Espace enseignant" → `/teacher/homework` (côté prof)

## Limitations & TODO

- Pas de persistance Hive (les devoirs créés disparaissent au redémarrage).
  → Brancher sur `boxes['homeworks']` + adapter `homework.dart` en
  `@HiveType` quand le backend FastAPI sera prêt.
- 2e tentative non implémentée (l'élève ne peut pas refaire un devoir
  déjà rendu).
- Questions ouvertes : auto-correction souple (l'élève peut saisir une
  réponse libre, comparaison exacte sensible à la casse).
  → Pour les questions vraiment ouvertes (rédaction), prévoir un workflow
  d'auto-évaluation (l'élève coche "Je pense avoir juste" avant de voir
  la correction).
- Pas de notifications push (deadline proche, nouveau devoir).
- Export CSV : copie dans le presse-papier. Prévoir un vrai partage
  fichier (`share_plus`) ou un download web.
- Backend FastAPI : endpoints à créer
  - `POST /homeworks` (créer)
  - `GET /homeworks?eleve_id=X` (liste élève)
  - `GET /homeworks/:id/submissions` (liste enseignant)
  - `POST /homeworks/:id/submit` (soumettre)
