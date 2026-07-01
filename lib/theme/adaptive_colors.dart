// lib/theme/adaptive_colors.dart
// Couleurs adaptatives pour le dark mode d'ExamBoost Togo.
//
// Le probleme : `AppColors` (dans app_theme.dart) declare des couleurs
// `const` (ex: `AppColors.surface = Color(0xFFFFFFFF)`). Ces valeurs sont
// figees a la compilation et NE s'adaptent PAS au ThemeMode. Resultat :
// tous les widgets qui ecrivent `color: AppColors.surface` affichent du
// blanc meme en theme sombre.
//
// Solution : `AdaptiveColors` fournit les memes couleurs mais calculees
// a l'execution en fonction de `Theme.of(context).brightness`. On les
// utilise dans les widgets via `AdaptiveColors.surface(context)`.
//
// Pour alleger la syntaxe, l'extension `AdaptiveContext` expose des
// getters directement sur `BuildContext` :
//   - `context.bg`
//   - `context.surface`
//   - `context.surfaceVariant`
//   - `context.textPrimary`
//   - `context.textSecondary`
//   - `context.dividerColor`
//   - `context.primarySurface`
//   - `context.accentSurface`
//   - `context.isDark` (bool)
//
// Conventions :
//   - Toutes les methodes prennent un `BuildContext` et retournent un `Color`.
//   - Les couleurs claires sont identiques a celles de `AppColors` pour ne
//     pas introduire de regression visuelle en theme clair.
//   - Les couleurs sombres suivent les recommandations Material 3 dark
//     (#121212 background, #1E1E1E surface, niveaux de gris pour le texte).
//   - Les couleurs sémantiques (success/warning/error) ne sont PAS redefinies
//     ici : elles sont deja disponibles via `AppColors` et restent lisibles
//     sur fond sombre (le theme dark les eclaircit indirectement via les
//     ColorScheme).

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Couleurs adaptatives qui changent selon le ThemeMode.
///
/// Utilisation :
/// ```dart
/// Container(
///   color: AdaptiveColors.surface(context),
///   child: Text('Hello', style: TextStyle(color: AdaptiveColors.textPrimary(context))),
/// )
/// ```
class AdaptiveColors {
  AdaptiveColors._(); // constructeur prive : on n'instancie pas cette classe

  // ─── Backgrounds & surfaces ───────────────────────────────────────

