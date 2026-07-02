# Audit Dark Mode — ExamBoost Togo

Cet document liste, **pour chaque ecran et widget existant**, les couleurs
codées en dur qui empechent le dark mode de s'afficher correctement, ainsi
que la correction precise a appliquer (recherche/remplacement).

## Contexte

L'Agent V (Vague 1) a ajoute le theme sombre (`AppTheme.dark`) dans
`lib/theme/app_theme.dart` et le `ThemeProvider` dans
`lib/providers/theme_provider.dart`. Le `MaterialApp.router` (dans `main.dart`)
branche correctement `theme`, `darkTheme` et `themeMode`.

**Le probleme** : de nombreux widgets utilisent `AppColors.surface`,
`AppColors.background`, `Colors.white`, `Color(0xFF...)` qui sont des
constantes figees. Elles restent blanches / claires meme en theme sombre,
rendant l'UI illisible (texte blanc sur fond blanc, fond blanc alors que le
scaffold est gris foncé, etc.).

## Solution

Deux helpers ont ete crees dans `lib/theme/` :

- **`adaptive_colors.dart`** : classe `AdaptiveColors` avec methodes
  statiques `background(context)`, `surface(context)`, etc. + extension
  `BuildContext` (`context.surface`, `context.isDark`, ...).
- **`dark_mode_fixes.dart`** : widgets `AdaptiveScaffold`, `AdaptiveCard`,
  `AdaptiveChip`, `AdaptiveBadge`, `AdaptiveInfoBanner`, `AdaptiveProgressBar`.

L'agent de wiring appliquera les corrections ci-dessous. Chaque entree
indique :

- **Ligne** (approximative — verifier avant de remplacer)
- **Actuel** : le code problematique
- **Probleme** : pourquoi ca casse en dark
- **Correction** : le code de remplacement

## Conventions de remplacement

| Pattern problematique | Remplacement |
|---|---|
| `AppColors.background` (Scaffold) | `AdaptiveColors.background(context)` (ou retirer l'attribut, le theme s'applique) |
| `AppColors.surface` (fond de Container/Card) | `AdaptiveColors.surface(context)` |
| `AppColors.surfaceVariant` | `AdaptiveColors.surfaceVariant(context)` |
| `AppColors.textPrimary` | `AdaptiveColors.textPrimary(context)` |
| `AppColors.textSecondary` | `AdaptiveColors.textSecondary(context)` |
| `AppColors.textDisabled` | `AdaptiveColors.textDisabled(context)` |
| `AppColors.divider` | `AdaptiveColors.divider(context)` |
| `AppColors.primarySurface` | `AdaptiveColors.primarySurface(context)` |
| `AppColors.accentSurface` | `AdaptiveColors.accentSurface(context)` |
| `Colors.white` (fond) | `AdaptiveColors.surface(context)` |
| `Colors.white` (texte sur fond primaire) | `AdaptiveColors.onPrimary(context)` |
| `Colors.black.withOpacity(0.05)` (ombre) | `AdaptiveColors.shadow(context)` |
| `color.withOpacity(0.12)` (chip) | `AdaptiveChip(label: ..., color: color)` |
| `AppColors.primary` (chip petit, dark) | `AdaptiveColors.primary(context)` |

**Note** : `AppColors.primary`, `.accent`, `.success`, `.error`, `.warning`,
`.info`, `.facile`, `.moyen`, `.difficile`, `.echec` restent OK en dark (ce
sont des couleurs sémantiques assez vives). Ne pas les remplacer.

---

## 1. `lib/main.dart`

**Resume** : RAS pour le dark mode. Le `MaterialApp.router` est deja
correctement branche avec `theme`, `darkTheme` et `themeMode`.

| Ligne | Actuel | Probleme | Correction |
|---|---|---|---|
| 103 | `theme: AppTheme.light,` | OK | Aucune |
| 104 | `darkTheme: AppTheme.dark,` | OK | Aucune |
| 105 | `themeMode: themeProvider.themeMode,` | OK | Aucune |

**Temps de correction estime** : 0 minute (deja OK).

---

## 2. `lib/screens/home/home_screen.dart`

### Ligne 21 — `backgroundColor: AppColors.background`
**Actuel** :
```dart
return Scaffold(
  backgroundColor: AppColors.background,
  body: SafeArea(
```
**Probleme** : `AppColors.background` est const (#F8F9FA), reste gris clair
en dark mode. Le Scaffold ne s'adapte pas.
**Correction** : Retirer l'attribut (le theme s'applique) OU utiliser
`AdaptiveScaffold` :
```dart
return AdaptiveScaffold(
  body: SafeArea(
```
OU
```dart
return Scaffold(
  body: SafeArea(
```
**Temps** : 1 min.

### Ligne 40 — `Icon(Icons.school, color: Colors.white, size: 24)`
**Actuel** :
```dart
child: const Icon(Icons.school, color: Colors.white, size: 24),
```
**Probleme** : `Colors.white` en dur. L'icone est sur un fond vert (`AppColors.primary`),
donc le blanc reste correct en dark. **Acceptable** mais pour cohérence :
**Correction** : pas de changement necessaire (texte blanc sur fond vert
foncé = bon contraste en dark aussi).
**Temps** : 0 min.

