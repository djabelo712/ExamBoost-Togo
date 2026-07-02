// test/widget/widgets/svg_figure_test.dart
// Tests for the SvgFigure widget — affiche une figure SVG inline.
//
// The widget resolves `figureId` against [FiguresLibrary]. If unknown,
// a placeholder "Figure introuvable" is shown (no crash). If known,
// the SVG is rendered via flutter_svg's SvgPicture.string.
//
// We test:
//   - Unknown figureId: shows the "Figure introuvable" placeholder.
//   - Unknown figureId: shows the figureId text in the placeholder.
//   - Known figureId: renders without throwing (SvgPicture.string).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:examboost_togo/widgets/figures/svg_figure.dart';

void main() {
  group('SvgFigure widget', () {
    testWidgets('Figure inconnue : affiche "Figure introuvable"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgFigure(figureId: 'figure_inexistante_xyz'),
          ),
        ),
      );

      expect(find.text('Figure introuvable'), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('Figure inconnue : affiche l\'ID dans le placeholder',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgFigure(figureId: 'unknown_id_42'),
          ),
        ),
      );

      // The placeholder shows the figureId in monospace.
      expect(find.text('« unknown_id_42 »'), findsOneWidget);
    });

    testWidgets('Figure connue : rendu via SvgPicture.string (pas de crash)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgFigure(
              figureId: 'triangle_rectangle_3_4_5',
              width: 200,
            ),
          ),
        ),
      );

      // The widget should NOT show the placeholder.
      expect(find.text('Figure introuvable'), findsNothing);
      // The widget should produce a SvgPicture.
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('Figure connue : semanticLabel exposé pour l\'accessibilité',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgFigure(
              figureId: 'cercle_rayon_5',
              width: 150,
              semanticLabel: 'Cercle de rayon 5 cm',
            ),
          ),
        ),
      );

      // The semantics tree should contain the provided label.
      expect(
        find.bySemanticsLabel('Cercle de rayon 5 cm'),
        findsWidgets,
      );
    });
  });
}
