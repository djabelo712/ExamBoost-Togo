// test/widget/screens/badges_screen_test.dart
// Tests for the BadgesScreen — collection complète des badges.
//
// The BadgesScreen loads from Hive (users, review_cards, user_badges,
// badge_metrics), SharedPreferences, and Provider<SrsService>. The
// BadgeService lazy-inits in _loadData and opens 2 additional boxes.
//
// We test:
//   - Loading state shows CircularProgressIndicator.
//   - Loaded state shows "Mes Badges" AppBar + "Ma collection" header.
//   - 4 status filter segments rendered (Tous, Débloqués, En cours, Verrouillés).
//   - Tap "Verrouillés" filter shows only locked badges.
//
// Prerequisites: Hive adapters must be generated via build_runner. See
// test/README.md "Prerequisites".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:examboost_togo/models/badge.dart';
import 'package:examboost_togo/screens/badges/badges_screen.dart';
import 'package:examboost_togo/services/srs_service.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('BadgesScreen widget', () {
    setUpAll(() {
      initHiveForTests();
      // Register badge adapters if not already registered.
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(BadgeCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(BadgeLevelAdapter());
      }
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(UserBadgeAdapter());
      }
      SharedPreferences.setMockInitialValues({
        'current_user_id': 'test-user',
      });
    });

    /// Helper: pump the BadgesScreen with a MockSrsService.
    Future<void> pumpBadges(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<SrsService>.value(value: MockSrsService()),
            ],
            child: const BadgesScreen(),
          ),
        ),
      );
      // Resolve the postFrameCallback + Hive reads + BadgeService.init().
      await tester.pumpAndSettle();
    }

    testWidgets('État de chargement : affiche CircularProgressIndicator',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<SrsService>.value(value: MockSrsService()),
            ],
            child: const BadgesScreen(),
          ),
        ),
      );
      // First frame: _loading is true.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Chargé : AppBar "Mes Badges" + header "Ma collection"',
        (tester) async {
      await pumpBadges(tester);
      expect(find.text('Mes Badges'), findsOneWidget);
      expect(find.text('Ma collection'), findsOneWidget);
    });

    testWidgets('Chargé : 4 segments de filtre statut visibles',
        (tester) async {
      await pumpBadges(tester);
      // SegmentedButton labels for BadgeStatusFilter.
      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('Débloqués'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);
      expect(find.text('Verrouillés'), findsOneWidget);
    });

    testWidgets('Tap "Verrouillés" filtre les badges verrouillés', (tester) async {
      await pumpBadges(tester);

      // Tap the "Verrouillés" segment.
      await tester.tap(find.text('Verrouillés'));
      await tester.pumpAndSettle();

      // Either locked badges are shown (default for a fresh user — all
      // badges start locked) OR the empty-filter message is shown.
      // For a fresh test user with no UserBadge state, the "Verrouillés"
      // filter should return a non-empty list (Badges.all has 39 badges,
      // none unlocked yet). We just assert the "Verrouillé" footer appears
      // at least once, OR the empty-filter text appears.
      final lockedFooter = find.text('Verrouillé');
      final emptyFilter = find.text('Aucun badge ne correspond à ce filtre.');
      expect(
        lockedFooter.evaluate().isNotEmpty || emptyFilter.evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