### Lignes 47, 52 — `AppTextStyles.h3` et `AppTextStyles.bodySmall`
**Actuel** :
```dart
Text('ExamBoost Togo', style: AppTextStyles.h3),
Text('Bonjour, $prenom !', style: AppTextStyles.bodySmall),
```
**Probleme** : `AppTextStyles.h3` utilise `color: AppColors.textPrimary`
(const #1A1A1A), reste noir en dark. Idem `bodySmall` avec `textSecondary`
(#757575, gris moyen peu lisible sur fond #121212).
**Correction** :
```dart
Text('ExamBoost Togo',
  style: AppTextStyles.h3.copyWith(color: AdaptiveColors.textPrimary(context))),
Text('Bonjour, $prenom !',
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
```
**Temps** : 1 min.

### Ligne 60 — `Icon(Icons.person_outline, color: AppColors.textSecondary)`
**Actuel** :
```dart
icon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
```
**Probleme** : `AppColors.textSecondary` const reste gris (#757575) en dark,
peu lisible sur #121212 (contraste 4.6:1 — limite WCAG AA).
**Correction** :
```dart
icon: Icon(Icons.person_outline, color: AdaptiveColors.textSecondary(context)),
```
**Temps** : 1 min.

### Ligne 68 — `Text('Que veux-tu faire ?', style: AppTextStyles.h2)`
**Probleme** : `AppTextStyles.h2` utilise `AppColors.textPrimary` (const noir).
**Correction** :
```dart
Text('Que veux-tu faire ?',
  style: AppTextStyles.h2.copyWith(color: AdaptiveColors.textPrimary(context))),
```
**Temps** : 1 min.

### Lignes 222, 225 — `_ActionCard` (couleur icon + withOpacity)
**Actuel** :
```dart
color: color.withOpacity(0.12),
borderRadius: BorderRadius.circular(12),
child: Icon(icon, color: color, size: 26),
```
**Probleme** : En dark, `color.withOpacity(0.12)` est trop peu opaque sur
fond sombre — le chip devient invisible. `color` (primary, accent, info,
textSecondary) est OK.
**Correction** : Augmenter l'opacite en dark :
```dart
color: color.withOpacity(context.isDark ? 0.20 : 0.12),
```
**Temps** : 1 min.

### Ligne 232 — `Text(title, style: AppTextStyles.h3.copyWith(fontSize: 16))`
**Probleme** : `h3` couleur const texte noir.
**Correction** :
```dart
Text(title,
  style: AppTextStyles.h3.copyWith(
    fontSize: 16,
    color: AdaptiveColors.textPrimary(context),
  )),
```
**Temps** : 1 min.

### Ligne 234 — `Text(subtitle, style: AppTextStyles.bodySmall)`
**Probleme** : bodySmall couleur const gris (#757575), peu lisible en dark.
**Correction** :
```dart
Text(subtitle,
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
```
**Temps** : 1 min.

### Ligne 238 — `Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary)`
**Correction** :
```dart
Icon(Icons.arrow_forward_ios, size: 16, color: AdaptiveColors.textSecondary(context)),
```
**Temps** : 1 min.

### Lignes 177, 151, 157, 161, 164 — `AppTextStyles.h3`, `.body`, `.bodySmall` dans `_showProfileDialog`
**Probleme** : tous ces styles ont des couleurs const qui restent sombres en
dark. Le `AlertDialog` utilise le theme de l'app (fond sombre OK), mais le
texte reste noir/gris foncé.
**Correction** : ajouter `.copyWith(color: AdaptiveColors.textPrimary(context))`
sur `h3` et `body`, `.copyWith(color: AdaptiveColors.textSecondary(context))`
sur `bodySmall`. Voir ci-dessus.
**Temps** : 2 min.

**Total home_screen.dart** : ~10 corrections, ~10 minutes.

---

## 3. `lib/screens/auth/onboarding_screen.dart`

### Ligne 175 — `backgroundColor: AppColors.background`
**Actuel** :
```dart
return Scaffold(
  resizeToAvoidBottomInset: true,
  backgroundColor: AppColors.background,
  body: _isSaving ? _buildSuccessView() : SafeArea(...),
);
```
**Correction** : Retirer l'attribut (le theme s'applique) :
```dart
return Scaffold(
  resizeToAvoidBottomInset: true,
  body: _isSaving ? _buildSuccessView() : SafeArea(...),
);
```
**Temps** : 1 min.

### Ligne 238 — `color: active || passed ? AppColors.primary : AppColors.divider`
**Actuel** :
```dart
decoration: BoxDecoration(
  color: active || passed ? AppColors.primary : AppColors.divider,
  borderRadius: BorderRadius.circular(4),
),
```
**Probleme** : `AppColors.divider` est const (#E0E0E0), reste gris clair en
dark. Sur fond #121212, un divider clair peut etre OK (contraste 7:1) mais
la couleur "officielle" en dark est #424242.
**Correction** :
```dart
decoration: BoxDecoration(
  color: active || passed ? AppColors.primary : AdaptiveColors.divider(context),
  borderRadius: BorderRadius.circular(4),
),
```
**Temps** : 1 min.

### Lignes 263, 271 — `AppColors.primary.withOpacity(0.3)` et `Colors.white`
**Actuel** :
```dart
color: AppColors.primary,
borderRadius: BorderRadius.circular(20),
boxShadow: <BoxShadow>[
  BoxShadow(
    color: AppColors.primary.withOpacity(0.3),
    ...
  ),
],
child: const Icon(Icons.school, color: Colors.white, size: 44),
```
**Probleme** : Aucun — le fond est vert Togo (#006837), l'icone blanche reste
lisible en dark (contraste 6.5:1).
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 280, 286, 306, 458, 580, 666 — `AppTextStyles.h3.copyWith(color: AppColors.textSecondary)` et `.body.copyWith(color: AppColors.textSecondary)`
**Actuel** :
```dart
Text('Prépare tes examens...', style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
Text('BEPC · BAC · ...', style: AppTextStyles.bodySmall),
Text('Dis-nous en plus...', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
```
**Probleme** : `AppColors.textSecondary` (#757575) reste gris moyen en dark,
peu lisible sur fond #121212.
**Correction** :
```dart
Text('Prépare tes examens...',
  style: AppTextStyles.h3.copyWith(color: AdaptiveColors.textSecondary(context))),
Text('BEPC · BAC · ...',
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
```
**Temps** : 3 min (6 occurrences).

### Lignes 492, 600, 622 — `AppColors.primarySurface` / `AppColors.surface` (cards de niveau/serie)
**Actuel** :
```dart
color: selected ? AppColors.primarySurface : AppColors.surface,
border: Border.all(
  color: selected ? AppColors.primary : AppColors.divider,
  ...
),
boxShadow: <BoxShadow>[
  if (!selected)
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      ...
    ),
],
```
**Probleme** : `AppColors.surface` const (#FFFFFF) reste blanc en dark.
`AppColors.primarySurface` const reste vert clair. `Colors.black.withOpacity(0.04)`
invisible en dark.
**Correction** :
```dart
color: selected ? AdaptiveColors.primarySurface(context) : AdaptiveColors.surface(context),
border: Border.all(
  color: selected ? AppColors.primary : AdaptiveColors.divider(context),
  ...
),
boxShadow: <BoxShadow>[
  if (!selected)
    BoxShadow(
      color: AdaptiveColors.shadow(context),
      ...
    ),
],
```
**Temps** : 3 min (2 cards × 2 occurrences : niveau + série).

### Lignes 514, 520, 627, 642, 644 — Icones et textes colors
**Actuel** :
```dart
Icon(n.icon, size: 36, color: selected ? AppColors.primary : AppColors.textSecondary),
Text(n.label, style: AppTextStyles.h3.copyWith(color: selected ? AppColors.primary : AppColors.textPrimary)),
Icon(s.icon, color: selected ? Colors.white : AppColors.textSecondary),
const Icon(Icons.check_circle, color: AppColors.primary),
const Icon(Icons.radio_button_unchecked, color: AppColors.textDisabled),
```
**Probleme** : `AppColors.textSecondary`, `AppColors.textPrimary`,
`AppColors.textDisabled` sont const et peu lisibles en dark. `Colors.white`
sur fond vert OK.
**Correction** :
```dart
Icon(n.icon, size: 36,
  color: selected ? AppColors.primary : AdaptiveColors.textSecondary(context)),
Text(n.label,
  style: AppTextStyles.h3.copyWith(
    color: selected ? AppColors.primary : AdaptiveColors.textPrimary(context))),
Icon(s.icon, color: selected ? Colors.white : AdaptiveColors.textSecondary(context)),
Icon(Icons.check_circle, color: AppColors.primary),
Icon(Icons.radio_button_unchecked, color: AdaptiveColors.textDisabled(context)),
```
**Temps** : 4 min.

### Lignes 709-720 — `FilterChip` couleurs
**Actuel** :
```dart
FilterChip(
  ...
  selectedColor: AppColors.primary,
  backgroundColor: AppColors.surface,
  side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
  labelStyle: TextStyle(
    color: selected ? Colors.white : AppColors.textPrimary,
    ...
  ),
  checkmarkColor: Colors.white,
  ...
)
```
**Probleme** : `AppColors.surface` const reste blanc en dark, `AppColors.divider`
const reste gris clair, `AppColors.textPrimary` const reste noir (sur fond
blanc du chip = OK en clair, illisible en dark).
**Correction** :
```dart
FilterChip(
  ...
  selectedColor: AppColors.primary,
  backgroundColor: AdaptiveColors.surface(context),
  side: BorderSide(color: selected ? AppColors.primary : AdaptiveColors.divider(context)),
  labelStyle: TextStyle(
    color: selected ? Colors.white : AdaptiveColors.textPrimary(context),
    ...
  ),
  checkmarkColor: Colors.white,
  ...
)
```
**Temps** : 2 min.

### Lignes 812-826 — `_buildSuccessView` (container vert succes + icone blanche)
**Actuel** :
```dart
decoration: BoxDecoration(
  color: AppColors.success,
  shape: BoxShape.circle,
  ...
),
child: const Icon(Icons.check, color: Colors.white, size: 56),
```
**Probleme** : Aucun — fond vert success, icone blanche, OK en dark.
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 829, 833-835, 839 — `AppTextStyles.h1`, `.body.copyWith(color: AppColors.textSecondary)`, `.bodySmall`
**Correction** :
```dart
Text('Profil créé !',
  style: AppTextStyles.h1.copyWith(color: AdaptiveColors.textPrimary(context))),
Text('Bienvenue ${_prenomCtrl.text.trim()} !',
  style: AppTextStyles.body.copyWith(color: AdaptiveColors.textSecondary(context))),
Text('Redirection vers l\'accueil...',
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
```
**Temps** : 1 min.

**Total onboarding_screen.dart** : ~15 corrections, ~15 minutes.

---

## 4. `lib/screens/revision/revision_screen.dart`

### Lignes 221, 378, 398, 440, 504 — `backgroundColor: AppColors.background`
**Actuel** (5 occurrences, une par etat : main, loading, error, empty, summary) :
```dart
return Scaffold(
  backgroundColor: AppColors.background,
  ...
);
```
**Correction** : Retirer l'attribut sur les 5 Scaffold :
```dart
return Scaffold(
  ...
);
```
**Temps** : 2 min.

### Ligne 285 — `color: AppColors.textSecondary`
**Actuel** :
```dart
'${_currentIndex + 1} / ${_questions.length}',
style: AppTextStyles.label.copyWith(
  color: AppColors.textSecondary,
  fontSize: 14,
),
```
**Correction** :
```dart
'${_currentIndex + 1} / ${_questions.length}',
style: AppTextStyles.label.copyWith(
  color: AdaptiveColors.textSecondary(context),
  fontSize: 14,
),
```
**Temps** : 1 min.

### Lignes 301-302 — `LinearProgressIndicator`
**Actuel** :
```dart
return LinearProgressIndicator(
  value: progress,
  minHeight: 4,
  backgroundColor: AppColors.primarySurface,
  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
);
```
**Probleme** : `AppColors.primarySurface` const reste vert clair en dark.
**Correction** :
```dart
return LinearProgressIndicator(
  value: progress,
  minHeight: 4,
  backgroundColor: AdaptiveColors.primarySurface(context),
  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
);
```
**Temps** : 1 min.

### Lignes 311, 321 — `_buildChip` (matiere + annee)
**Actuel** :
```dart
_buildChip(label: question.matiere, color: AppColors.primary),
...
_buildChip(label: question.annee.toString(), color: AppColors.textSecondary),
```
**Probleme** : `_buildChip` utilise `color.withOpacity(0.12)` (ligne 332) —
trop peu opaque en dark.
**Correction** : Modifier `_buildChip` directement (ligne 332) :
```dart
Widget _buildChip({required String label, required Color color}) {
  return Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: color),
      ),
    ),
  );
}
```
(Note : `_buildChip` n'a pas de BuildContext en parametre — il faut ajouter
un `Builder` ou passer `context`.)
**Alternative** : Remplacer les appels `_buildChip(...)` par
`AdaptiveChip(label: ..., color: ...)`.
**Temps** : 3 min.

### Lignes 352, 367 — `_buildVoirReponseButton`, `_buildPasserButton`
**Actuel** :
```dart
style: ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  padding: const EdgeInsets.symmetric(vertical: 16),
),
...
style: TextButton.styleFrom(
  foregroundColor: AppColors.textSecondary,
  textStyle: AppTextStyles.label.copyWith(fontSize: 13),
),
```
**Probleme** : `AppColors.primary` OK (vert fonce lisible en dark).
`AppColors.textSecondary` const gris moyen peu lisible en dark.
**Correction** :
```dart
style: TextButton.styleFrom(
  foregroundColor: AdaptiveColors.textSecondary(context),
  textStyle: AppTextStyles.label.copyWith(fontSize: 13),
),
```
**Temps** : 1 min.

### Lignes 386-389, 414, 416 — `_buildLoadingScreen`, `_buildErrorScreen`
**Actuel** :
```dart
const Text('Chargement des questions...', style: AppTextStyles.bodySmall),
...
const Icon(Icons.error_outline, size: 64, color: AppColors.error),
Text('Une erreur est survenue', style: AppTextStyles.h2),
Text(_loadingError ?? 'Erreur inconnue', style: AppTextStyles.bodySmall),
```
**Probleme** : `bodySmall` couleur const reste gris peu lisible en dark. `h2`
couleur const reste noir. `AppColors.error` (#C62828) OK en dark.
**Correction** :
```dart
Text('Chargement des questions...',
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
Icon(Icons.error_outline, size: 64, color: AppColors.error),
Text('Une erreur est survenue',
  style: AppTextStyles.h2.copyWith(color: AdaptiveColors.textPrimary(context))),
Text(_loadingError ?? 'Erreur inconnue',
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
```
**Temps** : 2 min.

### Lignes 451, 454, 460, 463-465 — `_buildEmptyState`
**Actuel** :
```dart
const Icon(Icons.inbox, size: 80, color: AppColors.textSecondary),
Text('Aucune question disponible...', style: AppTextStyles.h2),
Text('Pas encore de questions...',
  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
```
**Correction** :
```dart
Icon(Icons.inbox, size: 80, color: AdaptiveColors.textSecondary(context)),
Text('Aucune question disponible...',
  style: AppTextStyles.h2.copyWith(color: AdaptiveColors.textPrimary(context))),
Text('Pas encore de questions...',
  style: AppTextStyles.body.copyWith(color: AdaptiveColors.textSecondary(context))),
```
**Temps** : 2 min.

### Lignes 516-526, 538-540 — `_buildSessionSummary`
**Actuel** :
```dart
Text('Session terminée !', style: AppTextStyles.h1),
Text('Tu as répondu correctement...',
  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
...
decoration: BoxDecoration(
  shape: BoxShape.circle,
  color: _scoreColor(taux).withOpacity(0.15),
  border: Border.all(color: _scoreColor(taux), width: 4),
),
```
**Probleme** : `AppTextStyles.h1` couleur const noir reste noir en dark
(illisible sur #121212). `withOpacity(0.15)` OK car _scoreColor est vif.
**Correction** :
```dart
Text('Session terminée !',
  style: AppTextStyles.h1.copyWith(color: AdaptiveColors.textPrimary(context))),
Text('Tu as répondu correctement...',
  style: AppTextStyles.body.copyWith(color: AdaptiveColors.textSecondary(context))),
```
**Temps** : 2 min.

### Lignes 569-570 — `_buildStatRow` Container + Border
**Actuel** :
```dart
decoration: BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.divider),
),
```
**Correction** :
```dart
decoration: BoxDecoration(
  color: AdaptiveColors.surface(context),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AdaptiveColors.divider(context)),
),
```
**Temps** : 1 min.

### Lignes 640, 643 — `Text(label, style: AppTextStyles.body)` et `Text(value, style: AppTextStyles.h3.copyWith(color: iconColor))`
**Correction** :
```dart
Text(label,
  style: AppTextStyles.body.copyWith(color: AdaptiveColors.textPrimary(context))),
```
**Temps** : 1 min.

### Lignes 657-658 — `_showQuitDialog` AlertDialog
**Probleme** : AlertDialog utilise le theme (fond sombre OK en dark),
le texte par defaut est `Theme.of(context).textTheme.titleLarge` qui est
blanc en dark (voir AppTheme.dark). OK.
**Correction** : Aucune.
**Temps** : 0 min.

**Total revision_screen.dart** : ~15 corrections, ~20 minutes.

---

## 5. `lib/screens/simulation/simulation_screen.dart`

Ce fichier est tres long (~2000 lignes). La plupart des patterns se repetent.

### Lignes 438, 784, 1336, 1699 — `backgroundColor: AppColors.background`
**Actuel** (4 occurrences : config, examen, rapport, corrections sheet) :
```dart
return Scaffold(
  backgroundColor: AppColors.background,
  ...
);
```
**Correction** : Retirer l'attribut.
**Temps** : 2 min.

### Lignes 544, 614, 641, 667, 687 — `AppColors.surface` et `AppColors.divider` dans ChoiceChip
**Actuel** :
```dart
selectedColor: AppColors.primary,
backgroundColor: AppColors.surface,
shape: RoundedRectangleBorder(
  ...
  side: BorderSide(
    color: selected ? AppColors.primary : AppColors.divider,
  ),
),
labelStyle: TextStyle(
  color: selected ? Colors.white : AppColors.textPrimary,
  ...
),
```
**Correction** :
```dart
selectedColor: AppColors.primary,
backgroundColor: AdaptiveColors.surface(context),
shape: RoundedRectangleBorder(
  ...
  side: BorderSide(
    color: selected ? AppColors.primary : AdaptiveColors.divider(context),
  ),
),
labelStyle: TextStyle(
  color: selected ? Colors.white : AdaptiveColors.textPrimary(context),
  ...
),
```
**Temps** : 3 min (5 ChoiceChips × 3 attributs).

### Lignes 713, 719, 728, 731, 745, 754, 769 — `_buildResumeCarte` gradient
**Actuel** :
```dart
gradient: const LinearGradient(
  colors: [AppColors.primarySurface, AppColors.accentSurface],
  ...
),
border: Border.all(
  color: AppColors.primaryLight.withOpacity(0.4),
  ...
),
...
const Icon(Icons.assignment, color: AppColors.primary),
Text('Résumé', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
```
**Probleme** : `AppColors.primarySurface` const reste vert clair en dark —
le gradient devient vert clair/orange clair (illisible). `AppColors.primary`
OK.
**Correction** : Utiliser les couleurs adaptatives pour le gradient :
```dart
gradient: LinearGradient(
  colors: [AdaptiveColors.primarySurface(context), AdaptiveColors.accentSurface(context)],
  ...
),
border: Border.all(
  color: AppColors.primaryLight.withOpacity(0.4),
  ...
),
...
const Icon(Icons.assignment, color: AppColors.primary),
Text('Résumé', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
```
**Temps** : 2 min.

### Lignes 797, 806, 812 — `_buildPhaseExamen` AppBar compteur
**Actuel** :
```dart
color: urgent
    ? AppColors.error.withOpacity(0.12)
    : AppColors.primarySurface,
...
color: urgent ? AppColors.error : AppColors.primary,
```
**Correction** :
```dart
color: urgent
    ? AppColors.error.withOpacity(context.isDark ? 0.20 : 0.12)
    : AdaptiveColors.primarySurface(context),
...
color: urgent ? AppColors.error : AppColors.primary,
```
**Temps** : 1 min.

### Lignes 883-885 — `_buildProgressionHeader`
**Actuel** :
```dart
LinearProgressIndicator(
  value: ...,
  minHeight: 6,
  backgroundColor: AppColors.primarySurface,
  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
),
```
**Correction** :
```dart
LinearProgressIndicator(
  value: ...,
  minHeight: 6,
  backgroundColor: AdaptiveColors.primarySurface(context),
  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
),
```
**Temps** : 1 min.

### Lignes 925-929 — `_buildQuestionMeta` chips
**Actuel** :
```dart
_buildChip(label: q.matiere, color: AppColors.primary),
_buildChip(label: _typeLabel(q.type), color: AppColors.info),
if (q.annee != null)
  _buildChip(label: q.annee.toString(), color: AppColors.textSecondary),
_buildChip(label: '${q.points ?? 1} pts', color: AppColors.accent),
```
**Probleme** : `_buildChip` (ligne 406) utilise `color.withOpacity(0.12)` —
trop peu opaque en dark. Aussi `AppColors.textSecondary` en dark.
**Correction** : Modifier `_buildChip` (ligne 406-418) :
```dart
Widget _buildChip({required String label, required Color color}) {
  return Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: color),
      ),
    ),
  );
}
```
Et remplacer le chip "annee" qui utilise `AppColors.textSecondary` :
```dart
_buildChip(label: q.annee.toString(), color: AdaptiveColors.textSecondary(context)),
```
**Temps** : 2 min.

### Lignes 939, 943, 1144, 1147, 1497, 1501, 1544, 1765 — `BoxShadow` `Colors.black.withOpacity(0.04)` ou `0.05`
**Actuel** :
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
],
```
**Probleme** : `Colors.black.withOpacity(0.04)` est invisible en dark (sur
fond #121212). Les cards n'ont plus de separation visuelle.
**Correction** : Utiliser `AdaptiveColors.shadow(context)` :
```dart
boxShadow: [
  BoxShadow(
    color: AdaptiveColors.shadow(context),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
],
```
**Temps** : 3 min (8 occurrences).

### Lignes 939, 1144, 1497, 1544, 1765 — `color: AppColors.surface` (cards)
**Correction** :
```dart
color: AdaptiveColors.surface(context),
```
**Temps** : 2 min (5 occurrences).

### Lignes 1003, 1006, 1017, 1027 — `_buildQcmReponse` Container
**Actuel** :
```dart
decoration: BoxDecoration(
  color: isSelected ? AppColors.primarySurface : AppColors.surface,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: isSelected ? AppColors.primary : AppColors.divider,
    ...
  ),
),
...
color: isSelected ? AppColors.primary : AppColors.textSecondary,
...
color: isSelected ? AppColors.primary : AppColors.textPrimary,
```
**Correction** :
```dart
decoration: BoxDecoration(
  color: isSelected ? AdaptiveColors.primarySurface(context) : AdaptiveColors.surface(context),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: isSelected ? AppColors.primary : AdaptiveColors.divider(context),
    ...
  ),
),
...
color: isSelected ? AppColors.primary : AdaptiveColors.textSecondary(context),
...
color: isSelected ? AppColors.primary : AdaptiveColors.textPrimary(context),
```
**Temps** : 2 min.

### Lignes 1084, 1087, 1093, 1098 — `_buildVraiFauxButton`
**Actuel** :
```dart
color: selected ? color : AppColors.surface,
border: Border.all(
  color: selected ? color : AppColors.divider,
  ...
),
Icon(icon, size: 36, color: selected ? Colors.white : color),
Text(label, style: AppTextStyles.h3.copyWith(color: selected ? Colors.white : color)),
```
**Correction** :
```dart
color: selected ? color : AdaptiveColors.surface(context),
border: Border.all(
  color: selected ? color : AdaptiveColors.divider(context),
  ...
),
Icon(icon, size: 36, color: selected ? Colors.white : color),
Text(label, style: AppTextStyles.h3.copyWith(color: selected ? Colors.white : color)),
```
**Temps** : 1 min.

### Lignes 1201, 1227-1229, 1255, 1268, 1277-1278 — `_ouvrirPlanExamen` ModalBottomSheet
**Actuel** :
```dart
showModalBottomSheet<void>(
  ...
  backgroundColor: AppColors.surface,
  ...
  _legendeCircle(AppColors.surfaceVariant, 'Non répondue'),
  _legendeCircle(AppColors.success, 'Répondue'),
  _legendeCircle(AppColors.accent, 'Marquée'),
  ...
  couleur = AppColors.surfaceVariant; // pour "non répondue"
  border: Border.all(
    color: courante ? AppColors.primary : Colors.transparent,
    ...
  ),
  color: repondue || marquee ? Colors.white : AppColors.textSecondary,
);
```
**Correction** :
```dart
showModalBottomSheet<void>(
  ...
  backgroundColor: AdaptiveColors.surface(context),
  ...
  _legendeCircle(AdaptiveColors.surfaceVariant(context), 'Non répondue'),
  _legendeCircle(AppColors.success, 'Répondue'),
  _legendeCircle(AppColors.accent, 'Marquée'),
  ...
  couleur = AdaptiveColors.surfaceVariant(context);
  border: Border.all(
    color: courante ? AppColors.primary : Colors.transparent,
    ...
  ),
  color: repondue || marquee
    ? Colors.white
    : AdaptiveColors.textSecondary(context),
);
```
**Temps** : 2 min.

### Lignes 1319, 1375, 1420, 1463, 1472, 1481, 1597 — `Border.all(color: AppColors.divider)`, `AppColors.surface` in rapport
**Correction** : Remplacer par `AdaptiveColors.divider(context)` /
`AdaptiveColors.surface(context)` partout.
**Temps** : 2 min.

### Lignes 1624, 1626, 1659, 1662, 1668 — `_buildRecommandations` encart accent
**Actuel** :
```dart
decoration: BoxDecoration(
  color: AppColors.accentSurface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.accentLight.withOpacity(0.4), width: 1),
),
...
color: Colors.white,  // chips internes
border: Border.all(
  color: AppColors.accentLight.withOpacity(0.6),
),
```
**Probleme** : `AppColors.accentSurface` const reste orange clair en dark.
`Colors.white` pour les chips internes reste blanc en dark (sur fond orange
fonce = OK mais incoherent avec les autres chips qui auraient fond teinte).
**Correction** :
```dart
decoration: BoxDecoration(
  color: AdaptiveColors.accentSurface(context),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.accentLight.withOpacity(0.4), width: 1),
),
...
color: AdaptiveColors.surfaceVariant(context), // ou AdaptiveColors.surface(context)
```
**Temps** : 2 min.

### Lignes 1817, 1851, 1877, 1898 — `AppColors.primarySurface` et `AppColors.accentSurface`
**Correction** : Remplacer par `AdaptiveColors.primarySurface(context)` /
`AdaptiveColors.accentSurface(context)`.
**Temps** : 1 min.

### Lignes 1803, 1809, 1879, 1900 — `AppColors.textDisabled`, `AppColors.success`, `AppColors.error`
**Actuel** :
```dart
color: reponseEleve.isEmpty ? AppColors.textDisabled : color,
color: AppColors.success,
foregroundColor: correcte ? Colors.white : AppColors.success,
foregroundColor: !correcte ? Colors.white : AppColors.error,
```
**Probleme** : `AppColors.textDisabled` const reste gris clair (#BDBDBD) en
dark (sur fond sombre = peu lisible, contraste 4:1). `AppColors.success` et
`AppColors.error` OK.
**Correction** :
```dart
color: reponseEleve.isEmpty ? AdaptiveColors.textDisabled(context) : color,
```
**Temps** : 1 min.

### Lignes 1970, 1689 — `OutlineButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary))`
**Probleme** : OK en dark (vert fonce lisible).
**Correction** : Aucune.
**Temps** : 0 min.

**Total simulation_screen.dart** : ~25 corrections, ~25 minutes.

---

## 6. `lib/screens/dashboard/dashboard_screen.dart`

### Ligne 99 — `backgroundColor: AppColors.background`
**Correction** : Retirer l'attribut.
**Temps** : 1 min.

### Lignes 178, 270, 280, 359, 389, 473, 547, 574, 589, 607, 627, 685, 751, 1420, 1521, 1584, 1591, 1597 — TextStyles avec couleurs const
**Actuel** (pattern recurrent) :
```dart
Text('Bonjour, $prenom !', style: AppTextStyles.h2),
Text(_formatToday(), style: AppTextStyles.bodySmall),
Text('Score global de maîtrise',
  style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary, ...)),
Text('maîtrise', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
```
**Correction** : Pour chaque `AppTextStyles.h1/h2/h3/body` pur, ajouter
`.copyWith(color: AdaptiveColors.textPrimary(context))`. Pour chaque
`.copyWith(color: AppColors.textSecondary)`, remplacer par
`AdaptiveColors.textSecondary(context)`. Pour `bodySmall` pur, remplacer par
`.copyWith(color: AdaptiveColors.textSecondary(context))`.
**Temps** : 8 min (18 occurrences).

### Lignes 168, 214, 479-484, 500-502, 519, 686, 743, 751 — `AppColors.textSecondary`, `AppColors.textDisabled` pour icones et accents
**Actuel** :
```dart
final streakColor = streak >= 3 ? AppColors.accent : AppColors.textSecondary;
...
const Icon(Icons.show_chart, color: AppColors.textDisabled, size: 36),
const Icon(Icons.waving_hand, size: 72, color: AppColors.primary),
```
**Correction** :
```dart
final streakColor = streak >= 3 ? AppColors.accent : AdaptiveColors.textSecondary(context);
...
Icon(Icons.show_chart, color: AdaptiveColors.textDisabled(context), size: 36),
const Icon(Icons.waving_hand, size: 72, color: AppColors.primary),
```
**Temps** : 3 min.

### Lignes 208, 222, 270, 287, 293, 298, 361, 373, 458, 607, 685, 719, 727, 740, 745, 750, 1375, 1597, 1801, 1817 — `withOpacity(0.12)` et `AppColors.primarySurface`, `AppColors.accentSurface`
**Actuel** :
```dart
color: streakColor.withOpacity(0.12),
backgroundColor: scoreColor.withOpacity(0.12),
color: AppColors.accentSurface,
color: color.withOpacity(0.12), // _buildWeakChapterRow, _buildStatCard
backgroundColor: color.withOpacity(0.15),
backgroundColor: AppColors.surfaceVariant, // LineChart grid
color: AppColors.primary.withOpacity(0.12), // belowBarData
color: AppColors.primarySurface, // explication container
```
**Correction** :
```dart
color: streakColor.withOpacity(context.isDark ? 0.20 : 0.12),
backgroundColor: scoreColor.withOpacity(context.isDark ? 0.20 : 0.12),
color: AdaptiveColors.accentSurface(context),
color: color.withOpacity(context.isDark ? 0.20 : 0.12),
backgroundColor: color.withOpacity(context.isDark ? 0.20 : 0.15),
backgroundColor: AdaptiveColors.surfaceVariant(context),
color: AdaptiveColors.primary(context).withOpacity(0.12),
color: AdaptiveColors.primarySurface(context),
```
**Temps** : 5 min.

### Ligne 681 — `strokeColor: Colors.white` (LineChart dots)
**Actuel** :
```dart
FlDotCirclePainter(
  radius: 4,
  color: AppColors.primary,
  strokeWidth: 2,
  strokeColor: Colors.white,
),
```
**Probleme** : `Colors.white` en dur pour la bordure du point. En dark, la
bordure blanche sur un point vert fonce reste OK (contraste 6:1) mais
visuellement etrange.
**Correction** : Utiliser la couleur de surface pour que la bordure se
confonde avec le fond de la card :
```dart
FlDotCirclePainter(
  radius: 4,
  color: AdaptiveColors.primary(context),
  strokeWidth: 2,
  strokeColor: AdaptiveColors.surface(context),
),
```
**Temps** : 1 min.

### Lignes 884-894 — `_cardDecoration()` helper
**Actuel** :
```dart
BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);
```
**Probleme** : `AppColors.surface` const reste blanc en dark. `Colors.black
.withOpacity(0.05)` invisible en dark. Ce helper est utilise dans toute la
dashboard (multiple cards).
**Correction** : Faire de `_cardDecoration` une methode qui prend
`BuildContext` :
```dart
BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
  color: AdaptiveColors.surface(context),
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: AdaptiveColors.shadow(context),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);
```
Et mettre a jour les ~8 appels : `_cardDecoration()` -> `_cardDecoration(context)`.
**Temps** : 4 min.

### Lignes 9, 607, 1375 — `AppColors.divider` (LineChart grid, etc.)
**Correction** : Remplacer par `AdaptiveColors.divider(context)`.
**Temps** : 1 min.

**Total dashboard_screen.dart** : ~20 corrections, ~22 minutes.

---

## 7. `lib/screens/community/community_screen.dart`

### Ligne 35 — `backgroundColor: AppColors.background`
**Correction** : Retirer l'attribut.
**Temps** : 1 min.

### Lignes 37-38 — `AppBar backgroundColor: AppColors.primary` + `foregroundColor: Colors.white`
**Actuel** :
```dart
appBar: AppBar(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  ...
),
```
**Probleme** : `AppColors.primary` (#006837) en fond d'AppBar — OK en dark
aussi (vert fonce lisible). `Colors.white` pour le texte — OK sur vert fonce.
**Correction** : Aucune (le branding "Communaute ExamBoost" est volontairement
vert fonce dans les deux themes).
**Temps** : 0 min.

### Lignes 48, 58 — `color: Colors.white` et `Colors.white70` (titre + sous-titre)
**Actuel** :
```dart
Text('Communauté ExamBoost',
  style: TextStyle(color: Colors.white, ...),
),
Text('Élèves de tout le Togo',
  style: TextStyle(color: Colors.white70, ...),
),
```
**Probleme** : Sur fond vert Togo, blanc et blanc70 sont OK dans les 2 themes.
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 82-84 — `TabBar` colors
**Actuel** :
```dart
labelColor: Colors.white,
unselectedLabelColor: Colors.white60,
indicatorColor: AppColors.accent,
```
**Probleme** : Sur fond vert Togo, blanc/blanc60/accent tous OK en dark.
**Correction** : Aucune.
**Temps** : 0 min.

**Total community_screen.dart** : 1 correction (retrait background), ~1 minute.

---

## 8. `lib/screens/admin/admin_login_screen.dart`

### Ligne 176 — `backgroundColor: AppColors.background`
**Correction** : Retirer l'attribut.
**Temps** : 1 min.

### Ligne 93, 280, 306, 314, 322, 346, 350, 356, 364 — `_openDemoRequest` et `_buildHeader` styles
**Actuel** :
```dart
const Icon(Icons.school, color: AppColors.primary),
Text('Demander une démo', style: AppTextStyles.h2),
Text('Notre équipe vous recontactera...', style: AppTextStyles.bodySmall),
...
const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
Text('Licence ExamBoost : ...',
  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark)),
