// test/widget/widgets/empty_state_test.dart
// Tests for the EmptyState widget — état vide générique réutilisable.
//
// Verifies:
//   - Title + description rendered.
//   - Action button rendered only when actionLabel is provided.
//   - Tap on action button calls onAction.
//   - Secondary action link rendered when secondaryActionLabel is provided.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examboost_togo/widgets/states/empty_state.dart';

void main() {
  group('EmptyState widget', () {
    testWidgets('Affiche le titre + la description + l\'icône', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Aucune question disponible',
              description: 'Pas encore de questions pour cette matière.',
            ),
          ),
        ),
      );

      expect(find.text('Aucune question disponible'), findsOneWidget);
      expect(find.text('Pas encore de questions pour cette matière.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('Bouton d\'action rendu seulement si actionLabel est fourni',
        (tester) async {
      // Case 1: with actionLabel → button visible.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Titre',
              actionLabel: 'Recharger',
              onAction: () {},
            ),
          ),
        ),
      );
      expect(find.text('Recharger'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Case 2: without actionLabel → no button.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Titre',
            ),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('Tap sur le bouton d\'action appelle onAction', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Titre',
              actionLabel: 'Recharger',
              onAction: () => tapCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Recharger'));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('Lien secondaire rendu si secondaryActionLabel est fourni',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Titre',
              secondaryActionLabel: 'Contacter le support',
              onSecondaryAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Contacter le support'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    // Added by Agent BU2 (Session 4 — reduced widget scope).
    // Verifies the mirror case: with no description, only the title Text
    // is rendered (no orphan placeholder).
    testWidgets('Sans description : seul le titre est rendu comme Text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Titre seul',
              // description, actionLabel and secondaryActionLabel all null.
            ),
          ),
        ),
      );

      expect(find.text('Titre seul'), findsOneWidget);
      // Only the title Text widget is in the tree (no description, no
      // action button label, no secondary action label).
      expect(find.byType(Text), findsOneWidget);
    });

    // Added by Agent BU2 (Session 4 — reduced widget scope).
    // Verifies the secondary link is interactive, not just decorative.
    testWidgets('Tap sur le lien secondaire appelle onSecondaryAction',
        (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Titre',
              secondaryActionLabel: 'Continuer hors-ligne',
              onSecondaryAction: () => tapCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Continuer hors-ligne'));
      await tester.pump();
      expect(tapCount, 1);
    });
  });
}
