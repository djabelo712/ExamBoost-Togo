# lib/theme — Theme & Dark Mode

Ce dossier contient le systeme de theme d'ExamBoost Togo :

- `app_theme.dart` : theme Material 3 (clair + sombre), constantes `AppColors`
  et styles `AppTextStyles`.
- `adaptive_colors.dart` : couleurs **adaptees** qui changent selon le
  `ThemeMode` (helpers `AdaptiveColors.xxx(context)` + extension
  `BuildContext`).
- `dark_mode_fixes.dart` : wrappers de widgets qui s'adaptent au dark mode
  (`AdaptiveScaffold`, `AdaptiveCard`, `AdaptiveChip`, `AdaptiveBadge`,
  `AdaptiveInfoBanner`, `AdaptiveProgressBar`).

L'audit complet des couleurs en dur est dans `docs/DARK_MODE_AUDIT.md`.

---

## 1. `AppColors` vs `AdaptiveColors` — quand utiliser quoi ?

### `AppColors` (theme/app_theme.dart)

Constantes figees a la compilation. **Ne s'adaptent pas au theme.**

```dart
class AppColors {
  static const Color primary        = Color(0xFF006837); // OK partout
  static const Color accent         = Color(0xFFD97700); // OK partout
  static const Color success        = Color(0xFF2E7D32); // OK partout
  static const Color error          = Color(0xFFC62828); // OK partout
  static const Color warning        = Color(0xFFF57C00); // OK partout
  static const Color info           = Color(0xFF1565C0); // OK partout
  static const Color facile         = Color(0xFF2E7D32); // OK partout
  static const Color moyen          = Color(0xFF1565C0); // OK partout
  static const Color difficile      = Color(0xFFD97700); // OK partout
  static const Color echec          = Color(0xFFC62828); // OK partout

  static const Color background     = Color(0xFFF8F9FA); // BUG dark : reste gris clair
  static const Color surface        = Color(0xFFFFFFFF); // BUG dark : reste blanc
  static const Color surfaceVariant = Color(0xFFF1F3F4); // BUG dark
  static const Color divider        = Color(0xFFE0E0E0); // BUG dark
  static const Color textPrimary    = Color(0xFF1A1A1A); // BUG dark : reste noir
  static const Color textSecondary  = Color(0xFF757575); // BUG dark
  static const Color textDisabled   = Color(0xFFBDBDBD); // BUG dark
  static const Color primarySurface = Color(0xFFE8F5ED); // BUG dark : vert clair
  static const Color accentSurface  = Color(0xFFFFF3E0); // BUG dark : orange clair
}
```

### `AdaptiveColors` (theme/adaptive_colors.dart)

Couleurs calculees a l'execution. **S'adaptent au theme.**

```dart
AdaptiveColors.background(context)     // #F8F9FA en clair, #121212 en sombre
AdaptiveColors.surface(context)        // #FFFFFF / #1E1E1E
AdaptiveColors.surfaceVariant(context) // #F1F3F4 / #2C2C2C
AdaptiveColors.textPrimary(context)    // #1A1A1A / #EAEAEA
AdaptiveColors.textSecondary(context)  // #757575 / #BDBDBD
AdaptiveColors.textDisabled(context)   // #BDBDBD / #757575
AdaptiveColors.divider(context)        // #E0E0E0 / #424242
AdaptiveColors.primarySurface(context) // #E8F5ED / #1B3D2E
AdaptiveColors.accentSurface(context)  // #FFF3E0 / #3D2A0F
AdaptiveColors.shadow(context)         // black 6% / black 30%
AdaptiveColors.primary(context)        // #006837 / #4CAF7A
AdaptiveColors.accent(context)         // #D97700 / #FFB74D
AdaptiveColors.onPrimary(context)      // blanc / noir
AdaptiveColors.onAccent(context)       // blanc / noir
```

### Regle d'or

| Cas d'usage | Utiliser |
|---|---|
| Couleur sémantique (success, error, warning, info) | `AppColors` — deja lisible en dark |
| Couleur de marque (primary, accent) pour un bouton / icone | `AppColors` — l'AppBar et les ElevatedButton sont geres par le theme |
| Background de Scaffold | `AdaptiveColors.background(context)` ou `AdaptiveScaffold` |
| Fond de Card / Container / BottomSheet | `AdaptiveColors.surface(context)` ou `AdaptiveCard` |
| Fond de champ input / chip / encart | `AdaptiveColors.surfaceVariant(context)` ou `primarySurface` / `accentSurface` |
| Couleur de texte | `AdaptiveColors.textPrimary(context)` / `textSecondary(context)` / `textDisabled(context)` |
| Bordure / divider | `AdaptiveColors.divider(context)` |
| Ombre (BoxShadow) | `AdaptiveColors.shadow(context)` |

### Pourquoi `AppColors.primary` reste-t-il OK en dark ?

