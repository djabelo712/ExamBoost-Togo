# Mode Multijoueur Étude — ExamBoost Togo

Module de **révision collaborative en temps réel** entre élèves togolais.
Permet à jusqu'à 6 joueurs de réviser ensemble sur des questions
synchronisées, avec chat live et podium final.

## Objectif

Offrir un mode "Kahoot-like" entre amis pour réviser les examens
nationaux (BEPC, BAC) :
- **Compétitif** : chacun pour soi, classement individuel, bonus vitesse.
- **Coopératif** : score cumulé de l'équipe, questions plus difficiles.

## Structure

```
lib/screens/multiplayer/
├── multiplayer_home_screen.dart       # Menu (Créer / Rejoindre)
├── create_room_screen.dart            # Formulaire de création
├── join_room_screen.dart              # Rejoindre (code / room publique)
├── multiplayer_lobby_screen.dart      # Salle d'attente + chat
├── multiplayer_game_screen.dart       # Partie (question + timer + chat)
├── multiplayer_results_screen.dart    # Podium + classement + stats
├── widgets/
│   ├── room_code_display.dart         # Code à 6 chiffres + copier/partager
│   ├── player_avatar_grid.dart        # Grille 3x2 des joueurs (max 6)
│   ├── synchronized_question.dart     # Question + timer ring + 4 choix
│   ├── live_chat_widget.dart          # Chat live (suspendu pendant réponse)
│   └── podium_multiplayer.dart        # Podium animé top 3 (or/argent/bronze)
├── services/
│   └── multiplayer_socket_service.dart # WebSocket simulé (mock 5 joueurs)
├── models/
│   ├── multiplayer_room.dart          # Room + Question + ChatMessage + Results
│   └── multiplayer_player.dart        # Player {id, name, score, ready, host}
└── README.md
```

## Dépendances packages

Le module utilise les packages **déjà présents** dans `pubspec.yaml` :

- `web_socket_channel: ^3.0.0` — canal WebSocket (déjà ajouté par Agent AH).
- `uuid: ^4.4.0` — génération d'identifiants joueurs.
- `provider: ^6.1.2` — injection du service via `ChangeNotifierProvider`.

Aucune modification du `pubspec.yaml` n'est nécessaire.

## État : simulation locale

Le `MultiplayerSocketService` fonctionne actuellement en **mode simulation**
(`simulateMode = true` par défaut) :
- Aucune connexion réseau réelle.
- 5 joueurs togolais fictifs (Kossi, Aya, Komlan, Délali, Mawuko) rejoignent
  automatiquement la room après sa création.
- Les mock joueurs répondent aléatoirement avec une "compétence" par nom
  (Kossi = 75%, Aya = 65%, Komlan = 55%, Délali = 45%, Mawuko = 35%).
- Le timer 30s est local (Timer.periodic).
- Les messages du chat simulés répondent parfois au joueur local.

### Activation du mode réseau (backend FastAPI)

Le code est préparé pour un backend WebSocket à `/multiplayer/{code}` :
1. Passer `simulateMode: false` dans le constructeur de
   `MultiplayerSocketService`.
2. Passer `baseUrl: 'ws://10.0.2.2:8000'` (ou l'URL de production).
3. Implémenter le backend FastAPI avec les événements suivants :
   - Sortant (client -> serveur) : `create`, `join`, `toggle_ready`,
     `send_answer`, `send_chat`, `leave`.
   - Entrant (serveur -> client) : `joined`, `player_joined`, `player_left`,
     `chat_message`, `game_started`, `new_question`, `answer_confirmed`,
     `leaderboard_update`, `all_answered`, `game_ended`, `error`.

Le parsing réseau (`_onNetworkData`) est en TODO : il faudra mapper les
événements entrants vers les mises à jour d'état (similaire à
`ClassroomSocketService._handleEvent`).

## Flux utilisateur

```
[Home multijoueur]
       |
       +-- Créer --> [Create room] --> [Lobby] -- démarrer --> [Game]
       |                                            |
       +-- Rejoindre --> [Join room] --> [Lobby]    +-- fin --> [Results]
                                                       |
                                                       +-- Rejouer --> [Home]
                                                       +-- Accueil --> [Home]
```

## Navigation

Les écrans utilisent `Navigator.push` / `pushReplacement` (pas de go_router)
car le module est volontairement isolé du routeur principal. Le point
d'entrée `MultiplayerHomeScreen` est conçu pour être branché depuis la
home par l'Agent BA (wiring).

## Couleurs et style

Respect du thème `AppColors` (vert Togo #006837 + orange #D97700) et
`AppTextStyles` de `lib/theme/app_theme.dart`. Pas d'emojis, commentaires
en français.

## Banque de questions mock

5 matières disponibles avec banque locale :
- Maths (10 questions)
- Français (10 questions)
- Physique-Chimie (8 questions)
- SVT (6 questions)
- Histoire-Géo (5 questions)

En production, les questions seraient tirées de la base ExamBoost
(`QuestionService`) filtrées par matière + niveau + difficulté.

## Limitations connues (v1 démo)

- Pas de persistance des résultats (ils sont perdus au `leaveRoom()`).
- Pas d'invitation par contact (le code doit être partagé manuellement).
- Le chat n'est pas persistant (disparaît à la fermeture de la room).
- Le mode "coopératif" ne change pas réellement la difficulté des questions
  (même banque que le mode compétitif) — à différencier côté backend.
- Le timer continue de tourner même si on n'est pas sur l'écran de jeu.

## Branchement (à faire par l'Agent BA)

Ajouter dans `app_router.dart` :

```dart
GoRoute(
  path: '/multiplayer',
  builder: (context, state) => const MultiplayerHomeScreen(),
),
```

Et une carte dans `home_screen.dart` :

```dart
_ActionCard(
  title: 'Multijoueur',
  subtitle: 'Révise à plusieurs',
  icon: Icons.groups,
  onTap: () => context.go('/multiplayer'),
),
```
