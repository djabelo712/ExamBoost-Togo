# Typographie — ExamBoost Togo

> Système typographique officiel pour l'app Flutter, le site web et tous les supports de communication.
> Polices Google Fonts gratuites, open source (SIL Open Font License 1.1).

---

## 1. Familles de polices

### Outfit — Titres & display
- **Fournisseur** : [Google Fonts — Outfit](https://fonts.google.com/specimen/Outfit)
- **Classification** : Sans-serif géométrique moderne
- **Caractère** : Amical, confiant, optimiste — idéal pour une app éducative grand public
- **Poids disponibles** : 100 (Thin), 200 (ExtraLight), 300 (Light), 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold), 800 (ExtraBold), 900 (Black)
- **Poids utilisés chez ExamBoost** : 600 (SemiBold), 700 (Bold), 800 (ExtraBold pour le logo)
- **Usage** : H1, H2, H3, logo "EB", titres de slides pitch, bannières

### Inter — Corps de texte & chiffres
- **Fournisseur** : [Google Fonts — Inter](https://fonts.google.com/specimen/Inter)
- **Classification** : Sans-serif néo-grotesque optimisé pour écran
- **Caractère** : Très lisible à toutes les tailles, excellent rendu numérique
- **Poids disponibles** : 100, 200, 300, 400, 500, 600, 700, 800, 900 (+ italiques)
- **Poids utilisés** : 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)
- **Usage** : body, bodySmall, label, button, questionText, chiffres stats

### Fallbacks (si Google Fonts indisponibles)
```
Titres : Outfit, Inter, "Segoe UI", Roboto, system-ui, sans-serif
Corps  : Inter, "Segoe UI", Roboto, system-ui, sans-serif
Code   : "JetBrains Mono", "Fira Code", Consolas, monospace
```

> **Note Flutter** : la version actuelle d'`app_theme.dart` utilise `Roboto` par défaut. Migration vers Outfit/Inter recommandée — déclarer les polices dans `pubspec.yaml` puis mettre à jour `AppTextStyles.fontFamily` (hors périmètre de cette tâche branding).

---

## 2. Hiérarchie typographique

| Style          | Police  | Taille | Poids | Line-height | Letter-spacing | Usage                                              |
|----------------|---------|--------|-------|-------------|----------------|---------------------------------------------------|
| `displayLarge` | Outfit  | 32 px  | 700   | 1.25        | -0.5 px        | Splash screen, onboarding étapes importantes       |
| `h1`           | Outfit  | 28 px  | 700   | 1.3         | -0.3 px        | Titres d'écran principaux (H1)                     |
| `h2`           | Outfit  | 22 px  | 600   | 1.35        | -0.2 px        | Sous-titres de section, titres de cartes larges    |
| `h3`           | Outfit  | 18 px  | 600   | 1.4         | 0             | Titres AppBar, titres de cartes                    |
| `body`         | Inter   | 15 px  | 400   | 1.5         | 0             | Texte courant, descriptions, paragraphes           |
| `bodySmall`    | Inter   | 13 px  | 400   | 1.5         | 0             | Captions, métadonnées, timestamps                  |
| `label`        | Inter   | 12 px  | 500   | 1.4         | +0.5 px       | Étiquettes, tags, badges, labels de formulaire     |
| `button`       | Inter   | 15 px  | 600   | 1.2         | +0.3 px       | Texte de bouton (ElevatedButton, OutlinedButton)   |
| `questionText` | Inter   | 17 px  | 500   | 1.6         | 0             | Énoncé de question (flashcard, simulation)         |
| `stat`         | Inter   | 24 px  | 700   | 1.2         | -0.5 px       | Chiffres stats Dashboard (tabular nums)            |
| `caption`      | Inter   | 11 px  | 400   | 1.4         | +0.3 px       | Mentions légales, version, helper text             |

---

## 3. Règles d'usage par contexte

### AppBar
- Titre : `h3` (Outfit 18/600) — couleur `textPrimary`
- Pas de mise en majuscules automatique (Title case naturel)

### Cartes d'action (Home)
- Titre de carte : `h3` (Outfit 18/600) — `textPrimary`
- Sous-titre : `bodySmall` (Inter 13/400) — `textSecondary`
- Badge / label : `label` (Inter 12/500) — `primary` ou `accent`

### Flashcard (révision)
- Question : `questionText` (Inter 17/500) — `textPrimary`
- Réponse / explication : `body` (Inter 15/400) — `textPrimary`
- Métadonnées (matière, difficulté) : `label` (Inter 12/500) — `textSecondary`