```
**Probleme** : `AppTextStyles.h2` couleur const noir reste noir en dark.
`AppColors.primaryDark` (#004A26) est trop fonce pour etre lisible sur fond
#121212 (contraste 1.5:1 — illisible !). C'est le bug le plus visible.
**Correction** :
```dart
const Icon(Icons.school, color: AppColors.primary),
Text('Demander une démo',
  style: AppTextStyles.h2.copyWith(color: AdaptiveColors.textPrimary(context))),
Text('Notre équipe vous recontactera...',
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
...
const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
Text('Licence ExamBoost : ...',
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.primary(context))),
```
**Temps** : 3 min.

### Lignes 305-308 — `AppColors.primarySurface` et `AppColors.primaryLight`
**Actuel** :
```dart
decoration: BoxDecoration(
  color: AppColors.primarySurface,
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: AppColors.primaryLight, width: 1),
),
```
**Correction** :
```dart
decoration: BoxDecoration(
  color: AdaptiveColors.primarySurface(context),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: AppColors.primaryLight, width: 1),
),
```
**Temps** : 1 min.

### Lignes 197, 279, 359 — `AppTextStyles.h2`, `bodySmall`, `h1`
**Correction** : Ajouter `.copyWith(color: AdaptiveColors.textPrimary(context))`
pour h1/h2 et `.copyWith(color: AdaptiveColors.textSecondary(context))` pour
bodySmall.
**Temps** : 2 min.

### Lignes 349-354 — `_buildHeader` logo
**Actuel** :
```dart
color: AppColors.primary,
borderRadius: BorderRadius.circular(18),
boxShadow: [
  BoxShadow(
    color: AppColors.primary.withOpacity(0.25),
    ...
  ),
],
child: const Icon(Icons.school, color: Colors.white, size: 42),
```
**Probleme** : OK en dark (vert fonce + blanc).
**Correction** : Aucune.
**Temps** : 0 min.

**Total admin_login_screen.dart** : ~7 corrections, ~7 minutes.

---

## 9. `lib/screens/admin/admin_dashboard_screen.dart`

### Ligne 466 — `backgroundColor: AppColors.background`
**Correction** : Retirer l'attribut.
**Temps** : 1 min.

### Lignes 469, 517, 540 — `AppBar backgroundColor: AppColors.surface`, `TabBar container color: AppColors.surface`, `_buildHeaderSection color: AppColors.surface`
**Actuel** :
```dart
appBar: AppBar(
  title: const Text('Espace Directeur'),
  backgroundColor: AppColors.surface,
  ...
),
...
Widget _buildTabBar() {
  return Container(
    color: AppColors.surface,
    child: TabBar(...),
  );
}
...
Widget _buildHeaderSection() {
  return Container(
    color: AppColors.surface,
    ...
  );
}
```
**Probleme** : `AppColors.surface` const reste blanc en dark — l'AppBar et
le header restent blancs (très visible / cassé).
**Correction** :
```dart
appBar: AppBar(
  title: const Text('Espace Directeur'),
  backgroundColor: AdaptiveColors.surface(context),
  ...
),
...
Widget _buildTabBar() {
  return Container(
    color: AdaptiveColors.surface(context),
    child: TabBar(...),
  );
}
...
Widget _buildHeaderSection() {
  return Container(
    color: AdaptiveColors.surface(context),
    ...
  );
}
```
**Temps** : 2 min.

### Lignes 520-522 — `TabBar` colors
**Actuel** :
```dart
TabBar(
  controller: _tabController,
  labelColor: AppColors.primary,
  unselectedLabelColor: AppColors.textSecondary,
  indicatorColor: AppColors.primary,
  ...
)
```
**Correction** :
```dart
TabBar(
  controller: _tabController,
  labelColor: AppColors.primary,
  unselectedLabelColor: AdaptiveColors.textSecondary(context),
  indicatorColor: AppColors.primary,
  ...
)
```
**Temps** : 1 min.

### Lignes 561-565 — `_buildSchoolHeader` logo
**Actuel** :
```dart
decoration: BoxDecoration(
  color: AppColors.primarySurface,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: AppColors.primaryLight, width: 1),
),
child: const Icon(Icons.school, color: AppColors.primary, size: 32),
```
**Correction** :
```dart
decoration: BoxDecoration(
  color: AdaptiveColors.primarySurface(context),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: AppColors.primaryLight, width: 1),
),
child: const Icon(Icons.school, color: AppColors.primary, size: 32),
```
**Temps** : 1 min.

### Lignes 574, 579-592 — `Wrap` chips
**Actuel** :
```dart
Text(AdminMockData.etablissementNom, style: AppTextStyles.h2),
...
_buildChip(
  AdminMockData.etablissementType,
  AppColors.primarySurface,
  AppColors.primaryDark,
),
_buildChip(
  '${AdminMockData.effectifTotal} élèves',
  AppColors.surfaceVariant,
  AppColors.textSecondary,
),
_buildChip(
  AdminMockData.licenceStatut,
  const Color(0xFFE8F5E9),  // BUG : vert clair reste en dark
  AppColors.success,
),
```
**Probleme** : `AppColors.primarySurface`, `AppColors.surfaceVariant`,
`AppColors.primaryDark`, `AppColors.textSecondary` sont const. `Color(0xFFE8F5E9)`
est un vert clair qui reste vert clair en dark (le success chip devient
illisible). `AppColors.primaryDark` (#004A26) trop fonce en dark.
**Correction** :
```dart
Text(AdminMockData.etablissementNom,
  style: AppTextStyles.h2.copyWith(color: AdaptiveColors.textPrimary(context))),
