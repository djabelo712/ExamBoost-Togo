// lib/widgets/math/math_expression.dart
// Widget wrapper autour de flutter_math_fork pour rendre une expression LaTeX.
//
// Sécurités :
// - Conversion automatique LaTeX -> syntaxe flutter_math_fork via
//   [LatexToFlutterMath.convert].
// - Détection des constructions non supportées (align, cases, etc.) qui
//   déclenche un fallback en texte brut monospace.
// - try/catch autour de `Math.tex` pour rattraper toute erreur de parsing
//   et afficher un fallback lisible plutôt qu'un crash.

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'latex_to_fluttermath.dart';

/// Rend une expression LaTeX unique (sans les délimiteurs `$`).
///
/// Pour afficher du texte mixte (texte + formules), utiliser [MathText] qui
/// s'occupe du parsing et alterne `Text` et `MathExpression`.
class MathExpression extends StatelessWidget {
  /// Expression LaTeX à rendre (ex: `"\frac{a}{b}"`, `"x^2 + 2x + 1"`).
  final String latex;

  /// Style de texte appliqué (couleur, taille de police, graisse).
  /// La taille de police est propagée à flutter_math_fork.
  final TextStyle? textStyle;

  /// Couleur de l'expression. Si non nulle, surcharge `textStyle.color`.
  final Color? color;

  /// Multiplicateur de taille de police transmis à flutter_math_fork.
  /// Utile pour grossir les formules en accessibilité.
  final double textSizeMultiplier;

  /// Style mathématique : `MathStyle.text` (inline) ou `MathStyle.display`
  /// (centré, plus aéré). Par défaut `MathStyle.text` car [MathExpression]
  /// est prévu pour un usage inline dans [MathText].
  final MathStyle mathStyle;

  /// Hauteur de ligne minimale du fallback monospace (pour alignement).
  final double? fallbackLineHeight;

  const MathExpression({
    super.key,
    required this.latex,
    this.textStyle,
    this.color,
    this.textSizeMultiplier = 1.0,
    this.mathStyle = MathStyle.text,
    this.fallbackLineHeight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (textStyle ?? DefaultTextStyle.of(context).style)
        .copyWith(color: color ?? textStyle?.color);

    // 1) Construction non supportée -> fallback texte brut monospace.
    if (!LatexToFlutterMath.isSupported(latex)) {
      return _buildFallback(context, effectiveStyle);
    }

    // 2) Conversion LaTeX -> syntaxe flutter_math_fork.
    final converted = LatexToFlutterMath.convert(latex);

    // 3) Rendu via flutter_math_fork avec garde-fou try/catch.
    try {
      return Math.tex(
        converted,
        textStyle: effectiveStyle,
        mathStyle: mathStyle,
        textSizeMultiplier: textSizeMultiplier,
        onErrorFallback: (error) {
          // Erreur de parsing -> fallback monospace lisible.
          // (Le type de `error` est inféré depuis le typedef OnErrorFallback
          //  du package flutter_math_fork ; on l'ignore volontairement ici.)
          return _buildFallback(context, effectiveStyle);
        },
      );
    } catch (e) {
      // Erreur inattendue -> fallback monospace lisible.
      return _buildFallback(context, effectiveStyle);
    }
  }

  /// Fallback universel : affiche le LaTeX brut en police monospace pour
  /// rester lisible même si flutter_math_fork ne sait pas rendre l'expression.
  Widget _buildFallback(BuildContext context, TextStyle effectiveStyle) {
    final fallbackStyle = effectiveStyle.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier', 'monospace'],
    );
    Widget child = Text(latex, style: fallbackStyle);
    if (fallbackLineHeight != null) {
      child = SizedBox(height: fallbackLineHeight, child: child);
    }
    return child;
  }
}
