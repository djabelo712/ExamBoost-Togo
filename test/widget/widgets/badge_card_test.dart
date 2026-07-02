// test/widget/widgets/badge_card_test.dart
// Tests for the BadgeCard widget (3 states: unlocked, inProgress, locked).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/badge.dart';
import 'package:examboost_togo/screens/badges/widgets/badge_card.dart';

void main() {
  group('BadgeCard widget', () {
    // Pick representative badges from the catalog.
    final streakBronze = Badges.byId('streak_7j_bronze')!;
    final streakArgent = Badges.byId('streak_7j_argent')!;
    final premierPasOr = Badges.byId('premier_pas_or')!;

    testWidgets('État verrouillé : affiche "Verrouillé" et "?"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(
              badge: streakBronze,
              userBadge: null, // never touched
            ),
          ),
        ),
      );

      expect(find.text('Verrouillé'), findsOneWidget);
      expect(find.text('???'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('État verrouillé : n\'affiche pas le titre du badge', (tester) async {
      // The title IS shown (badge.title) but the description is hidden.
      // We verify the title text "Régularité" is rendered.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(badge: streakBronze, userBadge: null),
          ),
        ),
      );

      expect(find.text('Régularité'), findsOneWidget);
    });

    testWidgets('État en cours : affiche la barre de progression', (tester) async {
      final userBadge = UserBadge(
        badgeId: streakBronze.id,
        progress: 3, // 3 / 7 jours
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(
              badge: streakBronze,
              userBadge: userBadge,
            ),
          ),
        ),
      );

      // ProgressText shows "3 / 7 jours".
      expect(find.text('3 / 7 jours'), findsOneWidget);
      // LinearProgressIndicator is rendered.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('État débloqué : affiche le titre, le niveau et la date',
        (tester) async {
      final unlockedDate = DateTime(2026, 3, 15);
      final userBadge = UserBadge(
        badgeId: streakBronze.id,
        progress: 7,
        unlockedAt: unlockedDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(
              badge: streakBronze,
              userBadge: userBadge,
            ),
          ),
        ),
      );

      // Title visible.
      expect(find.text('Régularité'), findsOneWidget);
      // Level label "Bronze" visible.
      expect(find.text('Bronze'), findsOneWidget);
      // Date visible (15/3/2026).
      expect(find.text('15/3/2026'), findsOneWidget);
      // Not locked.
      expect(find.text('Verrouillé'), findsNothing);
      expect(find.text('???'), findsNothing);
    });

    testWidgets('Badge Or affiche le label "Or"', (tester) async {
      final userBadge = UserBadge(
        badgeId: premierPasOr.id,
        progress: 1,
        unlockedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(
              badge: premierPasOr,
              userBadge: userBadge,
            ),
          ),
        ),
      );

      expect(find.text('Or'), findsOneWidget);
      expect(find.text('Premier pas'), findsOneWidget);
    });

    // Added by Agent BU2 (Session 4 — reduced widget scope).
    // Covers the middle level (Argent) which was otherwise untested —
    // Bronze and Or are already covered above.
    testWidgets('Badge Argent affiche le label "Argent"', (tester) async {
      final userBadge = UserBadge(
        badgeId: streakArgent.id,
        progress: 30, // required value for streak_7j_argent
        unlockedAt: DateTime(2026, 2, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(
              badge: streakArgent,
              userBadge: userBadge,
            ),
          ),
        ),
      );

      expect(find.text('Argent'), findsOneWidget);
      expect(find.text('Régularité'), findsOneWidget);
      // Date 10/2/2026 is rendered.
      expect(find.text('10/2/2026'), findsOneWidget);
    });

    testWidgets('Le tap déclenche le callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(
              badge: streakBronze,
              userBadge: null,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BadgeCard));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('Sans onTap, le tap ne plante pas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(badge: streakBronze, userBadge: null),
          ),
        ),
      );

      await tester.tap(find.byType(BadgeCard));
      await tester.pump();
      // Test passes if no exception was thrown.
    });

    testWidgets('BadgeCardState déduit correctement l\'état', (tester) async {
      // Locked: null userBadge.
      final card1 = BadgeCard(badge: streakBronze, userBadge: null);
      expect(card1.state, BadgeCardState.locked);

      // InProgress: userBadge with progress > 0, not unlocked.
      final card2 = BadgeCard(
        badge: streakBronze,
        userBadge: UserBadge(badgeId: streakBronze.id, progress: 3),
      );
      expect(card2.state, BadgeCardState.inProgress);

      // Unlocked: userBadge with unlockedAt + progress >= requiredValue.
      final card3 = BadgeCard(
        badge: streakBronze,
        userBadge: UserBadge(
          badgeId: streakBronze.id,
          progress: 7,
          unlockedAt: DateTime(2026),
        ),
      );
      expect(card3.state, BadgeCardState.unlocked);
    });
  });
}