...
_buildChip(
  AdminMockData.etablissementType,
  AdaptiveColors.primarySurface(context),
  AdaptiveColors.primary(context),
),
_buildChip(
  '${AdminMockData.effectifTotal} élèves',
  AdaptiveColors.surfaceVariant(context),
  AdaptiveColors.textSecondary(context),
),
_buildChip(
  AdminMockData.licenceStatut,
  AdaptiveColors.primarySurface(context),  // ou un helper successSurface
  AppColors.success,
),
```
**Temps** : 3 min.

### Lignes 623-638 — `_buildChip` helper
**Actuel** :
```dart
Widget _buildChip(String label, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: fg,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
```
**Probleme** : Helper OK en soi — les couleurs viennent des appelants.
Mais les appelants passent des const `AppColors.xxx`. Voir ci-dessus.
**Correction** : Aucune (le helper est correct, ce sont les appels qu'il
faut corriger).
**Temps** : 0 min.

### Lignes 660, 666, 673, 680 — KPI colors
**Actuel** :
```dart
color: AppColors.primary,
color: AppColors.info,
color: AppColors.accent,
color: AppColors.success,
```
**Probleme** : OK en dark (couleurs sémantiques assez vives).
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 699-712 — `_buildKpiCard` Container + shadow
**Actuel** :
```dart
return Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.divider, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        ...
      ),
    ],
  ),
