// test/widget/screens/dashboard_screen_test.dart
// Tests for the DashboardScreen — visualisation of student progression.
//
// The DashboardScreen loads its data from:
//   - SharedPreferences 'current_user_id'
//   - Hive box 'users' (AppUser)
//   - Hive box 'review_cards' (ReviewCard[])
//
// We initialise Hive in a temp directory (initHiveForTests) and pre-seed
// the boxes for tests that need a populated user. The empty-state path
// (no user, no cards) is tested without any seeding.
//
// We test:
//   - Loading state shows CircularProgressIndicator.
//   - Empty state (no user data) shows "Bienvenue !" + CTA.
//   - Populated user (bktMaitrise != empty) shows the greeting header.
//   - Populated user shows the "Progression par matière" section.
//   - Populated user shows the "Chapitres à travailler" section.
//
// Prerequisites: Hive adapters must be generated via build_runner. See
// test/README.md "Prerequisites".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:examboost_togo/models/review_card.dart';
import 'package:examboost_togo/models/user.dart';
import 'package:examboost_togo/screens/dashboard/dashboard_screen.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('DashboardScreen widget', () {
    setUpAll(() {
      // Initialise Hive in a temp directory + register adapters.
      initHiveForTests();
      // SharedPreferences mock — point current_user_id to 'test-user'
      // so the dashboard looks up the user we'll seed in the box.
      SharedPreferences.setMockInitialValues({
        'current_user_id': 'test-user',
      });
    });

    /// Helper: open the 'users' Hive box and put [user] inside.
    Future<void> seedUser(AppUser user) async {
      final userBox = await Hive.openBox<AppUser>('users');
      await userBox.put(user.id, user);
    }

    /// Helper: open the 'review_cards' Hive box with the given cards.
    Future<void> seedReviewCards(List<ReviewCard> cards) async {
      final cardBox = await Hive.openBox<ReviewCard>('review_cards');
      for (final c in cards) {
        await cardBox.add(c);
      }
    }

    /// Helper: clear boxes between tests so each test starts fresh.
    Future<void> clearBoxes() async {
      if (Hive.isBoxOpen('users')) {
        await Hive.box<AppUser>('users').clear();
      }
      if (Hive.isBoxOpen('review_cards')) {
        await Hive.box<ReviewCard>('review_cards').clear();
      }
    }

    tearDown(() async => await clearBoxes());

    testWidgets('État de chargement : affiche CircularProgressIndicator',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      // First frame: _loading is true.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('État vide (nouvel utilisateur) : affiche "Bienvenue !"',
        (tester) async {
      // No user in the box, no review cards — the dashboard will fall back
      // to an empty AppUser and the empty-state branch.
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      // Let the postFrameCallback + Hive reads resolve.
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue !'), findsOneWidget);
      expect(
        find.text('Démarrer ma première révision'),
        findsOneWidget,
      );
    });

    testWidgets('Utilisateur avec bktMaitrise : affiche "Bonjour, <prenom> !"',
        (tester) async {
      // Pre-seed a user with bktMaitrise data (using the sample competences).
      final user = createMockUser(
        id: 'test-user',
        prenom: 'Amina',
        nom: 'Badawi',
        bktMaitrise: Map<String, double>.from(sampleBktMaitrise),
      );
      await seedUser(user);

      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pumpAndSettle();

      // The header should greet Amina.
      expect(find.textContaining('Amina'), findsOneWidget);
    });

    testWidgets('Utilisateur avec bktMaitrise : section "Progression par matière" visible',
        (tester) async {
      final user = createMockUser(
        id: 'test-user',
        bktMaitrise: Map<String, double>.from(sampleBktMaitrise),
      );
      await seedUser(user);

      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Progression par matière'), findsOneWidget);
    });

    testWidgets('Utilisateur avec bktMaitrise : section "Chapitres à travailler" visible',
        (tester) async {
      // sampleBktMaitrise has at least one competence < 0.5 (TG-MATHS-EQ1D-001
      // at 0.10) — the weak-chapters section should populate.
      final user = createMockUser(
        id: 'test-user',
        bktMaitrise: Map<String, double>.from(sampleBktMaitrise),
      );
      await seedUser(user);

      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Chapitres à travailler'), findsOneWidget);
    });
  });
}
