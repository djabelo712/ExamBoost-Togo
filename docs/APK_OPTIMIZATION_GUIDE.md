# Guide d'optimisation APK - ExamBoost Togo

> Cible : **APK < 25 Mo** par ABI (contrainte smartphones bas de gamme Togo -
> Tecno Spark 4/5, Itel A50, Infinix Hot 10 - 16 Go de stockage, data
> cellulaire limitee).

## 1. Objectif et contexte

Au Togo, la grande majorite des eleves utilisent des smartphones Android
d'entree de gamme (Tecno, Itel, Infinix) achetes d'occasion, avec 16 Go de
stockage partage entre apps, photos et WhatsApp. Le telechargement d'un APK de
50 Mo sur un forfait data limite (500 Mo / mois en moyenne) est un frein
critique a l'adoption.

La cible **< 25 Mo** par APK (apres `--split-per-abi`) est le seuil en dessous
duquel le telechargement reste acceptable meme en 2G/3G limitee. C'est aussi la
limite pratique pour partager l'APK via WhatsApp ou Bluetooth entre eleves.

Ce guide documente les 5 strategies d'optimisation implementees dans les
scripts `scripts/build_apk_optimized.sh`, `scripts/optimize_assets.sh` et
`scripts/analyze_apk_size.sh`.

## 2. Vue d'ensemble des strategies

| # | Strategie | Outil / Flag | Gain estime | Cout |
|---|-----------|--------------|-------------|------|
| 1 | Split per ABI | `--split-per-abi` | -40% par APK | aucun |
| 2 | R8 / ProGuard | `--shrink` | -20% code | compilation +2 min |
| 3 | Tree-shake icons | `--tree-shake-icons` | -2 Mo (font Material) | aucun |
| 4 | Obfuscation | `--obfuscate --split-debug-info` | -5% + securite | necessite symbols pour deobf |
| 5 | Assets optimises | `optimize_assets.sh` | -30% assets | manuel (1 fois) |
| 6 | Lazy loading | Deferred Components | -10 Mo potentiel | architecture |

**Cumul realiste** : un APK `arm64-v8a` non optimise pese typiquement 30-40 Mo.
Apres les strategies 1-5, on obtient 12-18 Mo (objectif < 25 Mo atteint avec
marge).

## 3. Strategie 1 - Split per ABI

### Principe

Un APK "fat" contient les bibliotheques natives pour **toutes** les
architectures CPU Android :

- `arm64-v8a` : smartphones 64-bits (Tecno Spark 5+, Infinix Hot 10+,
  quasi-totalite des modeles 2020+).
- `armeabi-v7a` : smartphones 32-bits (Tecno Spark 4, Itel A50, modeles 2017-
  2019 encore tres repandus au Togo).
- `x86_64` : emulateurs (pratique pour les dev, inutile en prod Togo).

Le moteur Flutter (`libflutter.so`) et le code Dart compile (`libapp.so`)
existent en 3 versions, soit ~6-8 Mo par ABI. Un APK fat embarque donc
~18-24 Mo de bibliotheques natives, alors qu'un smartphone donne n'en utilise
qu'une seule.

### Mise en oeuvre

```bash
flutter build apk --release --split-per-abi
```

Produit 3 APK distincts :

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk     # ~12-15 Mo
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk   # ~10-13 Mo
build/app/outputs/flutter-apk/app-x86_64-release.apk        # ~14-17 Mo
```

### Distribution ciblee au Togo

| APK | Cible | Part estimee |
|-----|-------|--------------|
| `arm64-v8a` | Smartphones 2020+ (Tecno Spark 5+, Infinix Hot 10+) | 65% |
| `armeabi-v7a` | Smartphones 2017-2019 (Tecno Spark 4, Itel A50) | 30% |
| `x86_64` | Emulateurs (dev / salles informatiques) | 5% |

**Recommandation** : pour la beta Togo, distribuer majoritairement
`arm64-v8a`. Proposer `armeabi-v7a` en seconde option pour les telephones
anciens (download link distinct sur la landing page).

## 4. Strategie 2 - R8 / ProGuard

### Principe

R8 (remplacement moderne de ProGuard integre a Android Gradle Plugin) :

- **Shrinking** : retire le code Java/Kotlin/Dart inutilise (analyses de
  graphe de appel depuis les entry points).
- **Obfuscation** : renomme les classes / methodes / champs en noms courts
  (`a.b.c` au lieu de `com.examboost.togo.services.SrsService`). Reduit la
  taille des noms stockes dans `classes.dex` et `libapp.so`.
- **Optimization** : inline, dead-code elimination, peephole opts.

### Mise en oeuvre Flutter

Flutter expose ces optimisations via les flags de `flutter build apk` :

```bash
flutter build apk --release \
  --split-per-abi \
  --shrink \
  --obfuscate \
  --split-debug-info=build/symbols/<timestamp>/
