// test/integration/badges_unlock_flow_test.dart
// Integration scenario: 1 révision -> badge "Premier pas" débloqué -> dialog
// animation -> badge visible comme débloqué.
//
// LIMITATIONS:
//   The current revision_screen.dart does NOT call BadgeService.checkAndUnlock
//   nor BadgeUnlockDialog.show. The full E2E flow (revision -> unlock -> dialog)
//   requires wiring that is not yet implemented. This test therefore
//   exercises the visual pieces that ARE available today:
//     - The "Premier pas" badge definition (Badges.all constant).
//     - BadgeUnlockDialog showing the "Premier pas" badge (forward animation).
//     - BadgeCard rendering with an unlocked UserBadge.
//   When the wiring lands (revision_screen calls BadgeService.checkAndUnlock
//   and shows the dialog), the test should be extended to pump the router
//   and trigger the unlock via a real revision session.
//
// NOTE: This file imports models that use @HiveType, so it requires the
// generated .g.dart adapters for UserBadge (typeId 9). Run:
//   dart run build_runner build --delete-conflicting-outputs

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:examboost_togo/models/badge.dart';
import 'package:examboost_togo/screens/badges/badge_unlock_dialog.dart';
import 'package:examboost_togo/screens/badges/widgets/badge_card.dart';
import 'package:examboost_togo/theme/app_theme.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: badges unlock flow', () {
    // ─── Step 1: "Premier pas" badge definition ─────────────────
    // Spec: badges_unlock_flow_test.dart — Step 1 (user with 0 badges).
    //
    // We verify that the "Premier pas" badge exists in the catalogue
    // with the expected shape: id, title, requiredValue=1, xpReward=500,
    // category=special, level=or.
    test('Step 1 : "Premier pas" existe dans le catalogue avec le bon shape',
        () {
      // The helper from test_app.dart returns the premier_pas badge.
      final badge = premierPasBadge;

      expect(badge.id, 'premier_pas_or');
      expect(badge.group, 'premier_pas');
      expect(badge.title, 'Premier pas');
      expect(badge.category, BadgeCategory.special);
      expect(badge.level, BadgeLevel.or);
      expect(badge.requiredValue, 1,
          reason: 'Le badge se débloque après 1 révision.');
      expect(badge.xpReward, 500);
    });

    // ─── Step 2: BadgeUnlockDialog shows the badge ──────────────
    // Spec: Step 3 (dialog animation affiché).
    //
    // We pump a MaterialApp that triggers the dialog with the premier_pas
    // badge, then verify the dialog contents (BADGE DÉBLOQUÉ !, badge title,
    // +500 XP, Cool !, Partager).
    testWidgets('Step 2 : BadgeUnlockDialog affiche "BADGE DÉBLOQUÉ !" + titre + XP',
        (tester) async {
      final badge = premierPasBadge;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Trigger the dialog on first frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                BadgeUnlockDialog.show(context, badge: badge);
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      // Let the dialog animation run forward (1.8s controller).
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify the dialog content.
      expect(find.text('BADGE DÉBLOQUÉ !'), findsOneWidget);
      expect(find.text('Premier pas'), findsOneWidget);
      expect(find.textContaining('Niveau Or'), findsOneWidget);
      expect(find.text('+500 XP'), findsOneWidget);

      // The two action buttons are present.
      expect(find.text('Cool !'), findsOneWidget);
      expect(find.text('Partager'), findsOneWidget);
    });

    // ─── Step 3: tapping "Cool !" dismisses the dialog ──────────
    testWidgets('Step 3 : Tap "Cool !" ferme le dialog', (tester) async {
      final badge = premierPasBadge;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                BadgeUnlockDialog.show(context, badge: badge);
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('BADGE DÉBLOQUÉ !'), findsOneWidget);

      // Tap "Cool !" to dismiss.
      await tester.tap(find.text('Cool !'));
      await tester.pumpAndSettle();

      // The dialog is no longer visible.
      expect(find.text('BADGE DÉBLOQUÉ !'), findsNothing);
      expect(find.text('Cool !'), findsNothing);
    });

    // ─── Step 4: BadgeCard renders unlocked state ───────────────
    // Spec: Step 4 (badge visible comme débloqué).
    //
    // We render a BadgeCard with an unlocked UserBadge (progress=1,
    // unlockedAt set) and verify the unlocked state visuals.
    testWidgets('Step 4 : BadgeCard affiche l\'état débloqué (progress = 1)',
        (tester) async {
      final badge = premierPasBadge;
      final userBadge = buildUserBadge(
        badgeId: badge.id,
        progress: 1,
        unlockedAt: DateTime(2026, 7, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeCard(badge: badge, userBadge: userBadge),
          ),
        ),
      );

      // The BadgeCard exposes its state via the `state` getter.
      final card = tester.widget<BadgeCard>(find.byType(BadgeCard));
      expect(card.state, BadgeCardState.unlocked);

      // The badge title is visible (not "???").
      expect(find.text('Premier pas'), findsOneWidget);
    });

    // ─── Step 5: BadgeCard locked vs unlocked contrast ──────────
    // Spec: Step 4 (badge visible comme débloqué, contrast with locked).
    //
    // We render two BadgeCards side-by-side: one locked, one unlocked,
    // and verify the visual difference (the locked card shows "???").
    testWidgets('Step 5 : BadgeCard locked affiche "???", unlocked affiche le titre',
        (tester) async {
      final badge = premierPasBadge;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                // Locked: no userBadge (or progress = 0).
                Expanded(child: BadgeCard(badge: badge)),
                // Unlocked: progress = 1 with unlockedAt.
                Expanded(
                  child: BadgeCard(
                    badge: badge,
                    userBadge: buildUserBadge(
                      badgeId: badge.id,
                      progress: 1,
                      unlockedAt: DateTime.now(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Both cards rendered.
      expect(find.byType(BadgeCard), findsNWidgets(2));

      // The locked card shows "???" once (in the title slot).
      expect(find.text('???'), findsOneWidget);
      // The unlocked card shows "Premier pas" once.
      expect(find.text('Premier pas'), findsOneWidget);
    });

    // ─── Step 6 (forward-looking): revision session -> unlock ───
    // Spec: Step 2 (faire 1 révision -> badge "Premier pas" débloqué).
    //
    // SKIPPED until revision_screen.dart is wired to BadgeService.
    // When the wiring lands, the test should:
    //   1. Pump the router with an authenticated user + mock SrsService.
    //   2. Navigate home -> revision.
    //   3. Answer one question.
    //   4. Assert BadgeUnlockDialog is shown with the premier_pas badge.
    //
    // For now, we just document the expectation.
    test('Step 6 (skip) : révision -> débloquage automatique — non implémenté', () {
      // The wiring (revision_screen -> BadgeService.checkAndUnlock ->
      // BadgeUnlockDialog.show) is not yet implemented. This test is a
      // placeholder for the future integration.
      expect(true, isTrue);
    });
  });
}