```
**Correction** :
```dart
return Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: AdaptiveColors.surface(context),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AdaptiveColors.divider(context), width: 1),
    boxShadow: [
      BoxShadow(
        color: AdaptiveColors.shadow(context),
        ...
      ),
    ],
  ),
```
**Temps** : 1 min.

### Lignes 723-728, 738-741, 745-750 — `TextStyle` const
**Actuel** :
```dart
style: const TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  color: AppColors.textSecondary,
),
...
style: const TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
  height: 1.1,
),
...
style: const TextStyle(
  fontSize: 11,
  color: AppColors.textSecondary,
),
```
**Probleme** : `AppColors.textSecondary` et `AppColors.textPrimary` const
restent gris/noir en dark. Le `const` doit etre retiré pour permettre
`AdaptiveColors.xxx(context)`.
**Correction** :
```dart
style: TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  color: AdaptiveColors.textSecondary(context),
),
...
style: TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  color: AdaptiveColors.textPrimary(context),
  height: 1.1,
),
...
style: TextStyle(
  fontSize: 11,
  color: AdaptiveColors.textSecondary(context),
),
```
**Temps** : 2 min.

### Ligne 780 — `backgroundColor: AppColors.error` (bouton déconnexion)
**Probleme** : OK en dark.
**Correction** : Aucune.
**Temps** : 0 min.

**Total admin_dashboard_screen.dart** : ~12 corrections, ~12 minutes.

---

## 10. `lib/screens/settings/settings_screen.dart`

### Ligne 94 — `backgroundColor: AppColors.background`
**Correction** : Retirer l'attribut.
**Temps** : 1 min.

### Lignes 275, 285, 288, 293, 315, 329, 342, 358, 389, 404, 427, 441, 455 — Icones `color: AppColors.warning/error/primary/textSecondary/accent/info`
**Probleme** : Toutes ces couleurs sont sémantiques (warning, error, primary,
accent, info) — OK en dark. Sauf `AppColors.textSecondary` (ligne 342) qui
reste gris moyen en dark.
**Correction pour ligne 342** :
```dart
leading: Icon(Icons.gavel, color: AdaptiveColors.textSecondary(context)),
```
**Temps** : 1 min.

### Ligne 741 — `color: AppColors.primary.withOpacity(0.12)`
**Actuel** (dans `_SectionCard`) :
```dart
decoration: BoxDecoration(
  color: AppColors.primary.withOpacity(0.12),
  borderRadius: BorderRadius.circular(10),
),
```
**Correction** :
```dart
decoration: BoxDecoration(
  color: AppColors.primary.withOpacity(context.isDark ? 0.20 : 0.12),
  borderRadius: BorderRadius.circular(10),
),
```
**Temps** : 1 min.

### Lignes 500, 532, 543, 561, 562, 595 — `backgroundColor: AppColors.warning/success/error` (SnackBars et FilledButtons)
**Probleme** : Ces couleurs sémantiques sont OK en dark.
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 167, 196, 230, 277-279, 291, 316-317, 332-333, 343, 359, 405-408, 429-431, 443-445, 457-461 — `AppTextStyles.bodySmall`, `.h3.copyWith(fontSize: 16)`
**Probleme** : `bodySmall` couleur const reste gris peu lisible en dark.
**Correction** : Pour chaque `bodySmall` dans `_SectionCard`, ajouter
`.copyWith(color: AdaptiveColors.textSecondary(context))`. Pour les `h3`
dans les titres de section, ajouter
`.copyWith(color: AdaptiveColors.textPrimary(context))`.
**Temps** : 4 min.

### Ligne 562 — `foregroundColor: Colors.white` (FilledButton error)
**Probleme** : OK en dark (texte blanc sur rouge error).
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 786-795 — `_InfoRow` styles
**Actuel** :
```dart
Text(label, style: AppTextStyles.bodySmall),
Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.right),
```
**Correction** :
```dart
Text(label,
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
Text(value,
  style: AppTextStyles.body.copyWith(
    fontWeight: FontWeight.w500,
    color: AdaptiveColors.textPrimary(context),
  ),
  textAlign: TextAlign.right),
```
**Temps** : 1 min.

### Lignes 751, 753 — `h3.copyWith(fontSize: 16)` et `bodySmall` dans `_SectionCard` header
**Correction** :
```dart
Text(title,
  style: AppTextStyles.h3.copyWith(
    fontSize: 16,
    color: AdaptiveColors.textPrimary(context),
  )),
Text(subtitle,
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
```
**Temps** : 1 min.

**Total settings_screen.dart** : ~9 corrections, ~9 minutes.

---

## 11. `lib/screens/splash/splash_screen.dart`

### Lignes 162-175 — `Material color: Colors.transparent` + `gradient LinearGradient`
**Actuel** :
```dart
return Material(
  color: Colors.transparent,
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          AppColors.primary,
          AppColors.primaryDark,
        ],
      ),
    ),
