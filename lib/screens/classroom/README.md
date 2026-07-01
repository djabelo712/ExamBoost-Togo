# Module Classe Temps Reel (Kahoot-like + devoir asynchrone)

Module permettant a un enseignant de lancer une session de questions en
temps reel. Les eleves rejoignent via un code a 6 chiffres, les questions
sont diffusees en live, un classement live s'affiche et un podium final
clot la session.

Deux modes supportes :
- **Live** : Kahoot-like, timer 30s par question, diffusion temps reel.
- **Devoir (asynchrone)** : l'enseignant genere un code, les eleves
  rejoignent quand ils veulent dans les 7 jours, repondent a leur rythme
  sans timer live.

## Structure

```
lib/screens/classroom/
├── classroom_menu_screen.dart       # Menu choix (rejoindre / creer)
├── join_class_screen.dart           # Eleve : saisir code + rejoindre
├── student_live_quiz_screen.dart    # Eleve : repond questions en live
├── student_results_screen.dart      # Eleve : ses resultats finaux
├── teacher_create_screen.dart       # Enseignant : creer session
├── teacher_live_screen.dart         # Enseignant : controle live + classement
├── teacher_results_screen.dart      # Enseignant : resultats detailles
├── widgets/
│   ├── player_list_widget.dart      # Liste joueurs connectes
│   ├── live_question_display.dart   # Question affichee en live
│   ├── live_leaderboard.dart        # Classement temps reel
│   ├── podium_widget.dart           # Podium top 3 (animation)
│   └── timer_ring.dart              # Anneau timer decompte
├── services/
│   ├── classroom_socket_service.dart # WebSocket client (ChangeNotifier)
│   └── classroom_rest_service.dart   # Client REST (create / status / results)
├── models/
│   ├── classroom_session.dart       # Session + question publique + resultats
│   ├── classroom_player.dart        # Player + role + statut + answer result
│   └── classroom_event.dart         # Events WS (parse + payloads sortants)
└── README.md                         # Ce fichier

backend/routers/classroom.py         # WebSocket endpoint + REST
backend/services/classroom_manager.py # Gestion sessions en memoire (singleton)
backend/models/classroom_models.py    # Pydantic schemas
```

## Backend

### Enregistrer le router dans `backend/main.py`

Ajouter dans `backend/main.py` :

```python
from routers import classroom

# ... apres les autres include_router
app.include_router(classroom.router, tags=["classroom"])
```

Le router expose :
- `WS   /classroom/{session_code}`        — canal temps reel
- `POST /classroom/create`                — cree une session
- `GET  /classroom/{code}/status`         — statut public
- `GET  /classroom/{code}/results`        — resultats finaux
- `POST /classroom/{code}/end`            — termine la session (REST)
- `POST /classroom/cleanup`               — nettoyage memoire
- `GET  /classroom`                       — liste (debug)

### Protocole WebSocket

1. **Connexion** : `ws://host:port/classroom/{session_code}`
2. **Client -> Server** (1er message obligatoire) :
   ```json
   {"type": "join", "player_id": "uuid-v4", "player_name": "Awa", "role": "student"}
   ```
3. **Server -> Client** :
   - `joined` — connexion confirmee + session + player
   - `player_joined` / `player_left` — maj liste joueurs
   - `quiz_started` — l'enseignant a lance le quiz
   - `new_question` — nouvelle question diffusee (sans la reponse !)
   - `answer_confirmed` — confirmation de la reponse + points
   - `leaderboard_update` — classement mis a jour
   - `all_answered` — tous les eleves ont repondu
   - `session_ended` — session terminee + resultats
   - `error` — message d'erreur

4. **Client -> Server** (apres join) :
   - `{"type": "answer", "question_id": "...", "answer": "A", "time_taken_seconds": 5.2}`
   - `{"type": "start_quiz"}` (enseignant)
   - `{"type": "next_question"}` (enseignant)
   - `{"type": "force_next"}` (enseignant, sans attendre tous)
   - `{"type": "end_session"}` (enseignant)

### Score

- Mode live : `points = 100 + (1000 - 100) * (1 - temps_pris / temps_total)`
  (min 100, max 1000 pour reponse instantanee)
- Mode devoir : `points = 1000` par question correcte (pas de bonus vitesse)

### Persistence

Aucune. Tout est en memoire dans `classroom_manager` (singleton). Pour
multi-instance, brancher Redis pub/sub. Le manager est compatible
(testable unittairement sans FastAPI).

## Frontend Flutter

### Dependances a ajouter dans `pubspec.yaml`

