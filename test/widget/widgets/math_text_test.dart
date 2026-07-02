// test/widget/widgets/math_text_test.dart
// Tests for the LatexParser — pure-Dart helper used by MathText.
//
// NOTE: We test `LatexParser` (pure Dart, no Flutter widget pumping)
// rather than the `MathText` widget itself because `MathText` imports
// `flutter_math_fork` (added to pubspec.yaml in Session 4 but not yet
// present in pubspec.lock — `flutter pub get` is required before the
// full widget can be tested).
//
// Once `flutter pub get` has been run, the tests below remain valid
// (they cover the parsing layer that MathText delegates to). Additional
// widget-level tests for MathText (parsing, Wrap vs Text fallback,
// single-formula centering) can be added in a V3 pass.
//
// We test:
//   - LatexParser.containsLatex: true for text with $...$, false otherwise.
//   - LatexParser.parse: splits text + LaTeX into ordered TextSegments.
//   - LatexParser.parse: handles empty string + plain text edge cases.

import 'package:flutter_test/flutter_test.dart';

import 'package:examboost_togo/widgets/math/latex_parser.dart';

void main() {
  group('LatexParser', () {
    group('containsLatex', () {
      test('retourne true pour un texte avec une formule $...$', () {
        expect(LatexParser.containsLatex('Calcule $x^2 + 1$.'), isTrue);
      });

      test('retourne true pour un texte avec plusieurs formules', () {
        expect(
          LatexParser.containsLatex('Soit $a$ et $b$ deux réels.'),
          isTrue,
        );
      });

      test('retourne false pour un texte sans formule', () {
        expect(
          LatexParser.containsLatex('Calcule x^2 + 1.'),
          isFalse,
        );
      });

      test('retourne false pour une chaîne vide', () {
        expect(LatexParser.containsLatex(''), isFalse);
      });
    });

    group('parse', () {
      test('sépare texte + LaTeX dans l\'ordre', () {
        final segments = LatexParser.parse('Calcule $x^2 + 1$.');
        expect(segments.length, 2);
        expect(segments[0].isLatex, isFalse);
        expect(segments[0].text, 'Calcule ');
        expect(segments[1].isLatex, isTrue);
        expect(segments[1].text, r'x^2 + 1');
      });

      test('plusieurs formules : segments alternés', () {
        final segments =
            LatexParser.parse('Soit $a$ et $b$ deux réels.');
        // Expected order: ['Soit ', 'a', ' et ', 'b', ' deux réels.']
        expect(segments.length, 5);
        expect(segments[0].text, 'Soit ');
        expect(segments[0].isLatex, isFalse);
        expect(segments[1].text, 'a');
        expect(segments[1].isLatex, isTrue);
        expect(segments[2].text, ' et ');
        expect(segments[2].isLatex, isFalse);
        expect(segments[3].text, 'b');
        expect(segments[3].isLatex, isTrue);
        expect(segments[4].text, ' deux réels.');
        expect(segments[4].isLatex, isFalse);
      });

      test('texte seul (sans $) : un seul segment non-LaTeX', () {
        final segments = LatexParser.parse('Calcule x^2 + 1.');
        expect(segments.length, 1);
        expect(segments[0].isLatex, isFalse);
        expect(segments[0].text, 'Calcule x^2 + 1.');
      });

      test('chaîne vide : retourne une liste vide', () {
        final segments = LatexParser.parse('');
        expect(segments, isEmpty);
      });

      test('formule en début de texte : segment LaTeX d\'abord', () {
        final segments = LatexParser.parse(r'$x^2$ vaut 4.');
        expect(segments.length, 2);
        expect(segments[0].isLatex, isTrue);
        expect(segments[0].text, r'x^2');
        expect(segments[1].isLatex, isFalse);
        expect(segments[1].text, ' vaut 4.');
      });
    });

    group('escape', () {
      test('échappe les backslashes et dollars', () {
        // LatexParser.escape replaces `\` -> `\\` and `$` -> `\$`.
        final escaped = LatexParser.escape(r'math\with$dollar');
        expect(escaped, r'math\\with\$dollar');
      });

      test('chaîne sans caractères spéciaux : inchangée', () {
        expect(LatexParser.escape('plain text'), 'plain text');
      });
    });
  });
}
