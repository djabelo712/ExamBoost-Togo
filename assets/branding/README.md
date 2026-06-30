# Branding ExamBoost Togo

Identité visuelle complète du projet ExamBoost Togo : logo, icônes, palette, typographie et mockups.

> Référence pour toute production graphique (app Flutter, site web, pitch deck, bannière GitHub, supports print).
> Alignée sur `lib/theme/app_theme.dart` (AppColors + AppTextStyles).

---

## Arborescence

```
assets/branding/
├── README.md                        ← ce fichier
├── logo_examboost.svg               ← Logo principal (vert + couleurs, cercle plein)
├── logo_examboost_white.svg         ← Version blanche (pour fonds foncés)
├── logo_examboost_dark.svg          ← Version couleurs pleines (pour fonds clairs, sans cercle)
├── icon_app.svg                     ← Icône app carrée (Material 3 squircle)
├── favicon.svg                      ← Favicon 32x32 (monogramme EB)
├── banner_github.svg                ← Bannière GitHub 1280x400
├── color_palette.md                 ← Palette complète + codes hex + usage
├── typography.md                    ← Typographies Outfit + Inter + hiérarchie
└── mockups/
    ├── home_screen_wireframe.svg    ← Wireframe écran d'accueil (header + 3 cartes)
    └── pitch_slide_template.svg     ← Gabarit de slide de pitch (16:9)
```

---

## Concept graphique

Le logo combine quatre symboles en une seule composition circulaire :

| Symbole          | Élément graphique        | Signification                          |
|------------------|--------------------------|----------------------------------------|
| Apprentissage    | Livre ouvert blanc       | La base, la matière, l'étude           |
| Réussite         | Mortarboard (cap) orange | Le diplôme, la destination             |
| Progression      | Flèche ascendante        | Le "boost", l'amélioration continue    |
| Excellence       | Étoile dorée             | La validation, le score cible          |
| Identité Togo    | Vert #006837 + Orange #D97700 | Couleurs nationales togolaises   |

Le monogramme **EB** (ExamBoost) en bas du logo renforce la mémorisation de marque.

---

## Spécifications techniques

### Formats SVG

Tous les SVG sont valides W3C, testés dans les navigateurs modernes (Chrome, Firefox, Safari). Ils utilisent :
- `viewBox` pour la mise à l'échelle
- `<defs>` pour les dégradés réutilisables
- Polices génériques (`Outfit, Inter, Arial, sans-serif`) — le navigateur fait le fallback si les Google Fonts ne sont pas chargées
- Aucune dépendance externe (pas de `<image href>`, pas de `<script>`)
- Encodage UTF-8 déclaré

### ViewBox par fichier

| Fichier                          | ViewBox       | Ratio     | Usage typique                            |
|----------------------------------|---------------|-----------|------------------------------------------|
| `logo_examboost.svg`             | `0 0 200 200` | 1:1       | Site web, documents, splash screen       |
| `logo_examboost_white.svg`       | `0 0 200 200` | 1:1       | Fonds foncés (footer sombre, T-shirts)   |
| `logo_examboost_dark.svg`        | `0 0 200 200` | 1:1       | Fonds clairs (documents, slides)         |
| `icon_app.svg`                   | `0 0 100 100` | 1:1       | Icône Android/iOS, splash, notifications |
| `favicon.svg`                    | `0 0 32 32`   | 1:1       | Onglet navigateur                        |
| `banner_github.svg`              | `0 0 1280 400`| 3.2:1     | En-tête du repo GitHub                   |
| `mockups/home_screen_wireframe.svg` | `0 0 480 820` | portrait | Wireframe home screen (pitch, doc)    |
| `mockups/pitch_slide_template.svg` | `0 0 1280 720`| 16:9     | Gabarit slide pitch DJANTA              |

---

## Guide d'utilisation

### 1. Logo principal (`logo_examboost.svg`)

Usage général : site web, en-tête de documents, splash screen, signature d'email.

```html
<img src="logo_examboost.svg" alt="ExamBoost Togo" width="120" />
```

**Espace de respiration** : laisser au moins 12% de la largeur du logo autour (padding minimal). Ne pas recadrer le cercle.

**Taille minimale** : 64x64 px pour préserver la lisibilité du "EB" et de l'étoile.

### 2. Version blanche (`logo_examboost_white.svg`)

À utiliser **uniquement sur fonds foncés** (vert `#004A26`, noir, bleu marine). Toutes les formes sont blanches ou orange clair (`#FFB74D`) pour conserver la lisibilité.

Cas d'usage : t-shirts sombres, slides pitch à fond vert, footer de site web sombre.

### 3. Version couleurs pleines (`logo_examboost_dark.svg`)

À utiliser sur **fonds clairs** (blanc, gris clair, beige). Le cercle vert est retiré, les éléments ont un contour vert pour la lisibilité. Le monogramme "EB" est en vert foncé.

Cas d'usage : papier à en-tête, factures, slides pitch à fond blanc.

### 4. Icône app (`icon_app.svg`)

Carrée avec coins arrondis (radius 22%, conforme Material 3). Fond dégradé diagonal vert Togo → vert foncé.

**Optimisée pour la lisibilité à 48x48** (taille notification Android) :
- Le cap reste reconnaissable (forme losange)
- Le livre reste visible (forme en V)
- Les détails fins (lignes de texte) sont volontairement simplifiés