### Dashboard (stats)
- Chiffre principal : `stat` (Inter 24/700, `font-feature-settings: "tnum"`) — `primary`
- Label sous le chiffre : `label` (Inter 12/500) — `textSecondary`
- Légende graphique : `caption` (Inter 11/400)

### Boutons
- Texte : `button` (Inter 15/600) — blanc sur `primary`, ou `primary` sur fond transparent
- PAS de mise en majuscules (éviter l'effet "too corporate")

### Pitch deck (slides)
- Titre de slide : `h1` (Outfit 28/700) — `textPrimary` ou blanc si fond vert
- Sous-titre : `h3` (Outfit 18/600)
- Corps de slide : `body` (Inter 15/400)
- Notes / sources : `caption` (Inter 11/400) — italique

---

## 4. Numéros et chiffres (tabular nums)

Pour tous les chiffres (scores, pourcentages, compteurs, statistiques), activer les **chiffres tabulaires** :

```css
font-feature-settings: "tnum" 1;
font-variant-numeric: tabular-nums;
```

```dart
// Flutter — TextStyle
TextStyle(
  fontFamily: 'Inter',
  fontFeatures: const [FontFeature.tabularFigures()],
  // ...
)
```

Cela empêche les chiffres de "danser" quand ils sont mis à jour (animations de compteur, timers d'examen, scores temps réel).

---

## 5. Accessibilité

- Taille minimale de texte courant : **13 px** (bodySmall).
- Taille minimale de label : **12 px** (label).
- Ne pas descendre en dessous de **11 px** (caption) — réservé aux mentions légales.
- Supporter le **text scaling** Android jusqu'à 1.5x sans casser la mise en page (tester avec `MediaQuery.textScaleFactor`).
- Contraste : respecter WCAG AA (cf. `color_palette.md` section 1 & 2).
- Éviter l'italique pour les longs paragraphes (lisibilité réduite).

---

## 6. Intégration Flutter (référence future)

### Déclaration `pubspec.yaml`
```yaml
flutter:
  fonts:
    - family: Outfit
      fonts:
        - asset: assets/fonts/Outfit-Regular.ttf
        - asset: assets/fonts/Outfit-Medium.ttf
          weight: 500
        - asset: assets/fonts/Outfit-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Outfit-Bold.ttf
          weight: 700
        - asset: assets/fonts/Outfit-ExtraBold.ttf
          weight: 800
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### Mise à jour `AppTextStyles` (proposition)
```dart
class AppTextStyles {
  static const String fontFamilyHeading = 'Outfit';
  static const String fontFamilyBody = 'Inter';

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamilyHeading,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );
  // ... etc.
}
```

> Hors périmètre de la tâche branding — à réaliser par l'agent wiring (Session 2 finale).

---

## 7. Intégration web (landing page, GitHub pages)

### HTML
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@600;700;800&display=swap" rel="stylesheet">
```

### CSS
```css
:root {
  --font-heading: 'Outfit', 'Inter', system-ui, sans-serif;
  --font-body: 'Inter', system-ui, sans-serif;
}

body {
  font-family: var(--font-body);
  font-size: 15px;
  line-height: 1.5;
}

h1, h2, h3 {
  font-family: var(--font-heading);
  font-weight: 700;
}
```

---

## 8. Spécificités linguistiques

- **Français (langue principale)** : utiliser les guillemets français " " et l'apostrophe typographique ’ (U+2019).
- **Ewe / Kabyè (futur i18n)** : Inter supporte les diacritiques nécessaires. Pour les langues nationales togolaises à extensions Unicode, prévoir Noto Sans comme fallback.
- **Anglais (slogan / pitch international)** : Outfit + Inter rendent parfaitement l'anglais.
- **Chiffres** : utiliser les chiffres arabes occidentaux (0-9) — standards au Togo.

---

## 9. Récapitulatif rapide

```
Titres   : Outfit  600 / 700 / 800
Corps    : Inter   400 / 500 / 600 / 700
Chiffres : Inter   tabular-nums

H1       28 / 700   →  titres écran
H2       22 / 600   →  sous-titres section
H3       18 / 600   →  titres cartes / AppBar
Body     15 / 400   →  texte courant
BodySm   13 / 400   →  captions
Label    12 / 500   →  tags / badges
Button   15 / 600   →  boutons
Question 17 / 500   →  énoncés
Stat     24 / 700   →  chiffres stats
Caption  11 / 400   →  mentions légales
```

---

*Dernière mise à jour : 30 juin 2026 — Agent J (Task 12-logo).*
