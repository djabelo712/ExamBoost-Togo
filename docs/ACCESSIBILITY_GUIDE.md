# Guide Accessibilité — ExamBoost Togo

> Conformité WCAG 2.1 AAA pour l'application ExamBoost Togo (Flutter 3.44+,
> Material 3). Cible : élèves togolais avec besoins spécifiques (dyslexie,
> déficience visuelle, handicap moteur, navigation clavier desktop/web).

Ce guide documente les 6 axes d'accessibilité avancée mis en place par
l'**Agent CB** (Task ID `CB-accessibility-advanced`, Vague 3, Session 4).
Pour chaque axe : principe, code à intégrer, tests à effectuer.

---

## Sommaire

1. [Navigation clavier](#1-navigation-clavier)
2. [Screen reader (TalkBack / VoiceOver)](#2-screen-reader-talkback--voiceover)
3. [Contraste](#3-contraste)
4. [Animations réductibles](#4-animations-réductibles)
5. [Taille de texte](#5-taille-de-texte)
6. [Switch control (dalle tactile)](#6-switch-control-dalle-tactile)
7. [Checklist d'intégration](#checklist-intégration)
8. [Tests avec TalkBack](#test-avec-talkback)
9. [Tests avec VoiceOver](#test-avec-voiceover)
10. [Audit automatisé (golden tests)](#audit-automatisé-golden-tests)
11. [Références WCAG](#références-wcag)

---

## Conformité WCAG 2.1 AAA

WCAG (Web Content Accessibility Guidelines) 2.1 définit 3 niveaux de
conformité :

- **A** : niveau minimum (ex : tout est accessible clavier).
- **AA** : niveau standard (ex : contraste 4.5:1).
- **AAA** : niveau maximum (ex : contraste 7:1, animations réductibles).

ExamBoost Togo vise le niveau **AAA** car la cible (élèves avec handicap)
bénéficie directement des exigences les plus strictes. Les 6 axes ci-dessous
couvrent les critères AAA pertinents pour une app mobile :

| Critère WCAG | Niveau | Axe couvert |
|---|---|---|
| 1.3.1 Info and Relationships | A | Screen reader |
| 1.4.4 Resize text (200%) | AA | Taille texte |
| 1.4.5 Images of text | AA | (n/a — pas d'images de texte) |
| 1.4.6 Contrast (Enhanced) | **AAA** | Contraste |
| 1.4.10 Reflow (320px) | AA | Layout adaptatif |
| 1.4.13 Content on Hover or Focus | AA | Focus ring |
| 2.1.1 Keyboard | A | Navigation clavier |
| 2.1.2 No Keyboard Trap | A | Escape close |
| 2.3.3 Animation from Interactions | **AAA** | Animations réductibles |
| 2.4.1 Bypass Blocks | A | Raccourcis numériques |
| 2.4.3 Focus Order | A | Focus order logique |
| 2.4.7 Focus Visible | AA | Focus ring |
| 4.1.2 Name, Role, Value | A | Labels sémantiques |
| 4.1.3 Status Messages | AA | Live region / announce |

---

## 1. Navigation clavier

### Principe

Sur desktop (Windows, macOS, Linux) et web, l'utilisateur peut naviguer
au clavier sans souris. Sur mobile, les switch controls (dalle tactile,
commande vocale) simulent un clavier.

Flutter fournit les widgets `Shortcuts` + `Actions` pour déclarer des
raccourcis clavier mappés à des intentions.

### Raccourcis implémentés

Le fichier `lib/utils/keyboard_shortcuts.dart` définit les raccourcis
suivants :

| Touche | Intent | Action |
|---|---|---|
| `1` (ou Numpad 1) | `NumericShortcutIntent(0)` | Aller à l'Accueil |
| `2` (ou Numpad 2) | `NumericShortcutIntent(1)` | Aller à la Révision |
| `3` (ou Numpad 3) | `NumericShortcutIntent(2)` | Démarrer une Simulation |
| `4` (ou Numpad 4) | `NumericShortcutIntent(3)` | Aller au Tableau de bord |
| `5` (ou Numpad 5) | `NumericShortcutIntent(4)` | Ouvrir la Recherche |
| `6` (ou Numpad 6) | `NumericShortcutIntent(5)` | Ouvrir les Favoris |
| `7` (ou Numpad 7) | `NumericShortcutIntent(6)` | Ouvrir les Statistiques |
| `8` (ou Numpad 8) | `NumericShortcutIntent(7)` | Ouvrir le Profil |
| `9` (ou Numpad 9) | `NumericShortcutIntent(8)` | Ouvrir les Paramètres |
| `Escape` | `CloseIntent` | Fermer la dialog/sheet/menu courant |
| `Enter` / `Space` | `ActivateIntent` | Activer l'élément focusé |
| `Flèche bas` | `NextItemIntent` | Élément suivant dans une liste |
| `Flèche haut` | `PreviousItemIntent` | Élément précédent dans une liste |
| `Flèche droite` | `NextQuestionIntent` | Question suivante |
| `Flèche gauche` | `PreviousQuestionIntent` | Question précédente |

### Intégration

Wrapper `MaterialApp` (ou `MaterialApp.router`) avec `AppKeyboardShortcuts`
via le paramètre `builder` :

```dart
// lib/main.dart (à modifier par l'Agent BA lors du wiring final)
MaterialApp(
  builder: (context, child) => AppKeyboardShortcuts(
    onNumericShortcut: (index) {
      const routes = [
        '/home', '/revision', '/simulation', '/dashboard',
        '/search', '/favorites', '/stats', '/profile', '/settings',
      ];
      if (index >= 0 && index < routes.length) {
        Navigator.of(context).pushNamed(routes[index]);
      }
    },
    onClose: () => Navigator.of(context).maybePop(),
    child: child!,
  ),
  home: const HomeScreen(),
);
```

Pour les raccourcis locaux à un écran (ex : `Ctrl+S` pour sauvegarder un
brouillon), utiliser `LocalKeyboardShortcuts` :

```dart
class SaveIntent extends Intent { const SaveIntent(); }

LocalKeyboardShortcuts(
  shortcuts: {
    const SingleActivator(LogicalKeyboardKey.keyS, control: true):
        const SaveIntent(),
  },
  actions: {
    SaveIntent: CallbackAction<SaveIntent>(
      onInvoke: (_) => _saveDraft(),
    ),
  },
  child: ExamEditor(),
);
```

### Éviter les pièges clavier (No Keyboard Trap, SC 2.1.2)

Tout `Dialog`, `BottomSheet` ou `Drawer` doit pouvoir être fermé au
clavier. Wrapper leur contenu avec `EscapeCloseHandler` :

```dart
showDialog(
  context: context,
  builder: (_) => EscapeCloseHandler(
    onClose: () => Navigator.of(context).pop(),
    child: MyDialog(),
  ),
);
```

### Vérification

- [ ] Lancer `flutter run -d windows` (ou macOS / Linux / chrome).
- [ ] Appuyer sur `Tab` : le focus doit se déplacer entre éléments focusables
      dans un ordre logique (gauche-droite, haut-bas).
- [ ] Appuyer sur `1` : doit aller à l'Accueil.
- [ ] Appuyer sur `2` : doit aller à la Révision.
- [ ] Ouvrir un Dialog avec `Enter` sur un bouton, puis fermer avec `Escape`.
- [ ] Vérifier qu'aucun écran ne "piège" le focus (Tab tourne en boucle
      sans sortie).

---

## 2. Screen reader (TalkBack / VoiceOver)

### Principe

Les lecteurs d'écran annoncent les éléments à l'utilisateur via synthèse
vocale. Pour qu'un élément soit annoncé correctement, il doit porter un
**label sémantique** (nom accessible) + un **rôle** (bouton, lien, titre)
+ optionnellement un **hint** (comment interagir).

Flutter expose la sémantique via le widget `Semantics` et la classe
`SemanticsService`.

### Labels centralisés

Le fichier `lib/widgets/semantic_labels.dart` contient tous les labels FR
dans la classe `SemanticLabels`. **Ne pas écrire de labels en dur dans
les écrans** : toujours référencer `SemanticLabels.xxx`.

Exemples :

```dart
// Mauvais (label non centralisé, pas de hint)
IconButton(icon: const Icon(Icons.favorite), onPressed: _toggleFav)

// Bon (label centralisé + tooltip accessible)
IconButton(
  icon: const Icon(Icons.favorite),
  onPressed: _toggleFav,
  tooltip: SemanticLabels.addToFavorites,
)
```

### Widgets helpers

| Widget | Usage |
|---|---|
| `LabeledSemantics` | Applique un label complet (label + hint + role) à un élément custom |
| `LiveRegion` | Annonce automatiquement les changements de contenu (scores, progression) |
| `SemanticGroup` | Groupe plusieurs enfants en un seul élément annoncé |
| `SemanticHeader` | Marque un titre (rôle "header") pour la navigation par titres |

Exemple — bouton SRS "Facile" :

```dart
LabeledSemantics(
  label: SemanticLabels.facileButton,
  button: true,
  child: GestureDetector(
    onTap: () => onQualitySelected(5),
    child: const Card(child: Text('Facile')),
  ),
)
// TalkBack annonce : "Bouton Facile. Appuyez pour indiquer que la
//                    question était facile."
```

Exemple — live region pour le score :

```dart
LiveRegion(
  child: Text(SemanticLabels.scoreLabel(score, total)),
)
// Quand le score change, TalkBack annonce automatiquement :
// "Score : 14 sur 20, 70 pour cent."
```

### Annonces ponctuelles

Pour annoncer un changement d'état **sans** live region (ex : badge
débloqué, temps écoulé), utiliser `ScreenReaderUtils` :

```dart
import 'package:examboost_togo/utils/screen_reader_utils.dart';

// Score
ScreenReaderUtils.announceScore(14, 20);
// "Score mis à jour : 14 sur 20, 70 pour cent."

// Badge débloqué
ScreenReaderUtils.announceBadgeUnlocked('Maître des mathématiques');

// Alerte temps critique (assertive, interrompt la lecture)
ScreenReaderUtils.announceTimeAlert(const Duration(minutes: 1), critical: true);
// "ALERTE. Plus que 1 minutes."
```

### Icônes décoratives vs informatives

- **Décorative** (ne pas annoncer) : icône à côté d'un texte qui porte
  déjà le sens. Utiliser `Icon(...).asDecorative()`.
- **Informative** (à annoncer) : icône seule (pas de texte à côté).
  Utiliser `Icon(...).withLabel('Réponse correcte')` ou
  `IconButton(tooltip: SemanticLabels.xxx)`.

```dart
// Décorative : l'icône est à côté du texte "Accueil"
Row(children: [
  const Icon(Icons.home).asDecorative(),
  const Text('Accueil'),
])

// Informative : l'icône est seule
IconButton(
  icon: const Icon(Icons.favorite),
  tooltip: SemanticLabels.addToFavorites,
  onPressed: _toggleFav,
)
```

### Vérification

Voir section [Test avec TalkBack](#test-avec-talkback) ci-dessous.

---

## 3. Contraste

### Principe

WCAG 2.1 SC 1.4.6 (Contrast Enhanced, Level AAA) impose :

- **Texte normal** (< 18pt ou < 14pt bold) : ratio **≥ 7.0:1**
- **Grand texte** (≥ 18pt ou ≥ 14pt bold) : ratio **≥ 4.5:1**

Le ratio est calculé avec la formule W3C : `(L1 + 0.05) / (L2 + 0.05)` où
L1 et L2 sont les luminances relatives des deux couleurs (de 0 à 1).

### Calcul du ratio

Le service `AccessibilityAdvancedService` expose la formule W3C :

```dart
import 'package:examboost_togo/services/accessibility_advanced_service.dart';

final ratio = AccessibilityAdvancedService.contrastRatio(
  AppColors.textPrimary, // #1A1A1A
  AppColors.surface,     // #FFFFFF
);
// ratio ≈ 16.10:1 (>= AAA OK)

final ok = AccessibilityAdvancedService.meetsAaaContrast(
  AppColors.textSecondary, // #757575
  AppColors.surface,       // #FFFFFF
  largeText: false,
);
// ok = false (4.5:1, AAA echoue mais AA OK)
```

### Audit complet

Méthode `auditContrast` renvoie un `ContrastAuditResult` avec tous les
verdicts :

```dart
final result = AccessibilityAdvancedService.auditContrast(
  Colors.white, AppColors.warning,
);
print(result.humanReadable);  // "4.17:1 - ECHEC"
print(result.passesAaaNormal); // false
print(result.passesAaNormal);  // false
```

### Audit de la palette ExamBoost

La méthode `auditExamBoostPalette()` audite les 10 couples principaux de
`lib/theme/app_theme.dart`. Lancer en CI :

```dart
test('Palette ExamBoost respecte AAA texte normal', () {
  final failures = AccessibilityAdvancedService.auditExamBoostPalette();
  expect(failures, isEmpty,
    reason: 'Couples non AAA : ${failures.map((r) => r.humanReadable)}');
});
```

**Couples à vérifier manuellement** (orange warning #F57C00 sur blanc
pourrait échouer AAA) :

| Couple | Ratio | AAA normal | Action |
|---|---|---|---|
| textPrimary (#1A1A1A) sur surface (#FFFFFF) | 16.10:1 | OK | — |
| textPrimary sur background (#F8F9FA) | 14.93:1 | OK | — |
| textSecondary (#757575) sur surface | 4.52:1 | **Échoue AAA** (OK AA) | Assombrir à #6E6E6E pour AAA (5.05:1) |
| white sur primary (#006837) | 5.91:1 | **Échoue AAA** (OK AA) | OK pour grand texte |
| white sur accent (#D97700) | 3.78:1 | **Échoue AAA et AA** | Assombrir à #B85F00 (5.13:1 AA OK) |
| white sur warning (#F57C00) | 2.92:1 | **Échoue AAA et AA** | À corriger (assombrir warning) |

### Mode contraste élevé

Le service expose une palette "contraste élevé" prête à l'emploi :

```dart
// Dans un widget
final bg = AccessibilityAdvancedService.resolveBackgroundColor(context);
final fg = AccessibilityAdvancedService.resolveTextColor(context);

Container(
  color: bg,
  child: Text('Mon texte', style: TextStyle(color: fg)),
)
```

Couleurs :

- `kHighContrastBackground` = jaune vif `#FFEB3B`
- `kHighContrastText` = noir pur `#000000`
- Ratio noir sur jaune = **19.0:1** (AAA OK, largement)
- Alternative : noir/blanc pur (21.0:1, maximum WCAG)

Le mode est activé par l'utilisateur via `AccessibilityService.settings.highContrast`
(option "Contraste élevé" dans la dialog d'accessibilité existante).

### Vérification

- [ ] Lancer `flutter test test/unit/accessibility_contrast_test.dart`
      (test à écrire par l'Agent tests — code fourni ci-dessus).
- [ ] Activer "Contraste élevé" dans la dialog accessibilité : tout le
      texte doit passer en noir sur jaune.
- [ ] Vérifier que `auditExamBoostPalette()` renvoie une liste vide
      (après corrections éventuelles).

---

## 4. Animations réductibles

### Principe

WCAG 2.1 SC 2.3.3 (Animation from Interactions, Level AAA) : les
animations déclenchées par interaction doivent pouvoir être désactivées.

Flutter expose `MediaQuery.disableAnimations` qui reflète :

- **iOS** : Réglages > Accessibilité > Mouvement > Réduire les animations
- **Android** : Réglages > Accessibilité > Supprimer les animations
- **macOS** : Préférences Système > Accessibilité > Moniteur > Réduire le mouvement
- **Windows** : Paramètres > Accessibilité > Effets visuels > Effets d'animation
- **Web** : `prefers-reduced-motion: reduce` (CSS media query)

### Wrapper générique

```dart
ReducedMotionWidget(
  child: myContent,
  builder: (context, child, reduce) {
    if (reduce) return child!;
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  },
)
```

### Widgets de commodité

| Widget | Comportement réduit | Comportement normal |
|---|---|---|
| `ReducedMotionFadeIn` | Affiche directement l'enfant à opacité finale | Fade-in animé (300 ms par défaut) |
| `ReducedMotionAnimatedSwitcher` | Remplace l'enfant sans transition | FadeTransition entre enfants |

```dart
// Splash -> Home
ReducedMotionFadeIn(
  duration: const Duration(milliseconds: 400),
  delay: const Duration(milliseconds: 100),
  child: const HomeScreen(),
)
```

### Helpers statiques (sans wrapper)

Pour les `StatefulWidget` qui possèdent leur propre `AnimationController` :

```dart
class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // sera ajusté dans didChangeDependencies
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ajuste la durée selon la préférence système (Duration.zero si réduit)
    _controller.duration = ReducedMotionWidget.duration(
      context,
      const Duration(milliseconds: 300),
    );
    if (ReducedMotionControllerShortcut.skipIfReduced(context, _controller)) {
      return; // animations désactivées, controller à 1.0
    }
    _controller.forward();
  }
}
```

Pour conditionner rapidement une durée ou une courbe :

```dart
final d = ReducedMotionWidget.duration(context, const Duration(milliseconds: 250));
final c = ReducedMotionWidget.curve(context, Curves.easeOut);
```

### Animations à wrapper (audit)

Liste des widgets d'animation dans ExamBoost qui devraient être wrappés :

| Fichier | Animation | Action |
|---|---|---|
| `lib/widgets/animations/fade_in_list.dart` | Fade-in liste | Wrapper dans `ReducedMotionFadeIn` |
| `lib/widgets/animations/streak_flame.dart` | Flamme animée | Skip si `disableAnimations` |
| `lib/widgets/animations/confetti_animation.dart` | Confettis | Skip si `disableAnimations` |
| `lib/widgets/animations/count_up_text.dart` | Comptage animé | Skip : afficher valeur finale |
| `lib/widgets/animations/typewriter_text.dart` | Effet machine à écrire | Skip : afficher texte complet |
| `lib/widgets/animations/shimmer_loading.dart` | Shimmer | Remplacer par `SkeletonStatic` |
| `lib/widgets/animations/bounce_button.dart` | Bounce au tap | Skip scale animation |
| `lib/widgets/animations/progress_ring.dart` | Anneau progressif | OK (animation informative) |
| `lib/screens/level/widgets/xp_gain_animation.dart` | XP qui vole | Skip |
| `lib/screens/level/widgets/level_up_dialog.dart` | Dialog level up | Wrapper transitions |

### Vérification

- [ ] Activer "Supprimer les animations" sur Android (API 31+).
- [ ] Naviguer dans l'app : aucune animation décorative ne doit se jouer.
- [ ] Les animations informatives (progress bars, compteurs de score)
      peuvent rester si elles apportent de l'information.
- [ ] Vérifier que les transitions de page sont instantanées (pas de slide).

---

## 5. Taille de texte

### Principe

WCAG 2.1 SC 1.4.4 (Resize text, Level AA) impose que le texte puisse être
agrandi jusqu'à 200% sans perte de fonctionnalité. ExamBoost va au-delà
(300% via l'option "très grand texte") pour viser AAA.

Flutter expose `MediaQuery.textScaler` qui reflète la préférence système :

- **Android** : "Taille de police" (0.85x à 2.0x)
- **iOS** : "Texte plus grand" (avec accessibilité : jusqu'à ~3.0x)
- **Web** : zoom du navigateur

### Facteur d'échelle effectif

Le service `AccessibilityAdvancedService` combine les deux facteurs
(système × préférence app) :

```dart
final scale = AccessibilityAdvancedService.textScaleFactorOf(context);
// Ex : système 1.3x × app 1.5x = 1.95x

final fontSize = AccessibilityAdvancedService.scaledFontSize(
  context, 16.0,
); // = 16.0 × 1.95 = 31.2 px
```

L'option "Taille du texte" dans la dialog accessibilité existante permet
à l'utilisateur de régler `AccessibilitySettings.textSizeScale` de 0.85
(S) à 2.0 (XXL). Le service avance la possibilité d'aller à 3.0x en
combinant système (1.5x) × app (2.0x).

### Adaptation des layouts

Quand le facteur d'échelle devient très grand (≥ 2.0), les layouts en
`Row` peuvent déborder. Utiliser les helpers :

```dart
final isVeryLarge = AccessibilityAdvancedService.isVeryLargeText(context);
final isExtraLarge = AccessibilityAdvancedService.isExtraLargeText(context);

Widget build(BuildContext context) {
  if (isExtraLarge) {
    // Layout vertical scrollable
    return ListView(children: [...]);
  }
  if (isVeryLarge) {
    // Layout vertical non-scrollable
    return Column(children: [...]);
  }
  // Layout horizontal par défaut
  return Row(children: [...]);
}
```

### Règles de layout anti-overflow

1. **Jamais de `Text` sans `Flexible` ou `Expanded` dans une `Row`** :
   ```dart
   // MAUVAIS (overflow si texte long)
   Row(children: [Text(longText), Icon(Icons.chevron_right)])

   // BON
   Row(children: [
     Expanded(child: Text(longText, maxLines: 2, overflow: TextOverflow.ellipsis)),
     const Icon(Icons.chevron_right),
   ])
   ```

2. **Préférer `Wrap` à `Row` pour les chips/badges** :
   ```dart
   Wrap(spacing: 8, children: [Chip(...), Chip(...), Chip(...)])
   ```

3. **`SingleChildScrollView` autour des `Column` denses** :
   ```dart
   SingleChildScrollView(
     child: Column(children: [...]),
   )
   ```

4. **Tester avec `textScaler: TextScaler.linear(2.0)` dans les tests** :
   ```dart
   testWidgets('HomeScreen ne déborde pas à 2x', (tester) async {
     await tester.pumpWidget(MaterialApp(
       home: MediaQuery(
         data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
         child: const HomeScreen(),
       ),
     ));
     expect(tester.takeException(), isNull);
   });
   ```

### Vérification

- [ ] Régler la taille de police système à 2.0x et naviguer dans l'app.
- [ ] Aucun texte ne doit être tronqué (à part les ellipsis volontaires).
- [ ] Aucun `RenderFlex overflowed` dans les logs.
- [ ] Les `BottomNavigationBar` restent utilisables (icônes + labels).
- [ ] Les dialogues d'accessibilité scrollent verticalement si besoin.

---

## 6. Switch control (dalle tactile)

### Principe

Le switch control (Android : "Commande par commutation", iOS :
"Switch Control") permet à un utilisateur avec handicap moteur de
naviguer en scanuant les éléments focusables un par un et en activant
via un switch externe (dalle tactile, souffle, etc.).

Flutter gère le switch control via le système de focus natif
(`FocusNode`, `FocusScope`). Les éléments `Semantics` interactifs sont
automatiquement exposés au switch control.

### Bonnes pratiques

1. **Ordre de focus logique** : déclarer les éléments dans l'ordre de
   lecture (gauche-droite, haut-bas). Ne pas utiliser `FocusNode.skipTraversal = true`
   sauf pour les éléments décoratifs.

2. **Groupes sémantiques** : grouper les éléments liés en un seul
   élément annoncé pour éviter de scanner 5 éléments pour une carte
   complexe. Utiliser `SemanticGroup` :

   ```dart
   SemanticGroup(
     label: SemanticLabels.questionWithProgress(5, 20),
     child: Column(children: [
       Text('Question 5 sur 20'),
       Text('Théorème de Pythagore'),
       Text('Score : 14/20'),
     ]),
   )
   // TalkBack annonce en une fois :
   // "Question 5 sur 20, progression 25 pour cent."
   ```

3. **Taille des cibles tactiles** : WCAG 2.5.5 (Level AAA) recommande
   ≥ 44 × 44 px. Tous les boutons interactifs doivent avoir au minimum
   cette taille. Vérifier via `Material` + `InkWell` avec `padding`
   suffisant.

   ```dart
   // MAUVAIS (cible 24x24)
   GestureDetector(onTap: ..., child: Icon(Icons.close, size: 24))

   // BON (cible 48x48)
   InkWell(
     onTap: ...,
     child: Container(
       width: 48, height: 48,
       alignment: Alignment.center,
       child: const Icon(Icons.close, size: 24),
     ),
   )
   ```

4. **Pas de piège de focus** : tout élément qui peut recevoir le focus
   doit pouvoir le perdre (Escape, Tab vers l'extérieur). Voir
   [EscapeCloseHandler](#éviter-les-pièges-clavier-no-keyboard-trap-sc-212).

5. **Rôles sémantiques corrects** : déclarer `button: true` pour les
   éléments cliquables custom, `header: true` pour les titres, etc.
   Utiliser `LabeledSemantics` :

   ```dart
   LabeledSemantics(
     label: SemanticLabels.facileButton,
     button: true,
     child: GestureDetector(onTap: ..., child: Card(...)),
   )
   ```

### Vérification

- [ ] Activer "Commande par commutation" sur Android (Paramètres >
      Accessibilité > Commande par commutation).
- [ ] Scanner les éléments : tous les éléments interactifs doivent
      apparaître un par un.
- [ ] Vérifier que les groupes sémantiques fonctionnent (une carte =
      un scan, pas 5).
- [ ] Activer "Switch Control" sur iOS (Réglages > Accessibilité >
      Switch Control) et tester de même.

---

## Checklist intégration

À compléter par l'Agent BA lors du wiring final dans `main.dart`,
`app_router.dart` et `home_screen.dart`.

- [ ] **Semantics sur tous les boutons** : remplacer tous les `IconButton`
      sans `tooltip` par `IconButton(tooltip: SemanticLabels.xxx, ...)`.
      Lister avec : `grep -rn "IconButton(" lib/ | grep -v tooltip`.
- [ ] **Shortcuts/Actions sur MaterialApp** : wrapper `MaterialApp.builder`
      avec `AppKeyboardShortcuts` (voir [section 1](#1-navigation-clavier)).
- [ ] **EscapeCloseHandler** sur tous les `Dialog` / `BottomSheet` /
      `Drawer` (voir [section 1](#éviter-les-pièges-clavier-no-keyboard-trap-sc-212)).
- [ ] **FocusRing** autour des boutons custom et des cartes interactives
      (`SrsButton`, carte de question, item de liste).
- [ ] **ReducedMotionWidget** autour des animations décoratives (voir
      [table section 4](#animations-à-wrapper-audit)).
- [ ] **LiveRegion** sur les zones de score et de progression.
- [ ] **SemanticGroup** sur les cartes complexes (carte de question,
      tuile de dashboard).
- [ ] **Tests golden** avec `textScaler: TextScaler.linear(2.0)` pour
      vérifier qu'aucun écran ne déborde (voir
      [section 5](#taille-de-texte)).
- [ ] **Audit contraste** via `AccessibilityAdvancedService.auditExamBoostPalette()`
      dans un test unitaire.
- [ ] **Vérifier cibles tactiles ≥ 48 × 48 px** sur tous les boutons.
- [ ] **Vérifier l'ordre de focus** (Tab) sur tous les écrans principaux.
- [ ] **Tester avec TalkBack** (voir ci-dessous).
- [ ] **Tester avec VoiceOver** (voir ci-dessous).

---

## Test avec TalkBack

TalkBack est le lecteur d'écran Android.

### Activation

1. **Android** : Paramètres > Accessibilité > TalkBack > Activer.
2. Raccourci : maintenir volume haut + volume bas pendant 3 secondes
   (si activé dans Paramètres > Accessibilité > Raccourci volume).

### Navigation

- **Balayage droit** : élément suivant (équivalent Tab).
- **Balayage gauche** : élément précédent (équivalent Shift+Tab).
- **Double-tap** n'importe où : activer l'élément focusé (équivalent Enter).
- **Balayage haut puis bas** : changer de mode de navigation (titres,
  liens, boutons, mots, caractères).
- **Balayage bas puis droit** : lecture continue depuis l'élément actuel.

### Vérifications

Pour chaque écran de l'app :

1. **Tous les éléments sont annoncés** : balayer droit pour parcourir
   l'écran entier. Aucun élément ne doit être silencieux (sauf éléments
   décoratifs marqués `asDecorative()`).

2. **Labels explicites** : chaque élément doit être annoncé avec un nom
   clair (pas "Bouton" seul, mais "Bouton Facile. Appuyez pour...").

3. **Rôles corrects** : un bouton doit être annoncé "Bouton", un lien
   "Lien", une case à cocher "Case à cocher". Vérifier que
   `LabeledSemantics(button: true)` est utilisé sur les éléments custom.

4. **Ordre logique** : les éléments doivent être annoncés dans l'ordre
   de lecture (haut-bas, gauche-droite). Si l'ordre est incohérent,
   revoir la structure du widget tree.

5. **Changements d'état annoncés** : quand on répond à une question,
   TalkBack doit annoncer "Bonne réponse" ou "Mauvaise réponse" (via
   `ScreenReaderUtils.announceAnswerFeedback`).

6. **Live regions** : le score et la progression doivent être ré-annoncés
   automatiquement à chaque mise à jour (via `LiveRegion`).

7. **Pas de piège** : on peut sortir de n'importe quel écran avec le
   bouton Retour physique ou gestuel.

### Captures de test

Pour documenter les tests TalkBack, enregistrer l'écran avec
`adb shell screenrecord /sdcard/test_talkback.mp4` puis
`adb pull /sdcard/test_talkback.mp4`.

---

## Test avec VoiceOver

VoiceOver est le lecteur d'écran iOS.

### Activation

1. **iOS** : Réglages > Accessibilité > VoiceOver > Activer.
2. Raccourci : triple-clic sur le bouton latéral (iPhone X+) ou bouton
   Home (iPhone avec Home).

### Navigation

- **Balayage droit** : élément suivant.
- **Balayage gauche** : élément précédent.
- **Double-tap** n'importe où : activer l'élément focusé.
- **Tour de deux doigts** : changer de mode de navigation (mots,
  caractères, titres).
- **Balayage à deux doigts vers le bas** : lecture continue.

### Vérifications

Les mêmes que TalkBack (voir ci-dessus), avec les particularités VoiceOver :

- VoiceOver annonce le **type d'élément** en premier ("Bouton", puis
  le label).
- VoiceOver lit les `tooltip` des `IconButton` automatiquement.
- VoiceOver respecte `accessibilityLiveRegion` (politely par défaut).
- VoiceOver supporte `accessibilityHeaders` pour la navigation par titres.

---

## Audit automatisé (golden tests)

### Test de contraste (unitaire)

Créer `test/unit/accessibility_contrast_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/services/accessibility_advanced_service.dart';

void main() {
  group('Contraste palette ExamBoost', () {
    test('textPrimary sur surface respecte AAA texte normal', () {
      final result = AccessibilityAdvancedService.auditContrast(
        const Color(0xFF1A1A1A), // textPrimary
        Colors.white,            // surface
      );
      expect(result.passesAaaNormal, isTrue,
        reason: 'Ratio ${result.ratio} insuffisant (AAA >= 7.0)');
    });

    test('white sur primary respecte AAA grand texte', () {
      final result = AccessibilityAdvancedService.auditContrast(
        Colors.white,
        const Color(0xFF006837), // primary
      );
      expect(result.passesAaaLarge, isTrue,
        reason: 'Ratio ${result.ratio} insuffisant (AAA large >= 4.5)');
    });

    test('Audit complet palette - 0 échec', () {
      final failures =
          AccessibilityAdvancedService.auditExamBoostPalette();
      expect(failures, isEmpty,
        reason: 'Couples non AAA : '
                '${failures.map((r) => r.humanReadable).join(', ')}');
    });
  });
}
```

### Test de non-overflow à 2x texte (widget)

Créer `test/widget/accessibility_text_scale_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';

void main() {
  group('HomeScreen accessibilité texte', () {
    testWidgets('Ne déborde pas à textScale 2.0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: const HomeScreen(),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ne déborde pas à textScale 3.0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
          child: const HomeScreen(),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
```

### Test des labels sémantiques (golden)

Créer `test/widget/accessibility_semantics_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/widgets/semantic_labels.dart';

void main() {
  group('SemanticLabels', () {
    test('Aucun label vide', () {
      const labels = [
        SemanticLabels.home, SemanticLabels.revision,
        SemanticLabels.facileButton, SemanticLabels.correctButton,
        // ... tous les labels
      ];
      for (final label in labels) {
        expect(label.isNotEmpty, isTrue, reason: 'Label vide trouvé');
      }
    });

    test('Aucun emoji dans les labels', () {
      final emojiRegex = RegExp(
        r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]',
        unicode: true,
      );
      const labels = [
        SemanticLabels.home, SemanticLabels.revision,
        SemanticLabels.facileButton,
      ];
      for (final label in labels) {
        expect(emojiRegex.hasMatch(label), isFalse,
          reason: 'Emoji dans : $label');
      }
    });
  });
}
```

---

## Références WCAG

- **WCAG 2.1 (traduction FR)** : https://www.w3.org/Translations/WCAG21-fr/
- **Understanding WCAG 2.1** : https://www.w3.org/WAI/WCAG21/Understanding/
- **Flutter accessibility** : https://docs.flutter.dev/ui/accessibility
- **Flutter Semantics API** : https://api.flutter.dev/flutter/widgets/Semantics-class.html
- **Android TalkBack** : https://developer.android.com/guide/topics/ui/accessibility/principles
- **iOS VoiceOver** : https://developer.apple.com/design/human-interface-guidelines/accessibility/overview
- **W3C relative luminance** : https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
- **Contrast checker (en ligne)** : https://webaim.org/resources/contrastchecker/

---

## Annexes

### A. Liste des fichiers créés (Agent CB)

| Fichier | Rôle | Lignes |
|---|---|---|
| `lib/services/accessibility_advanced_service.dart` | Contraste WCAG, animations, texte, palette | ~290 |
| `lib/widgets/focus_ring_widget.dart` | Anneau de focus clavier (FocusRing, FocusableButton, FocusableListItem) | ~230 |
| `lib/widgets/semantic_labels.dart` | Catalogue labels FR + LabeledSemantics, LiveRegion, SemanticGroup, SemanticHeader | ~330 |
| `lib/widgets/reduced_motion_widget.dart` | ReducedMotionWidget, ReducedMotionFadeIn, ReducedMotionAnimatedSwitcher | ~250 |
| `lib/utils/keyboard_shortcuts.dart` | Intents + AppKeyboardShortcuts + LocalKeyboardShortcuts + EscapeCloseHandler | ~330 |
| `lib/utils/screen_reader_utils.dart` | ScreenReaderUtils + extensions AccessibleIconButton / AccessibleIcon | ~270 |
| `docs/ACCESSIBILITY_GUIDE.md` | Ce guide | ~560 |

### B. Mapping WCAG → code

| Critère WCAG | Fichier(s) implémentant |
|---|---|
| 1.3.1 Info and Relationships | `semantic_labels.dart` (SemanticGroup, SemanticHeader) |
| 1.4.4 Resize text | `accessibility_advanced_service.dart` (textScaleFactorOf, scaledFontSize) |
| 1.4.6 Contrast (Enhanced) | `accessibility_advanced_service.dart` (contrastRatio, meetsAaaContrast, auditPalette) |
| 2.1.1 Keyboard | `keyboard_shortcuts.dart` (AppKeyboardShortcuts, LocalKeyboardShortcuts) |
| 2.1.2 No Keyboard Trap | `keyboard_shortcuts.dart` (EscapeCloseHandler) |
| 2.3.3 Animation from Interactions | `reduced_motion_widget.dart` (ReducedMotionWidget, ReducedMotionFadeIn) |
| 2.4.1 Bypass Blocks | `keyboard_shortcuts.dart` (NumericShortcutIntent, raccourcis 1-9) |
| 2.4.3 Focus Order | `focus_ring_widget.dart` (FocusRing respecte l'ordre naturel) |
| 2.4.7 Focus Visible | `focus_ring_widget.dart` (FocusRing, kFocusRingWidth=3.0) |
| 4.1.2 Name, Role, Value | `semantic_labels.dart` (LabeledSemantics, SemanticLabels) |
| 4.1.3 Status Messages | `screen_reader_utils.dart` (announce, announcePolite, announceAssertive) + `semantic_labels.dart` (LiveRegion) |
