# Module Communauté — ExamBoost Togo

Module Flutter "Communauté" de l'app ExamBoost Togo : classements inter-établissements, défis hebdomadaires et entraide entre élèves de tout le Togo.

## Structure

```
lib/screens/community/
├── community_screen.dart     # Écran principal (DefaultTabController + 3 onglets)
├── leaderboard_tab.dart      # Onglet Classements (National / Régional / Établissement)
├── challenges_tab.dart       # Onglet Défis hebdomadaires (semaine + en cours + historique)
├── forum_tab.dart            # Onglet Forum d'entraide (threads + filtres matière)
└── README.md                 # Ce fichier
```

## Onglets et fonctionnalités

### 1. Classements (`leaderboard_tab.dart`)
- 3 vues switchables via `SegmentedButton` (Material 3) :
  - **National** — top 50 élèves du Togo (toutes régions confondues)
  - **Régional** — filtre par région via chips horizontaux (Lomé, Maritime, Plateaux, Centrale, Kara, Savanes)
  - **Établissement** — top 50 dans mon lycée (mock : Lycée de Tokoin)
- Carte "Mon rang" sticky en haut avec ma position + score + streak
- Pour chaque élève : avatar (initiales), Prénom + initiale nom, établissement, score semaine, streak, badge médaille (or/argent/bronze) pour le top 3
- Mock data : 50 élèves togolais (Kossi, Aya, Komlan, Adjo, Yao, Akossiwa…) répartis dans 18 lycées réels des 6 régions

### 2. Défis hebdomadaires (`challenges_tab.dart`)
- **Section 1 — Défi de la semaine** : carte prominent en gradient vert avec titre, description, récompense, barre de progression X/N, bouton "Participer"/"Continuer" + `LineChart` fl_chart (points gagnés par jour Lun→Dim)
- **Section 2 — Défis en cours** : 3 cartes (Streak 7 jours, Simulation BAC, Aidant du forum) avec barre de progression + %
- **Section 3 — Défis terminés (historique)** : 5 derniers défis terminés avec badge obtenu et points gagnés
- Interactivité : bouton "Continuer" incrémente la progression du défi de la semaine (mock), snackbar de confirmation si défi terminé

