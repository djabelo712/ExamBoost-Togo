# Tuteur IA in-app — ExamBoost Togo

Tuteur IA conversationnel (chatbot Claude) intégré à l'app Flutter.
L'élève pose n'importe quelle question sur n'importe quel chapitre ; le
tuteur répond avec des exemples contextualisés au Togo (FCFA, villes,
vie quotidienne, BEPC/BAC).

> Périmètre : ce dossier `lib/screens/tutor/` + 2 fichiers backend
> (`backend/routers/tutor.py` et `backend/services/tutor_service.py`).
> Aucune autre partie du projet n'a été modifiée (router, main.dart,
> pubspec.yaml, autres écrans, models existants).

## Structure

```
lib/screens/tutor/
├── tutor_screen.dart             # Écran principal chat (Material 3)
├── tutor_controller.dart         # ChangeNotifier (messages, loading, erreur)
├── models/
│   └── chat_message.dart         # Message {id, role, content, timestamp, matiere, isError}
├── services/
│   └── tutor_service.dart        # Appel backend /tutor/ask (dio + connectivity_plus)
├── widgets/
│   ├── message_bubble.dart       # Bulle user/IA + rendu markdown léger
│   ├── typing_indicator.dart     # Animation "le tuteur écrit..." (3 points)
│   ├── suggestion_chips.dart     # 6 questions suggérées au démarrage
│   └── voice_input_button.dart   # Bouton micro (stub, activation voir §4)
└── README.md                     # Ce fichier

backend/
├── routers/tutor.py              # POST /tutor/ask + GET /tutor/health
└── services/tutor_service.py     # Claude API via anthropic SDK + fallback mock
```

## Fonctionnalités

- Chat conversationnel (user à droite / IA à gauche, bulles vertes/grises)
- Markdown léger sans dépendance externe : **gras**, *italique*, `code inline`,
  blocs de code (```...```), listes à puces, listes numérotées, titres # ## ###
