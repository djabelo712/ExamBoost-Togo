// lib/widgets/math/math_text.dart
// Widget principal pour afficher un texte mixte : texte normal + formules LaTeX.
//
// Convention : les formules LaTeX sont encadrées par `$...$` dans la chaîne.
// Exemple : "Calculer $A = \frac{b \times h}{2} = 20 \text{ cm}^2$."
//
// Usage typique (remplace `Text` là où des formules peuvent apparaître) :
/// ```dart
/// MathText(text: question.enonce, style: AppTextStyles.questionText);
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart' show MathStyle;

import 'latex_parser.dart';
import 'math_expression.dart';

/// Affiche un texte pouvant contenir des formules LaTeX entre `$...$`.
///
/// - Si aucune formule n'est détectée, renvoie un simple [Text] (performances
///   optimales, préservation de `maxLines`/`overflow`).
/// - Si des formules sont détectées, renvoie un [Wrap] qui alterne [Text] et
///   [MathExpression] en respectant l'alignement demandé.
class MathText extends StatelessWidget {
  /// Texte à afficher, pouvant contenir des blocs `$...$` LaTeX.
  final String text;

  /// Style de texte appliqué aux portions normales ET aux formules.
  final TextStyle? style;

  /// Alignement horizontal (gauche/centre/droite/justifié).
  final TextAlign? textAlign;

  /// Nombre max de lignes (pris en compte uniquement si aucune formule LaTeX).
  /// Le [Wrap] utilisé pour le texte mixte ne supporte pas `maxLines`.
  final int? maxLines;

  /// Comportement de débordement (idem, uniquement sans LaTeX).
  final TextOverflow? overflow;

  /// Espacement horizontal autour de chaque formule LaTeX inline.
  /// Par défaut 2 px de chaque côté pour respirer un peu.
  final double mathPadding;

  /// Style mathématique transmis à [MathExpression] (`text` ou `display`).
  final MathStyle mathStyle;

  /// Multiplicateur de taille de police pour les formules.
  final double mathTextSizeMultiplier;

  /// Couleur forcée pour les formules (sinon reprend `style.color`).
  final Color? mathColor;

  const MathText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.mathPadding = 2.0,
    this.mathStyle = MathStyle.text,
    this.mathTextSizeMultiplier = 1.0,
    this.mathColor,
  });

  @override
  Widget build(BuildContext context) {
    // Cas 1 : texte vide -> Text simple (évite tout widget inutile).
    if (text.isEmpty) {
      return Text('', style: style, textAlign: textAlign);
    }

    // Cas 2 : aucune formule LaTeX -> Text natif (préserve maxLines/overflow).
    if (!LatexParser.containsLatex(text)) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Cas 3 : texte mixte -> Wrap (Text + MathExpression).
    final segments = LatexParser.parse(text);

    // Si après parsing il n'y a qu'un segment non-Latex (cas dégénéré),
    // on retombe sur un Text simple.
    if (segments.length == 1 && !segments.first.isLatex) {
      return Text(
        segments.first.text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Si une seule formule (et rien autour), on la centre si demandé.
    if (segments.length == 1 && segments.first.isLatex) {
      final expr = _buildMath(segments.first.text);
      if (textAlign == TextAlign.center) {
        return Center(child: expr);
      }
      if (textAlign == TextAlign.right) {
        return Align(alignment: Alignment.centerRight, child: expr);
      }
      return Align(alignment: Alignment.centerLeft, child: expr);
    }

    // Cas général : Wrap de segments.
    final wrapAlignment = _wrapAlignment(textAlign);
    return Wrap(
      alignment: wrapAlignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: segments.map((seg) {
        if (seg.isLatex) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: mathPadding),
            child: _buildMath(seg.text),
          );
        }
        return Text(seg.text, style: style);
      }).toList(),
    );
  }

  /// Construit un [MathExpression] en propageant le style et la couleur.
  Widget _buildMath(String latex) {
    return MathExpression(
      latex: latex,
      textStyle: style,
      color: mathColor ?? style?.color,
      textSizeMultiplier: mathTextSizeMultiplier,
      mathStyle: mathStyle,
    );
  }

  /// Convertit un [TextAlign] en [WrapAlignment] équivalent.
  WrapAlignment _wrapAlignment(TextAlign? align) {
    switch (align) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.right:
        return WrapAlignment.end;
      case TextAlign.justify:
        // Wrap ne gère pas la justification ; on se rabat sur start.
        return WrapAlignment.start;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.end:
      case null:
        return WrapAlignment.start;
    }
  }
}