### 3. Forum d'entraide (`forum_tab.dart`)
- Liste de 10 threads mock avec questions réalistes (factorisation, loi d'Ohm, méiose/mitose, indépendance Togo, etc.)
- Chaque thread : titre, extrait, auteur (prénom + niveau + ville), nb réponses, timestamp relatif, tag matière
- Filtres par matière via chips horizontaux (Toutes, Mathématiques, Français, Sciences, SVT, H-G, Anglais)
- `FloatingActionButton.extended` "Poser une question" (snackbar en v1, formulaire à venir en v2)
- Tap sur thread : ouverture de la vue détaillée (snackbar en v1, vue détaillée à venir)

## Design & UX
- Palette `AppColors` (vert Togo #006837 + orange #D97700 + sémantique)
- Cards arrondies 14-18 px avec ombres légères
- `fl_chart` pour le graphique d'activité hebdomadaire du défi de la semaine
- Pull-to-refresh sur chaque onglet (mock : 800 ms de latence simulée)
- États vides soignés ("Aucun défi en cours. Reviens lundi prochain !" etc.)
- Material 3, `SegmentedButton` et `ChoiceChip` natifs
- Avatars circulaires avec initiales (pas de `CachedNetworkImage` requis)

## Intégration au router (à faire par l'agent principal)

### 1. Ajouter la route dans `lib/utils/app_router.dart`

```dart
// 1. Ajouter l'import en haut du fichier :
import '../screens/community/community_screen.dart';

// 2. Ajouter la constante dans la classe AppRoutes :
class AppRoutes {
  // ... routes existantes ...
  static const String community = '/community';
}

// 3. Ajouter la route dans la liste `routes` du GoRouter :
GoRoute(
  path: AppRoutes.community,
  name: 'community',
  builder: (context, state) => const CommunityScreen(),
),
```

### 2. Ajouter un bouton dans `lib/screens/home/home_screen.dart`

```dart
// 1. Ajouter dans la liste des children de la Column (après la carte "Tableau de bord") :
const SizedBox(height: 12),
_ActionCard(
  icon: Icons.groups,
  title: 'Communauté',
  subtitle: 'Classements, défis hebdo et entraide entre élèves',
  color: AppColors.primary,
  onTap: () => context.go(AppRoutes.community),
),

// 2. S'assurer que l'import d'AppRoutes est bien présent (déjà le cas dans home_screen.dart).
```

### 3. (Optionnel) Ajouter un accès rapide depuis le dashboard

Pour permettre un retour facile entre Communauté ↔ Dashboard, l'agent principal peut ajouter un bouton dans la section "Actions rapides" de `lib/screens/dashboard/dashboard_screen.dart` :

```dart
// Dans _buildQuickActions() — remplacer la Row 2 boutons par une Row 3 boutons,
// ou ajouter un 3e ElevatedButton.icon :
ElevatedButton.icon(
  onPressed: () => context.go('/community'),
  icon: const Icon(Icons.groups, size: 20),
  label: const Text('Communauté'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
  ),
),
```

## Mock data vs Production

Toutes les données sont actuellement **mockées localement** dans chaque onglet :
- `leaderboard_tab.dart` : `_generateMockEleves()` (50 élèves déterministes via `Random(42)`)
- `challenges_tab.dart` : `_mockDefiSemaine()`, `_mockDefisEnCours()`, `_mockDefisTermines()`
- `forum_tab.dart` : `_mockThreads()` (10 threads)

### Pour brancher sur le backend FastAPI (à venir)

Créer un service `lib/services/community_service.dart` qui exposera :
- `Future<List<Eleve>> fetchLeaderboard({required String scope, String? region})`
- `Future<List<Defi>> fetchActiveChallenges(String userId)`
- `Future<List<Defi>> fetchCompletedChallenges(String userId)`
- `Future<List<Thread>> fetchForumThreads({String? matiere, int page = 0})`

Puis enregistrer ce service comme `Provider` dans `main.dart` (comme `SrsService` et `QuestionService`) et remplacer les appels `_mockXxx()` par `Provider.of<CommunityService>(context, listen: false).fetchXxx()`.

### Schéma de données attendu côté backend

```python
# Eleve
class Eleve(BaseModel):
    id: str
    prenom: str
    nom: str
    etablissement: str
    region: str  # Lomé | Maritime | Plateaux | Centrale | Kara | Savanes
    score_semaine: int  # points SRS + simulations cette semaine
    streak: int  # nb jours consécutifs de révision

# Defi
class Defi(BaseModel):
    id: str
    titre: str
    description: str
    recompense: str
    type: str  # streak | simulation | aidant | matiere
    objectif: int
    progression: int
    points_gagnes: int
    badge: str | None
    date_fin: datetime | None

# Thread
class Thread(BaseModel):
    id: str
    titre: str
    extrait: str
    auteur_id: str
    auteur_prenom: str
    auteur_niveau: str
    auteur_ville: str
    nb_reponses: int
    timestamp: datetime
    matiere: str
```

## Notes techniques

- **Déterminisme** : le mock des 50 élèves utilise `Random(42)` pour éviter que le classement ne change à chaque rebuild (sinon les positions sauteraient à chaque `setState`).
- **Pas de dépendance réseau** : aucun `dio`, aucun `connectivity_plus` — tous les onglets restent fonctionnels hors-ligne en v1.
- **Pas d'emojis** dans le code source (conforme aux règles du projet).
- **Commentaires et UI en français** (cohérent avec le reste de l'app).
- **Imports isolés** : aucun import ne pointe vers `main.dart`, `app_router.dart` ou `home_screen.dart` → aucune dépendance circulaire possible.