- Typing indicator animé (3 points sautillants) pendant la réflexion IA
- 6 suggestions de questions au démarrage (Pythagore, factorisation, métaphore,
  loi d'Ohm, subjonctif, Thalès)
- Suggestions de follow-up dynamiques (renvoyées par le backend)
- Persistance Hive de la dernière conversation (box "tutor_conversations")
- Bouton "Nouvelle conversation" + bouton "Effacer" (avec confirmation)
- Détection hors-ligne (connectivity_plus) + bandeau d'avertissement
- Gestion des erreurs : bulle rouge + bouton "Réessayer"
- Rate limiting 30 questions/heure/user côté backend (in-memory)
- Voice input (stub — voir §4 pour activer)
- Bouton "Joindre une photo" (UI seulement v1 — voir §5)

## Intégration — À faire par l'agent principal

### 1. Ajouter la route `/tutor` au router Flutter

Dans `lib/utils/app_router.dart` :

```dart
// 1. Import en haut du fichier :
import '../screens/tutor/tutor_screen.dart';

// 2. Ajouter la constante de route dans la classe AppRoutes :
class AppRoutes {
  // ... routes existantes ...
  static const String tutor = '/tutor';
}

// 3. Ajouter la route dans le GoRouter.routes :
GoRoute(
  path: AppRoutes.tutor,
  name: 'tutor',
  builder: (context, state) {
    // Récupère l'éventuel token JWT depuis le UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.authToken; // à exposer dans UserProvider
    final extra = state.extra as Map<String, dynamic>?;
    return TutorScreen(
      authToken: token,
      matiere: extra?['matiere'] as String?,
      chapitre: extra?['chapitre'] as String?,
      competenceId: extra?['competence_id'] as String?,
    );
  },
),
```

> Note : `UserProvider` ne expose pas encore `authToken`. À ajouter dans
> `lib/providers/user_provider.dart` (le backend `/auth/login` renvoie déjà un
> JWT `access_token`). Voir §6.

### 2. Ajouter un bouton "Tuteur IA" dans home_screen.dart

Dans `lib/screens/home/home_screen.dart`, ajouter une `_ActionCard` :

```dart
_ActionCard(
  icon: Icons.smart_toy,
  title: 'Tuteur IA',
  subtitle: 'Pose-moi tes questions sur n\'importe quel chapitre',
  color: AppColors.primary,
  onTap: () => context.go(AppRoutes.tutor),
),
```

Optionnel : passer une matière pour contextualiser :

```dart
onTap: () => context.go(
  AppRoutes.tutor,
  extra: {'matiere': 'Mathématiques'},
),
```

### 3. Ajouter `speech_to_text` et `image_picker` au pubspec.yaml

```yaml
dependencies:
  # ... deps existantes ...
  speech_to_text: ^7.0.0      # Saisie vocale (tutor voice input)
  image_picker: ^1.1.2        # Joindre une photo d'exercice (tutor + futur OCR)
```

Puis lancer :

```bash
flutter pub get
```

**Permissions à ajouter :**

Android — `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

iOS — `ios/Runner/Info.plist` :

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Pose tes questions au tuteur à voix haute.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Pose tes questions au tuteur à voix haute.</string>
<key>NSCameraUsageDescription</key>
<string>Photographie un exercice pour demander de l'aide au tuteur.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Choisis une photo d'exercice pour demander de l'aide au tuteur.</string>
```

### 4. Activer la vraie saisie vocale (speech_to_text)

Le fichier `lib/screens/tutor/widgets/voice_input_button.dart` contient une
implémentation STUB (sans reconnaissance vocale). Pour activer la vraie
saisie vocale :

1. Ajouter `speech_to_text: ^7.0.0` au pubspec (voir §3)
2. Dans `voice_input_button.dart`, décommenter le bloc `_realToggle` (code
   complet fourni en commentaire dans le fichier)
3. Renommer `_realToggle` en `_toggleListening` (et supprimer le stub)
4. Ajouter les permissions micro (voir §3)

Le bouton est automatiquement masqué sur desktop/web
(`!kIsWeb && defaultTargetPlatform == android|iOS`).

### 5. Activer "Joindre une photo" (image_picker)

Actuellement `_pickPhoto()` dans `tutor_screen.dart` affiche un simple snackbar.
Pour activer la vraie sélection photo :

```dart
// Dans tutor_screen.dart, remplacer le corps de _pickPhoto() par :
final picker = ImagePicker();
final xFile = await picker.pickImage(source: ImageSource.gallery);
if (xFile == null) return;
// v1 : juste insérer un placeholder dans le TextField
_textController.text = '${_textController.text}[photo jointe]'.trim();
// v2 : envoyer la photo au backend pour analyse (endpoint /tutor/ask
// avec multipart/form-data — non implémenté en v1)
```

### 6. Exposer `authToken` dans UserProvider

Ajouter dans `lib/providers/user_provider.dart` :

```dart
class UserProvider extends ChangeNotifier {
  // ...
  String? _authToken;
  String? get authToken => _authToken;

  // À appeler après un login réussi (backend /auth/login renvoie un JWT)
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    notifyListeners();
  }

  // Dans initialize() : recharger le token depuis SharedPreferences
  // _authToken = prefs.getString('auth_token');
}
```

### 7. Backend — Inclure le router tutor dans main.py

Dans `backend/main.py` :

```python
# 1. Import (en haut, avec les autres routers) :
from routers import auth, predict, questions, sessions, tutor

# 2. Ajouter le tag dans openapi_tags :
openapi_tags=[
    # ... tags existants ...
    {"name": "tutor", "description": "Tuteur IA conversationnel (Claude)"},
],

# 3. Inclure le router (à la fin, avec les autres include_router) :
app.include_router(tutor.router, prefix="/tutor", tags=["tutor"])
```

### 8. Backend — Ajouter `anthropic` au requirements.txt

Dans `backend/requirements.txt` :

```
anthropic>=0.40.0
```

Puis :

```bash
cd backend && pip install -r requirements.txt
```

### 9. Backend — Configurer `ANTHROPIC_API_KEY`

Créer ou éditer `backend/.env` :

```env
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxx
# Optionnel : surcharger le modèle par défaut
# ANTHROPIC_MODEL=claude-sonnet-4-6
```

> Sans clé API, le backend renvoie une réponse mock (mode démo).
> Le champ `fallback: true` dans la réponse indique ce mode.

## API — POST /tutor/ask

**Auth :** Bearer JWT (header `Authorization: Bearer <token>`)

**Request body :**

```json
{
  "question": "Explique-moi Pythagore",
  "context": {
    "matiere": "Mathématiques",
    "chapitre": "Théorème de Pythagore",
    "competence_id": "TG-MATHS-PYT-001"
  },
  "conversation_history": [
    {"role": "user", "content": "Bonjour"},
    {"role": "assistant", "content": "Bonjour ! Comment puis-je t'aider ?"}
  ]
}
```

**Response 200 :**

```json
{
  "answer": "Le théorème de Pythagore dit que dans un triangle rectangle...",
  "suggested_followup": [
    "Donne-moi un exercice d'application.",
    "Comment démontrer cette propriété ?",
    "Quels sont les pièges fréquents ?"
  ],
  "tokens_used": 342,
  "model": "claude-sonnet-4-6",
  "fallback": false
}
```

**Codes d'erreur :**

| Code | Cause                                         |
|------|-----------------------------------------------|
| 401  | Token JWT absent ou invalide                  |
| 422  | Question vide ou > 2000 caractères            |
| 429  | Rate limit dépassé (30 questions/heure/user)  |
| 502  | Erreur interne (API Anthropic indisponible)   |

**Healthcheck :** `GET /tutor/health` → `{status, anthropic_configured, model, rate_limit_per_hour}`

## Décisions de conception

### Markdown léger maison (pas de package `markdown`)

Pour éviter d'ajouter `markdown` + `flutter_highlight` au pubspec (qui
dépasserait le périmètre autorisé), un parser markdown minimal est
implémenté dans `message_bubble.dart`. Il gère :