Le module utilise une nouvelle dependance a ajouter (NE PAS modifier
pubspec.yaml depuis ce module — delegue a l'agent principal) :

```yaml
dependencies:
  web_socket_channel: ^3.0.0
```

Les autres dependances utilisees sont deja presentes :
- `provider` (gestion d'etat via ChangeNotifier)
- `dio` (REST client)
- `uuid` (generation d'ID joueur cote client)
- `path_provider` (export CSV)
- `shared_preferences` (memo nom eleve / enseignant)

### Routes a ajouter dans `lib/utils/app_router.dart`

Ajouter dans `AppRoutes` :

```dart
static const String classroom         = '/classroom';
static const String classroomJoin     = '/classroom/join';
static const String classroomTeacher  = '/classroom/teacher/create';
```

Et dans la liste `routes` du GoRouter :

```dart
GoRoute(
  path: AppRoutes.classroom,
  name: 'classroom',
  pageBuilder: (context, state) => buildPageWithTransition(
    child: const ClassroomMenuScreen(),
    type: TransitionType.slideRight,
  ),
),
GoRoute(
  path: AppRoutes.classroomJoin,
  name: 'classroomJoin',
  pageBuilder: (context, state) => buildPageWithTransition(
    child: const JoinClassScreen(),
    type: TransitionType.slideUp,
  ),
),
GoRoute(
  path: AppRoutes.classroomTeacher,
  name: 'classroomTeacher',
  pageBuilder: (context, state) => buildPageWithTransition(
    child: const TeacherCreateScreen(),
    type: TransitionType.slideUp,
  ),
),
```

### Configuration backend URL

Les URLs backend sont actuellement en dur dans :
- `lib/screens/classroom/join_class_screen.dart` (`_defaultBaseUrl`, `_defaultWsUrl`)
- `lib/screens/classroom/teacher_create_screen.dart` (idem)

Valeur par defaut : `http://10.0.2.2:8000` (localhost depuis l'emulateur
Android). En production, remplacer par l'URL Railway/Render et utiliser
une variable d'environnement via `--dart-define`.

## Flux utilisateur

### Eleve (mode live)

1. Menu classe -> "Rejoindre une classe"
2. Saisit le code a 6 chiffres (cases OTP)
3. Saisit son prenom (memo pour la prochaine fois)
4. WebSocket se connecte -> salle d'attente avec liste joueurs
5. L'enseignant demarre le quiz -> question 1 s'affiche + timer 30s
6. L'eleve clique sur A/B/C/D (QCM) ou tape sa reponse
7. "En attente des autres..." + score qui monte
8. Question suivante / classement live
9. A la fin : podium + classement complet + bouton "Revoir mes reponses"

### Eleve (mode devoir)

Identique mais sans timer et sans "en attente des autres". L'eleve voit
sa propre progression et son score final a la fin.

### Enseignant

1. Menu classe -> "Créer une session"
2. Choisit mode Live / Devoir
3. Choisit examen + matiere + questions (max 20)
4. Configure duree (live) ou nb jours (devoir)
5. "Lancer la session" -> POST /classroom/create
6. Code a 6 chiffres affiche en grand + WebSocket connectee en role teacher
7. "Demarrer le quiz" -> broadcast new_question a tous
8. Stats temps reel : "X/Y eleves ont repondu"
9. "Forcer question suivante" si besoin
10. "Terminer la session" -> ecran resultats
11. Podium + classement complet + stats par question + export CSV

## Points d'attention

### Securite

- Aucune authentification sur la WebSocket (join public). En production,
  ajouter un JWT dans le 1er message `join` et verifier cote serveur.
- Les reponses attendues ne sont JAMAIS envoyees au client avant la fin
  de la question. Le backend ne renvoie que l'enonce + les choix.
- En mode devoir, l'expiration est verifiee a chaque appel REST.

### Concurrency

- Le `ClassroomManager` utilise un `asyncio.Lock` par session pour eviter
  les courses sur les reponses simultanees.
- Les broadcasts sont envoyes en parallele (best-effort). Les websockets
  fermees sont marquee `disconnected` silencieusement.

### Limites connues

- **Pas de persistence** : une session perdue au redemarrage du serveur.
  Brancher Redis pour la prod.
- **Pas de reconnexion automatique** : si la WS se coupe, l'eleve doit
  revenir au menu et re-saisir le code. (Le serveur garde son score
  pendant 24h grace au statut `disconnected`.)
- **Stats par question limitees** : seules les stats de la question
  courante sont conservees. Pour un historique complet, etendre
  `_QuestionRuntime` avec un historique.
- **Export CSV** : sauvegarde dans `getApplicationDocumentsDirectory()` +
  copie dans le presse-papier. Pas de share sheet (dependance
  `share_plus` non ajoutee pour ne pas modifier pubspec).

### Tests

Aucun test automatique fourni dans ce module. Les tests a ecrire :
- Backend : `backend/tests/test_classroom.py` (creation session,
  enregistrement reponses, classement, end_session)
- Frontend : `test/widget/screens/classroom_*_test.dart` (rendu des
  ecrans avec un mock de `ClassroomSocketService`)

### Performance

- Le manager est un singleton en memoire : OK pour ~100 sessions
  simultanees sur une petite instance.
- Chaque broadcast est O(n) ou n = nombre de joueurs. Pour 100 joueurs,
  ~100 envois WS paralleles -> acceptable.
- Les sessions terminees sont nettoyables via `POST /classroom/cleanup`
  (cron recommande toutes les heures).
