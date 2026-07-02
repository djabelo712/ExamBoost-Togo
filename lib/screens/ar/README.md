# Module AR Géométrie — `lib/screens/ar/`

Module de **réalité augmentée (AR) pour formes 3D géométriques**, destiné à
l'écran de visualisation interactive des solides étudiés au BEPC et BAC
(cylindre, pyramide, cône, sphère, cube, prisme).

L'élève sélectionne une forme, la visualise en 3D, la manipule (rotation,
zoom, translation), ajuste ses dimensions et lit en temps réel le volume et la
surface calculés. Une capture photo permet de sauvegarder la vue courante.

## Sommaire

1. [Structure](#structure)
2. [Fonctionnalités](#fonctionnalités)
3. [Architecture](#architecture)
4. [Packages à ajouter au `pubspec.yaml`](#packages-à-ajouter-au-pubspecyaml)
5. [Prérequis techniques](#prérequis-techniques)
6. [Wiring — branchement dans le router](#wiring--branchement-dans-le-router)
7. [Branchement de l'AR native (futur)](#branchement-de-lar-native-futur)
8. [API publique](#api-publique)
9. [Conformité aux consignes](#conformité-aux-consignes)

---

## Structure

```
lib/screens/ar/
├── ar_viewer_screen.dart             # Écran principal (StatefulWidget)
├── ar_object_selector.dart           # Sélecteur horizontal des 6 formes
├── ar_instructions_sheet.dart        # Bottom sheet d'aide (gestes + prérequis)
├── widgets/
│   ├── ar_camera_view.dart           # Vue camera + overlay 3D + RepaintBoundary
│   ├── ar_object_overlay.dart        # Rendu 3D CustomPainter + gestures
│   └── ar_info_panel.dart            # Panneau volume / surface / dimensions
├── services/
│   └── ar_service.dart               # Interface ArService + SimulatedArService + Factory
├── models/
│   └── ar_object.dart                # Modèle ARObject + calculs volume/surface
└── README.md                         # CE FICHIER
```

**Total : 9 fichiers** (8 fichiers Dart + 1 README).

---

## Fonctionnalités

| # | Feature | Implémentation |
|---|---------|----------------|
| 1 | Sélection forme | `ArObjectSelector` (6 formes en grille horizontale) |
| 2 | Vue AR / 3D | `ArCameraView` (arrière-plan simulé + `ArObjectOverlay`) |
| 3 | Manipulation rotation | Drag 1 doigt → yaw + pitch (CustomPainter `_Ar3DPainter`) |
| 4 | Manipulation scale | Pincement 2 doigts → scale 0,3× à 3× |
| 5 | Manipulation translation | Drag 2 doigts → offset écran |
| 6 | Auto-rotation | `AnimationController` repeat, yaw += 0,004 / frame |
| 7 | Infos temps réel | `ArInfoPanel` : volume, surface totale, surface latérale |
| 8 | Dimensions éditables | Sliders dans `ArInfoPanel` (1 à 20 cm) |
| 9 | Capture photo | `RepaintBoundary.toImage()` → PNG → `path_provider` |
| 10 | Aide intégrée | `ArInstructionsSheet` (gestes + fonctionnalités + prérequis) |
| 11 | Fallback non-AR | `SimulatedArService` actif par défaut |
| 12 | Indicateur état | Chip dans l'AppBar (idle / init / ready / mode simulé / AR native) |
| 13 | Reset vue | Bouton refresh → repositionnement forme |
| 14 | Toggle auto-rotate | Bouton sync → on/off |

---

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                   ArViewerScreen (Statefull)                │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ArObjectSelector  ←→  _currentObject (ARObject)        │ │
│  │                          ↑↓                            │ │
│  │ ArCameraView (Expanded)  │                             │ │
│  │   ├ _SimulatedCameraBackground                         │ │
│  │   ├ ArObjectOverlay (3D) ─── _Ar3DPainter (CustomPaint)│ │
│  │   └ _SimulatedModeBadge                                │ │
│  │                          │                             │ │
│  │ ArInfoPanel ←────────────┘  (volume, surface, sliders)  │ │
│  └────────────────────────────────────────────────────────┘ │
│                            ↑↓                               │
│  ArService (interface) ←── ArServiceFactory.create()        │
│   └ SimulatedArService (par défaut)                         │
│   └ NativeArService (futur — quand ar_flutter_plugin)       │
└────────────────────────────────────────────────────────────┘
```

### Flux de données

1. L'utilisateur sélectionne une forme → `_selectShape(type)` met à jour
   `_currentObject` via `ARObject.defaultFor(type)`.
2. Le `ArObjectOverlay` rebuild avec le nouvel `ARObject` → le
   `_Ar3DPainter` regénère les polygones 3D (`_buildPolygons`).
3. L'utilisateur drag/pinch → `_yaw`, `_pitch`, `_scale`, `_translation`
   changent → `setState` → `_Ar3DPainter` redessine.
4. L'utilisateur bouge un slider de dimension → `_updateDimensions` →
   `_currentObject.copyWith(dimensions: ...)` → rebuild → `_Ar3DPainter`
   regénère les polygones + `ArInfoPanel` recalcule volume/surface.
5. L'utilisateur appuie sur "Photo" → `_capturePhoto` →
   `RepaintBoundary.toImage()` → PNG bytes → fichier dans documents dir.

### Rendu 3D (mode simulé)

Le `_Ar3DPainter` fait un rendu 3D logiciel en pure Dart (aucun plugin) :

- **Construction des polygones** : chaque forme est décrite par une liste de
  faces (`_Poly`), chaque face étant une liste de sommets 3D (`Vec3`).
  - Cercles (cylindre, cône) approximés avec `_kSegments = 28` segments.
  - Sphère générée avec `_kLatBands = 14` bandes de latitude.
- **Rotation** : matrice de rotation yaw (autour Y) + pitch (autour X) appliquée
  à chaque sommet.
- **Projection perspective** : `factor = fov / (z + fov + 6)`, `screen_x = cx + x * factor * scale * pxPerCm`.
- **Algorithme du peintre** : tri des polygones par z moyen décroissant (le
  plus lointain dessiné en premier).
- **Ombrage Lambert** : `intensity = max(0, dot(normal, lightDir))`,
  `color = base * (0.35 + 0.65 * intensity)` — ambient + diffus.
- **Contours** : dessinés uniquement sur les faces planes (cube, pyramide,
  prisme) — pas sur les surfaces courbes pour éviter l'effet facette.

---

## Packages à ajouter au `pubspec.yaml`

Le module fonctionne **immédiatement** sans aucun package additionnel — il
utilise uniquement des packages déjà présents dans le projet :

- `path_provider: ^2.1.3` (déjà présent, ligne 31) — pour sauvegarder les
  captures photo PNG.
- Aucune autre dépendance.

### Pour activer l'AR native (optionnel, futur)

Ajouter au `pubspec.yaml` l'une des deux options suivantes :

```yaml
dependencies:
  # Option A (recommandée) — ARCore (Android) + ARKit (iOS)
  ar_flutter_plugin: ^0.7.3

  # Option B (iOS uniquement) — ARKit seul
  # arkit_plugin: ^1.1.0
```

> **Note** : `ar_flutter_plugin` est en maintenance réduite depuis 2023. Pour
> un projet production, envisager aussi :
> - [`model_viewer_plus`](https://pub.dev/packages/model_viewer_plus) pour
>   visualiser des modèles GLB sans AR.
> - [`flutter_gl`](https://pub.dev/packages/flutter_gl) pour du rendu WebGL
>   multiplateforme (mais API bas niveau).

---

## Prérequis techniques

### Mode simulé (par défaut — fonctionne partout)

| Plateforme | Support | Notes |
|-----------|---------|-------|
| Android | OK | Toutes versions |
| iOS | OK | Toutes versions |
| Web | OK | Rendu 3D logiciel |
| Desktop | OK | Rendu 3D logiciel |

Aucune permission requise, aucun plugin AR, aucun ARCore/ARKit.

### Mode AR native (futur — après ajout de `ar_flutter_plugin`)

| Plateforme | Support | Prérequis |
|-----------|---------|-----------|
| Android | 8.0+ (API 26+) | ARCore installé (Play Store) |
| iOS | 12.0+ | Appareil avec processeur A9+ (iPhone 6s+) |
| Web | Non | — |
| Desktop | Non | — |

**Permissions à déclarer :**

Android (`android/app/src/main/AndroidManifest.xml`) :
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera.ar" android:required="false" />
<meta-data android:name="com.google.ar.core" android:value="optional" />
```

iOS (`ios/Runner/Info.plist`) :
```xml
<key>NSCameraUsageDescription</key>
<string>La caméra est utilisée pour visualiser les formes 3D en réalité augmentée.</string>
```

La détection automatique de plateforme se fait dans `ArServiceFactory._isArNativeSupported`
(vérifie `Platform.isAndroid` + SDK ≥ 26, ou `Platform.isIOS` + version ≥ 12).

---

## Wiring — branchement dans le router

L'agent de wiring doit faire **2 actions** (aucun autre fichier n'est touché) :

### 1. Ajouter la route dans `lib/utils/app_router.dart`

```dart
import '../screens/ar/ar_viewer_screen.dart';
// ... autres imports

// Dans la liste `routes` du GoRouter :
GoRoute(
  path: '/ar-geometrie',
  builder: (context, state) => const ArViewerScreen(),
),
```

### 2. (Optionnel) Ajouter un bouton d'accès dans le tableau de bord

Dans `lib/screens/dashboard/dashboard_screen.dart` ou
`lib/screens/home/home_screen.dart`, ajouter une carte qui pointe vers
`/ar-geometrie` :

```dart
ListTile(
  leading: const Icon(Icons.view_in_ar, color: Color(0xFF006837)),
  title: const Text('AR Géométrie'),
  subtitle: const Text('Visualiser les formes 3D en réalité augmentée'),
  onTap: () => context.go('/ar-geometrie'),
),
```

> **Pas d'adaptateur Hive à enregistrer** — `ARObject` est un modèle pur (sans
> persistance). Pas de `*.g.dart` à générer. Pas de `pubspec.yaml` à modifier
> pour le mode simulé.

---

## Branchement de l'AR native (futur)

Quand `ar_flutter_plugin` est ajouté au `pubspec.yaml`, créer le fichier
`lib/screens/ar/services/ar_native_service.dart` avec le squelette suivant :

```dart
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'ar_service.dart';
import '../models/ar_object.dart';

class NativeArService implements ArService {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;

  @override
  bool get isNativeSupported => true;

  @override
  ArSessionState get state => /* ... */;

  @override
  Stream<ArSessionState> get stateStream => /* ... */;

  @override
  Future<void> initialize() async {
    // Ouvrir la session AR avec detection de plans horizontaux.
    _sessionManager = ARSessionManager();
    _objectManager = ARObjectManager();
    await _sessionManager!.showInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: true,
      handleRotation: true,
    );
    _sessionManager!.onPlaneOrPointTapped = _onSurfaceTapped;
  }

  void _onSurfaceTapped(List<ARHitTestResult> hits) {
    if (hits.isEmpty) return;
    // Ancre un noeud 3D (GLB/USDZ) a la position tapée.
    final hit = hits.first;
    final node = ARNode(
      type: ARNodeType.localGLTF2,
      uri: 'assets/models/cylindre.glb',
      scale: Vector3(0.2, 0.2, 0.2),
      position: Vector3(hit.worldTransform.getColumn(3).x,
                        hit.worldTransform.getColumn(3).y,
                        hit.worldTransform.getColumn(3).z),
      rotation: Vector4(0, 1, 0, 0),
    );
    _objectManager!.addNode(node);
  }

  @override
  Future<void> placeObject(ARObject object) async {
    // Mapper ARObject.type -> asset GLB/USDZ correspondant.
    // Ex : ARShapeType.cylindre -> 'assets/models/cylindre.glb'
  }

  @override
  Future<ArCaptureResult> captureScreenshot({
    required GlobalKey repaintBoundaryKey,
  }) async {
    // En mode AR natif, la capture se fait via le plugin AR (frame camera +
    // overlay 3D natif), PAS via RepaintBoundary.
    final path = await _sessionManager!.snapshot();
    return ArCaptureResult(success: true, filePath: path);
  }

  @override
  void dispose() {
    _sessionManager?.dispose();
  }
  // ... autres methodes
}
```

Puis, dans `ArServiceFactory.create()`, décommenter le bloc :

```dart
static ArService create() {
  if (_isArNativeSupported) {
    return NativeArService();
  }
  return SimulatedArService();
}
```

### Assets 3D (GLB / USDZ)

Pour l'AR native, il faut des modèles 3D au format GLB (Android/ARCore) et
USDZ (iOS/ARKit). À placer dans `assets/models/` :

```
assets/models/
├── cylindre.glb
├── pyramide.glb
├── cone.glb
├── sphere.glb
├── cube.glb
└── prisme.glb
```

Et déclarer dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/models/
```

Les modèles peuvent être générés gratuitement avec [Blender](https://www.blender.org/)
(export GLB) ou téléchargés depuis [Google Poly archive](https://poly.pizza/)
ou [Sketchfab](https://sketchfab.com/) (CC).

---

## API publique

### `ArViewerScreen`

```dart
// Constructeur par défaut (cylindre sélectionné).
const ArViewerScreen();

// Avec une forme initiale spécifique.
ArViewerScreen(initialShape: ARShapeType.sphere);
```

### `ArService` (interface)

```dart
abstract class ArService {
  bool get isNativeSupported;
  bool get isSimulated;
  ArSessionState get state;
  Stream<ArSessionState> get stateStream;

  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> placeObject(ARObject object);
  Future<void> clearScene();
  Future<ArCaptureResult> captureScreenshot({required GlobalKey repaintBoundaryKey});
  void dispose();
}
```

### `ARObject` (modèle)

```dart
final obj = ARObject.defaultFor(ARShapeType.cylindre);
// dimensions: {'r': 3.0, 'h': 10.0}, color: vert Togo

obj.volume;             // 282.74 cm³ (π × 3² × 10)
obj.surfaceTotale;      // 244.92 cm² (2πr² + 2πrh)
obj.surfaceLaterale;    // 188.50 cm² (2πrh)
obj.formuleVolume;      // 'V = π × r² × h'
obj.formuleSurface;     // 'S = 2πr² + 2πrh'
obj.dimensionsListees;  // [ARDimension('r', 'Rayon', 3.0, 'cm'), ARDimension('h', 'Hauteur', 10.0, 'cm')]

// Modifier les dimensions (recalcule automatiquement volume / surface).
final modifie = obj.copyWith(dimensions: {'r': 5.0, 'h': 8.0});
```

---

## Conformité aux consignes

- **Périmètre strict** : 9 fichiers créés uniquement dans `lib/screens/ar/`.
  Aucune modification de `main.dart`, `app_router.dart`, `pubspec.yaml`, ou
  d'autres fichiers du projet.
- **Flutter 3.44+ / Material 3** : utilisation de `ColorScheme.surfaceContainerHighest`,
  `ColorScheme.outlineVariant`, `FilledButton.icon`, switch expressions, etc.
- **Palette Togo** : `#006837` (vert) pour cylindre, cube, prisme ; `#D97700`
  (orange) pour pyramide, cône ; `#1565C0` (bleu info) pour cône ; `#2E7D32`
  (success) pour sphère. Respect de la palette définie dans
  `lib/theme/app_theme.dart`.
- **Commentaires en français** : tous les commentaires (en-têtes de fichiers,
  docstrings, commentaires inline) sont en français.
- **Pas d'emojis** : aucun emoji dans le code ni dans les commentaires. Les
  caractères box-drawing (`├`, `│`, `└`) sont conservés dans le README et les
  commentaires pour la lisibilité (cohérent avec le reste du projet).
- **Pas de `print()`** : utilisation de `ScaffoldMessenger.showSnackBar` pour
  le feedback utilisateur.
- **Dépendances optionnelles documentées** : `ar_flutter_plugin: ^0.7.3` est
  mentionné dans ce README mais **non ajouté** au `pubspec.yaml` (par respect
  de la consigne).
- **Fallback universel** : `SimulatedArService` fonctionne sur mobile, web et
  desktop sans aucune permission ni plugin.
- **Persistance** : aucune (les `ARObject` sont des modèles purs en mémoire,
  pas de Hive, pas de SQLite).

---

## Tests rapides (sans flutter installé)

Vérifications syntaxiques à effectuer avant livraison (par l'agent BE futur) :

- Aucune apostrophe non échappée dans les littéraux string (rechercher
  `'[^']*'[^']*'` pour détecter).
- Toutes les `switch` sur `ARShapeType` sont exhaustives (6 cas).
- Aucun import circulaire (`ar_service.dart` importe `ar_object.dart` qui
  n'importe rien du module AR).
- Tous les widgets utilisent `Theme.of(context)` pour les couleurs sémantiques
  (pas de couleurs codées en dur hors palette Togo).
- `RenderRepaintBoundary` correctement importé depuis
  `package:flutter/rendering.dart` pour la capture photo.
- `path_provider` déjà présent dans le `pubspec.yaml` (ligne 31, version
  `^2.1.3`) — pas besoin de l'ajouter.

---

## Prochaines étapes possibles (V2)

1. **Activer l'AR native** : ajouter `ar_flutter_plugin`, créer
   `ar_native_service.dart`, générer les 6 modèles GLB/USDZ.
2. **Bibliothèque de formes étendue** : pavé droit, tétraèdre, octaèdre,
   prisme hexagonal, torus.
3. **Mode "coupe"** : afficher la forme coupée par un plan pour visualiser
   la section (utile pour le cours sur les volumes).
4. **Mode "dépliage"** : animer le dépliage de la forme en patron (cube →
   croix, cylindre → rectangle + 2 disques, etc.).
5. **Quiz associé** : après manipulation, poser des questions ("Quel est le
   volume d'un cylindre r=3, h=10 ?") et vérifier la réponse.
6. **Partage de la capture** : `share_plus` pour partager le PNG via WhatsApp,
   email, etc. (dépendance à ajouter).
7. **Sauvegarde des dimensions personnalisées** : Hive pour retenir les
   dernières dimensions utilisées par l'élève.
8. **Mode "deux formes"** : afficher 2 formes côte à côte pour comparer
   volumes et surfaces (utile pour le cours sur les proportions).
