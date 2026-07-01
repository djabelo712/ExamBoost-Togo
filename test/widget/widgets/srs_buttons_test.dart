// test/widget/widgets/srs_buttons_test.dart
// Tests for the SrsButtons widget.
//
// Verifies:
//   - The 4 quality buttons (Facile=5, Correct=4, Difficile=3, Oublié=1) render.
//   - Tapping each button calls onQualitySelected with the right value.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/widgets/buttons/srs_buttons.dart';

void main() {
  group('SrsButtons widget', () {
    testWidgets('Rend les 4 boutons avec leurs labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SrsButtons(onQualitySelected: (_) {}),
          ),
        ),
      );

      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Difficile'), findsOneWidget);
      expect(find.text('Oublié'), findsOneWidget);
    });

    testWidgets('Affiche le titre "Comment tu t\'en s sorti ?"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SrsButtons(onQualitySelected: (_) {}),
          ),
        ),
      );
      expect(find.textContaining('Comment tu t\'en s sorti'), findsOneWidget);
    });

    testWidgets('Tap "Facile" appelle onQualitySelected avec 5',
        (tester) async {
      int? quality;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SrsButtons(onQualitySelected: (q) => quality = q),
          ),
        ),
      );

      await tester.tap(find.text('Facile'));
      await tester.pump();
      expect(quality, 5);
    });

    testWidgets('Tap "Correct" appelle onQualitySelected avec 4',
        (tester) async {
      int? quality;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SrsButtons(onQualitySelected: (q) => quality = q),
          ),
        ),
      );

      await tester.tap(find.text('Correct'));
      await tester.pump();
      expect(quality, 4);
    });

    testWidgets('Tap "Difficile" appelle onQualitySelected avec 3',
        (tester) async {
      int? quality;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SrsButtons(onQualitySelected: (q) => quality = q),
          ),
        ),
      );

      await tester.tap(find.text('Difficile'));
      await tester.pump();
      expect(quality, 3);
    });

    testWidgets('Tap "Oublié" appelle onQualitySelected avec 1',
        (tester) async {
      int? quality;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SrsButtons(onQualitySelected: (q) => quality = q),
          ),
        ),
      );

      await tester.tap(find.text('Oublié'));
      await tester.pump();
      expect(quality, 1);
    });

    testWidgets('Plusieurs taps successifs appellent le callback plusieurs fois',
        (tester) async {
      final List<int> calls = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SrsButtons(onQualitySelected: (q) => calls.add(q)),
          ),
        ),
      );

      await tester.tap(find.text('Facile'));
      await tester.pump();
      await tester.tap(find.text('Oublié'));
      await tester.pump();
      await tester.tap(find.text('Difficile'));
      await tester.pump();

      expect(calls, [5, 1, 3]);
    });

    testWidgets('Chaque bouton affiche son icône de sentiment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SrsButtons(onQualitySelected: (_) {}),
          ),
        ),
      );

      // Facile = sentiment_very_satisfied
      expect(
        find.byIcon(Icons.sentiment_very_satisfied),
        findsOneWidget,
      );
      // Correct = sentiment_satisfied
      expect(find.byIcon(Icons.sentiment_satisfied), findsOneWidget);
      // Difficile = sentiment_neutral
      expect(find.byIcon(Icons.sentiment_neutral), findsOneWidget);
      // Oublié = sentiment_very_dissatisfied
      expect(
        find.byIcon(Icons.sentiment_very_dissatisfied),
        findsOneWidget,
      );
    });
  });
}
