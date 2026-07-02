// lib/widgets/math/latex_to_fluttermath.dart
// Convertit la syntaxe LaTeX standard vers la syntaxe acceptée par
// flutter_math_fork (un fork maintenu de flutter_math).
//
// flutter_math_fork supporte l'essentiel du LaTeX mathématique mais avec
// quelques différences de noms de commandes. Ce convertisseur se contente
// de patcher ces cas particuliers et de signaler les constructions non
// supportées (align, cases, etc.) pour activer un fallback texte brut.

class LatexToFlutterMath {
  LatexToFlutterMath._();

  /// Table de conversion des commandes LaTeX -> équivalent flutter_math_fork.
  /// On applique un `replaceAll` simple pour chacune. L'ordre a son importance :
  /// on traite d'abord les séquences les plus longues pour éviter les conflits
  /// (par ex. `\rightarrow` avant `\to` n'a pas d'impact ici mais on garde la
  /// discipline pour faciliter l'extension future).
  static const List<MapEntry<String, String>> _replacements = [
    // Comparaisons
    MapEntry(r'\leq', r'\le'),
    MapEntry(r'\geq', r'\ge'),
    MapEntry(r'\neq', r'\ne'),
    // Flèches
    MapEntry(r'\rightarrow', r'\to'),
    MapEntry(r'\leftarrow', r'\leftarrow'), // compatible tel quel
    MapEntry(r'\leftrightarrow', r'\leftrightarrow'),
    MapEntry(r'\Leftrightarrow', r'\Leftrightarrow'),
    MapEntry(r'\implies', r'\Longrightarrow'),
    MapEntry(r'\iff', r'\Longleftrightarrow'),
    // Ensembles — flutter_math_fork supporte \mathbb{R}, on garde tel quel.
    MapEntry(r'\R', r'\mathbb{R}'),
    MapEntry(r'\N', r'\mathbb{N}'),
    MapEntry(r'\Z', r'\mathbb{Z}'),
    MapEntry(r'\Q', r'\mathbb{Q}'),
    MapEntry(r'\C', r'\mathbb{C}'),
    MapEntry(r'\D', r'\mathbb{D}'),
    // Angles / fonctions usuelles
    MapEntry(r'\deg', r'\text{°}'), // fallback propre pour le degré
    // Espaces fines : \, est supporté tel quel, on le conserve.
  ];

  /// Constructions LaTeX non supportées par flutter_math_fork à ce jour.
  /// Si l'une d'elles est détectée, [MathExpression] basculera en fallback
  /// texte brut monospace.
  static const List<String> _unsupported = [
    r'\begin{align}',
    r'\begin{align*}',
    r'\begin{cases}',
    r'\begin{array}',
    r'\substack',
    r'\overset',
    r'\underset',
    r'\substack',
    r'\boxed',
    r'\textbf',
    r'\mathit',
    r'\mathsf',
    r'\tikz',
    r'\cite',
    r'\ref',
  ];

  /// Convertit une chaîne LaTeX standard en syntaxe flutter_math_fork.
  static String convert(String latex) {
    var result = latex;
    for (final entry in _replacements) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Renvoie `true` si la chaîne LaTeX est compatible flutter_math_fork.
  /// `false` déclenche un fallback texte brut (police monospace) côté UI.
  static bool isSupported(String latex) {
    for (final cmd in _unsupported) {
      if (latex.contains(cmd)) return false;
    }
    return true;
  }

  /// Vérifie grossièrement qu'un `$...$` est bien équilibré dans la chaîne
  /// (utile pour les agents générant du contenu). Renvoie `true` si OK.
  static bool isBalanced(String text) {
    final dollarCount = '$'.allMatches(text).length;
    return dollarCount % 2 == 0;
  }
}
