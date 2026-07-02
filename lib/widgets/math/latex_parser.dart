// lib/widgets/math/latex_parser.dart
// Détecte et isole les portions LaTeX dans un texte mixte.
//
// Convention : les formules LaTeX sont encadrées par `$...$` (style Markdown).
// Exemple : "Résoudre $x^2 + 2x + 1 = 0$" -> 2 segments (texte + LaTeX).

/// Un fragment de texte : soit du texte normal, soit une expression LaTeX.
class TextSegment {
  /// Contenu du segment (sans les délimiteurs `$` pour le LaTeX).
  final String text;

  /// `true` si le segment est une formule LaTeX à rendre avec flutter_math_fork.
  final bool isLatex;

  const TextSegment(this.text, {required this.isLatex});

  @override
  String toString() => isLatex ? 'Latex("$text")' : 'Text("$text")';
}

/// Parseur de texte mixte (texte normal + formules LaTeX entre `$...$`).
class LatexParser {
  LatexParser._();

  /// Expression régulière repérant les blocs `$...$` (un seul niveau, non greedy).
  /// On accepte n'importe quel caractère sauf `$` entre les délimiteurs, ce qui
  /// interdit d'imbriquer des `$` mais reste suffisant pour les cas d'usage
  /// pédagogiques (énoncés BAC/BEPC).
  static final RegExp _latexRegex = RegExp(r'\$([^$]+)\$');

  /// Découpe un texte en segments [TextSegment] (texte normal ou LaTeX).
  ///
  /// Renvoie toujours au moins un segment (texte brut si aucun `$...$` trouvé).
  /// Les segments vides (par ex. texte vide avant le premier `$`) sont ignorés
  /// pour éviter d'ajouter des widgets inutiles.
  static List<TextSegment> parse(String text) {
    final segments = <TextSegment>[];
    if (text.isEmpty) return segments;

    int lastEnd = 0;
    for (final match in _latexRegex.allMatches(text)) {
      // Texte précédent le `$` ouvrant.
      if (match.start > lastEnd) {
        final before = text.substring(lastEnd, match.start);
        if (before.isNotEmpty) {
          segments.add(TextSegment(before, isLatex: false));
        }
      }
      // Contenu LaTeX (groupe 1 = entre les deux `$`).
      final latex = match.group(1)!;
      if (latex.isNotEmpty) {
        segments.add(TextSegment(latex, isLatex: true));
      }
      lastEnd = match.end;
    }

    // Texte final après le dernier `$` fermant.
    if (lastEnd < text.length) {
      final after = text.substring(lastEnd);
      if (after.isNotEmpty) {
        segments.add(TextSegment(after, isLatex: false));
      }
    }

    return segments;
  }

  /// Renvoie `true` si le texte contient au moins une formule LaTeX `$...$`.
  static bool containsLatex(String text) {
    return _latexRegex.hasMatch(text);
  }

  /// Échappe une chaîne pour être insérée telle quelle dans un bloc `$...$`.
  /// Pratique pour les agents générant du contenu : `LatexParser.escape("x=1")`
  /// puis encadrement manuel par `$...$`.
  static String escape(String raw) {
    return raw.replaceAll(r'\', r'\\').replaceAll(r'$', r'\$');
  }
}
