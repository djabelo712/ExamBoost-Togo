// test/widget/widgets/error_state_test.dart
// Tests for the ErrorState widget — état d'erreur générique réutilisable.
//
// Verifies:
//   - Message + description rendered.
//   - Retry button rendered only when onRetry is provided (and showRetry=true).
//   - Tap on retry button calls onRetry.
//   - Error code rendered when provided.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examboost_togo/widgets/states/error_state.dart';

void main() {
  group('ErrorState widget', () {
    testWidgets('Affiche le message + la description + l\'icône', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Impossible de charger les questions',
              description: 'Vérifie ta connexion Internet et réessaie.',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Impossible de charger les questions'), findsOneWidget);
      expect(
        find.text('Vérifie ta connexion Internet et réessaie.'),
        findsOneWidget,
      );
      // Default icon is Icons.error_outline.
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Bouton "Réessayer" rendu seulement si onRetry est fourni',
        (tester) async {
      // Case 1: with onRetry → button visible.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Erreur',
              onRetry: () {},
            ),
          ),
        ),
      );
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Case 2: without onRetry → no button.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(message: 'Erreur'),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('Tap sur "Réessayer" appelle onRetry', (tester) async {
      int retryCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Erreur',
              onRetry: () => retryCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      expect(retryCount, 1);
    });

    testWidgets('Code erreur technique affiché si fourni', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Erreur',
              errorCode: 'ERR_NETWORK_001',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('ERR_NETWORK_001'), findsOneWidget);
    });
  });
}