```

- `--shrink` : active R8 shrinking + resource shrinking.
- `--obfuscate` : active la renommage Dart.
- `--split-debug-info=<dir>` : ecrit la table de symboles dans `<dir>/`
  (indispensable pour decoder les stack traces de crash en production -
  **conserver ce dossier** dans un endroit sur, par exemple un bucket S3
  versionne par release).

### Configuration Android native (deja activee par --shrink)

Pour memoire, la configuration Gradle equivalente est :

```gradle
// android/app/build.gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

Flutter active automatiquement `minifyEnabled true` en release ; le flag
`--shrink` ajoute `shrinkResources true` et le R8 full mode.

### Risques et mitigations

| Risque | Mitigation |
|--------|-----------|
| Plugin natif casse par R8 (reflection) | Ajouter `-keep` rules dans `proguard-rules.pro` |
| Stack trace obfusquee illisible | Conserver `--split-debug-info` + utiliser `flutter symbolize` |
| Build +2 min | Acceptable en CI, pas en boucle dev (utiliser `--debug`) |

## 5. Strategie 3 - Tree-shake icons

### Principe

La police Material Icons (`MaterialIcons-Regular.otf`, ~1.7 Mo) embarque
**tous** les glyphes d'icones Material. Une app Flutter n'en utilise
typiquement qu'une centaine, mais sans tree-shaking, la police entiere est
bundlee dans l'APK.

`--tree-shake-icons` analyse le code Dart pour identifier les icones
effectivement referencees (via `Icons.xxx`) et retire les autres glyphes de la
police embarquee.

### Mise en oeuvre

```bash
flutter build apk --release --tree-shake-icons
```

> Note : `--tree-shake-icons` est active **par defaut** en mode release depuis
> Flutter 2.0. Le passer explicitement n'est utile que pour les pipelines CI
> ou l'on veut garantir l'activation.

### Gain attendu

- Polices Material entieres : ~1.7 Mo
- Apres tree-shaking (100 icones utilisees) : ~50-100 Ko
- **Gain net** : ~1.5-2 Mo par APK

### Limitation

Le tree-shaking ne fonctionne que pour les icones referencees statiquement
(`Icons.foo`). Les icones referencees dynamiquement via
`IconData(0xe123, fontFamily: 'MaterialIcons')` ne sont pas detectees et sont
retirees - ce qui peut casser l'UI. Si vous utilisez des icones dynamiques,
desactivez le flag ou ajoutez-les manuellement a la police.

## 6. Strategie 4 - Assets optimises

Cette strategie est implementee par `scripts/optimize_assets.sh` (dry-run par
defaut, `--apply` pour modifier en place avec backup `.bak`).

### 6.1 PNG -> WebP

WebP offre une compression superieure de 25-35% vs PNG pour une qualite
visuelle identique. Supporte par Android depuis API 14 (Android 4.0) - couvre
100% du parc Togo cible (Android 5+ minimum).

```bash
cwebp -q 80 input.png -o output.webp
```

| Format | Taille typique | Qualite |
|--------|----------------|---------|
| PNG (sans compression) | 100% | perteless |
| PNG (optimise pngquant) | 70% | perteless |
| WebP q=90 | 50% | visuellement perteless |
| WebP q=80 | 35% | tres bonne |
| WebP q=70 | 25% | bonne |