- `**gras**`, `*italique*`, `` `code inline` ``
- Blocs de code ``` ```lang ... ``` ``` (fond sombre, police monospace, pas
  de coloration syntaxique — pour activer flutter_highlight, voir ci-dessous)
- Listes à puces `- item` et numérotées `1. item`
- Titres `#`, `##`, `###`

Pour une coloration syntaxique complète des blocs de code, ajouter au
pubspec :

```yaml
flutter_highlight: ^0.7.0
```

Et remplacer le `SelectableText` de `_CodeBlock` par un widget `HighlightView`.

### Persistance Hive sans adapter

`ChatMessage` n'est pas un `@HiveType` (cela aurait nécessité d'enregistrer
un adapter dans `main.dart`, hors périmètre). À la place, sérialisation
manuelle en `Map<String, dynamic>` stockée directement dans la box
`tutor_conversations` (Hive supporte nativement les Maps).

### Rate limiting in-memory

30 questions/heure/user via un `defaultdict(deque)` de timestamps. Pour
passer à Redis (recommandé en production) :

```python
import redis.asyncio as redis
r = redis.from_url(os.environ.get("REDIS_URL"))

async def _check_rate_limit_redis(user_id: str) -> None:
    key = f"tutor:rl:{user_id}"
    count = await r.incr(key)
    if count == 1:
        await r.expire(key, RATE_LIMIT_WINDOW_SEC)
    if count > RATE_LIMIT_MAX_REQUESTS:
        ttl = await r.ttl(key)
        raise HTTPException(429, ...)
```

### Fallback sans clé API

Si `ANTHROPIC_API_KEY` n'est pas configurée, le service renvoie une réponse
templatee (mode démo) avec `fallback: true`. L'app Flutter peut afficher un
badge "mode démo" si souhaité (non implémenté en v1).

### Voice input : stub pour ne pas casser la compilation

Le package `speech_to_text` n'étant pas dans le pubspec, `voice_input_button.dart`
fournit une implémentation stub (snackbar explicatif). Le code réel complet
est fourni en commentaire dans le fichier — il suffit de décommenter après
ajout du package.

## Compatibilité

- Flutter 3.44+ (Material 3, `IconButton.filled` non utilisé — Material
  brut pour contrôle précis)
- Provider 6.x (déjà dans pubspec)
- Backend Python 3.11+ (type hints + async/await)
- Anthropic SDK ≥ 0.40 (optionnel — fallback sinon)
- Toutes les dépendances utilisées (dio, connectivity_plus, hive, intl,
  uuid) sont déjà dans pubspec.yaml — aucun ajout requis pour le
  fonctionnement de base.

## Tests rapides (sans clé API)

```bash
# 1. Backend
cd backend
pip install fastapi uvicorn
uvicorn main:app --reload

# 2. Healthcheck
curl http://localhost:8000/tutor/health
# → {"status":"ok","anthropic_configured":false,"model":"claude-sonnet-4-6","rate_limit_per_hour":30}

# 3. Login (créer un user via /auth/register d'abord)
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"eleve@example.com","password":"password123"}' | jq -r .access_token)

# 4. Ask (mode fallback)
curl -X POST http://localhost:8000/tutor/ask \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"question":"Explique-moi Pythagore","conversation_history":[]}'
```
