# lib/widgets/states/ — Empty states, Loading skeletons & Error states

Librairie de widgets réutilisables pour gérer les **3 états critiques souvent oubliés** dans les écrans avec données :

1. **Loading state** (pendant le chargement) — skeleton shimmer
2. **Empty state** (pas de données) — icône + titre + CTA
3. **Error state** (échec de chargement) — icône + message + retry

Le **4e état** (loaded / contenu réel) est fourni par l'écran lui-même.

## Sommaire

1. [Widgets génériques](#1-widgets-génériques)
2. [Skeletons spécifiques](#2-skeletons-spécifiques)
3. [Empty states spécifiques](#3-empty-states-spécifiques)
4. [Error states spécifiques](#4-error-states-spécifiques)
5. [Wrapper un écran existant avec StateWrapper](#5-wrapper-un-écran-existant-avec-statewrapper)
6. [Créer un nouveau empty/error state](#6-créer-un-nouveau-emptyerror-state)
7. [Bonnes pratiques](#7-bonnes-pratiques)
8. [Performance](#8-performance)
9. [Compatibilité dark mode](#9-compatibilité-dark-mode)

---

## 1. Widgets génériques

3 widgets génériques à la base de tous les autres.

### `StateWrapper<T>` — `state_wrapper.dart`

Wrapper qui gère les 4 états possibles d'un écran avec données. À utiliser
dans le `build()` d'un écran à la place des `if (_loading) return X; if
(_error != null) return Y; ...` répétitifs.

```dart
import 'package:examboost_togo/widgets/states/state_wrapper.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Favoris')),
    body: StateWrapper(
      state: _widgetState,        // WidgetState.loading/empty/error/loaded
      loaded: FavoritesList(favorites: _favorites),
      loading: ListSkeleton(itemCount: 5, leadingAvatar: true),
      empty: NoFavoritesEmpty(onStartRevision: _goToRevision),
      error: NetworkError(onRetry: _loadFavorites),
    ),
  );
}
```

Fournit aussi les fallbacks `DefaultLoadingSkeleton`, `DefaultEmptyState`,
`DefaultErrorState` si `loading` / `empty` / `error` ne sont pas fournis.

### `EmptyState` — `empty_state.dart`

Empty state générique : icône (grand cercle teinté) + titre + description +
bouton d'action + lien secondaire optionnel.

```dart
import 'package:examboost_togo/widgets/states/empty_state.dart';

EmptyState(
  icon: Icons.inbox,
  title: 'Aucune question disponible',
  description: 'Pas encore de questions pour cette matière.',
  actionLabel: 'Choisir une autre matière',
  onAction: () => context.go('/matieres'),
  iconColor: AppColors.primary,        // optionnel
  iconSize: 96,                        // optionnel (defaut 96)
  secondaryActionLabel: 'Revenir plus tard',  // optionnel
  onSecondaryAction: () => Navigator.pop(context),
)
```

### `LoadingSkeleton` + `ShimmerBox` — `loading_skeleton.dart`

Skeleton shimmer générique. Utilise `ShimmerLoading` (Agent AB) avec couleurs
adaptatives (`AdaptiveColors.surfaceVariant` / `.surface`).

```dart
import 'package:examboost_togo/widgets/states/loading_skeleton.dart';

// 4 cartes standard
LoadingSkeleton(itemCount: 4)

// Layout custom
LoadingSkeleton(
  itemCount: 1,
  child: Column(
    children: [
      ShimmerBox(width: double.infinity, height: 24, borderRadius: 8),
      SizedBox(height: 12),
      ShimmerBox(width: 200, height: 16, borderRadius: 4),
      SizedBox(height: 8),
      ShimmerBox(width: 140, height: 12, borderRadius: 4),
    ],
  ),
)

// Box individuelle (cercle = avatar)
ShimmerBox(width: 40, height: 40, circular: true)
```

### `ErrorState` — `error_state.dart`

Error state générique : icône (rouge par défaut, orange si non bloquant) +
message + description + code erreur technique (optionnel) + bouton "Réessayer"
+ lien secondaire (optionnel).

```dart
import 'package:examboost_togo/widgets/states/error_state.dart';

ErrorState(
  icon: Icons.wifi_off,
  iconColor: AppColors.warning,         // orange = non bloquant
  message: 'Pas de connexion Internet',
  description: 'Vérifie ta connexion et réessaie.',
  onRetry: () => _loadData(),
  retryLabel: 'Réessayer',
  errorCode: 'ERR_NETWORK_001',         // optionnel, gris petit
  secondaryActionLabel: 'Continuer hors-ligne',
  onSecondaryAction: () => _goOffline(),
)
```

---

## 2. Skeletons spécifiques

4 skeletons qui reproduisent la forme des écrans principaux.

| Fichier | Cas d'usage |
|---------|-------------|
| `skeletons/question_card_skeleton.dart` | Écran de révision (flashcard) |
| `skeletons/dashboard_skeleton.dart` | Tableau de bord |
| `skeletons/leaderboard_skeleton.dart` | Classement communautaire |
| `skeletons/list_skeleton.dart` | Listes génériques (favoris, notes, simulations, badges, search) |

### `QuestionCardSkeleton`

```dart
QuestionCardSkeleton()                        // 1 carte
QuestionCardSkeleton(itemCount: 3)            // 3 cartes empilées
```

Reproduit : header (chip + points) → icône help_outline → 4 lignes d'énoncé
→ footer (indice italique).

### `DashboardSkeleton`

```dart
DashboardSkeleton()
```

Reproduit : header (avatar + 2 lignes texte) → carte score (cercle 100px +
3 lignes) → 3 lignes matières (avatar + titre + progress bar) → 3 stats
cards en row → graphique (6 barres verticales).

### `LeaderboardSkeleton`

```dart
LeaderboardSkeleton()                         // podium + 7 lignes
LeaderboardSkeleton(itemCount: 10)            // podium + 10 lignes
```

Reproduit : podium Top 3 (2e | 1er | 3e avec hauteurs décalées) + N lignes
standard (rang + avatar + nom + score).

### `ListSkeleton`

```dart
ListSkeleton(itemCount: 5)                                    // 5 lignes
ListSkeleton(itemCount: 5, leadingAvatar: true)               // avatars
ListSkeleton(itemCount: 5, leadingAvatar: true, showTrailing: true)
```

Chaque ligne : icône (ou avatar cercle) + titre + sous-titre. Largeurs des
titres/sous-titres variables (effet naturel).

---

## 3. Empty states spécifiques

8 empty states pré-configurés pour les cas d'usage les plus fréquents.
Tous wrap `EmptyState` avec l'icône, les textes et le CTA adaptés.

| Fichier | Icône | Titre | CTA |
|---------|-------|-------|-----|
| `empty_states/no_questions_empty.dart` | `inbox` | Aucune question disponible | Choisir une autre matière |
| `empty_states/no_favorites_empty.dart` | `favorite_border` (rouge) | Tu n'as pas encore de favoris | Commencer à réviser |
| `empty_states/no_notes_empty.dart` | `note_add` | Aucune note pour le moment | Voir mes questions |
| `empty_states/no_badges_empty.dart` | `emoji_events_outlined` (orange) | Aucun badge débloqué | Commencer à réviser |
| `empty_states/no_search_results_empty.dart` | `search_off` | Aucun résultat | Effacer les filtres |
| `empty_states/no_simulations_empty.dart` | `timer_off` (orange) | Aucune simulation terminée | Démarrer une simulation |
| `empty_states/no_progress_empty.dart` | `trending_up` (vert) | Pas encore de progression | Démarrer ma première révision |
| `empty_states/first_launch_empty.dart` | `waving_hand` (vert) | Bienvenue sur ExamBoost ! | Créer mon profil |

### Exemple d'usage

```dart
import 'package:examboost_togo/widgets/states/empty_states/no_favorites_empty.dart';

body: StateWrapper(
  state: _state,
  loaded: FavoritesList(favorites: _favorites),
  loading: ListSkeleton(itemCount: 5, leadingAvatar: false),
  empty: NoFavoritesEmpty(
    onStartRevision: () => context.go('/revision/${Uri.encodeComponent("Mathématiques")}'),
  ),
  error: GenericError(onRetry: _loadFavorites),
),
```

---

## 4. Error states spécifiques

4 error states pré-configurés pour les erreurs typiques d'ExamBoost.
Tous wrap `ErrorState` avec l'icône, la couleur, les textes et les CTA.

| Fichier | Icône | Couleur | Titre | CTA principal | CTA secondaire |
|---------|-------|---------|-------|---------------|----------------|
| `error_states/network_error.dart` | `wifi_off` | warning (orange) | Pas de connexion Internet | Réessayer | Continuer hors-ligne |
| `error_states/database_error.dart` | `storage` | error (rouge) | Erreur de base de données | Réessayer | Signaler le bug |
| `error_states/sync_error.dart` | `cloud_off` | warning (orange) | Synchronisation impossible | Forcer la sync | Voir le statut |
| `error_states/generic_error.dart` | `error_outline` | error (rouge) | Une erreur est survenue | Réessayer | Contacter le support |

### Exemple d'usage

```dart
import 'package:examboost_togo/widgets/states/error_states/database_error.dart';

body: StateWrapper(
  state: _state,
  loaded: NotesList(notes: _notes),
  loading: ListSkeleton(itemCount: 6),
  empty: NoNotesEmpty(onViewQuestions: _goToHistory),
  error: DatabaseError(
    onRetry: _loadNotes,
    onReportBug: _openSupportEmail,
    errorCode: 'HIVE_ADAPTER_NOT_REGISTERED',
  ),
),
```

---

## 5. Wrapper un écran existant avec StateWrapper

Étape par étape — migration d'un écran qui a déjà les 3 états codés en dur
(comme `revision_screen.dart` ou `dashboard_screen.dart`).

### Étape 1 — Convertir les flags existants en `WidgetState`

La plupart des écrans ont :
```dart
bool _isLoading = true;
String? _loadingError;
List<T> _data = [];
```

Convertir en :
```dart
WidgetState _state = WidgetState.loading;
List<T> _data = [];
String? _errorMessage;  // garder pour ErrorState custom
String? _errorCode;     // optionnel

// Dans _loadData() :
setState(() {
  _state = WidgetState.loading;
});
try {
  _data = await _fetchData();
  setState(() {
    _state = _data.isEmpty ? WidgetState.empty : WidgetState.loaded;
  });
} catch (e) {
  setState(() {
    _errorMessage = e.toString();
    _state = WidgetState.error;
  });
}
```

### Étape 2 — Remplacer les méthodes `_buildLoadingScreen / _buildErrorScreen / _buildEmptyState`

Avant :
```dart
@override
Widget build(BuildContext context) {
  if (_isLoading) return _buildLoadingScreen();
  if (_loadingError != null) return _buildErrorScreen();
  if (_data.isEmpty) return _buildEmptyState();
  return _buildContent();
}
```

Après :
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Mon écran')),
    body: StateWrapper(
      state: _state,
      loaded: _buildContent(),
      loading: ListSkeleton(itemCount: 5, leadingAvatar: true),
      empty: NoFavoritesEmpty(onStartRevision: _goToRevision),
      error: GenericError(
        message: _errorMessage,
        onRetry: _loadData,
      ),
    ),
  );
}
```

### Étape 3 — Supprimer les méthodes `_buildLoadingScreen / _buildErrorScreen / _buildEmptyState`

Elles sont remplacées par les widgets de `lib/widgets/states/`. Gain : ~150
LOC par écran.

### Mapping écran → widget recommandé

| Écran | Skeleton | Empty | Error |
|-------|----------|-------|-------|
| `dashboard_screen.dart` | `DashboardSkeleton()` | `NoProgressEmpty` ou `FirstLaunchEmpty` | `DatabaseError` (Hive) |
| `revision_screen.dart` | `QuestionCardSkeleton()` | `NoQuestionsEmpty(matiere: ...)` | `GenericError` |
| Favoris | `ListSkeleton(itemCount: 5, leadingAvatar: false)` | `NoFavoritesEmpty` | `DatabaseError` |
| Notes | `ListSkeleton(itemCount: 6)` | `NoNotesEmpty` | `DatabaseError` |
| Badges | `ListSkeleton(itemCount: 4, leadingAvatar: true)` | `NoBadgesEmpty` | `DatabaseError` |
| Simulations | `ListSkeleton(itemCount: 4, leadingAvatar: true)` | `NoSimulationsEmpty` | `DatabaseError` |
| Search | `ListSkeleton(itemCount: 5)` | `NoSearchResultsEmpty(query: ...)` | `GenericError` |
| Leaderboard | `LeaderboardSkeleton()` | (n/a — toujours data) | `NetworkError(onContinueOffline: ...)` |
| Sync settings | (n/a) | (n/a) | `SyncError(onForceSync: ..., onViewStatus: ...)` |

---

## 6. Créer un nouveau empty/error state

### Nouveau empty state

```dart
// lib/widgets/states/empty_states/no_notifications_empty.dart
import 'package:flutter/material.dart';
import '../empty_state.dart';

class NoNotificationsEmpty extends StatelessWidget {
  final VoidCallback? onOpenSettings;
  const NoNotificationsEmpty({super.key, this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.notifications_none,
      title: 'Aucune notification',
      description: "Tu n'as pas de notification pour le moment.",
      // Pas de bouton d'action (consultation seule)
    );
  }
}
```

### Nouveau error state

```dart
// lib/widgets/states/error_states/auth_error.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../error_state.dart';

class AuthError extends StatelessWidget {
  final VoidCallback? onRelogin;
  const AuthError({super.key, this.onRelogin});

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.lock_outline,
      iconColor: AppColors.error,
      message: 'Session expirée',
      description: "Ta session a expiré. Reconnecte-toi pour continuer.",
      onRetry: onRelogin,
      retryLabel: 'Se reconnecter',
    );
  }
}
```

**Convention de nommage** : `<cas>_empty.dart` / `<cas>_error.dart` en
snake_case. Classe en PascalCase : `NoFavoritesEmpty`, `NetworkError`.

---

## 7. Bonnes pratiques

### Règle d'or : 4 états obligatoires pour tout écran avec données

Tout écran qui charge des données externes (Hive, réseau, calcul lourd)
**doit** gérer les 4 états via `StateWrapper` :

```dart
// BON :
body: StateWrapper(
  state: _state,
  loaded: MyContent(),
  loading: MySkeleton(),
  empty: MyEmpty(),
  error: MyError(),
)

// A EVITER :
body: _isLoading
    ? Center(child: CircularProgressIndicator())
    : _data.isEmpty
        ? Center(child: Text('Vide'))
        : MyContent(),
// Pas de gestion d'erreur, loading minimaliste, empty trop sobre.
```

### Skeleton adapté à la forme de l'écran

Un skeleton doit donner à l'utilisateur une ** anticipation visuelle** de
la forme du contenu. Ne pas utiliser `LoadingSkeleton(itemCount: 5)` pour
un dashboard — préférer `DashboardSkeleton()` qui reproduit les cartes,
le cercle, les barres.

### Empty state avec CTA orienté action

Un empty state passif ("Aucune donnée") est frustrant. Toujours fournir un
**CTA qui débloque la situation** :

| Empty state | CTA |
|-------------|-----|
| NoFavoritesEmpty | "Commencer à réviser" → ouvre la revision |
| NoNotesEmpty | "Voir mes questions" → ouvre l'historique |
| NoSearchResultsEmpty | "Effacer les filtres" → reset query |

### Error state avec retry ET issue de secours

Un error state doit toujours offrir un **retry** + une **issue de secours**
(lien secondaire) :

| Error state | Retry | Lien secondaire |
|-------------|-------|-----------------|
| NetworkError | Réessayer | Continuer hors-ligne |
| DatabaseError | Réessayer | Signaler le bug |
| SyncError | Forcer la sync | Voir le statut |
| GenericError | Réessayer | Contacter le support |

### Couleurs cohérentes

- **Rouge** (`AppColors.error`) : erreur bloquante (DB corrompue, données illisibles)
- **Orange** (`AppColors.warning`) : erreur non bloquante (sync impossible, réseau mais mode offline disponible)
- **Vert** (`AppColors.primary`) : empty state positif (bienvenue, première étape)
- **Gris** (`textSecondary`, defaut) : empty state neutre (aucune donnée, mais pas bloquant)

---

## 8. Performance

### Skeletons = widgets simples

Les skeletons sont des widgets **stateless** (sauf `ShimmerLoading` qui est
stateful pour animer le shader). Aucune logique métier, aucun appel réseau,
aucune lecture Hive. Ils peuvent être rendus en 1 frame.

### Shimmer : 1 AnimationController par ShimmerLoading

Chaque `ShimmerBox` instancie un `ShimmerLoading` qui a son propre
`AnimationController`. Pour les listes longues (>10 items), encapsuler dans
`RepaintBoundary` pour limiter les repaints :

```dart
RepaintBoundary(
  child: ListSkeleton(itemCount: 20),
)
```

### Pas de boucles infinies inutiles

Le shimmer tourne en boucle (`repeat()`). Dès que `_state` passe à `loaded`,
le `StateWrapper` remplace le skeleton par le contenu réel — le controller
est disposé (plus de boucle).

### Lazy : ne pas rendre les skeletons si pas nécessaire

Si l'écran a déjà des données en cache (offline-first), afficher directement
le contenu `loaded` + un `RefreshIndicator` plutôt qu'un skeleton. Le
skeleton est réservé au **premier chargement à froid**.

---

## 9. Compatibilité dark mode

Tous les widgets utilisent `AdaptiveColors` (créé par Agent AP) pour les
surfaces, textes et ombres. Le rendu est correct en thème clair ET sombre :

| Élément | Clair | Sombre |
|---------|-------|--------|
| Fond du scaffold | `#F8F9FA` | `#121212` |
| Fond des cards skeleton | `#FFFFFF` | `#1E1E1E` |
| Shimmer base | `#F1F3F4` | `#2C2C2C` |
| Shimmer highlight | `#FFFFFF` | `#1E1E1E` |
| Texte titre | `#1A1A1A` | `#EAEAEA` |
| Texte description | `#757575` | `#BDBDBD` |
| Dividers | `#E0E0E0` | `#424242` |
| Ombres | black 6% | black 30% |

Les couleurs sémantiques (`AppColors.error`, `.warning`, `.primary`, `.accent`)
restent identiques en clair et sombre — elles sont suffisamment vives pour
rester lisibles sur fond sombre (cf. audit Agent AP `docs/DARK_MODE_AUDIT.md`).

### Test rapide dark mode

```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.dark,   // forcer dark pour tester
  home: Scaffold(
    body: StateWrapper(
      state: WidgetState.empty,
      loaded: Container(),
      empty: NoFavoritesEmpty(),
    ),
  ),
)
```

L'empty state doit être lisible (contraste WCAG AA) dans les deux thèmes.

---

## Inventaire des fichiers

```
lib/widgets/states/
├── empty_state.dart                      # EmptyState générique
├── loading_skeleton.dart                 # LoadingSkeleton + ShimmerBox
├── error_state.dart                      # ErrorState générique
├── state_wrapper.dart                    # StateWrapper + Default* fallbacks
├── README.md                             # ce fichier
├── skeletons/
│   ├── question_card_skeleton.dart       # QuestionCardSkeleton
│   ├── dashboard_skeleton.dart           # DashboardSkeleton
│   ├── leaderboard_skeleton.dart         # LeaderboardSkeleton
│   └── list_skeleton.dart                # ListSkeleton
├── empty_states/
│   ├── no_questions_empty.dart
│   ├── no_favorites_empty.dart
│   ├── no_notes_empty.dart
│   ├── no_badges_empty.dart
│   ├── no_search_results_empty.dart
│   ├── no_simulations_empty.dart
│   ├── no_progress_empty.dart
│   └── first_launch_empty.dart
└── error_states/
    ├── network_error.dart
    ├── database_error.dart
    ├── sync_error.dart
    └── generic_error.dart
```

Total : 21 fichiers (1 README + 20 Dart).

## Dépendances

- `lib/theme/app_theme.dart` — `AppColors`, `AppTextStyles` (déjà existant)
- `lib/theme/adaptive_colors.dart` — `AdaptiveColors` (Agent AP)
- `lib/widgets/animations/shimmer_loading.dart` — `ShimmerLoading` (Agent AB)

Aucune dépendance externe à ajouter au `pubspec.yaml`.

## Intégration par l'agent wiring

1. Importer `lib/widgets/states/state_wrapper.dart` dans chaque écran avec
   données.
2. Convertir les flags `_isLoading` / `_loadingError` en `WidgetState`.
3. Remplacer `_buildLoadingScreen / _buildErrorScreen / _buildEmptyState`
   par les widgets spécifiques.
4. Tester en dark mode.
5. Valider 60fps sur Tecno/Itel cible (les skeletons sont très légers).