```
**Probleme** : Splash plein ecran avec degrade vert Togo — OK en dark
(volontaire : le branding reste vert dans les 2 themes).
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 198-205 — `Text('ExamBoost Togo')` `TextStyle(color: Colors.white)`
**Probleme** : Sur fond vert degrade, blanc = OK dans les 2 themes.
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 215-218 — `Text('Préparation intelligente...')` `TextStyle(color: Colors.white.withOpacity(0.85))`
**Probleme** : OK.
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 243-244 — `LinearProgressIndicator` `backgroundColor: Colors.white24, color: AppColors.accent`
**Probleme** : `Colors.white24` OK sur fond vert. `AppColors.accent` (#D97700)
OK en dark.
**Correction** : Aucune.
**Temps** : 0 min.

### Lignes 276-283 — `_buildLogo` `color: Colors.white` (logo container)
**Actuel** :
```dart
decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  boxShadow: <BoxShadow>[
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      ...
    ),
  ],
),
child: const Icon(Icons.school, color: AppColors.primary, size: 44),
```
**Probleme** : Le logo est un container blanc arrondi. En dark, c'est
volontairement blanc (effet de "carte" sur le fond vert fonce).
**Correction** : Aucune (le splash reste branding vert + blanc dans les 2 themes).
**Temps** : 0 min.

**Total splash_screen.dart** : 0 correction necessaire — le splash utilise
volontairement le branding vert Togo plein ecran dans les 2 themes.

---

## 12. `lib/widgets/cards/question_card.dart`

### Lignes 42-43 — `_CardBase(color: AppColors.surface, borderColor: AppColors.primary.withOpacity(0.2))`
**Actuel** :
```dart
return _CardBase(
  color: AppColors.surface,
  borderColor: AppColors.primary.withOpacity(0.2),
  ...
);
```
**Probleme** : `AppColors.surface` const reste blanc en dark — la carte
question reste blanche en dark (illisibile si le fond du Scaffold est
#121212). `_CardBase` prend `Color` (pas BuildContext), il faut donc le
modifier pour passer `BuildContext` ou wrapper dans un `Builder`.
**Correction** : Utiliser `Builder` pour recuperer le context :
```dart
return Builder(
  builder: (context) => _CardBase(
    color: AdaptiveColors.surface(context),
    borderColor: AppColors.primary.withOpacity(0.2),
    ...
  ),
);
```
**Temps** : 1 min.

### Lignes 53, 58 — `AppColors.primarySurface` et `AppColors.primary` (chip chapitre)
**Actuel** :
```dart
decoration: BoxDecoration(
  color: AppColors.primarySurface,
  borderRadius: BorderRadius.circular(8),
),
child: Text(
  question.chapitre,
  style: AppTextStyles.label.copyWith(color: AppColors.primary),
),
```
**Correction** :
```dart
decoration: BoxDecoration(
  color: AdaptiveColors.primarySurface(context),
  borderRadius: BorderRadius.circular(8),
),
child: Text(
  question.chapitre,
  style: AppTextStyles.label.copyWith(color: AppColors.primary),
),
```
**Temps** : 1 min.

### Lignes 65, 73, 81, 92 — `AppTextStyles.bodySmall`, `AppColors.primary`, `AppTextStyles.questionText`
**Actuel** :
```dart
Text('${question.points} pts', style: AppTextStyles.bodySmall),
const Icon(Icons.help_outline, size: 32, color: AppColors.primary),
Text(question.enonce, style: AppTextStyles.questionText),
Text('Appuyez sur "Voir la réponse"...',
  style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
```
**Probleme** : `bodySmall` et `questionText` utilisent des couleurs const
gris/noir qui restent peu lisibles en dark.
**Correction** :
```dart
Text('${question.points} pts',
  style: AppTextStyles.bodySmall.copyWith(color: AdaptiveColors.textSecondary(context))),
const Icon(Icons.help_outline, size: 32, color: AppColors.primary),
Text(question.enonce,
  style: AppTextStyles.questionText.copyWith(color: AdaptiveColors.textPrimary(context))),
Text('Appuyez sur "Voir la réponse"...',
  style: AppTextStyles.bodySmall.copyWith(
    fontStyle: FontStyle.italic,
    color: AdaptiveColors.textSecondary(context),
  )),
```
**Temps** : 2 min.

### Lignes 108-109 — `_buildReponse _CardBase color: AppColors.primarySurface`
**Actuel** :
```dart
child: _CardBase(
  color: AppColors.primarySurface,
  borderColor: AppColors.primary.withOpacity(0.4),
  ...
),
```
**Correction** : Wrapper dans un Builder et utiliser `AdaptiveColors` :
```dart
child: Builder(
  builder: (context) => _CardBase(
    color: AdaptiveColors.primarySurface(context),
    borderColor: AppColors.primary.withOpacity(0.4),
    ...
  ),
),
```
**Temps** : 1 min.

### Lignes 119, 124, 132, 144, 155, 158, 167, 171 — `_buildReponse` internals
**Actuel** :
```dart
decoration: BoxDecoration(
  color: AppColors.primary,
  borderRadius: BorderRadius.circular(8),
),
child: Text('Réponse',
  style: AppTextStyles.label.copyWith(color: Colors.white)),
...
const Icon(Icons.check_circle_outline, size: 32, color: AppColors.primary),
Text(question.reponse,
  style: AppTextStyles.questionText.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.w600,
  )),
