# Illustrations ExamBoost Togo

> Bibliothèque d'illustrations SVG pour l'app Flutter ExamBoost Togo.
> Style : flat design moderne, palette **vert Togo + orange + blanc**, personnages stylisés togolais.

---

## 1. Liste des illustrations (8 SVG)

| Fichier                      | Format      | Usage                                                                        | Étape / Écran                                             |
|------------------------------|-------------|------------------------------------------------------------------------------|-----------------------------------------------------------|
| `onboarding_welcome.svg`     | 400 x 300   | Onboarding étape 1 : bienvenue (élève + smartphone + bulles apprentissage)   | `OnboardingScreen` — page 0 `_welcomeStep`                |
| `onboarding_identity.svg`    | 400 x 300   | Onboarding étape 2 : identité (formulaire prénom/nom/établissement)          | `OnboardingScreen` — page 1 `_identityStep`               |
| `onboarding_level.svg`       | 400 x 300   | Onboarding étape 3 : niveau scolaire (4 cartes 3e/2nde/1ère/Terminale)       | `OnboardingScreen` — page 2 `_niveauStep`                 |
| `onboarding_serie.svg`       | 400 x 300   | Onboarding étape 4 : série au BAC (5 cartes A/B/C/D/F)                       | `OnboardingScreen` — page 3 `_serieStep`                  |
| `onboarding_subjects.svg`    | 400 x 300   | Onboarding étape 5 : matières préférées (6 icônes en cercle autour du logo)  | `OnboardingScreen` — page 4 `_matieresStep`               |
| `splash_illustration.svg`    | 400 x 600   | Splash screen : logo central + tagline + particules                          | `SplashScreen` (au lancement de l'app)                    |
| `empty_state_reading.svg`    | 200 x 200   | Empty state "Continue à réviser" (élève assis lisant un livre)               | Écrans vides : révision, favoris, dashboard               |
| `empty_state_no_data.svg`    | 200 x 200   | Empty state "Aucune donnée" (graphique vide + loupe "?")                     | Écrans stats / historique / résultats vides               |

---

## 2. Utilisation dans Flutter (`flutter_svg`)

### 2.1 Dépendance

Ajouter dans `pubspec.yaml` (section `dependencies`) :

```yaml
dependencies:
  flutter_svg: ^2.0.10+1
```

Puis déclarer les assets (section `flutter.assets`) :

```yaml
flutter:
  assets:
    - assets/illustrations/
```

Lancer :

```bash
flutter pub get
```

### 2.2 Widget réutilisable

Exemple d'intégration d'une illustration dans une page :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingIllustration extends StatelessWidget {
  final String assetName; // ex: 'onboarding_welcome'
  const OnboardingIllustration({super.key, required this.assetName});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/illustrations/$assetName.svg',
      fit: BoxFit.contain,
      semanticsLabel: 'Illustration $assetName',
      placeholderBuilder: (context, _) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
```

### 2.3 Cas d'usage typique — page d'onboarding

```dart
SizedBox(
  height: 220,
  width: double.infinity,
  child: OnboardingIllustration(
    assetName: _illustrationForStep(_currentStep),
  ),
);

// Mapping étape → fichier SVG
String _illustrationForStep(int step) {
  switch (step) {
    case 0: return 'onboarding_welcome';
    case 1: return 'onboarding_identity';
    case 2: return 'onboarding_level';
    case 3: return 'onboarding_serie';
    case 4: return 'onboarding_subjects';
    default: return 'onboarding_welcome';
  }
}
```

### 2.4 Cas d'usage — empty state

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SvgPicture.asset(
      'assets/illustrations/empty_state_reading.svg',
      height: 160,
    ),
    const SizedBox(height: 16),
    const Text('Continue à réviser !',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    const Text('Aucune carte à réviser pour le moment.',
      style: TextStyle(color: Colors.grey)),
  ],
)
```

---

## 3. Style guide

### 3.1 Palette de couleurs

| Rôle                | Hex       | Usage                                                          |
|---------------------|-----------|----------------------------------------------------------------|
| Vert Togo (primary) | `#006837` | Fond principal, personnages, accents forts                     |
| Vert clair          | `#4CAF7A` | Dégradés, fonds secondaires, icônes secondaires                |
| Vert foncé          | `#004A26` | Dégradés vers le bas, ombres, profondeur                       |
| Vert surface        | `#E8F5ED` | Fonds décoratifs clairs, arrière-plans sobres                  |
| Orange (accent)     | `#D97700` | Mortarboard, étoiles, CTA secondaires, curseur                 |
| Orange clair        | `#FFB74D` | Dégradés, particules, reflets, étoiles                        |
| Orange surface      | `#FFF3E0` | Bulles, surfaces claires teintées                              |
| Blanc               | `#FFFFFF` | Cartes, livres, surfaces, texte sur fond vert                  |
| Gris texte          | `#757575` | Légendes, sous-texte                                           |
| Gris divisé         | `#E0E0E0` | Bordures, séparateurs                                          |
| Noir texte          | `#1A1A1A` | Texte principal, yeux, cheveux                                 |

### 3.2 Typographies

Police **Outfit** (texte UI), avec fallback `Inter, Arial, sans-serif`. Pour les formules mathématiques dans `onboarding_serie.svg` (série C), utiliser **Times New Roman** (effet manuel "formule à la craie").

### 3.3 Personnages stylisés élèves togolais

- **Silhouette simple** : corps en tunique claire (blanc ou vert), avec **col en V** blanc.
- **Bande décorative** horizontale orange sur le torse (rappel dashiki stylisé).
- **Tête** : visage ton beige-brun (`#A0703D` ou `#8D5524`), cheveux noirs courts.
- **Yeux** : petits ronds noirs ou arcs de concentration.
- **Sourire** : arc simple, jamais de dents détaillées.
- **Bras** : traits épais (stroke-linecap round) de la même couleur que le corps.
- **Pas d'emojis**, expressions sobres, posture dynamique (pointage, lecture, accueil).

### 3.4 Composition

- **5 illustrations onboarding** : format paysage 400x300, marges 5-10% pour respiration, personnage ancré en bas, bulles/icônes flottantes en haut.
- **Splash** : format portrait 400x600, logo centré à 60% de l'espace, tagline sous le logo, particules sur tout le pourtour.
- **Empty states** : format carré 200x200, fond radial doux, sujet central, particules discrètes.

### 3.5 Régles d'accessibilité

- Tous les SVG incluent un `role="img"` et un `aria-label` descriptif.
- Dans Flutter, passer `semanticsLabel` à `SvgPicture.asset` pour les lecteurs d'écran (TalkBack/VoiceOver).
- Contraste respecté : texte blanc sur fond vert `#006837` = ratio 6.3:1 (AA).

---

## 4. Comment créer une nouvelle illustration

### 4.1 Bonnes pratiques

1. **Toujours déclarer la viewBox** : `viewBox="0 0 W H"` (sans `width`/`height` fixe si l'illustration doit être responsive, ou avec `width`/`height` pour la taille par défaut).
2. **Inclure un commentaire XML** en tête du fichier :
   ```xml
   <!-- ExamBoost Togo — <nom court>
        <description une ligne>. Palette : <résumé>. ViewBox 0 0 W H -->
   ```
3. **Utiliser des `<defs>`** pour les dégradés et symboles réutilisables (`<linearGradient>`, `<symbol>`).
4. **Groupes sémantiques** : nommer les `<g>` par bloc logique (`<!-- Bulles -->`, `<!-- Personnage -->`, etc.).
5. **Privilégier les `<path>` et `<polygon>`** aux `<rect>` pour les formes organiques (visages, bras).
6. **Pas d'animations SMIL** dans les illustrations d'onboarding (Flutter `flutter_svg` ne les supporte pas). Préférer des animations Flutter (AnimatedBuilder / Lottie) par-dessus.
7. **Taille des fichiers < 12 Ko** : éviter les illustrations surdétaillées (le but reste la lisibilité à 200x200 px minimum).
8. **Tester le rendu** avec `flutter_svg` avant livraison (certains effets SVG comme `filter`, `clipPath` complexes ne sont pas supportés).

### 4.2 Template de base

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- ExamBoost Togo — <nom court>
     <description>. Palette : vert Togo #006837 + orange #D97700 + blanc.
     ViewBox 0 0 400 300 -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300" width="400" height="300"
     role="img" aria-label="<message accessibilité>">
  <defs>
    <linearGradient id="bgX" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#006837"/>
      <stop offset="100%" stop-color="#4CAF7A"/>
    </linearGradient>
  </defs>
  <rect x="0" y="0" width="400" height="300" fill="url(#bgX)"/>
  <!-- ... contenu ... -->
</svg>
```

### 4.3 Validation XML

Toujours valider le XML bien formé avant livraison :

```bash
# Python : valider tous les SVG du dossier
python3 -c "import xml.dom.minidom, glob; [xml.dom.minidom.parse(f) for f in glob.glob('assets/illustrations/*.svg')]; print('OK')"
```

---

## 5. Références et inspirations

- **undraw.co** : bibliothèque d'illustrations libres de droits, personnalisables (choisir la couleur `#006837` comme accent). Idéal pour des illustrations additionnelles (onboarding futur, messages de succès, tutoriels).
- **Heroicons / Tabler Icons** : icônes SVG simples pour enrichir les compositions.
- **Material Symbols** : icônes officielles Material 3 (déjà utilisées dans le reste de l'app Flutter).
- **Bootstrap Icons** : pour les symboles mathématiques et scientifiques (atome, globe, fleur).
- Palette et charte : voir `assets/branding/color_palette.md` (référence unique).

---

## 6. Maintenance

- **Ajout d'une nouvelle illustration** : créer le fichier SVG → l'ajouter au tableau ci-dessus → le déclarer dans `pubspec.yaml` (déjà couvert par le dossier `assets/illustrations/` entier).
- **Modification d'une illustration existante** : conserver le `viewBox` et le `aria-label` inchangés pour préserver la compatibilité Flutter.
- **Nouvelle langue** (i18n) : les SVG contiennent peu de texte, mais les mots comme "MATHS", "FRANÇAIS", "Chargement..." devront être localisés — préférer des SVG sans texte et ajouter les labels en Flutter via `Text` localisable.

---

*Dernière mise à jour : Session 3, Vague 3b — Agent BA (Task BA-illustrations-icons).*
