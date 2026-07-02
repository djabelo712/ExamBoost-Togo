# Lottie assets — ExamBoost Togo

Dossier : `lib/lottie/`

5 animations Lottie (JSON vectoriel) prêtes à être intégrées via le package
Flutter `lottie: ^3.1.2`.

## Fichiers

| Fichier             | Description                                                       | Durée   | Boucle | Cas d'usage                                  |
|---------------------|-------------------------------------------------------------------|---------|--------|----------------------------------------------|
| `success.json`      | Coche verte qui se dessine + cercle vert qui pulse                | 1s      | non    | Réponse correcte en révision                 |
| `streak.json`       | Flamme qui oscille + étincelles                                    | 2s      | oui    | Streak de jours (dashboard, badge)           |
| `badge_unlock.json` | Badge qui descend du ciel + 3 étincelles qui jaillissent          | 2s      | non    | Déblocage de badge                           |
| `exam_complete.json`| Trophée qui apparaît + 3 confettis qui jaillissent                | 3s      | non    | Fin d'examen blanc                           |
| `loading.json`      | Livre qui s'ouvre et se ferme + lignes de page qui clignotent     | 2s      | oui    | Chargement initial, transitions              |

Tous les fichiers sont au format Lottie 5.7.6, frame rate 30fps (60fps pour
`success.json` pour un dessin plus fluide).

## Palette utilisée

Pour rester cohérent avec `lib/theme/app_theme.dart` :

- Vert Togo : `#006837` → `[0.18, 0.49, 0.20, 1]` (RGBA normalisé Lottie)
- Orange : `#D97700` → `[0.85, 0.47, 0.0, 1]`
- Orange clair : `#FFB74D` → `[1.0, 0.72, 0.0, 1]`
- Bleu info : `#1565C0` → `[0.08, 0.40, 0.75, 1]`
- Jaune étincelles : `#FFD900` → `[1.0, 0.85, 0.0, 1]`
- Blanc : `[1, 1, 1, 1]`

## Structure d'un fichier Lottie

Format minimal (voir `success.json` pour exemple complet) :

```json
{
  "v": "5.7.6",        // version Lottie
  "fr": 30,            // frame rate (fps)
  "ip": 0,             // in point (frame de debut)
  "op": 60,            // out point (frame de fin) -> duree = (op - ip) / fr
  "w": 200,            // largeur en px
  "h": 200,            // hauteur en px
  "nm": "name",        // nom (info)
  "ddd": 0,            // 3D? (0 = 2D)
  "assets": [],        // assets prechargeables (images, etc.)
  "layers": [          // calques (rendus du bas vers le haut)
    {
      "ty": 4,          // type 4 = shape layer
      "nm": "circle",   // nom du calque
      "ks": {           // transform
        "o": { "a": 1, "k": [...] },  // opacity (a=1 = animated)
        "r": { "a": 0, "k": 0 },      // rotation
        "p": { "a": 0, "k": [100, 100, 0] },  // position
        "s": { "a": 0, "k": [100, 100, 100] } // scale (%)
      },
      "shapes": [
        { "ty": "el", "p": {...}, "s": {...} },  // ellipse
        { "ty": "fl", "c": { "a": 0, "k": [r,g,b,a] } }  // fill
      ],
      "ip": 0, "op": 60, "st": 0
    }
  ]
}
```

Propriétés d'animation (`a: 1`) : la valeur `k` devient un tableau de
keyframes `[ { "t": frame, "s": [value] }, ... ]`. Le moteur Lottie interpole
entre les keyframes.

Types de shapes (`ty`) :
- `el` : ellipse (cercle)
- `rc` : rectangle (avec `r` = rayon des coins)
- `sh` : shape path (bezier)
- `sr` : étoile (`pt` = nombre de branches, `ir`/`or` = rayons interne/externe)
- `fl` : fill (couleur de remplissage)
- `st` : stroke (contour)

## Comment ajouter un nouveau Lottie

### Option A : Télécharger depuis lottiefiles.com (recommandé)