...
decoration: BoxDecoration(
  color: AppColors.surface,  // encart explication
  borderRadius: BorderRadius.circular(10),
  border: Border.all(
    color: AppColors.primary.withOpacity(0.2),
  ),
),
...
Text('Explication',
  style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
Text(question.explication!, style: AppTextStyles.body),
```
**Correction** :
```dart
decoration: BoxDecoration(
  color: AdaptiveColors.primary(context),  // ou AppColors.primary
  borderRadius: BorderRadius.circular(8),
),
child: Text('Réponse',
  style: AppTextStyles.label.copyWith(
    color: AdaptiveColors.onPrimary(context),
  )),
...
const Icon(Icons.check_circle_outline, size: 32, color: AppColors.primary),
Text(question.reponse,
  style: AppTextStyles.questionText.copyWith(
    color: AdaptiveColors.primary(context),
    fontWeight: FontWeight.w600,
  )),
...
decoration: BoxDecoration(
  color: AdaptiveColors.surface(context),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(
    color: AppColors.primary.withOpacity(0.2),
  ),
),
...
Text('Explication',
  style: AppTextStyles.label.copyWith(color: AdaptiveColors.textSecondary(context))),
Text(question.explication!,
  style: AppTextStyles.body.copyWith(color: AdaptiveColors.textPrimary(context))),
```
**Temps** : 3 min.

### Lignes 209-213 — `_CardBase` boxShadow `Colors.black.withOpacity(0.06)`
**Actuel** :
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 16,
    offset: const Offset(0, 4),
  ),
],
```
**Correction** : Faire que `_CardBase` prenne un `BuildContext` (ou wrapper
les appels dans un `Builder`) et utiliser `AdaptiveColors.shadow(context)`.
**Temps** : 2 min.

**Total question_card.dart** : ~8 corrections, ~10 minutes.

---

## 13. `lib/widgets/buttons/srs_buttons.dart`

### Lignes 17-19 — `Text('Comment tu t\'en es sorti ?', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500))`
**Probleme** : `bodySmall` couleur const (#757575) reste gris moyen en dark
sur fond #121212 (contraste 4.6:1 — limite WCAG AA).
**Correction** :
```dart
Text('Comment tu t\'en es sorti ?',
  style: AppTextStyles.bodySmall.copyWith(
    fontWeight: FontWeight.w500,
    color: AdaptiveColors.textSecondary(context),
  )),
```
(Note : le widget `SrsButtons` n'a pas de BuildContext en champ, il faut
l'obtenir dans `build(BuildContext context)` qui existe deja — verifier que
le `context` soit bien accessible a cet endroit.)
**Temps** : 1 min.

### Lignes 99-101, 105 — `_SrsButton Material color: color.withOpacity(0.10)`
**Actuel** :
```dart
return Material(
  color: color.withOpacity(0.10),
  borderRadius: BorderRadius.circular(14),
  child: InkWell(
    onTap: () => onTap(quality),
    borderRadius: BorderRadius.circular(14),
    splashColor: color.withOpacity(0.2),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      ...
```
**Probleme** : En dark, `color.withOpacity(0.10)` est tres peu visible sur
fond #121212 (les 4 boutons SRS deviennent presque transparents).
`color.withOpacity(0.35)` pour la bordure reste OK.
**Correction** : Augmenter l'opacite du fond en dark :
```dart
return Material(
  color: color.withOpacity(context.isDark ? 0.20 : 0.10),
  borderRadius: BorderRadius.circular(14),
  child: InkWell(
    onTap: () => onTap(quality),
    borderRadius: BorderRadius.circular(14),
    splashColor: color.withOpacity(0.3),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(context.isDark ? 0.50 : 0.35),
          width: 1.5,
        ),
      ),
      ...
```
(Note : `_SrsButton.build(BuildContext context)` existe — on peut utiliser
`context.isDark`.)
**Temps** : 2 min.

### Lignes 114, 118, 122-125 — Icones et textes colors `color` (sémantique)
**Actuel** :
```dart
Icon(icon, color: color, size: 26),
Text(label, style: AppTextStyles.button.copyWith(color: color, fontSize: 13)),
Text(sublabel,
  style: AppTextStyles.label.copyWith(
    color: color.withOpacity(0.75),
    fontSize: 10,
  ),
  textAlign: TextAlign.center,
),
```
**Probleme** : `color` est une couleur sémantique (facile, info, difficile,
echec) — OK en dark. `color.withOpacity(0.75)` pour le sublabel reste OK
en dark (opacite 75% sur une couleur vive = contraste suffisant).
**Correction** : Aucune pour les couleurs. Eventuellement augmenter l'opacite
du sublabel en dark (0.85) :
```dart
Text(sublabel,
  style: AppTextStyles.label.copyWith(
    color: color.withOpacity(context.isDark ? 0.85 : 0.75),
    fontSize: 10,
  ),
  textAlign: TextAlign.center,
),
```
**Temps** : 1 min.

**Total srs_buttons.dart** : ~4 corrections, ~4 minutes.

---

## Synthese — Total des corrections

| Fichier | Nb corrections | Temps estime |
|---|---:|---:|
| `lib/main.dart` | 0 | 0 min |
| `lib/screens/home/home_screen.dart` | ~10 | 10 min |
| `lib/screens/auth/onboarding_screen.dart` | ~15 | 15 min |
| `lib/screens/revision/revision_screen.dart` | ~15 | 20 min |
| `lib/screens/simulation/simulation_screen.dart` | ~25 | 25 min |
| `lib/screens/dashboard/dashboard_screen.dart` | ~20 | 22 min |
| `lib/screens/community/community_screen.dart` | 1 | 1 min |
| `lib/screens/admin/admin_login_screen.dart` | ~7 | 7 min |
| `lib/screens/admin/admin_dashboard_screen.dart` | ~12 | 12 min |
| `lib/screens/settings/settings_screen.dart` | ~9 | 9 min |
| `lib/screens/splash/splash_screen.dart` | 0 | 0 min |
| `lib/widgets/cards/question_card.dart` | ~8 | 10 min |
| `lib/widgets/buttons/srs_buttons.dart` | ~4 | 4 min |
| **TOTAL** | **~126** | **~135 min (~2h15)** |

## Patterns recurrents a corriger en priorite

Si l'agent de wiring veut aller vite, il peut faire un recherche/remplacement
global sur les patterns suivants (attention aux faux positifs — verifier
chaque occurrence) :

1. **`backgroundColor: AppColors.background`** (Scaffold) → supprimer
   l'attribut. Pattern sure et tres impactant.

2. **`color: AppColors.surface`** dans `Container`/`BoxDecoration`/`Material` →
   `color: AdaptiveColors.surface(context)`.

3. **`color: AppColors.surfaceVariant`** → `color: AdaptiveColors.surfaceVariant(context)`.

4. **`color: AppColors.primarySurface`** → `color: AdaptiveColors.primarySurface(context)`.

5. **`color: AppColors.accentSurface`** → `color: AdaptiveColors.accentSurface(context)`.

6. **`border: Border.all(color: AppColors.divider)`** → `border: Border.all(color: AdaptiveColors.divider(context))`.

7. **`color: Colors.black.withOpacity(0.0X)`** (BoxShadow) →
   `color: AdaptiveColors.shadow(context)`.

8. **`color: color.withOpacity(0.12)`** (chips, badges, fonds teintes) →
   `color: color.withOpacity(context.isDark ? 0.20 : 0.12)`.

9. **`AppTextStyles.h1/h2/h3/body`** (sans copyWith) → ajouter
   `.copyWith(color: AdaptiveColors.textPrimary(context))`.

10. **`AppTextStyles.bodySmall`** (sans copyWith) → ajouter
    `.copyWith(color: AdaptiveColors.textSecondary(context))`.

11. **`.copyWith(color: AppColors.textSecondary)`** →
    `.copyWith(color: AdaptiveColors.textSecondary(context))`.

12. **`.copyWith(color: AppColors.textPrimary)`** →
    `.copyWith(color: AdaptiveColors.textPrimary(context))`.

13. **`.copyWith(color: AppColors.textDisabled)`** →
    `.copyWith(color: AdaptiveColors.textDisabled(context))`.

14. **`AppColors.primaryDark`** (texte sur fond) → `AdaptiveColors.primary(context)`
    (primaryDark #004A26 est illisible sur fond sombre).

## Stratégie recommandee pour l'agent de wiring

1. **Phase 1 — Fondations** (30 min) : Appliquer les patterns 1, 2, 3, 4, 5, 7
   sur tous les fichiers en parallele. Cela regle 80% des bugs visuels.

2. **Phase 2 — Textes** (30 min) : Appliquer les patterns 9, 10, 11, 12, 13, 14.
   Cela rend les textes lisibles.

3. **Phase 3 — Chips et details** (30 min) : Appliquer les patterns 6, 8 sur
   les fichiers restants. Polish final.

4. **Phase 4 — Verification manuelle** (15 min) : Lancer l'app en mode dark
   (`ThemeMode.dark`), parcourir chaque ecran, et corriger les cas restants.

## Risques et precautions

- **`const` keyword** : Remplacer `AppColors.surface` par `AdaptiveColors.surface(context)`
  necessite de retirer le `const` devant le `BoxDecoration` ou `TextStyle`.
  Sinon, le compilateur Flutter refuse (context n'est pas une constante).

- **`Builder` pour les widgets sans BuildContext** : Certains widgets comme
  `_CardBase` (question_card.dart) ou `_buildChip` (revision_screen.dart,
  simulation_screen.dart) ne recoivent pas de `BuildContext` en parametre.
  Pour utiliser `AdaptiveColors`, il faut soit :
  - Ajouter `BuildContext context` aux parametres
  - Wrapper le `return` dans un `Builder(builder: (context) => ...)`.

- **`Theme.of(context)` dans les boucles** : `AdaptiveColors` appelle
  `Theme.of(context)`, ce qui peut echouer si `context` n'est pas monte
  suffisamment dans le tree (hors `build`). Pour les helpers hors
  `build` (ex : `_buildChip` dans `_buildQuestionMeta`), utiliser `Builder`.

- **Tests** : Apres chaque phase, lancer `flutter analyze` et tester
  manuellement en dark mode (`ThemeMode.dark` dans `ThemeProvider`).

## Auteur

Audit realise par l'Agent AP (general-purpose) — Session 3, Vague 2.
Date : 30 juin 2026.
Voir aussi : `lib/theme/README.md`, `lib/theme/adaptive_colors.dart`,
`lib/theme/dark_mode_fixes.dart`.