**Recommandation** : `q=80` pour les photos, `q=90` pour les screenshots UI,
`lossless` pour les logos avec transparence.

### 6.2 SVG minification

Les SVG produits par Figma / Illustrator contiennent des commentaires, des
metadonnees `<metadata>`, des definitions inutilisees et un indentation
verbose. `svgo` les nettoie.

```bash
svgo --multipass input.svg -o output.svg
```

Gain typique : -30% a -50% sur des SVG Figma non optimises.

Si `svgo` n'est pas disponible, le script `optimize_assets.sh` applique un
fallback `sed` qui strip les commentaires XML et les espaces superflus (gain
plus modeste, ~10-20%).

### 6.3 Retrait metadonnees images

Les EXIF des photos (GPS, modele appareil, date) peuvent peser 50-200 Ko par
image et posent un probleme de confidentialite (GPS des eleves). Deux outils :

```bash
exiftool -all= -overwrite_original image.jpg
# ou
mogrify -strip image.png
```

### 6.4 Subset polices (latin uniquement)

Une police TTF complete (Outfit, Inter) avec tous les glyphes cyrilliques +
arabic + ideographs chinois pese 300-600 Ko. Pour une app togolaise, seul le
Latin Basic + accents francais est necessaire (~80 Ko).

```bash
pyftsubset font.ttf \
  --unicodes='U+0020-007E,U+00A0-00FF,U+2000-206F' \
  --output-file=font-subset.ttf \
  --layout-features='*' \
  --no-hinting
```

| Police | Complete | Subset Latin | Gain |
|--------|----------|--------------|------|
| Outfit Regular | 320 Ko | 80 Ko | -75% |
| Inter Regular | 380 Ko | 95 Ko | -75% |
| MaterialIcons-Regular | 1.7 Mo | 50 Ko (avec tree-shake) | -97% |

> Attention : si l'app affiche du contenu saisi par les utilisateurs (ex:
> tchat multijoueur, questions OCR), des caracteres non-Latin peuvent apparaitre
> et s'afficher en tofu (carre vide). Dans ce cas, elargir le subset :
> `--unicodes='U+0020-00FF,U+2000-206F,U+20A0-20CF'` (Latin + ponctuation +
> symboles monetaires).

### 6.5 Lottie JSON minification

Les animations Lottie exportees par After Effects / LottieFiles contiennent
des espaces, des commentaires et des proprietes redondantes. `jq -c` les
compacte en une seule ligne.

```bash
jq -c . input.json > output.json
```

Gain typique : -20% a -40%.

### 6.6 Detection assets non utilises

Le script `optimize_assets.sh` (layer 5) cross-reference les fichiers dans
`assets/` avec les references en dur dans `lib/` et `pubspec.yaml`. Tout
fichier non reference est un candidat a la suppression.

> Attention : c'est une heuristique. Les chemins construits dynamiquement
> (`'assets/images/logo_${subject}.png'`) ne sont pas detectes. Verifier
> manuellement avant de supprimer.

## 7. Strategie 5 - Lazy loading (Deferred Components)

### Principe

Flutter 2.0+ permet de decouper l'app en **Deferred Components** : modules
telecharges a la demande (Play Store only - pas de support sideload).

Cas d'usage ExamBoost :

- Module **AR / Scanner QR** (assets 3D lourds) - 5 Mo, telecharge au 1er
  usage.
- Module **Video explicatives** (mp4) - 10 Mo, telecharge a la demande.
- Module **Orientations** (illustrations + 15 filieres) - 2 Mo.

### Mise en oeuvre (Play Store uniquement)

```dart
// lib/screens/ar/ar_viewer_screen.dart
import 'package:examboost_togo/screens/ar/ar_viewer_screen.dart'
    deferred as ar;

// ...
await ar.loadLibrary();
ar.ArViewerScreen();
```

```yaml
# pubspec.yaml (a ajouter par l'agent master)
flutter:
  deferred-components:
    - name: ar
      libraries:
        - package:examboost_togo/screens/ar/
      assets:
        - assets/ar/models/
```

### Limite pour le Togo

