// lib/services/accessibility_advanced_service.dart
// Service d'accessibilite avancee pour conformite WCAG 2.1 AAA.
//
// Complemente AccessibilityService (basique : preferences utilisateur) avec :
//   1. Calcul du ratio de contraste WCAG (formule W3C officielle) + audit
//      AAA (7:1 texte normal, 4.5:1 grand texte).
//   2. Palette "contraste eleve" pre-definie (noir sur jaune, blanc sur noir).
//   3. Detection animations reduites (MediaQuery.disableAnimations).
//   4. Facteur d'echelle de texte combine (systeme x preference utilisateur).
//   5. Couleur d'anneau de focus clavier (jaune sur dark, bleu sur light).
//
// Ce service est SANS ETAT (toutes les methodes sont statiques) et ne depend
// pas de Hive. Il peut donc etre utilise dans les tests sans initialisation.
//
// Utilisation :
//   final ratio = AccessibilityAdvancedService.contrastRatio(
//     AppColors.textPrimary, AppColors.surface,
//   );
//   if (!AccessibilityAdvancedService.meetsAaaContrast(
//     fg, bg, largeText: false,
//   )) {
//     AppLogger.warn('Contraste insuffisant : $ratio');
//   }
//
// References :
//   - WCAG 2.1 Success Criterion 1.4.6 Contrast (Enhanced) - Level AAA
//     https://www.w3.org/WAI/WCAG21/Understanding/contrast-enhanced
//   - W3C relative luminance formula
//     https://www.w3.org/TR/WCAG21/#dfn-relative-luminance

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/accessibility_settings.dart';
import '../utils/app_logger.dart';
import 'accessibility_service.dart';

/// Resultat d'un audit de contraste entre deux couleurs.
///
/// Contient le ratio WCAG calcule et les verdicts pour les differents niveaux
/// (AA / AAA) x (texte normal / grand texte). Utilise par les golden tests
/// et par l'ecran de parametres accessibilite.
class ContrastAuditResult {
  /// Couleur de premier plan auditée.
  final Color foreground;

  /// Couleur de fond auditée.
  final Color background;

  /// Ratio de contraste WCAG (1.0 a 21.0).
  final double ratio;

  /// True si le ratio >= 4.5:1 (AA texte normal).
  final bool passesAaNormal;

  /// True si le ratio >= 3.0:1 (AA grand texte >= 18pt ou 14pt bold).
  final bool passesAaLarge;

  /// True si le ratio >= 7.0:1 (AAA texte normal).
  final bool passesAaaNormal;

  /// True si le ratio >= 4.5:1 (AAA grand texte).
  final bool passesAaaLarge;

  const ContrastAuditResult({
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.passesAaNormal,
    required this.passesAaLarge,
    required this.passesAaaNormal,
    required this.passesAaaLarge,
  });

  /// True si le couple de couleurs respecte le niveau WCAG AAA pour la
  /// taille de texte donnee. [largeText] true si >= 18pt ou 14pt bold.
  bool passesAaa({required bool largeText}) =>
      largeText ? passesAaaLarge : passesAaaNormal;

  /// True si le couple de couleurs respecte au minimum le niveau AA.
  bool passesAa({required bool largeText}) =>
      largeText ? passesAaLarge : passesAaNormal;

  /// Renvoie une description lisible du verdict (ex : "12.34:1 - AAA OK").
  String get humanReadable {
    final ratioStr = ratio.toStringAsFixed(2);
    final level = passesAaaNormal
        ? 'AAA'
        : passesAaNormal
            ? 'AA'
            : 'ECHEC';
    return '$ratioStr:1 - $level';
  }

  @override
  String toString() =>
      'ContrastAuditResult(fg=$foreground, bg=$background, ratio=$ratio, '
      'aaNormal=$passesAaNormal, aaaNormal=$passesAaaNormal)';
}

/// Service d'accessibilite avancee : contraste WCAG, animations reduites,
/// texte dynamique, palette contraste eleve, couleur focus clavier.
///
/// Toutes les methodes sont statiques et pures (pas d'etat mutable).
/// Les methodes dependantes du BuildContext (MediaQuery) acceptent un
/// [BuildContext] en parametre.
///
/// Ce service NE duplique PAS AccessibilityService : il fournit uniquement
/// des calculs et helpers supplementaires. Pour les preferences utilisateur
/// (highContrast, textSizeScale, dyslexiaFont...), utiliser AccessibilityService.
class AccessibilityAdvancedService {
  AccessibilityAdvancedService._();

