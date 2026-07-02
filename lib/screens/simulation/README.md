# Mode Examen Authentique — lib/screens/simulation/

Variante enrichie de l'écran de simulation (Agent C, Session 1) qui ajoute une
**couche d'authenticité** au mode examen : calculatrice scientifique intégrée,
feuille de brouillon tactile, en-tête officiel BEPC/BAC, minuterie avec
alarmes, options d'accessibilité (dyslexie, contraste élevé, temps +25%, TTS).

L'objectif est que l'élève s'entraîne dans des **conditions réelles d'examen**
plutôt que dans une simple liste de questions chronométrées.

## Fichiers créés

```
lib/
├── models/
│   └── accessibility_settings.dart      (Hive typeId 8)
├── services/
│   └── accessibility_service.dart        (singleton + helpers)
├── widgets/exam/                          (NOUVEAU dossier)
│   ├── calculator_widget.dart             (calculatrice scientifique)
│   ├── scratch_sheet_widget.dart          (brouillon tactile)
│   ├── exam_header_official.dart          (en-tête officiel)
│   ├── exam_timer_official.dart           (minuterie + alarmes)
│   ├── accessibility_options.dart         (dialog accessibilité)
│   └── exam_submit_dialog.dart            (dialog soumission + cachet)
└── screens/simulation/
    ├── authentic_examen_screen.dart       (variante enrichie)
    └── README.md                           (CE FICHIER)
```

**NE PAS MODIFIER** `simulation_screen.dart` (Agent C, ~2000 lignes) — il reste
l'écran de simulation "standard". `authentic_examen_screen.dart` est une
variante optionnelle que l'agent wiring peut activer à la place.

## Architecture en bref

| Composant | Rôle | Persistance |
|-----------|------|-------------|
| `AccessibilitySettings` | Préférences de l'utilisateur (HiveObject) | Box Hive `accessibility`, clé `settings` |
| `AccessibilityService` | Singleton synchronisé + helpers `adjustTextStyle`, `adjustDuration`, `backgroundColor`, `textColor` | Cache interne + Hive |
| `CalculatorWidget` | Calculatrice scientifique (Dialog/BottomSheet) | Historique en mémoire (per-session) |
| `ScratchSheetWidget` | Brouillon tactile (CustomPaint + gestures) | Box Hive `scratch_sheets`, clé `scratch_<examId>_q<index>` |
| `ExamHeaderOfficial` | En-tête officiel BEPC/BAC (Republique Togolaise) | Sans état |
| `ExamTimerOfficial` | Minuterie + alarmes SystemSound + HapticFeedback | Sans état (parent) |
| `AccessibilityOptionsDialog` | UI d'édition des préférences | Via `AccessibilityService.update()` |
| `ExamSubmitDialog` | Confirmation de soumission + cachet animé | Sans état |
| `AuthenticExamenScreen` | Variante enrichie du SimulationScreen | Réponses en mémoire (session) |

## Dépendances à ajouter au pubspec.yaml

Aucune dépendance n'a été ajoutée au pubspec.yaml (par respect de la consigne).
Les widgets utilisent uniquement des packages déjà présents :

- `hive` / `hive_flutter` (déjà présent) — pour la persistance
- `flutter/services.dart` (SDK) — pour `SystemSound.alert` + `HapticFeedback`

### Optionnel — pour aller plus loin

Si l'agent wiring souhaite activer certaines features avancées, ajouter au
`pubspec.yaml` :

