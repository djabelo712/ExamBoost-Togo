# lib/screens/splash/

Splash screen animé + transitions de page réutilisables pour ExamBoost Togo.

## Contenu

```
lib/screens/splash/
├── splash_screen.dart   # Splash animé 2.5s (logo + tagline + progress)
├── transitions.dart     # Transitions GoRouter (fade, slideUp, scale, slideRight)
└── README.md            # Ce fichier
```

## 1. Splash screen (`splash_screen.dart`)

### Utilisation simple

Le widget `SplashScreen` est un `StatefulWidget` qui :

1. Joue une animation en 4 temps sur **2500 ms** :
   - **0.0s -> 0.5s** : logo qui fade-in + scale 0.8 -> 1.0 (`Curves.easeOutBack`)
   - **0.5s -> 1.0s** : tagline "ExamBoost Togo" qui slide up (`Curves.easeOut`)
   - **1.0s -> 1.5s** : sous-tagline "Préparation intelligente aux examens" qui fade in
   - **1.5s -> 2.5s** : `LinearProgressIndicator` (orange `AppColors.accent`) + texte "Chargement..."
2. À **2.5s**, lit `UserProvider.isAuthenticated` :
   - `true`  -> `context.go(AppRoutes.home)` (`/`)
   - `false` -> `context.go(AppRoutes.onboarding)` (`/onboarding`)

### Design