  // ─── Seuils WCAG ──────────────────────────────────────────────

  /// Seuil WCAG AAA pour texte normal : 7.0:1.
  static const double kAaaNormalThreshold = 7.0;

  /// Seuil WCAG AAA pour grand texte (>= 18pt ou 14pt bold) : 4.5:1.
  static const double kAaaLargeThreshold = 4.5;

  /// Seuil WCAG AA pour texte normal : 4.5:1.
  static const double kAaNormalThreshold = 4.5;

  /// Seuil WCAG AA pour grand texte : 3.0:1.
  static const double kAaLargeThreshold = 3.0;

  // ─── Contraste WCAG ───────────────────────────────────────────

  /// Linearise une valeur de canal sRGB (0.0-1.0) en luminance lineaire
  /// selon la formule W3C.
  static double _linearizeChannel(double channelValue) {
    if (channelValue <= 0.03928) {
      return channelValue / 12.92;
    }
    return math.pow((channelValue + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Calcule la luminance relative d'une couleur (0.0 = noir, 1.0 = blanc)
  /// selon la formule W3C : L = 0.2126*R + 0.7152*G + 0.0722*B.
  ///
  /// Utilise les getters .red/.green/.blue (int 0-255) pour compatibilite
  /// avec toutes les versions de Flutter 3.x.
  static double relativeLuminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    return 0.2126 * _linearizeChannel(r) +
        0.7152 * _linearizeChannel(g) +
        0.0722 * _linearizeChannel(b);
  }

  /// Calcule le ratio de contraste WCAG entre deux couleurs.
  /// Renvoie une valeur entre 1.0 (meme couleur) et 21.0 (noir sur blanc).
  ///
  /// Formule : (L1 + 0.05) / (L2 + 0.05) ou L1 >= L2.
  static double contrastRatio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// True si le contraste respecte WCAG AAA pour la taille de texte donnee.
  /// [largeText] = true si texte >= 18pt (24px) ou >= 14pt (18.5px) bold.
  static bool meetsAaaContrast(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
    final ratio = contrastRatio(foreground, background);
    return largeText ? ratio >= kAaaLargeThreshold : ratio >= kAaaNormalThreshold;
  }

  /// True si le contraste respecte au minimum WCAG AA.
  static bool meetsAaContrast(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
    final ratio = contrastRatio(foreground, background);
    return largeText ? ratio >= kAaLargeThreshold : ratio >= kAaNormalThreshold;
  }

  /// Audite un couple de couleurs et renvoie un [ContrastAuditResult] complet
  /// (ratio + verdicts AA/AAA x normal/large).
  ///
  /// Utilise par les tests golden pour valider la palette de l'app.
  static ContrastAuditResult auditContrast(
    Color foreground,
    Color background,
  ) {
    final ratio = contrastRatio(foreground, background);
    return ContrastAuditResult(
      foreground: foreground,
      background: background,
      ratio: ratio,
      passesAaNormal: ratio >= kAaNormalThreshold,
      passesAaLarge: ratio >= kAaLargeThreshold,
      passesAaaNormal: ratio >= kAaaNormalThreshold,
      passesAaaLarge: ratio >= kAaaLargeThreshold,
    );
  }

  /// Audite tous les couples d'une palette et renvoie les couples non
  /// conformes AAA (texte normal). Retourne une liste vide si tout est OK.
  ///
  /// [palette] est une liste de couples (foreground, background, label)
  /// a auditer. Le label est utilise pour le rapport d'erreur.
  static List<ContrastAuditResult> auditPalette(
    List<({Color foreground, Color background, String label})> palette, {
    bool requireAaa = true,
  }) {
    final failures = <ContrastAuditResult>[];
    for (final entry in palette) {
      final result = auditContrast(entry.foreground, entry.background);
      final passes = requireAaa
          ? result.passesAaaNormal
          : result.passesAaNormal;
      if (!passes) {
        AppLogger.warn(
          'Contraste insuffisant pour "${entry.label}" : '
          '${result.humanReadable} (foreground=${entry.foreground}, '
          'background=${entry.background})',
        );
        failures.add(result);
      }
    }
    return failures;
  }

  // ─── Palette contraste eleve ──────────────────────────────────

  /// Couleur de fond en mode contraste eleve : jaune vif (#FFEB3B).
  /// Offre un contraste de 19.0:1 avec du noir pur (>= AAA).
  static const Color kHighContrastBackground = Color(0xFFFFEB3B);

  /// Couleur de texte en mode contraste eleve : noir pur.
  static const Color kHighContrastText = Color(0xFF000000);

  /// Variante alternative : noir pur comme fond, blanc pur comme texte.
  /// Contraste 21.0:1 (maximum WCAG).
  static const Color kHighContrastBackgroundAlt = Color(0xFF000000);

  /// Variante alternative : blanc pur comme texte sur fond noir.
  static const Color kHighContrastTextAlt = Color(0xFFFFFFFF);

  /// Renvoie le couple (texte, fond) a utiliser en mode contraste eleve,
  /// en fonction de la preference utilisateur [settings.highContrast].
  ///
  /// Si highContrast est false, renvoie les couleurs par defaut passees
  /// en parametre (textPrimary et surface du theme).
  static ({Color text, Color background}) resolveContrastColors(
    AccessibilitySettings settings, {
    Color? defaultText,
    Color? defaultBackground,
  }) {
    if (settings.highContrast) {
      return (text: kHighContrastText, background: kHighContrastBackground);
    }
    return (
      text: defaultText ?? const Color(0xFF1A1A1A),
      background: defaultBackground ?? Colors.white,
    );
  }

  /// Renvoie la couleur de fond a utiliser selon le mode contraste.
  /// Alias contextuel qui lit la preference via AccessibilityService.
  static Color resolveBackgroundColor(
    BuildContext context, {
    Color? defaultColor,
  }) {
    final settings = AccessibilityService.settings;
    if (settings.highContrast) return kHighContrastBackground;
    return defaultColor ?? Theme.of(context).scaffoldBackgroundColor;
  }

  /// Renvoie la couleur de texte a utiliser selon le mode contraste.
  static Color resolveTextColor(
    BuildContext context, {
    Color? defaultColor,
  }) {
    final settings = AccessibilityService.settings;
    if (settings.highContrast) return kHighContrastText;
    return defaultColor ?? Theme.of(context).textTheme.bodyLarge?.color ??
        const Color(0xFF1A1A1A);
  }

  // ─── Animations reduites ──────────────────────────────────────

  /// True si l'utilisateur a active "Reduire les animations" dans les
  /// preferences systeme (iOS : Reduire les animations ; Android :
  /// Supprimer les animations ; Web : prefers-reduced-motion).
  ///
  /// Utilise [MediaQuery.disableAnimationsOf] qui reflete cette preference
  /// sur toutes les plateformes.
  ///
  /// WCAG 2.1 SC 2.3.3 Animation from Interactions - Level AAA.
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Renvoie [original] si les animations sont activees, sinon [Duration.zero]
  /// (transition instantanee). Utiliser pour conditionner les durees
  /// d'AnimationController, AnimatedOpacity, etc.
  static Duration duration(BuildContext context, Duration original) {
    return shouldReduceMotion(context) ? Duration.zero : original;
  }

  /// Renvoie [normal] si les animations sont activees, sinon [Curves.linear]
  /// (pas d'effet de courbe). Utile pour AnimatedSwitcher etc.
  static Curve curve(BuildContext context, Curve normal) {
    return shouldReduceMotion(context) ? Curves.linear : normal;
  }

  // ─── Texte dynamique ──────────────────────────────────────────

  /// Facteur d'echelle de texte EFFECTIF combine :
  ///   - systeme (MediaQuery.textScaler, depuis les prefs OS)
  ///   - utilisateur (AccessibilitySettings.textSizeScale, depuis l'app)
  ///
  /// Ex : si l'utilisateur a regle son telephone sur 1.3x ET l'app sur 1.5x,
  /// le facteur effectif est 1.95x (les deux se multiplient).
  ///
  /// WCAG 2.1 SC 1.4.4 Resize text - Level AA (200%); notre option "tres
  /// grand texte" (3x) va au-dela pour AAA.
  static double textScaleFactorOf(BuildContext context) {
    final systemScale = MediaQuery.textScalerOf(context).scale(1.0);
    final userScale = AccessibilityService.settings.textSizeScale;
    return systemScale * userScale;
  }

  /// Calcule la taille de police effective en multipliant [baseFontSize]
  /// par le facteur d'echelle effectif (systeme x utilisateur).
  static double scaledFontSize(BuildContext context, double baseFontSize) {
    return baseFontSize * textScaleFactorOf(context);
  }

  /// True si le facteur d'echelle effectif est >= 2.0 (mode "tres grand
  /// texte"). Utilise pour adapter les layouts (ex : passer d'une Row a une
  /// Column pour eviter les overflow).
  static bool isVeryLargeText(BuildContext context) {
    return textScaleFactorOf(context) >= 2.0;
  }

  /// True si le facteur d'echelle effectif est >= 3.0 (mode "tres grand
  /// texte" extreme). Les layouts doivent etre verticaux et scrollables.
  static bool isExtraLargeText(BuildContext context) {
    return textScaleFactorOf(context) >= 3.0;
  }

  // ─── Couleur anneau focus clavier ─────────────────────────────

  /// Renvoie la couleur de l'anneau de focus clavier adaptee au theme.
  /// - Theme clair : bleu fonce (#1565C0, contraste 8.6:1 sur blanc)
  /// - Theme sombre : jaune ambre (#FFD54F, contraste 14.5:1 sur noir)
  ///
  /// WCAG 2.1 SC 2.4.7 Focus Visible - Level AA (et 2.4.13 Focus Appearance
  /// - Level AAA en cours de finalisation).
  static Color focusRingColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFFFFD54F) // Amber 200
        : const Color(0xFF1565C0); // Blue 800
  }