```yaml
dependencies:
  # Parser mathématique (alternative au parser maison de calculator_widget.dart)
  # NON REQUIS : un parser shunting-yard sécurisé est déjà implémenté en interne.
  math_expressions: ^2.6.0

  # Sons riches pour la minuterie (bip personnalisé, sonnerie finale)
  # NON REQUIS : SystemSound.alert est utilisé par défaut.
  # Si ajouté, brancher via le callback `onAlert` de ExamTimerOfficial.
  audioplayers: ^5.2.1

  # Police OpenDyslexic pour l'option dyslexiaFont
  # NON REQUIS : fallback Roboto + letterSpacing si police absente.
  # Si ajouté, déclarer dans flutter.fonts de pubspec.yaml :
  #   fonts:
  #     - family: OpenDyslexic
  #       fonts:
  #         - asset: assets/fonts/OpenDyslexic-Regular.ttf
  #         - asset: assets/fonts/OpenDyslexic-Bold.ttf
  #           weight: 700

  # Lecture audio des énoncés (TTS)
  # NON REQUIS : le bouton "Lire l'énoncé" affiche un SnackBar explicatif.
  # Si ajouté, remplacer le SnackBar dans authentic_examen_screen.dart
  # _buildQuestionDocument par FlutterTts().setLanguage('fr-FR') + .speak(q.enonce).
  flutter_tts: ^4.0.2
```

## Wiring — comment activer AuthenticExamenScreen

L'agent de wiring doit faire 4 actions (aucun autre fichier n'est touché) :

### 1. Enregistrer l'adaptateur Hive dans `main.dart`

Après `Hive.initFlutter()` et **avant** `runApp()`, ajouter :

```dart
import 'models/accessibility_settings.dart';
import 'services/accessibility_service.dart';

// ... après les autres registerAdapter ...

Hive.registerAdapter(AccessibilitySettingsAdapter());

// ... après les autres openBox ...

await Hive.openBox<AccessibilitySettings>('accessibility');
await AccessibilityService.init();
```

### 2. Générer les adaptateurs Hive

```bash
cd /home/z/my-project/ExamBoost-Togo
dart run build_runner build --delete-conflicting-outputs
```

Cela génère `lib/models/accessibility_settings.g.dart`.

### 3. Ajouter la route dans `lib/utils/app_router.dart`

Option A — **Remplacer** le SimulationScreen existant par la variante enrichie
(recommandé pour le pitch DJANTA du 24 juillet 2026) :

```dart
// AVANT
// import '../screens/simulation/simulation_screen.dart';
// ...
// GoRoute(
//   path: '/simulation',
//   builder: (context, state) => const SimulationScreen(),
// ),

// APRÈS
import '../screens/simulation/authentic_examen_screen.dart';
// ...
GoRoute(
  path: '/simulation',
  builder: (context, state) {
    final examen = state.uri.queryParameters['examen'];
    final serie = state.uri.queryParameters['serie'];
    return AuthenticExamenScreen(
      examen: examen,
      serie: serie,
    );
  },
),
```

Option B — **Coexistence** des deux écrans (simulation standard + simulation
authentique sur deux routes) :

```dart
import '../screens/simulation/simulation_screen.dart';
import '../screens/simulation/authentic_examen_screen.dart';
// ...
GoRoute(
  path: '/simulation',
  builder: (context, state) => const SimulationScreen(),
),
GoRoute(
  path: '/simulation/authentique',
  builder: (context, state) {
    final examen = state.uri.queryParameters['examen'];
    final serie = state.uri.queryParameters['serie'];
    return AuthenticExamenScreen(examen: examen, serie: serie);
  },
),
```

### 4. (Optionnel) Ajouter un bouton "Examen authentique" dans le dashboard

Dans `lib/screens/dashboard/dashboard_screen.dart`, ajouter une carte qui
pointe vers `/simulation/authentique` (Option B) ou qui garde la route
`/simulation` (Option A — transparent).

## API publique

### Calculatrice

```dart
final resultat = await CalculatorWidget.show(context);
// resultat = "12.5" (ou null si l'utilisateur a fermé sans insérer)
```

### Brouillon

```dart
await showScratchSheet(
  context,
  examId: 'BEPC-2026-sim-001',
  questionIndex: 3,
);
// Le brouillon est automatiquement sauvegardé dans Hive et restauré
// si l'élève quitte et revient sur la même question.
```

### En-tête officiel