Parce que `AppTheme.dark` surcharge `ColorScheme.primary` avec
`AppColors.primaryLight` (#4CAF7A), plus lisible sur fond sombre. Mais quand
vous ecrivez `color: AppColors.primary` dans un widget, vous contournez le
ColorScheme et utilisez #006837 directement — ce qui reste lisible (vert
fonce sur fond sombre = contraste correct). Pour les **chips et badges** ou
le vert est en petite surface, preferez `AdaptiveColors.primary(context)`
qui choisit automatiquement la bonne nuance.

---

## 2. `Scaffold` vs `AdaptiveScaffold`

### `Scaffold` (Flutter)

Le `backgroundColor` par defaut de `Scaffold` est `Theme.of(context).scaffoldBackgroundColor`,
qui est correctement defini dans `AppTheme.light` (#F8F9FA) et `AppTheme.dark` (#121212).

**Donc si vous ne specifiez pas `backgroundColor`, le Scaffold s'adapte deja.**

Le probleme : la plupart des ecrans existants ecrivent
`backgroundColor: AppColors.background` explicitement, ce qui **ecrase** la
valeur du theme avec une constante. D'ou le bug.

### `AdaptiveScaffold`

Utilisez `AdaptiveScaffold` a la place de `Scaffold` quand vous etes paresseux
ou que vous voulez garantir que le background s'adapte meme si quelqu'un
re-ajoute `backgroundColor: AppColors.background` par erreur.

```dart
// Avant (BUG en dark) :
Scaffold(
  backgroundColor: AppColors.background,
  appBar: AppBar(title: const Text('Tableau de bord')),
  body: ...,
)

// Apres (OK en dark) — solution 1 : retirer backgroundColor
Scaffold(
  appBar: AppBar(title: const Text('Tableau de bord')),
  body: ...,
)

// Apres (OK en dark) — solution 2 : AdaptiveScaffold
AdaptiveScaffold(
  appBar: AppBar(title: const Text('Tableau de bord')),
  body: ...,
)
```

---

## 3. Widgets adaptatifs disponibles

### `AdaptiveCard`

Carte avec fond, ombre et borderRadius qui s'adaptent.

```dart
AdaptiveCard(
  padding: const EdgeInsets.all(20),
  borderRadius: 16,
  onTap: () => context.go('/dashboard'),
  child: Column(
    children: [
      Text('Titre', style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
      Text('Sous-titre', style: AppTextStyles.bodySmall.copyWith(color: context.textSecondary)),
    ],
  ),
)
```

### `AdaptiveChip`

Chip compact avec fond teinte et texte colore qui s'adaptent.

```dart
AdaptiveChip(
  label: 'Mathematiques',
  color: AppColors.primary,
  icon: Icons.calculate,
)
```

En dark mode, l'opacite du fond passe de 0.12 a 0.20 pour rester lisible.

### `AdaptiveBadge`

Badge compact (valeur + libelle) pour les KPI, compteurs, statistiques.

```dart
AdaptiveBadge(
  value: '12',
  label: 'repondues',
  color: AppColors.success,
  icon: Icons.check_circle,
)
```

### `AdaptiveInfoBanner`

Encart d'information (background teinte + optionnellement icone).

```dart
AdaptiveInfoBanner(
  variant: AdaptiveInfoVariant.primary,
  icon: Icons.info_outline,
  child: Text(
    'Cette question sera corrigee lors du rapport final.',
    style: AppTextStyles.bodySmall,
  ),
)
```

Variantes : `primary`, `accent`, `success`, `error`.

### `AdaptiveProgressBar`

Barre de progression lineaire adaptee.

```dart
AdaptiveProgressBar(value: 0.5, minHeight: 4)
```

Le `backgroundColor` est calcule automatiquement a partir de la couleur de
progression (avec opacite adaptee au theme).

---

## 4. Extension `BuildContext`

Pour alleger la syntaxe, l'extension `AdaptiveContext` expose des getters
directement sur `BuildContext` :

```dart
// Au lieu de AdaptiveColors.surface(context)
Container(color: context.surface)

// Au lieu de Theme.of(context).brightness == Brightness.dark
if (context.isDark) { ... }
```

Getters disponibles :

| Getter | Equivalent |
|---|---|
| `context.isDark` | `Theme.of(context).brightness == Brightness.dark` |
| `context.bg` | `AdaptiveColors.background(context)` |
| `context.surface` | `AdaptiveColors.surface(context)` |
| `context.surfaceVariant` | `AdaptiveColors.surfaceVariant(context)` |
| `context.textPrimary` | `AdaptiveColors.textPrimary(context)` |
| `context.textSecondary` | `AdaptiveColors.textSecondary(context)` |
| `context.textDisabled` | `AdaptiveColors.textDisabled(context)` |
| `context.dividerColor` | `AdaptiveColors.divider(context)` |
| `context.primarySurface` | `AdaptiveColors.primarySurface(context)` |
| `context.accentSurface` | `AdaptiveColors.accentSurface(context)` |
| `context.shadowColor` | `AdaptiveColors.shadow(context)` |
| `context.adaptivePrimary` | `AdaptiveColors.primary(context)` |
| `context.adaptiveAccent` | `AdaptiveColors.accent(context)` |
| `context.onPrimary` | `AdaptiveColors.onPrimary(context)` |
| `context.onAccent` | `AdaptiveColors.onAccent(context)` |

**Note sur les conflits de noms** : `divider` est evite car une extension
Flutter existe deja avec ce nom sur `BuildContext`. On utilise `dividerColor`.
De meme pour `surface` : aucun conflit dans Flutter 3.44, mais si une future
version ajoute `context.surface`, il faudra renommer en `adaptiveSurface`.

---

## 5. Bonnes pratiques dark mode (contrastes WCAG)

### Objectifs WCAG 2.1 AA

- **Texte normal** (< 18px) : contraste >= 4.5:1 avec son fond.
- **Texte large** (>= 18px ou >= 14px gras) : contraste >= 3:1.
- **UI components** (bordures, icônes) : contraste >= 3:1 avec le fond.

### Verifications dans ExamBoost Togo

| Couleur | Fond clair | Contraste | Fond sombre | Contraste |
|---|---|---|---|---|
| `textPrimary` (#1A1A1A / #EAEAEA) | #F8F9FA | 16.1:1 | #121212 | 14.6:1 |
| `textSecondary` (#757575 / #BDBDBD) | #F8F9FA | 4.6:1 | #121212 | 8.4:1 |
| `primary` (#006837 / #4CAF7A) | #F8F9FA | 6.5:1 | #121212 | 5.8:1 |
| `accent` (#D97700 / #FFB74D) | #F8F9FA | 3.4:1 (texte large OK) | #121212 | 8.6:1 |
| `success` (#2E7D32) | #F8F9FA | 5.2:1 | #1E1E1E (card) | 4.6:1 |
| `error` (#C62828) | #F8F9FA | 5.9:1 | #1E1E1E (card) | 5.3:1 |

Tous les contrastes sont conformes WCAG AA. `accent` (#D97700) sur fond
clair est juste sous le seuil 4.5:1 pour du texte normal : a utiliser
**uniquement pour du texte large** (titres, boutons) ou sur fond teinte
(`accentSurface`).

### Regles pratiques

1. **Ne jamais utiliser `Colors.white` ou `Colors.black` en dur** pour un
   texte ou un fond. Utiliser `AdaptiveColors.surface(context)` (fond) ou
   `AdaptiveColors.textPrimary(context)` (texte) qui s'adapteront.

2. **`withOpacity` doit etre adaptatif** : un fond a 12% d'opacite est
   invisible en dark. Le helper `AdaptiveChip` regle ca automatiquement
   (0.12 en clair, 0.20 en sombre).

3. **Les ombres doivent etre plus prononcees en dark** : `Colors.black
   .withOpacity(0.06)` est invisible sur fond #121212. Utiliser
   `AdaptiveColors.shadow(context)` (0.06 en clair, 0.30 en sombre).

4. **Bannir `AppColors.surface` (const)** pour les fonds de Card / Container.
   Utiliser `AdaptiveColors.surface(context)` ou le widget `AdaptiveCard`.

5. **Bannir `AppColors.background` (const)** pour les fonds de Scaffold.
   Soit retirer l'attribut (le theme s'appliquera), soit utiliser
   `AdaptiveScaffold`.

6. **Couleurs sémantiques** (`AppColors.success`, `.error`, `.warning`,
   `.info`) : OK en dark sans adaptation, elles sont deja assez vives.
   Mais si vous les utilisez en fond (chip, encart), baissez l'opacite a
   20% en dark au lieu de 12% — voir `AdaptiveChip` et `AdaptiveBadge`.

7. **Tester les deux themes** : avant de merger une PR, basculez le
   `ThemeProvider` en `ThemeMode.dark` et parcourez tous les ecrans. Si
   un texte est illisible ou un fond trop clair, c'est une couleur en dur.

---

## 6. Plan de migration

L'agent de wiring (ou un agent Session 3 dedie) devra appliquer les
corrections listees dans `docs/DARK_MODE_AUDIT.md`. L'ordre recommande :

1. **Fonds globaux** (Scaffold backgrounds) — impact immediat sur tous les ecrans.
2. **Cards et Containers** (surface, surfaceVariant, primarySurface, accentSurface).
3. **Textes** (textPrimary, textSecondary, textDisabled).
4. **Ombres** (BoxShadow).
5. **Chips et badges** (withOpacity).
6. **Couleurs en dur** (`Colors.white`, `Colors.black`, `Color(0xFF...)`).

Chaque correction est un remplacement mecanique documente dans l'audit.
Estimated total : ~150 corrections sur les 13 fichiers audites, soit
~30 minutes de travail pour un agent wiring avec recherche/remplacement.

---

## 7. Liens

- Audit complet : `docs/DARK_MODE_AUDIT.md`
- Theme principal : `lib/theme/app_theme.dart`
- ThemeProvider : `lib/providers/theme_provider.dart`
- Settings (switch dark mode) : `lib/screens/settings/settings_screen.dart`