Deferred Components requiert le **Play Store** comme canal de distribution
(utilise Play Asset Delivery). Or, beaucoup d'eleves togolais installent les
APK directement (sideload) sans Play Store. Pour la beta Togo, cette strategie
est donc **secondaire** - privilégier les strategies 1-5 qui beneficient a
tous les canaux de distribution.

## 8. Workflow complet d'optimisation

### Workflow standard (recommande avant chaque release)

```bash
# 1. Optimiser les assets (dry-run d'abord pour verifier).
./scripts/optimize_assets.sh
./scripts/optimize_assets.sh --apply

# 2. Build APK ultra-optimise (5 couches).
./scripts/build_apk_optimized.sh

# 3. Analyser la composition (rapport Markdown).
./scripts/analyze_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 4. Verifier rapidement la taille < 25 Mo.
./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Workflow one-liner

```bash
./scripts/build_apk_optimized.sh --analyze
```

Cette commande :

1. Optimise les assets (`optimize_assets.sh --apply`).
2. Build les 3 APK avec `--split-per-abi --shrink --tree-shake-icons --obfuscate`.
3. Verifie chaque APK < 25 Mo.
4. Genere le rapport detaille (`scripts/apk_size_report.md`).

### Workflow debug (iteration rapide - pas d'optimisation)

```bash
./scripts/build_apk_debug.sh
# APK debug typique : 40-60 Mo (pas de shrinking, libapp.so en debug)
# OK pour tester sur smartphone en dev, PAS pour distribution.
```

## 9. Verification taille

### Verification rapide (1 APK)

```bash
./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# Limite par defaut : 25 Mo. Personnalisable : ./scripts/check_apk_size.sh <apk> 20
```

Exit code 0 = OK, exit code 1 = depassement.

### Verification complete (3 APK + composition)

```bash
./scripts/analyze_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Produit un rapport Markdown dans `scripts/apk_size_report.md` avec :

- Taille totale
- Repartition par categorie (lib/ assets/ dex/ res/ etc.)
- Top 10 fichiers les plus lourds
- Suggestions contextuelles

### Verification CI (GitHub Actions)