```dart
ExamHeaderOfficial(
  examen: 'BEPC',
  serie: null, // 'C' pour BAC, null pour BEPC
  session: 2026,
  epreuve: 'Mathématiques',
  duree: '2h',
  coefficient: '4',
)
// Masqué automatiquement si AccessibilitySettings.soberMode == true.
```

### Minuterie officielle

```dart
ExamTimerOfficial(
  duration: Duration(minutes: 120),
  onTimeout: () => print('Temps écoulé !'),
  onAlert: (level) => print('Alerte: $level'),
  canPause: false, // true seulement en mode rapide + AccessibilitySettings.allowPauses
  compact: true, // true pour AppBar, false pour grand format
)
```

Le `GlobalKey<ExamTimerOfficialState>` permet d'accéder à `tempsRestant`,
`enPause`, `pause()`, `resume()`, `basculerPause()`.

### Options d'accessibilité

```dart
await AccessibilityOptionsDialog.show(context);
// Les préférences sont persistées dans Hive via AccessibilityService.update().
// Le widget parent doit appeler setState() pour rebuild avec les nouveaux styles.
```

### Dialogue de soumission

```dart
final confirme = await ExamSubmitDialog.show(
  context,
  totalQuestions: 20,
  questionsRepondues: 18,
  tempsRestant: '00:15:30',
  nomExamen: 'BEPC - Mathématiques',
);
if (confirme) {
  // Procéder à la soumission (passer au rapport).
}
```

## Décisions de conception

### Parser mathématique maison (sans `math_expressions`)

La calculatrice ne fait pas `eval()` (sécurité). Un parser shunting-yard de
Dijkstra est implémenté en interne (`_MathParser` dans
`calculator_widget.dart`) :
- Tokenisation des nombres, identifiants, opérateurs, parenthèses.
- Conversion en RPN (notation polonaise inverse) avec gestion de la priorité
  et de l'associativité (gauche-droite sauf pour `^` qui est droitier).
- Évaluation RPN avec pile.
- Fonctions reconnues : `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `log`
  (base 10), `ln`, `sqrt`, factorielle postfixée `!`.
- Constantes : `pi`, `e`.
- Opérateurs : `+`, `-`, `*`, `/`, `%`, `^`.
- Opérateur unaire `-` géré par insertion d'un `0` (ex : `-5` → `0-5`).
- Aucune exécution de code arbitraire : tout symbole non reconnu lève une
  `_MathErreur`.

Si l'agent wiring préfère `math_expressions`, il peut remplacer `_MathParser`
par `Parser().parse(expression).evaluate(EvaluationType.REAL, ContextModel())`
et supprimer ~250 lignes. Le reste du widget est inchangé.

### Sons via SystemSound plutôt qu'audioplayers

`SystemSound.play(SystemSoundType.alert)` est utilisé pour les bips car :
- Aucune dépendance externe requise.
- Fonctionne sur toutes les plateformes (iOS, Android, desktop).
- Suffisamment distinctif pour les seuils de temps.

Pour des sons personnalisés (3 sons distincts comme demandé dans le brief),
brancher `audioplayers` via le callback `onAlert` du `ExamTimerOfficial` :

```dart
ExamTimerOfficial(
  duration: ...,
  onTimeout: ...,
  onAlert: (level) async {
    final player = AudioPlayer();
    switch (level) {
      case TimerAlertLevel.info30:
      case TimerAlertLevel.warning10:
      case TimerAlertLevel.warning5:
      case TimerAlertLevel.critical1:
        await player.play(AssetSource('sounds/bip_court.mp3'));
        break;
      case TimerAlertLevel.final_:
        await player.play(AssetSource('sounds/sonnerie_finale.mp3'));
        break;
    }
  },
)
```

### Vibration via HapticFeedback

`HapticFeedback.lightImpact()`, `mediumImpact()`, `heavyImpact()` du SDK
Flutter sont utilisés (pas besoin de `vibration` package). Désactivable via
`AccessibilitySettings.vibrationAlerts`.

### Brouillon : strokes sérialisés en JSON

Plutôt que d'exporter un PNG (qui nécessite `ui.Image.toByteData` + un plugin
pour sauvegarder en fichier), les **strokes** (liste de points + couleur +
épaisseur) sont sérialisés en JSON et stockés dans une box Hive `scratch_sheets`.
Avantages :
- Pas de plugin de fichier requis.
- Restauration parfaite (redessine les strokes au lieu de charger un bitmap).
- Permet l'undo/redo après restauration.
- Taille de stockage réduite (quelques KB par question vs centaines de KB pour
  un PNG).

### Accessibilité : pas de `OpenDyslexic` par défaut

La police `OpenDyslexic` n'est pas incluse dans les assets (droits + taille).
Si l'élève active `dyslexiaFont` :
- Si la police est déclarée dans le pubspec (font family `OpenDyslexic`), elle
  est utilisée.
- Sinon, `Roboto` est utilisé avec `letterSpacing: 0.5` (effet de respiration
  entre les lettres, aidant la lecture pour certains dyslexiques).

L'agent wiring peut ajouter `OpenDyslexic` dans `pubspec.yaml` :
```yaml
flutter:
  fonts:
    - family: OpenDyslexic
      fonts:
        - asset: assets/fonts/OpenDyslexic-Regular.ttf
        - asset: assets/fonts/OpenDyslexic-Bold.ttf
          weight: 700
