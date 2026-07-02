# Mode "Révision vocale" — Saisie de la réponse au micro

L'élève peut **dicter sa réponse** au lieu de la taper. Cas d'usage :

- Révision en marchant / dans les transports
- Élèves dyslexiques (saisie textuelle pénible)
- Apprentissage auditif (couplé au TTS déjà implémenté par l'Agent AQ)

Ce dossier contient l'écran `voice_answer_mode.dart` (variante de `revision_screen.dart`).
Les widgets et services associés vivent dans `lib/widgets/` et `lib/services/`.

## Fichiers créés (Agent BL — task `BL-voice-answers`)

```
lib/
├── models/
│   └── voice_settings.dart            # Préférences (langue, seuils, etc.)
├── services/
│   ├── voice_input_service.dart       # Wrapper speech_to_text
│   └── voice_comparison_service.dart  # Comparaison (Levenshtein + heuristique)
├── widgets/
│   ├── voice_answer_button.dart       # Bouton micro animé
│   ├── voice_answer_indicator.dart    # Vague animée pendant l'écoute
│   └── voice_result_display.dart      # Affichage transcription + verdict
└── screens/revision/
    ├── voice_answer_mode.dart         # Écran mode vocal (variante RevisionScreen)
    └── README.md                      # Ce fichier
```

## Dépendance : `speech_to_text: ^7.0.0`

Le package est **déjà déclaré** dans `pubspec.yaml` (ligne 57) :

```yaml
dependencies:
  # ─── Capteurs & saisie (Session 3) ────────────────────────────
  speech_to_text: ^7.0.0       # Agent BL : reconnaissance vocale réponses
```

Si la ligne a été retirée, la ré-ajouter dans la section `dependencies` :

```yaml
speech_to_text: ^7.0.0
```

Puis :

```bash
flutter pub get
```

## Permissions requises

`speech_to_text` a besoin de la permission **microphone** sur chaque plateforme.

### Android — `android/app/src/main/AndroidManifest.xml`

Ajouter au-dessus de la balise `<application>` :

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
```

Note : `INTERNET` est requis car le moteur speech_to_text par défaut envoie
l'audio au service Google (sauf si `ListenMode.deviceOnly` est utilisé, mais
cette option n'est pas supportée sur tous les appareils).

### iOS — `ios/Runner/Info.plist`

Ajouter dans le dictionnaire racine `<dict>` :

```xml
<key>NSMicrophoneUsageDescription</key>
<string>ExamBoost utilise le micro pour la saisie vocale des réponses en mode révision.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>ExamBoost utilise la reconnaissance vocale pour comparer ta réponse dictee à la bonne réponse.</string>
```

Sans ces clés, l'app crash au premier appel à `speech.initialize()` sur iOS.

### Web / Desktop

`speech_to_text` n'est **pas supporté** sur web ni desktop. Le widget
`VoiceAnswerButton` se masque automatiquement (`SizedBox.shrink()`) sur ces
plateformes grâce à `defaultTargetPlatform` + `kIsWeb`.

## Wiring (à faire par l'agent principal)

Le mode vocal n'est PAS encore routé dans `app_router.dart` (contrainte de la
tâche : ne pas toucher au router). Pour l'activer :

1. **Enregistrer les services dans `main.dart`** (juste après les autres
   `Provider`) :

```dart
import 'services/voice_input_service.dart';
import 'services/voice_comparison_service.dart';

MultiProvider(
  providers: [
    // ... providers existants ...
    ChangeNotifierProvider<VoiceInputService>(
      create: (_) => VoiceInputService(),
    ),
    Provider<VoiceComparisonService>(
      create: (_) => VoiceComparisonService(),
    ),
  ],
  child: ...
)
```

2. **Ajouter une route dans `app_router.dart`** :

```dart
GoRoute(
  path: 'revision-vocale/:matiere',
  builder: (context, state) => VoiceAnswerMode(
    matiere: state.pathParameters['matiere']!,
    userId: 'user_demo', // remplacer par UserProvider.userId
  ),
),
```

3. **Ajouter un bouton d'accès depuis `revision_screen.dart`** (par exemple
   dans l'AppBar) :

```dart
IconButton(
  icon: const Icon(Icons.mic),
  onPressed: () => context.go('/revision-vocale/${widget.matiere}'),
  tooltip: 'Mode révision vocale',
),
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│ VoiceAnswerMode (StatefulWidget, TickerProvider)                 │
│  └─ chargement QuestionService.getByMatiere + VoiceSettings.load  │
│  └─ écoute VoiceInputService via Consumer/Provider                │
│                                                                   │
│  UI:                                                              │
│  ┌─ QuestionCard (carte flip, comme RevisionScreen)              │
│  ├─ VoiceAnswerButton (déclenche écoute)                         │
│  │    └─ VoiceAnswerIndicator (vague animée pendant l'écoute)    │
│  └─ VoiceResultDisplay (verdict + transcription + score)         │
│                                                                   │
│  Logique:                                                         │
│  ┌─ VoiceInputService.startListening(onFinal: transcription)     │
│  ├─ VoiceComparisonService.compare(transcription, question.reponse)│
│  └─ qualité SRS dérivée du verdict (correct→5, partial→3,         │
│     incorrect→1) puis SrsService.recordAnswer + AppUser.updateBkt │
└──────────────────────────────────────────────────────────────────┘
```

## Algorithme de comparaison (`VoiceComparisonService`)

Pipeline :

1. **Normalisation canonique** des deux textes :
   - lowercase
   - suppression accents (`é→e`, `ç→c`, `à→a`, etc.)
   - expansion symboles (`=` → `egale`, `²` → `2`, `+` → `plus`, etc.)
   - conversion mots-nombres français en chiffres (`cinq → 5`, `vingt → 20`,
     `soixante-douze → 72`, etc. — map couvre 0-100 + grands nombres)
   - normalisation unités (`centimetres → cm`, `metres → m`, `carres → 2`,
     etc. — ordre important pour éviter les conflits)
   - suppression ponctuation résiduelle
   - collapse espaces multiples

2. **Distance de Levenshtein** sur les formes canoniques → `simLev`

3. **Heuristique sur les tokens numériques** :
   - Si la réponse attendue contient des nombres :
     - Si AU MOINS UN nombre attendu matche → `sim = max(simLev, 0.6)`
       (plancher "partiel" pour les réponses incomplètes comme `"5"` vs `"x = 5"`)
     - Si un nombre incorrect est cité (`"trois"` au lieu de `"5"`) → `sim = 0.2`
     - Sinon → `sim = simLev`
   - Sinon : `sim = simLev`

4. **Verdict** selon les seuils (configurables via `VoiceSettings`) :
   - `sim >= 0.80` → `correct`
   - `sim >= 0.50` → `partial`
   - `sim < 0.50` → `incorrect`

### Cas de test validés

| Réponse attendue | Transcription | Verdict   | Similarité |
|------------------|---------------|-----------|------------|
| `x = 5`          | `x égale cinq`   | correct   | 100%       |
| `x = 5`          | `x égal 5`      | correct   | ~89%       |
| `x = 5`          | `5`             | partial   | 60%        |
| `x = 5`          | `x égale trois` | incorrect | 20%        |
| `20 cm²`         | `vingt centimètres carrés` | correct | 100% |
| `20 cm²`         | `20 cm2`        | correct   | 100%       |
| `20 cm²`         | `vingt`         | partial   | 60%        |

## Préférences (`VoiceSettings`)

Persistées via **SharedPreferences** (clé `voice_settings`, JSON sérialisé).
On n'utilise PAS Hive pour éviter d'avoir à enregistrer un adaptateur dans
`main.dart` (contrainte de wiring).

Champs :

| Champ                       | Défaut   | Description                                            |
|-----------------------------|----------|--------------------------------------------------------|
| `enabled`                   | `true`   | Active/désactive globalement la saisie vocale          |
| `language`                  | `fr_FR`  | Locale BCP-47 (speech_to_text)                         |
| `silenceThresholdMs`        | `2000`   | Silence (ms) déclenchant la fin de parole              |
| `maxListenSeconds`          | `30`     | Durée max d'écoute avant arrêt forcé                   |
| `similarityThreshold`       | `0.80`   | Seuil au-dessus duquel = correct                       |
| `partialThreshold`          | `0.50`   | Seuil au-dessus duquel = partiel                       |
| `showPartialTranscription`  | `true`   | Affiche la transcription live pendant l'écoute         |
| `hapticFeedback`            | `true`   | Vibration au début/fin de l'écoute                     |
| `soundFeedback`             | `false`  | Bip discret au début/fin                               |
| `speakVerdict`              | `false`  | Prononce le verdict via TtsService                     |
| `autoNextOnCorrect`         | `false`  | Passe à la question suivante si verdict = correct      |

## Limitations connues

- **Mots-nombres > 100** : la map couvre 0-100 + `mille`, `million`,
  `milliard`. Les composés comme `cent vingt` (= 120) ne sont pas gérés
  (la similarité Levenshtein compense).
- **Connexion réseau** : le moteur speech_to_text par défaut envoie l'audio
  au service Google (sauf `ListenMode.deviceOnly`). Prévoir un message
  d'erreur si hors-ligne.
- **Accent régional** : la reconnaissance peut être moins précise avec un
  accent togolais marqué. Le seuil de similarité (80%) compense en partie.
- **QCM** : le mode vocal est conçu pour les questions à réponse OUVERTE.
  Pour les QCM, l'élève devrait dire "A", "B", "C" ou "D" — la comparaison
  fonctionne mais n'a pas été optimisée pour ce cas.