- Fond dégradé vertical `AppColors.primary` -> `AppColors.primaryDark` (vert Togo).
- Logo : container blanc 80x80 arrondi (radius 20) + `Icons.school` vert.
- Texte en blanc (sous-tagline à 85 % d'opacité).
- Pas de `Scaffold` : `Material` + `Container` décoré (pour préserver le dégradé plein écran).
- SafeArea pour les encoches.

### Personnaliser les durées

La durée totale est exposée comme paramètre nommé `durationMs` sur le `StatefulWidget` :

```dart
// Splash plus court (1.8s) pour les demos
SplashScreen(durationMs: 1800);
```

> Attention : si vous réduisez `durationMs`, les 4 phases se compressent
> proportionnellement (elles sont définies en pourcentages de la timeline
> via `Interval`). Ne pas descendre sous ~1500 ms sinon les phases se
> chevauchent visuellement.

Pour ajuster les durées de chaque phase individuellement, modifier les
`Interval(...)` dans `_SplashScreenState.initState()`.

## 2. Intégration au `main.dart` (À FAIRE PAR L'AGENT PRINCIPAL)

> ⚠️ Agent K n'a **pas** modifié `main.dart` ni `app_router.dart`.
> Les snippets ci-dessous sont des recommandations à appliquer lors du
> wiring final.

### Option A — Route initiale `/splash` (recommandée)

1. Ajouter une route `/splash` au router (voir section 3 ci-dessous).
2. Changer `initialLocation` du router :
   ```dart
   // lib/utils/app_router.dart
   return GoRouter(
     initialLocation: AppRoutes.splash, // au lieu de AppRoutes.home
     ...
   );
   ```
3. Le `SplashScreen` appellera lui-même `context.go('/')` ou `context.go('/onboarding')` à la fin de l'animation.
4. **Important** : ne pas inclure `/splash` dans le `redirect` du router, sinon
   l'utilisateur authentifié serait redirigé immédiatement vers `/` sans voir
   l'animation. Ajouter un guard explicite :
   ```dart
   redirect: (context, state) {
     final userProvider = Provider.of<UserProvider>(context, listen: false);
     // On reste sur /splash pendant l'init (le splash gère lui-même la suite).
     if (state.matchedLocation == AppRoutes.splash) return null;
     ...
   }
   ```

### Option B — Wrapper dans `main.dart` avant `runApp()`

Si on préfère que le splash s'affiche avant même le `MaterialApp.router` :

```dart
// lib/main.dart (extrait à adapter)
runApp(
  MultiProvider(
    providers: [...],
    child: const _SplashWrapper(child: ExamBoostApp()),
  ),
);

class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper({required this.child});
  final Widget child;

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash ? const SplashScreen() : widget.child;
  }
}
```

> L'Option A est préférable car elle laisse le `SplashScreen` décider de la
> destination en fonction de `UserProvider.isAuthenticated`.

## 3. Intégration des transitions au `app_router.dart` (À FAIRE PAR L'AGENT PRINCIPAL)

Pour chaque `GoRoute`, remplacer `builder:` par `pageBuilder:` qui renvoie une
`CustomTransitionPage<void>` construite via `buildPageWithTransition(...)`.

### Exemple complet

```dart
// lib/utils/app_router.dart (extrait à adapter)
import '../screens/splash/transitions.dart';

// ...

routes: [
  // Splash (route initiale si Option A)
  GoRoute(
    path: AppRoutes.splash,
    name: 'splash',
    builder: (context, state) => const SplashScreen(),
  ),

  // Onboarding : slide up (effet "montée" de modale)
  GoRoute(
    path: AppRoutes.onboarding,
    name: 'onboarding',
    pageBuilder: (context, state) => buildPageWithTransition(
      child: const OnboardingScreen(),
      type: TransitionType.slideUp,
    ),
  ),

  // Home : fade (sobre, transition neutre après splash)
  GoRoute(
    path: AppRoutes.home,
    name: 'home',
    pageBuilder: (context, state) => buildPageWithTransition(
      child: const HomeScreen(),
      type: TransitionType.fade,
    ),
  ),

  // Révision : slide right (navigation hiérarchique classique)
  GoRoute(
    path: '${AppRoutes.revision}/:matiere',
    name: 'revision',
    pageBuilder: (context, state) {
      final matiere = state.pathParameters['matiere'] ?? 'Mathématiques';
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      return buildPageWithTransition(
        child: RevisionScreen(
          matiere: Uri.decodeComponent(matiere),
          userId: userProvider.currentUserId,
        ),
        type: TransitionType.slideRight,
      );
    },
  ),

  // Simulation : scale (effet pop)
  GoRoute(
    path: AppRoutes.simulation,
    name: 'simulation',
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, String?>?;
      return buildPageWithTransition(
        child: SimulationScreen(
          examen: extra?['examen'] ?? 'BEPC',
          serie: extra?['serie'],
        ),
        type: TransitionType.scale,
      );
    },
  ),

  // Dashboard : fade
  GoRoute(
    path: AppRoutes.dashboard,
    name: 'dashboard',
    pageBuilder: (context, state) => buildPageWithTransition(
      child: const DashboardScreen(),
      type: TransitionType.fade,
    ),
  ),
],
```

Ne pas oublier d'ajouter la constante de route :

```dart
class AppRoutes {
  static const String splash     = '/splash';
  static const String onboarding = '/onboarding';
  static const String home       = '/';
  // ...
}
```

## 4. Transitions — référence API (`transitions.dart`)

### `TransitionType` (enum)

| Valeur       | Durée par défaut | Courbe            | Cas d'usage typique                         |
|--------------|------------------|-------------------|---------------------------------------------|
| `fade`       | 300 ms           | `easeInOut`       | Transitions neutres, dashboard, home        |
| `slideUp`    | 300 ms           | `easeOut`/`easeIn`| Modales, onboarding, formulaires            |
| `scale`      | 350 ms           | `easeOutBack`     | Dialogues, cartes qui pop                    |
| `slideRight` | 300 ms           | `easeInOut`       | Navigation push (liste -> détail)            |

### Builders individuels

Chaque type expose une classe `CustomTransitionPage<void>` instanciable directement :

```dart
FadeTransitionBuilder(child: const HomeScreen());
SlideUpTransitionBuilder(child: const OnboardingScreen(), duration: const Duration(milliseconds: 450));
ScaleTransitionBuilder(child: const DashboardScreen());
SlideRightTransitionBuilder(child: const RevisionScreen(...));
```

### Helper `buildPageWithTransition`

```dart
CustomTransitionPage<void> buildPageWithTransition({
  required Widget child,
  required TransitionType type,
  Duration? duration, // optionnel : surcharge la durée par défaut
  LocalKey? key,      // optionnel : force la clé de page
})
```

Exemple :

```dart
pageBuilder: (context, state) => buildPageWithTransition(
  child: const DashboardScreen(),
  type: TransitionType.fade,
  duration: const Duration(milliseconds: 500),
),
```

## 5. Contraintes techniques respectées

- **Pas de lib externe** : uniquement `AnimationController`, `Tween`,
  `CurvedAnimation`, `FadeTransition`, `SlideTransition`, `ScaleTransition`,
  et les `Curves` natives.
- **Durées courtes** : 300-350 ms pour les transitions, 2500 ms pour le splash.
- **Courbes** : `easeOutBack` pour les entrées "pop" (logo, scale),
  `easeInOut` pour les transitions sobres (fade, slideRight).
- **Code commenté en français**, pas d'emojis.
- **Imports uniquement depuis** `theme/app_theme.dart`, `providers/user_provider.dart`,
  `utils/app_router.dart`, `flutter/material.dart`, `go_router`, `provider`.
- Aucune modification de fichiers existants (main.dart, app_router.dart, pubspec.yaml).

## 6. Vérification rapide (à exécuter après wiring)

```bash
cd /home/z/my-project/ExamBoost-Togo
flutter analyze lib/screens/splash/
```

Doit retourner 0 erreur. Si `go_router` ou `provider` ne sont pas dans
`pubspec.yaml`, l'agent principal doit d'abord exécuter `flutter pub add go_router provider`
(ces packages sont déjà présents dans le projet, vérifié dans `main.dart`).