```

### Temps additionnel +25% appliqué au niveau de la minuterie

Le `ExamTimerOfficial` reçoit la durée **brute** (ex : 2h) et applique lui-même
`AccessibilityService.adjustDuration()` (→ 2h30 si +25% activé). Cela évite
à l'écran parent de dupliquer la logique d'ajustement. Le badge "+25%" est
affiché automatiquement dans la minuterie.

### Plan d'examen : pas de duplication avec SimulationScreen

Le plan d'examen dans `authentic_examen_screen.dart` est volontairement
simplifié par rapport à celui de `simulation_screen.dart` (Agent C) pour éviter
de dupliquer ~200 lignes. L'agent wiring peut si besoin extraire le widget
`_buildPlanExamen` dans un widget partagé `lib/widgets/exam/exam_plan_sheet.dart`
(à faire en V2).

## Conformité aux consignes

- Aucun fichier modifié en dehors du périmètre autorisé.
- Aucun emoji dans le code (les `──`, `│`, `├` sont des box-drawing chars
  cohérents avec le reste du projet).
- Commentaires en français.
- Flutter 3.44+ / Material 3.
- `simulation_screen.dart` (Agent C) n'est **pas** modifié — il reste l'écran
  standard. `authentic_examen_screen.dart` est une variante optionnelle.
- Pas d'ajout au `pubspec.yaml` (dépendances optionnelles documentées ci-dessus
  pour activation future).
- Le `README.md` (ce fichier) documente le wiring pour l'agent principal.

## Tests rapides (sans flutter installé)

Vérifications syntaxiques déjà effectuées :
- Aucune apostrophe non échappée dans les littéraux string.
- Toutes les `switch` sur `QuestionType` sont exhaustives.
- Aucun import circulaire.
- Tous les widgets utilisent `AppColors` / `AppTextStyles` du thème existant.

## Prochaines étapes possibles (V2)

1. Extraction du plan d'examen en widget partagé.
2. Activation de `flutter_tts` pour la lecture audio des énoncés.
3. Activation de `audioplayers` pour 3 sons distincts (bip court, bip long,
   sonnerie finale).
4. Ajout d'une police `OpenDyslexic` dans les assets.
5. Surligneur interactif sur les énoncés (long-press + drag pour sélectionner).
6. Instructions simplifiées : fichier JSON de réécriture `{questionId: enonce_simplifié}`.
7. Export du brouillon en PNG (via `ui.Image.toByteData`) pour partage.
8. Cache PDF officiel du BEPC/BAC pour afficher le vrai sujet (à terme).