Pour générer les PNG d'app (Android/iOS) :
```bash
# Installer flutter_launcher_icons (hors périmètre branding)
flutter pub add --dev flutter_launcher_icons
# Configurer pubspec.yaml puis :
dart run flutter_launcher_icons
```

> Référence de configuration proposée dans la section "Intégration Flutter" ci-dessous.

### 5. Favicon (`favicon.svg`)

Version la plus simplifiée : monogramme "EB" en orange sur fond vert. Suffisamment lisible à 16x16.

```html
<link rel="icon" type="image/svg+xml" href="/favicon.svg" />
<!-- Fallback PNG pour très vieux navigateurs : /favicon.ico 32x32 -->
```

### 6. Bannière GitHub (`banner_github.svg`)

Format 1280x400 (recommandé GitHub pour le header du repo). À placer dans le README principal du repo GitHub.

```markdown
![ExamBoost Togo](assets/branding/banner_github.svg)
```

### 7. Mockups

- `home_screen_wireframe.svg` : wireframe low-fidelity de l'écran d'accueil. Sert de référence pour le développement de `home_screen.dart` et pour les slides pitch.
- `pitch_slide_template.svg` : gabarit réutilisable pour les 10 slides du pitch DJANTA. Les zones sont annotées en pointillés rouges (titre, contenu, visuel).

---

## Intégration Flutter (propositions — hors périmètre branding)

> L'Agent J ne modifie pas `lib/` ni `pubspec.yaml`. Les propositions ci-dessous sont à réaliser par l'agent de wiring final.

### Déclaration des assets (`pubspec.yaml`)

```yaml
flutter:
  assets:
    - assets/branding/logo_examboost.svg
    - assets/branding/logo_examboost_white.svg
    - assets/branding/logo_examboost_dark.svg
    - assets/branding/icon_app.svg
    - assets/branding/favicon.svg
    - assets/branding/banner_github.svg
    - assets/branding/mockups/
```

### Affichage d'un SVG en Flutter

```yaml
dependencies:
  flutter_svg: ^2.0.10+1
```

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/branding/logo_examboost.svg',
  width: 120,
  semanticsLabel: 'Logo ExamBoost Togo',
)
```

### flutter_launcher_icons (générer les PNG)

```yaml
# pubspec.yaml — section flutter_launcher_icons
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/branding/icon_app.svg"  # convertir en PNG 1024x1024 avant
  # (flutter_launcher_icons ne supporte pas SVG nativement — utiliser rsvg-convert ou Inkscape)
  min_sdk_android: 21
  adaptive_icon_background: "#006837"
  adaptive_icon_foreground: "assets/branding/icon_app_foreground.png"
```

---

## Charte d'usage des couleurs

Voir `color_palette.md` pour la palette complète avec codes hex, RGB, contraste WCAG et combinaisons valides.

Règles essentielles :
1. **Vert Togo `#006837`** est la couleur dominante — l'utiliser pour 60% des surfaces colorées.
2. **Orange `#D97700`** est l'accent — l'utiliser pour 30% (CTA secondaires, badges, icônes de réussite).
3. Les 10% restants : couleurs sémantiques (success/warning/error/info).
4. Toujours vérifier le contraste WCAG AA (cf. `color_palette.md`).

---

## Charte d'usage de la typographie

Voir `typography.md` pour le système complet (Outfit + Inter).

Résumé :
- **Titres** : Outfit (600/700/800)
- **Corps** : Inter (400/500/600/700)
- **Chiffres** : Inter avec `tabular-nums`
- Hiérarchie : H1 (28/700) → H2 (22/600) → H3 (18/600) → body (15/400) → bodySmall (13/400) → label (12/500)

---

## Variantes et déclinaisons futures

Si déclinaisons supplémentaires nécessaires (imprimerie, merchandising, motion design) :

| Variante                | Quand créer                                              |
|-------------------------|----------------------------------------------------------|
| Logo noir & blanc       | Pour fax, photocopie, tampon — uniquement si nécessaire  |
| Logo horizontal         | Si usage dans bandeau étroit (header de document)        |
| Logo sans slogan        | Pour petites tailles (< 64px)                            |
| Animation logo (Lottie) | Pour splash screen animé (cf. Agent K — splash)          |
| Version animée SVG      | Pour intégration web (hero section du site)              |

Toutes ces déclinaisons doivent respecter la palette et la typographie officielles.

---

## Origine et licence

- Création : **Agent J** — Session 2 (30 juin 2026) — Task `12-logo`
- Auteur conceptuel : SmartFarm Togo / AIMS Ghana
- Polices : Outfit & Inter — Google Fonts (SIL Open Font License 1.1)
- Logo et assets : Propriétaire — Tous droits réservés ExamBoost Togo

---

## Checklist de livraison

- [x] Logo principal SVG (livre + cap + flèche + étoile + EB)
- [x] Version blanche (fond foncé)
- [x] Version couleurs pleines (fond clair)
- [x] Icône app carrée Material 3 (100x100, lisible à 48x48)
- [x] Favicon 32x32 (EB monogramme)
- [x] Bannière GitHub 1280x400 (logo + slogan + tags + mention DJANTA)
- [x] Palette complète (`color_palette.md`)
- [x] Typographie (`typography.md`)
- [x] Wireframe home screen SVG
- [x] Gabarit slide pitch SVG
- [x] README d'utilisation (ce fichier)

---

*Dernière mise à jour : 30 juin 2026 — Agent J (Task 12-logo).*