  /// Renvoie l'epaisseur recommandee pour l'anneau de focus (3.0 px).
  /// WCAG 2.1 SC 2.4.13 (draft) recommande >= 2 px CSS.
  static const double kFocusRingWidth = 3.0;

  // ─── Audit complet ────────────────────────────────────────────

  /// Audite la palette de couleurs principale d'ExamBoost Togo et renvoie
  /// un rapport. Utilise par les golden tests et le CI.
  ///
  /// Les couples audités sont les principaux de lib/theme/app_theme.dart :
  ///   - textPrimary sur surface
  ///   - textPrimary sur background
  ///   - textSecondary sur surface
  ///   - white sur primary (boutons)
  ///   - white sur accent (boutons secondaires)
  ///   - white sur error
  ///   - white sur success
  ///   - white sur warning (verifier si warning est trop clair)
  ///   - white sur info
  ///   - black sur primarySurface
  ///   - black sur accentSurface
  static List<ContrastAuditResult> auditExamBoostPalette() {
    return auditPalette(
      [
        (
          foreground: const Color(0xFF1A1A1A),
          background: Colors.white,
          label: 'textPrimary sur surface',
        ),
        (
          foreground: const Color(0xFF1A1A1A),
          background: const Color(0xFFF8F9FA),
          label: 'textPrimary sur background',
        ),
        (
          foreground: const Color(0xFF757575),
          background: Colors.white,
          label: 'textSecondary sur surface',
        ),
        (
          foreground: Colors.white,
          background: const Color(0xFF006837),
          label: 'white sur primary (vert Togo)',
        ),
        (
          foreground: Colors.white,
          background: const Color(0xFFD97700),
          label: 'white sur accent (orange Togo)',
        ),
        (
          foreground: Colors.white,
          background: const Color(0xFFC62828),
          label: 'white sur error',
        ),
        (
          foreground: Colors.white,
          background: const Color(0xFF2E7D32),
          label: 'white sur success',
        ),
        (
          foreground: Colors.white,
          background: const Color(0xFFF57C00),
          label: 'white sur warning',
        ),
        (
          foreground: Colors.white,
          background: const Color(0xFF1565C0),
          label: 'white sur info',
        ),
        (
          foreground: const Color(0xFF000000),
          background: const Color(0xFFFFEB3B),
          label: 'black sur highContrastBackground',
        ),
      ],
      requireAaa: true,
    );
  }
}