Le workflow `.github/workflows/build_apk.yml` (cree par l'Agent BF) verifie
deja chaque APK release < 25 Mo avec un avertissement `::warning::` (non
bloquant). Pour rendre la verification bloquante en CI, remplacer le
`::warning::` par `exit 1`.

## 10. Troubleshooting

### "APK depasse 25 Mo malgre toutes les optimisations"

1. **Analyser la composition** :
   ```bash
   ./scripts/analyze_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```
2. **Identifier la categorie dominante** :
   - `lib/` > 20 Mo : code Dart volumineux. Verifier
     `dart run dependency_validator` et retirer les packages non utilises.
   - `assets/` > 5 Mo : compresser plus (WebP q=70, subset polices).
   - `classes.dex` > 5 Mo : plugins natifs lourds (video_player, chewie).
3. **Considerer les Deferred Components** (Play Store uniquement).

### "tree-shake-icons casse mon UI"

Si vous referencez des icones dynamiquement (`IconData(0xe123)`), le
tree-shaking les retire. Solution :

```bash
flutter build apk --release --no-tree-shake-icons
```

### "R8 retire une classe necessaire (reflection)"

Ajouter une regle keep dans `android/app/proguard-rules.pro` :

```
-keep class com.example.MyReflectionClass { *; }
```

### "Stack trace prod illisible (obfuscation)"

Decoder avec `flutter symbolize` + le dossier `--split-debug-info` :

```bash
flutter symbolize -i stack_trace.txt -d build/symbols/<timestamp>/
```

### "optimize_assets.sh a detruit mes SVG"

Les originaux sont sauvegardes en `.bak` :

```bash
find assets/ -name "*.svg.bak" -exec sh -c 'mv "$0" "${0%.bak}"' {} \;
```

Ou via Git :

```bash
git checkout -- assets/
```

## 11. Optimisations futures (out of scope)

### Dynamic Feature Modules

Modules Android telecharges a la demande (Play Store). Contrairement aux
Deferred Components Flutter, les DFMs peuvent contenir du code natif Java/Kotlin
et des ressources Android. Utile pour isoler des fonctionnalites optionnelles
(modulo AR, camera OCR, etc.).

### Play Asset Delivery

Mechanisme Play Store pour livrer des assets volumineux (>10 Mo) en dehors de
l'APK. 3 modes :

- install-time : livre avec l'APK mais stocke separement.
- fast-follow : telecharge juste apres l'install.
- on-demand : telecharge a la demande.

### Conditional delivery

Livrer des assets differents selon le pays / langue / device. Pour ExamBoost :
livrer les PDFs annales BEPC vs BAC selon le niveau de l'eleve (recueilli lors
de l'onboarding).

### App Bundle (AAB) au lieu d'APK

Le format AAB (Android App Bundle) laisse a Google Play le soin de generer des
APK optimises par device (density, ABI, language). Taille telechargee
typiquement -30% vs APK split-per-abi. Limite : requiert Play Store (pas de
sideload).

### R8 full mode

Depuis Android Gradle Plugin 8.0, R8 full mode active des optimisations plus
agressives (cross-library inlining, etc.). Gain supplementaire ~5% sur le
code. Configurer dans `gradle.properties` :

```
android.enableR8.fullMode=true
```

## 12. Glossaire

| Terme | Definition |
|-------|------------|
| APK | Android Package - format d'installation d'une app Android. |
| AAB | Android App Bundle - format de publication Play Store (APK genere a la volee). |
| ABI | Application Binary Interface - architecture CPU (arm64-v8a, armeabi-v7a, x86_64). |
| R8 | Outil de shrinking + obfuscation Android (remplace ProGuard). |
| Tree-shaking | Retrait du code / glyphes non utilises a la compilation. |
| ProGuard | Predecesseur de R8, encore utilise pour les regles de configuration. |
| Deferred Component | Module Flutter telecharge a la demande (Play Store only). |
| DFM | Dynamic Feature Module - equivalent Android natif. |
| Subset (police) | Reduction d'une police aux seuls glyphes necessaires. |
| Lottie | Format d'animation vectorielle JSON (Airbnb). |
| Split-debug-info | Table des symboles pour decoder les stack traces obfusquees. |

## 13. References

- Flutter docs - Building APKs : https://docs.flutter.dev/deployment/android
- Flutter docs - Obfuscation : https://docs.flutter.dev/deployment/obfuscate
- Android docs - App size reduction :
  https://developer.android.com/topic/performance/reduce-apk-size
- Android docs - R8 : https://developer.android.com/build/shrink-code
- WebP docs : https://developers.google.com/speed/webp
- svgo : https://github.com/svg/svgo
- fonttools (pyftsubset) : https://github.com/fonttools/fonttools
- Bundletool : https://developer.android.com/tools/bundletool
- Play Asset Delivery :
  https://developer.android.com/guide/playcore/asset-delivery

## 14. Checklist pre-release

Avant chaque release publique, verifier :

- [ ] `./scripts/optimize_assets.sh` (dry-run) ne montre aucun asset inutilise
- [ ] `./scripts/build_apk_optimized.sh` sort 3 APK < 25 Mo chacun
- [ ] `./scripts/analyze_apk_size.sh` ne montre aucun fichier > 10 Mo (hors
      libflutter.so)
- [ ] `--split-debug-info` sauvegarde dans `build/symbols/` et archive
- [ ] Test installation `arm64-v8a` sur un smartphone physique (Tecno Spark 5
      ou equivalent)
- [ ] Test installation `armeabi-v7a` sur un smartphone ancien (Tecno Spark 4
      ou equivalent)
- [ ] L'app demarre < 5s sur le smartphone bas de gamme
- [ ] Memoire RAM < 200 Mo en utilisation normale (adb shell dumpsys meminfo)
- [ ] Pas de crash dans `adb logcat -b crash` apres 5 min d'usage

## 15. Historique

| Date | Action | Auteur |
|------|--------|--------|
| 2026-06-30 | Creation initiale (5 strategies + workflow) | Agent CD (task CD-apk-optimized) |
