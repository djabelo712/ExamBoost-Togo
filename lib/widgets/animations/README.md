# Librairie animations — ExamBoost Togo

Dossier : `lib/widgets/animations/`

Librairie de 10 widgets d'animation "premium" pour rendre l'app moins prototype
et plus engageante. Toutes les animations sont **sans dépendance externe** :
elles utilisent uniquement `CustomPaint` + `AnimationController` de Flutter.

Les animations Lottie (vectorielles) sont dans `lib/lottie/` et nécessitent
d'ajouter le package `lottie` au `pubspec.yaml` (voir §Integration ci-dessous).

## Sommaire

1. [Widgets disponibles](#widgets-disponibles)
2. [Utilisation par widget](#utilisation-par-widget)
3. [Combinaisons d'animations](#combinaisons-danimations)
4. [Animations Lottie](#animations-lottie)
5. [Performance](#performance)
6. [Integration (agent wiring)](#integration-agent-wiring)

---

## Widgets disponibles

| Widget               | Fichier                     | Usage principal                                   |
|----------------------|-----------------------------|---------------------------------------------------|
| `ConfettiAnimation`  | `confetti_animation.dart`   | Célébrations (fin de session, badge débloqué)     |
| `StreakFlame`        | `streak_flame.dart`         | Streak jours consécutifs (dashboard, badge)       |
| `SuccessBurst`       | `success_burst.dart`        | Réponse correcte en révision                      |
| `ProgressRing`       | `progress_ring.dart`        | Score circulaire animé (fin de session, stats)    |
| `CountUpText`        | `count_up_text.dart`        | Statistique qui monte de 0 à N (score, XP)        |
| `FadeInList`         | `fade_in_list.dart`         | Liste qui apparaît en cascade                     |
| `ShimmerLoading`     | `shimmer_loading.dart`      | Skeleton pendant les chargements                  |
| `BounceButton`       | `bounce_button.dart`        | CTA avec retour tactile spring                    |
| `TypewriterText`     | `typewriter_text.dart`      | Texte qui se tape (tuteur IA, citation)           |
| `PulseIndicator`     | `pulse_indicator.dart`      | Point "live"/"online" pulsé                       |

---

## Utilisation par widget

### 1. ConfettiAnimation

Confettis pendant X secondes, puis fade out. Deux modes : explosion depuis
le centre (`shouldExplode: true`) ou pluie depuis le haut (`false`).

```dart
import 'package:examboost_togo/widgets/animations/confetti_animation.dart';

// Sur Stack en overlay (full screen) :
Stack(
  children: [
    yourContent,
    Positioned.fill(
      child: ConfettiAnimation(
        particleCount: 100,
        duration: const Duration(seconds: 3),
        shouldExplode: true,
        onComplete: () => print('fini'),
      ),
    ),
  ],
)
```

### 2. StreakFlame

Flamme animée dont l'intensité dépend du nombre de jours consécutifs.

```dart
StreakFlame(days: user.streak, size: 32)

// Comportement automatique :
//   0-2 jours  : icône grise statique (pas de flamme)
//   3-6 jours  : flamme orange clair, oscillation subtile
//   7-29 jours : flamme orange vif + pulsation marquée
//   30+ jours  : flamme rouge + étincelles qui montent
```

### 3. SuccessBurst

Explosion de succès en 4 variantes via `SuccessType`.

```dart
// Apres une bonne reponse dans revision_screen :
OverlayEntry? entry;
entry = OverlayEntry(
  builder: (_) => Positioned.fill(
    child: SuccessBurst(
      type: SuccessType.correct,
      onComplete: () => entry?.remove(),
    ),
  ),
);
Overlay.of(context).insert(entry);

// Pour une reponse parfaite (avec confettis) :
SuccessBurst(type: SuccessType.perfect)

// Pour un passage de niveau :
SuccessBurst(type: SuccessType.levelup)
```

Variants :
- `correct` — 1s — petites étoiles jaunes qui explosent (8 directions)
- `mastered` — 1.5s — anneau vert qui s'étend + check central
- `perfect` — 2s — confettis + anneau + étoiles (combine plusieurs effets)
- `levelup` — 2s — cercle qui monte + texte "NIVEAU SUPERIEUR !"

### 4. ProgressRing

Anneau de progression circulaire animé, avec contenu central optionnel.

```dart
// Score final de session (combine avec CountUpText) :
ProgressRing(
  progress: taux / 100, // 0.0 - 1.0
  size: 160,
  strokeWidth: 12,
  color: AppColors.success,
  animationDuration: const Duration(milliseconds: 1500),
  child: CountUpText(
    value: taux,
    suffix: '%',
    style: AppTextStyles.h1,
  ),
)

// Maitrise d'une competence :
ProgressRing(
  progress: 0.42,
  size: 60,
  strokeWidth: 4,
  child: Text('42%', style: AppTextStyles.label),
)
```

### 5. CountUpText

Texte qui s'incrémente de 0 à la valeur cible.

```dart
CountUpText(value: 78, suffix: '%', style: AppTextStyles.h1)
CountUpText(value: 1250, prefix: '+', suffix: ' XP', duration: Duration(seconds: 2))
CountUpText(value: 12, suffix: ' cartes', style: AppTextStyles.h3)
```

### 6. FadeInList

Liste dont les items apparaissent en cascade (fade + slide).

```dart
FadeInList(
  itemDelay: const Duration(milliseconds: 100),
  itemDuration: const Duration(milliseconds: 400),
  offset: const Offset(0, 20), // slide up + fade
  children: [
    _buildStatCard('Cartes maitrisees', '42'),
    _buildStatCard('Streak', '12 jours'),
    _buildStatCard('Score moyen', '78%'),
  ],
)
```

### 7. ShimmerLoading

Effet shimmer (dégradé qui se déplace) sur un placeholder pendant le chargement.

```dart
ShimmerLoading(
  isLoading: _isLoading,
  child: Container(
    width: 200,
    height: 20,
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(4),
    ),
  ),
)

// Plusieurs squelettes en colonne :
ShimmerLoading(
  isLoading: _isLoading,
  child: Column(
    children: [
      _skeletonLine(width: 180),
      _skeletonLine(width: 140),
      _skeletonLine(width: 200),
    ],
  ),
)
```

### 8. BounceButton

Bouton avec effet spring au tap (scale 1.0 → 0.95 → 1.0).

```dart
BounceButton(
  onPressed: () => _startSession(),
  scale: 0.95, // facteur de compression au tap
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text('Demarrer la session', style: AppTextStyles.button),
  ),
)
```

### 9. TypewriterText

Texte qui se tape caractère par caractère avec curseur clignotant.

```dart
TypewriterText(
  text: 'Bonjour ! Je suis ton tuteur IA. Pose-moi ta question.',
  speed: const Duration(milliseconds: 40),
  style: AppTextStyles.body,
  showCursor: true,
  onComplete: () => print('fini de taper'),
)
```

### 10. PulseIndicator

Point pulsé (style "live" / "online" / "recording").

```dart
// Indicateur "EN DIRECT" (rouge)
Row(children: [
  PulseIndicator(color: AppColors.error, size: 8),
  const SizedBox(width: 6),
  Text('EN DIRECT', style: AppTextStyles.label),
])

// Indicateur "online" (vert)
PulseIndicator(color: AppColors.success, size: 10)

// Sans animation (statique)
PulseIndicator(animate: false)
```

---

## Combinaisons d'animations

### Réponse parfaite en révision (SuccessBurst + Confetti)

`SuccessBurst(type: SuccessType.perfect)` inclut déjà confettis + anneau + étoiles.
Pour un effet encore plus marqué, combiner avec une `ConfettiAnimation`
en arrière-plan :

```dart
Stack(
  alignment: Alignment.center,
  children: [
    // Confettis en arrière-plan (pluie depuis le haut, 3s)
    const Positioned.fill(
      child: ConfettiAnimation(
        duration: Duration(seconds: 3),
        shouldExplode: false,
      ),
    ),
    // SuccessBurst au centre (anneau + étoiles, 2s)
    SuccessBurst(type: SuccessType.perfect),
  ],
)
```

### Fin de session de révision (ProgressRing + CountUpText + Confetti)

```dart
Stack(
  children: [
    SingleChildScrollView(child: Column(children: [
      const SizedBox(height: 24),
      ProgressRing(
        progress: taux / 100,
        size: 180,
        strokeWidth: 14,
        color: _scoreColor(taux),
        child: CountUpText(
          value: taux,
          suffix: '%',
          duration: const Duration(seconds: 2),
          style: AppTextStyles.h1.copyWith(fontSize: 42),
        ),
      ),
      // ... autres stats
    ])),
    // Confettis seulement si taux >= 70%
    if (taux >= 70)
      const Positioned.fill(
        child: ConfettiAnimation(
          duration: Duration(seconds: 3),
          shouldExplode: true,
        ),
      ),
  ],
)
```

### Dashboard avec cascade + CountUp

```dart
FadeInList(
  itemDelay: const Duration(milliseconds: 150),
  children: [
    _buildStatTile(
      label: 'Cartes maitrisees',
      value: CountUpText(value: 42, suffix: '', style: AppTextStyles.h2),
    ),
    _buildStatTile(
      label: 'Streak',
      value: CountUpText(value: 12, suffix: ' j', style: AppTextStyles.h2),
    ),
    _buildStatTile(
      label: 'Score moyen',
      value: CountUpText(value: 78, suffix: '%', style: AppTextStyles.h2),
    ),
  ],
)
```

### Badge débloqué (SuccessBurst levelup + Lottie)

```dart
// Voir lib/screens/badges/badge_unlock_dialog.dart (deja implemente par Agent X)
// Pour enrichir avec un Lottie :
Stack(
  alignment: Alignment.center,
  children: [
    SuccessBurst(type: SuccessType.levelup),
    // Lottie badge_unlock (apres ajout du package lottie au pubspec)
    // Lottie.asset('lib/lottie/badge_unlock.json', repeat: false),
  ],
)
```

---

## Animations Lottie

5 fichiers JSON dans `lib/lottie/` :

| Fichier             | Description                                         | Durée   | Boucle |
|---------------------|-----------------------------------------------------|---------|--------|
| `success.json`      | Coche verte qui se dessine + cercle qui pulse       | 1s      | non    |
| `streak.json`       | Flamme qui danse + étincelles                        | 2s      | oui    |
| `badge_unlock.json` | Badge qui descend du ciel avec étincelles            | 2s      | non    |
| `exam_complete.json`| Trophée qui apparaît + confettis                     | 3s      | non    |
| `loading.json`      | Livre qui s'ouvre et se ferme                        | 2s      | oui    |

Voir `lib/lottie/README.md` pour le détail et comment en ajouter de nouveaux.

---

## Performance

Les animations sont gourmandes en CPU/GPU. Sur smartphones bas de gamme
(Tecno, Itel — cible principale au Togo), respecter ces règles :

1. **Une animation lourde à la fois** : éviter `SuccessBurst.perfect` (qui
   lance 60 confettis + anneau + étoiles) en même temps qu'un `ProgressRing`
   de 180px. Si nécessaire, désactiver le ProgressRing pendant 2s.

2. **Limiter le nombre de particules** : `ConfettiAnimation(particleCount: 100)`
   par défaut. Pour les appareils bas de gamme, passer à 40-50.

3. **Préférer les animations courtes** : 200-400ms pour les micro-interactions
   (BounceButton, PulseIndicator), 1-2s pour les célébrations (SuccessBurst,
   ProgressRing), 2-3s max pour les confettis.

4. **Éviter les boucles infinies multiples** : un seul `repeat()` à la fois
   par écran (ex. soit StreakFlame, soit PulseIndicator, pas les deux en
   boucle sur le même écran si possible).

5. **Désactiver en mode économie d'énergie** : détecter via
   `MediaQuery.disableAnimations` de Material ou un flag utilisateur.

   ```dart
   final shouldAnimate = !MediaQuery.disableAnimationsOf(context);
   // Si false, utiliser des widgets statiques (icone sans oscillation, etc.)
   ```

6. **RepaintBoundary** : encapsuler les widgets très animés dans un
   `RepaintBoundary` pour isoler la zone de repaint :

   ```dart
   RepaintBoundary(child: StreakFlame(days: streak, size: 32))
   ```

7. **Lottie vs CustomPaint** : les Lottie sont plus lourdes que les
   CustomPaint maison. Pour les animations simples (flamme, point pulsé),
   préférer les widgets de ce dossier. Réserver Lottie aux animations
   complexes (trophée, badge) où la valeur artistique justifie le coût.

---

## Integration (agent wiring)

Cette librairie est conçue pour être branchée par l'agent de wiring final.
Aucune modification du `pubspec.yaml` ou des écrans existants n'a été faite
par cet agent (conformément à la consigne).

### 1. Widgets (aucune dépendance externe)

Les 10 widgets sont immédiatement utilisables après import. Aucune entrée
`pubspec.yaml` requise.

### 2. Package `lottie` (déjà présent dans pubspec.yaml)

Le projet inclut déjà `lottie: ^3.1.2` dans `pubspec.yaml`. Aucune action
requise pour les widgets Lottie.

### 3. Déclarer les assets Lottie

Le `pubspec.yaml` actuel référence `assets/data/`, `assets/images/`, et
`assets/fonts/` mais pas les fichiers Lottie. L'agent wiring doit :

Soit (a) créer `assets/lottie/` à la racine du projet, y copier les 5 JSON
depuis `lib/lottie/`, et ajouter :

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/
    - assets/fonts/
    - assets/lottie/
```

Soit (b) référencer directement les JSON dans `lib/lottie/` :

```yaml
flutter:
  assets:
    - lib/lottie/success.json
    - lib/lottie/streak.json
    - lib/lottie/badge_unlock.json
    - lib/lottie/exam_complete.json
    - lib/lottie/loading.json
```

**Recommandation** : option (a) — suivre la convention Flutter standard
(assets à la racine, pas dans `lib/`).

### 4. Utiliser un Lottie dans un écran

```dart
import 'package:lottie/lottie.dart';

// Animation de chargement (boucle) :
Lottie.asset(
  'assets/lottie/loading.json', // NB: chemin pubspec, pas lib/lottie/
  width: 120,
  height: 120,
  fit: BoxFit.contain,
)

// Animation de succès (une fois) :
Lottie.asset(
  'assets/lottie/success.json',
  repeat: false,
  animate: true,
)
```

**Note** : le chemin d'asset dans `Lottie.asset(...)` dépend de la déclaration
dans `pubspec.yaml`. Si déclaré comme `lib/lottie/loading.json`, utiliser ce
chemin ; si copié dans `assets/lottie/`, utiliser `assets/lottie/loading.json`.
Recommandation : créer un dossier `assets/lottie/` à la racine et y copier
les 5 JSON pour suivre la convention Flutter standard.

### 5. Brancher dans revision_screen.dart

Dans `lib/screens/revision/revision_screen.dart` :

- Après `_recordAnswer(quality)` si `quality >= 4` : afficher un
  `SuccessBurst(type: SuccessType.correct)` en overlay pendant 1s.
- Dans `_buildSessionSummary()` : remplacer le `Container` circulaire par un
  `ProgressRing` + `CountUpText`, et ajouter une `ConfettiAnimation` si
  `taux >= 70%`.

Exemple de patch (à appliquer par l'agent wiring, pas par cet agent) :

```dart
// Dans _recordAnswer, apres isCorrect :
if (isCorrect) {
  _showSuccessBurst(SuccessType.correct);
}

void _showSuccessBurst(SuccessType type) {
  OverlayEntry? entry;
  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: SuccessBurst(
        type: type,
        onComplete: () => entry?.remove(),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
}
```

### 6. Brancher dans dashboard_screen.dart

- Remplacer le `CircularPercentIndicator` du score global par un `ProgressRing`
  + `CountUpText` (effet "premium").
- Encapsuler les statistiques SRS dans un `FadeInList`.
- Ajouter un `StreakFlame(days: user.streak, size: 32)` dans le header.

### 7. Brancher dans badges_screen.dart

- Dans `badge_unlock_dialog.dart` (déjà implémenté par Agent X) : ajouter
  `Lottie.asset('assets/lottie/badge_unlock.json')` en complément du
  CustomPainter existant pour un effet encore plus marqué.
- Ajouter une `ConfettiAnimation(shouldExplode: true)` en arrière-plan du
  dialog.

### 8. Tests recommandés

- Vérifier sur un émulateur Android bas de gamme (API 24, 1 GB RAM) que les
  animations ne jankent pas (> 60fps).
- Désactiver chaque animation une par une pour confirmer qu'aucune n'est
  bloquante pour la navigation.