  /// Background principal de l'app (Scaffold).
  /// Clair : #F8F9FA (gris tres clair). Sombre : #121212 (presque noir).
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : AppColors.background;
  }

  /// Surface de base (cards, app bars, bottom sheets).
  /// Clair : #FFFFFF. Sombre : #1E1E1E.
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : AppColors.surface;
  }

  /// Surface variant (champs input, secondary containers).
  /// Clair : #F1F3F4. Sombre : #2C2C2C.
  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : AppColors.surfaceVariant;
  }

  // ─── Textes ───────────────────────────────────────────────────────

  /// Texte principal (titres, corps).
  /// Clair : #1A1A1A (presque noir). Sombre : #EAEAEA (presque blanc).
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEAEAEA)
        : AppColors.textPrimary;
  }

  /// Texte secondaire (sous-titres, hints, meta-info).
  /// Clair : #757575. Sombre : #BDBDBD.
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFBDBDBD)
        : AppColors.textSecondary;
  }

  /// Texte desactive (placeholders, etats disabled).
  /// Clair : #BDBDBD. Sombre : #757575.
  static Color textDisabled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF757575)
        : AppColors.textDisabled;
  }

  // ─── Separateurs ──────────────────────────────────────────────────

  /// Divider / bordures subtiles.
  /// Clair : #E0E0E0. Sombre : #424242.
  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF424242)
        : AppColors.divider;
  }

  // ─── Surfaces teintees (chips, badges, encarts) ───────────────────

  /// Surface primaire (vert tres clair / vert tres fonce).
  /// Utilise pour les chips "matiere", les badges de progression, les
  /// encarts "explication" dans les cartes de reponse.
  /// Clair : #E8F5ED (vert tres clair). Sombre : #1B3D2E (vert fonce).
  static Color primarySurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B3D2E)
        : AppColors.primarySurface;
  }

  /// Surface accent (orange tres clair / orange tres fonce).
  /// Utilise pour les encarts "recommandation", les chips "points",
  /// les badges streak.
  /// Clair : #FFF3E0 (orange tres clair). Sombre : #3D2A0F (orange fonce).
  static Color accentSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3D2A0F)
        : AppColors.accentSurface;
  }

  // ─── Ombres ───────────────────────────────────────────────────────

  /// Couleur d'ombre (BoxShadow).
  /// En dark, les ombres doivent etre plus prononcees (opacite 0.3) car
  /// la surface est deja sombre et l'ombre classique (0.06) est invisible.
  /// Clair : black 6%. Sombre : black 30%.
  static Color shadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.30)
        : Colors.black.withOpacity(0.06);
  }

  // ─── Helpers de couleur sémantique (optionnels) ───────────────────

  /// Couleur primaire adaptative (vert Togo).
  /// En dark, on utilise `primaryLight` (#4CAF7A) pour garantir un
  /// contraste suffisant sur fond sombre.
  /// Clair : #006837. Sombre : #4CAF7A.
  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.primaryLight
        : AppColors.primary;
  }

  /// Couleur accent adaptative (orange Togo).
  /// Clair : #D97700. Sombre : #FFB74D (orange clair).
  static Color accent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.accentLight
        : AppColors.accent;
  }

  /// Couleur "on primary" (texte par-dessus un fond primaire).
  /// En clair : blanc (vert fonce = bon contraste).
  /// En sombre : noir (vert clair = bon contraste).
  static Color onPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
  }

  /// Couleur "on accent" (texte par-dessus un fond accent).
  /// En clair : blanc. En sombre : noir.
  static Color onAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
  }
}

/// Extension sur `BuildContext` pour alleger la syntaxe.
///
/// Au lieu de `AdaptiveColors.surface(context)`, on peut ecrire `context.surface`.
/// Au lieu de `Theme.of(context).brightness == Brightness.dark`, on peut
/// ecrire `context.isDark`.
///
/// Exemple :
/// ```dart
/// Container(
///   color: context.surface,
///   child: Text('Hello', style: TextStyle(color: context.textPrimary)),
/// )
/// ```
extension AdaptiveContext on BuildContext {
  /// True si le theme courant est sombre.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Background principal de l'app.
  Color get bg => AdaptiveColors.background(this);

  /// Surface de base (cards, app bars).
  Color get surface => AdaptiveColors.surface(this);

  /// Surface variant (champs input, containers secondaires).
  Color get surfaceVariant => AdaptiveColors.surfaceVariant(this);

  /// Texte principal.
  Color get textPrimary => AdaptiveColors.textPrimary(this);

  /// Texte secondaire.
  Color get textSecondary => AdaptiveColors.textSecondary(this);

  /// Texte desactive.
  Color get textDisabled => AdaptiveColors.textDisabled(this);

  /// Divider / bordures subtiles.
  /// Note : on evite le nom `divider` car il existe deja sur `BuildContext`
  /// via d'autres extensions Material. On utilise `dividerColor`.
  Color get dividerColor => AdaptiveColors.divider(this);

  /// Surface primaire (vert tres clair / vert tres fonce).
  Color get primarySurface => AdaptiveColors.primarySurface(this);

  /// Surface accent (orange tres clair / orange tres fonce).
  Color get accentSurface => AdaptiveColors.accentSurface(this);

  /// Couleur d'ombre.
  Color get shadowColor => AdaptiveColors.shadow(this);

  /// Couleur primaire adaptative.
  Color get adaptivePrimary => AdaptiveColors.primary(this);

  /// Couleur accent adaptative.
  Color get adaptiveAccent => AdaptiveColors.accent(this);

  /// Couleur "on primary" (texte sur fond primaire).
  Color get onPrimary => AdaptiveColors.onPrimary(this);

  /// Couleur "on accent" (texte sur fond accent).
  Color get onAccent => AdaptiveColors.onAccent(this);
}
