// lib/theme/dark_mode_fixes.dart
// Wrappers de widgets qui s'adaptent automatiquement au dark mode.
//
// Ces wrappers corrigent les problemes courants observes dans les ecrans
// existants d'ExamBoost Togo :
//   - `Scaffold` avec `backgroundColor: AppColors.background` (couleur const,
//     ne s'adapte pas au theme sombre)
//   - `Container` avec `color: AppColors.surface` (idem)
//   - `Card` avec `Colors.white` en dur
//   - Chips avec `color.withOpacity(0.12)` (trop peu opaque en dark)
//
// Ces widgets utilisent `AdaptiveColors` (voir adaptive_colors.dart) pour
// calculer la bonne couleur en fonction du theme.
//
// L'agent de wiring pourra, au fur et a mesure, remplacer dans les ecrans :
//   - `Scaffold(backgroundColor: AppColors.background, ...)` par `AdaptiveScaffold(...)`
//   - `Card(...)` par `AdaptiveCard(...)`
//   - `Container(...)` de chip par `AdaptiveChip(...)`
//
// Voir aussi : docs/DARK_MODE_AUDIT.md pour le detail ecran par ecran.

import 'package:flutter/material.dart';

import 'adaptive_colors.dart';
import 'app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════
// AdaptiveScaffold
// ═══════════════════════════════════════════════════════════════════════

/// Scaffold dont le `backgroundColor` s'adapte automatiquement au theme.
///
/// Remplace :
/// ```dart
/// Scaffold(
///   backgroundColor: AppColors.background,  // BUG : blanc en dark mode
///   body: ...,
/// )
/// ```
/// par :
/// ```dart
/// AdaptiveScaffold(body: ...)
/// ```
///
/// Si vous avez besoin de surcharger le background (par exemple un degrade
/// plein ecran comme le splash), passez `backgroundColor` explicite.
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AdaptiveColors.background(context),
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AdaptiveCard
// ═══════════════════════════════════════════════════════════════════════

/// Carte adaptee au dark mode.
///
/// Remplace les patterns problematiques :
/// ```dart
/// // BUG : AppColors.surface est const (#FFFFFF), reste blanc en dark
/// Container(
///   padding: EdgeInsets.all(16),
///   decoration: BoxDecoration(
///     color: AppColors.surface,
///     borderRadius: BorderRadius.circular(16),
///     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), ...)],
///   ),
///   child: ...,
/// )
/// ```
/// par :
/// ```dart
/// AdaptiveCard(child: ...)
/// ```
///
/// Si la carte doit etre tappable, passez `onTap` (InkWell integre).
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? color; // surcharge optionnelle
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AdaptiveColors.surface(context);
    final defaultShadow = BoxShadow(
      color: AdaptiveColors.shadow(context),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: boxShadow ?? [defaultShadow],
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: child,
            )
          : child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AdaptiveChip
// ═══════════════════════════════════════════════════════════════════════

/// Chip adapte au dark mode.
///
/// Remplace le pattern suivant (present dans revision_screen, simulation_screen,
/// question_card, dashboard_screen, admin_dashboard_screen) :
/// ```dart
/// // BUG : en dark, color.withOpacity(0.12) est presque invisible sur fond sombre
/// Container(
///   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
///   decoration: BoxDecoration(
///     color: color.withOpacity(0.12),
///     borderRadius: BorderRadius.circular(20),
///   ),
///   child: Text(label, style: AppTextStyles.label.copyWith(color: color)),
/// )
/// ```
/// par :
/// ```dart
/// AdaptiveChip(label: 'Mathematiques', color: AppColors.primary)
/// ```
///
/// En dark mode, l'opacite du fond passe de 0.12 a 0.20 pour rester lisible.
class AdaptiveChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final double borderRadius;
  final EdgeInsets padding;
  final TextStyle? labelStyle;

  const AdaptiveChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    final bgOpacity = context.isDark ? 0.20 : 0.12;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: chipColor.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: labelStyle ??
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: chipColor,
                ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AdaptiveBadge (pour les KPI, scores, compteurs)
// ═══════════════════════════════════════════════════════════════════════

/// Badge compact adapte au dark mode (compteur + libelle).
///
/// Remplace `_compteurBadge` dans simulation_screen.dart et `_buildStatCard`
/// dans dashboard_screen.dart (versions compactes).
class AdaptiveBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  const AdaptiveBadge({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bgOpacity = context.isDark ? 0.20 : 0.12;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AdaptiveInfoBanner (encarts explicatifs)
// ═══════════════════════════════════════════════════════════════════════

/// Encart d'information adapte au dark mode (background teinte + bordure).
///
/// Remplace les patterns problematiques :
/// ```dart
/// // BUG : AppColors.primarySurface est const (#E8F5ED clair), reste
/// // vert clair en dark mode (illisible)
/// Container(
///   padding: EdgeInsets.all(12),
///   decoration: BoxDecoration(
///     color: AppColors.primarySurface,
///     borderRadius: BorderRadius.circular(10),
///   ),
///   child: ...,
/// )
/// ```
/// par :
/// ```dart
/// AdaptiveInfoBanner(
///   variant: AdaptiveInfoVariant.primary,
///   icon: Icons.info_outline,
///   child: Text('...'),
/// )
/// ```
class AdaptiveInfoBanner extends StatelessWidget {
  final Widget child;
  final IconData? icon;
  final EdgeInsets padding;
  final double borderRadius;
  final AdaptiveInfoVariant variant;

  const AdaptiveInfoBanner({
    super.key,
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 10,
    this.variant = AdaptiveInfoVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (variant) {
      case AdaptiveInfoVariant.primary:
        bg = AdaptiveColors.primarySurface(context);
        fg = AdaptiveColors.primary(context);
        break;
      case AdaptiveInfoVariant.accent:
        bg = AdaptiveColors.accentSurface(context);
        fg = AdaptiveColors.accent(context);
        break;
      case AdaptiveInfoVariant.success:
        bg = context.isDark
            ? const Color(0xFF1E3A22)
            : const Color(0xFFE8F5E9);
        fg = AppColors.success;
        break;
      case AdaptiveInfoVariant.error:
        bg = context.isDark
            ? const Color(0xFF3A1E1E)
            : const Color(0xFFFFEBEE);
        fg = AppColors.error;
        break;
    }

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: icon != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}

/// Variantes de couleur pour `AdaptiveInfoBanner`.
enum AdaptiveInfoVariant { primary, accent, success, error }

// ═══════════════════════════════════════════════════════════════════════
// AdaptiveProgressBar (LinearProgressIndicator adapte)
// ═══════════════════════════════════════════════════════════════════════

/// Barre de progression adaptee au dark mode.
///
/// Remplace :
/// ```dart
/// // BUG : AppColors.primarySurface const reste vert clair en dark
/// LinearProgressIndicator(
///   backgroundColor: AppColors.primarySurface,
///   valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
/// )
/// ```
/// par :
/// ```dart
/// AdaptiveProgressBar(value: 0.5)
/// ```
class AdaptiveProgressBar extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color? progressColor;
  final Color? backgroundColor;

  const AdaptiveProgressBar({
    super.key,
    required this.value,
    this.minHeight = 4,
    this.progressColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = progressColor ?? AdaptiveColors.primary(context);
    return LinearProgressIndicator(
      value: value,
      minHeight: minHeight,
      backgroundColor:
          backgroundColor ?? color.withOpacity(context.isDark ? 0.20 : 0.12),
      valueColor: AlwaysStoppedAnimation<Color>(color),
    );
  }
}
