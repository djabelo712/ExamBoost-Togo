# Mode Révision Flash 5 min — `lib/screens/flash/`

Sessions courtes "transport" (métro, bus) : **5 questions en 5 minutes**,
optimisé pour usage mobile rapide.

## Structure

```
lib/screens/flash/
├── flash_intro_screen.dart           # Intro mode flash
├── flash_session_screen.dart         # Session 5 min
├── flash_results_screen.dart         # Résultats rapides
├── widgets/
│   ├── flash_timer_widget.dart       # Timer 5 min visible
│   ├── flash_question_card.dart      # Carte question simplifiée
│   └── flash_progress_dots.dart      # 5 dots progression
├── services/
│   └── flash_service.dart            # Logique sélection 5 questions
└── README.md
```

## Flow utilisateur

1. **Intro** (`FlashIntroScreen`) : présente le concept "5 questions en 5 min"
   + bouton "C'est parti".
2. **Session** (`FlashSessionScreen`) : timer 5:00 visible en haut, 5 dots de
   progression, carte question simplifiée. L'élève voit la réponse, puis
   s'auto-évalue (Correct / Incorrect). Auto-passe à la suivante après 60 s
   sans réponse.
3. **Résultats** (`FlashResultsScreen`) : score X/5, temps utilisé, message
   "Tu as amélioré P(L) en {matiere}" (ou matière la plus faible si 0/5),
   détail question par question (vert/rouge), boutons "Recommencer" et
   "Révision complète".

## Sélection intelligente (FlashService)

Le service `FlashService.selectFlashQuestions` applique la logique suivante :

1. **Pool** : toutes les questions disponibles (via `QuestionService.matieres`
   + `getByMatiere`), moins les IDs exclus.
2. **Score de priorité** pour chaque question :
   - `(1 - P(L)) * 0.60` : on cible d'abord les compétences faibles
     (P(L) issu du BKT stocké dans `AppUser.bktMaitrise`).
   - `+ 0.30` si la question n'a jamais été tentée (bonus nouveauté, via
     `SrsService.getOrCreate` + `totalAttempts`).
   - `- |b - theta| * 0.15` : on pénalise les questions trop faciles ou trop
     difficiles par rapport au niveau IRT de l'élève (`AppUser.thetaIrt`).
3. **Tri** par score décroissant.
4. **Mix matières** : au maximum 2 questions par matière (constante
   `maxParMatiere = 2`) pour éviter 5 maths d'affilée.
5. **Fallback** : si on n'a pas 5 questions avec la contrainte matière, on
   complète sans contrainte.

## Mises à jour de l'apprentissage

À chaque réponse (Correct/Incorrect/Passer/Auto-passe) :

- **SRS SM-2** (`SrsService.recordAnswer`) : qualité 5 si correct, 1 sinon.
  Met à jour l'intervalle de révision de la carte.
- **BKT** (`AppUser.updateBkt`) : met à jour P(L) de la compétence concernée.
  Persistance Hive immédiate.

Ces mises à jour sont **asynchrones et non bloquantes** : l'UI avance
immédiatement à la question suivante.

## Mesure de progression (écran de résultats)

`FlashService.matiereAvecPlusDeProgression` compare les P(L) avant et après
session :

1. Snapshot AVANT : `Map<String, double>` des P(L) de l'utilisateur au début
   de la session (capturé dans `FlashSessionScreen._initialiserSession`).
2. Snapshot APRÈS : on relit `AppUser` depuis Hive après la session (BKT
   déjà mis à jour).
3. Pour chaque matière, on calcule la hausse moyenne de P(L).
4. On retourne la matière avec la plus forte hausse.

Si aucune matière n'a progressé (ex : 0/5), on affiche
`FlashService.matiereLaPlusFaible` (matière avec P(L) moyenne la plus basse).

## Design

- **UI minimaliste** : gros boutons (Correct / Incorrect), texte lisible,
  pas d'explication détaillée (trop longue à lire en marchant).
- **Animations rapides** : `AnimatedSwitcher` 180 ms (au lieu du flip 350 ms
  de `QuestionCard` classique). Pas de Lottie, pas de confettis.
- **Couleurs vives** pour engagement :
  - Vert `AppColors.success` pour "Correct"
  - Rouge `AppColors.error` pour "Incorrect"
  - Orange `AppColors.accent` pour le timer critique et le bouton "C'est parti"
  - Vert Togo `AppColors.primary` pour la progression
- **Timer** : devient rouge (`AppColors.error`) quand il reste < 60 s.
- **Dark mode** : via `AdaptiveColors` et l'extension `context.isDark`.

## Contraintes techniques

- **Flutter 3.44+** / **Material 3** / **Provider** (compatible avec le
  reste du projet).
- **Pas d'emojis** dans le code (convention projet).
- **Commentaires FR** (convention projet).
- **Pas de dépendance sur le router** : les écrans sont poussés via
  `Navigator.push` / `pushReplacement`, pas via GoRouter. Le wiring final
  (carte home + route `/flash`) sera fait par l'agent principal.
- **Pas de modification** de `main.dart`, `app_router.dart`, `pubspec.yaml`,
  `home_screen.dart` ou tout autre fichier hors `lib/screens/flash/`.

## Branchement (à faire par l'agent principal)

Pour activer le mode Flash depuis la home :

1. **Ajouter une carte** dans `home_screen.dart` :
   ```dart
   _ActionCard(
     icon: Icons.flash_on,
     title: 'Mode Flash 5 min',
     subtitle: '5 questions en 5 min, parfait dans les transports',
     color: AppColors.accent,
     onTap: () => Navigator.of(context).push(
       MaterialPageRoute(
         builder: (_) => const FlashIntroScreen(),
       ),
     ),
   ),
   ```
2. **(Optionnel) Ajouter une route** `/flash` dans `app_router.dart` si on
   préfère GoRouter. Le `FlashIntroScreen` peut recevoir un `userId` en
   paramètre (sinon il lit `UserProvider.currentUserId`).

## Dépendances externes

- `QuestionService` (Provider) : chargement des questions.
- `SrsService` (Provider) : enregistrement SM-2 + info "déjà tentée".
- `AppUser` (Hive box `users`) : P(L) BKT + theta IRT.
- `UserProvider` (Provider) : utilisateur courant.
- Aucune nouvelle dépendance `pubspec.yaml`.

## Limitations connues

- Le timer par question (60 s) est **réinitialisé** quand l'élève clique
  "Voir la réponse" — il dispose donc de 60 s supplémentaires pour
  s'auto-évaluer. Compromis UX pour le mode transport (lecture de la
  réponse + décision).
- Si l'élève quitte la session en cours (dialog "Quitter"), les questions
  non répondues ne sont **pas** enregistrées comme incorrectes (elles
  restent à `null` dans `_resultats`, mais la session est abandonnée).
- La sélection intelligente ne prend pas en compte les **cartes dues
  aujourd'hui** (SrsService.getDueCards) — on privilégie systématiquement
  les compétences faibles. Une variante "Flash révisions dues" pourrait
  être ajoutée plus tard.