1. Aller sur https://lottiefiles.com/featured (section "Free Animations")
2. Filtrer par licence "Free" (icône verte "FREE")
3. Télécharger le JSON (bouton "Download" → "Lottie JSON")
4. Renommer si besoin et copier dans `lib/lottie/`
5. Adapter les couleurs si nécessaire (voir §Palette ci-dessus) en éditant
   le JSON avec un éditeur de texte
6. Vérifier la taille : < 100 KB idéal, < 500 KB acceptable
7. Ajouter au `pubspec.yaml` (voir README du dossier `animations/` §Integration)

**Licences** : lottiefiles.com propose des animations sous licence libre
(MIT, CC-BY, etc.). Toujours vérifier la licence spécifique de chaque
animation avant utilisation commerciale. Pour ExamBoost (projet open source
à but éducatif), les licences MIT et CC-BY sont compatibles.

### Option B : Créer depuis After Effects (avancé)

1. Créer l'animation dans Adobe After Effects
2. Installer le plugin **Bodymovin** (gratuit)
3. Exporter via Extensions → Bodymovin → Render
4. Le JSON généré est directement utilisable par `lottie` Flutter

### Option C : Créer depuis Rive (alternative)

[Rive](https://rive.app) est une alternative moderne à Lottie avec un éditeur
web gratuit. Les exports `.riv` nécessitent le package `rive` (pas `lottie`).
Non couvert par ce dossier — à évaluer si Lottie s'avère trop limité.

### Option D : Éditer le JSON à la main (cas simples)

Pour les animations simples (1-3 calques, keyframes basiques), il est possible
d'écrire le JSON à la main. C'est l'approche utilisée pour les 5 fichiers de
ce dossier. S'inspirer de `loading.json` (le plus simple) pour démarrer.

## Comment utiliser un Lottie dans Flutter

Après avoir ajouté `lottie: ^3.1.2` au `pubspec.yaml` :

```dart
import 'package:lottie/lottie.dart';

// Animation en boucle (chargement) :
Lottie.asset(
  'assets/lottie/loading.json',
  width: 120,
  height: 120,
  fit: BoxFit.contain,
)

// Animation une seule fois (succès) :
Lottie.asset(
  'assets/lottie/success.json',
  repeat: false,
  animate: true,
  onLoaded: (composition) {
    // composition.duration peut être utilisé pour des synchronisations
  },
)

// Animation avec controller custom (avancé) :
late final AnimationController _controller;
// ...
Lottie.asset(
  'assets/lottie/exam_complete.json',
  controller: _controller,
  onLoaded: (composition) {
    _controller
      ..duration = composition.duration
      ..forward();
  },
)
```

## Sources et crédits

Les 5 fichiers de ce dossier ont été créés à la main (JSON écrit directement)
pour cet agent. Ils sont volontairement simples (3-6 calques chacun, < 5 KB)
pour :

- Garder un poids minimal (idéal pour connexions 3G togolaises)
- Garantir la cohérence visuelle avec la palette ExamBoost
- Permettre une maintenance facile (un développeur peut éditer le JSON sans
  installer After Effects)

Pour des animations plus riches (effets de particules complexes, dégradés
animés, morphing), envisager de télécharger des Lottie libres sur
lottiefiles.com ou de créer un compte Rive.

## Liens utiles

- **Lottie specification** : https://lottiefiles.github.io/lottie-docs/
- **lottie package Flutter** : https://pub.dev/packages/lottie
- **LottieFiles free animations** : https://lottiefiles.com/featured
- **LottieFiles editor (online)** : https://lottiefiles.com/web-editor
- **Rive (alternative)** : https://rive.app
- **Bodymovin plugin AE** : https://aescripts.com/bodymovin/

## Tests recommandés

Après intégration :

1. Vérifier que les 5 fichiers se chargent sans erreur avec
   `Lottie.asset(...)` (warning console si JSON invalide).
2. Tester sur Android API 24+ (minimum cible Togo) : pas de jank visible.
3. Mesurer l'impact mémoire : un Lottie consomme ~1-3 MB par instance
   chargée. Ne pas en garder 5 en mémoire simultanément.
4. Pour les animations non-bouclées (`success`, `badge_unlock`,
   `exam_complete`) : bien mettre `repeat: false` pour éviter de consommer
   du CPU inutilement après la fin.
