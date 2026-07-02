// test/widget/screens/favorites_screen_test.dart
// Tests for the FavoritesScreen — liste des questions favorites de l'élève.
//
// The FavoritesScreen uses UserProvider (currentUserId), FavoritesService
// (getFavorites), and QuestionService (getById). It also calls
// context.go(...) on certain taps (go_router), so we avoid tapping
// navigation-triggering buttons and only verify their presence.
//
// We test:
//   - Empty state: shows "Tu n'as pas encore de favoris" + CTA.
//   - Empty state: shows the favorite_border icon illustration.
//   - Populated state: shows the question count + "Tout reviser" button.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/favorites/favorites_screen.dart';
import 'package:examboost_togo/screens/favorites/services/favorites_service.dart';
import 'package:examboost_togo/services/question_service.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_data.dart';

void main() {
  group('FavoritesScreen widget', () {
    /// Pump the FavoritesScreen with [favoritesService] seeding the
    /// favorites for 'test-user'. The QuestionService uses the sample
    /// question pool so seeded favorites resolve to real Question objects.
    Future<void> pumpFavorites(
      WidgetTester tester, {
      FakeFavoritesService? favoritesService,
    }) async {
      final fav = favoritesService ?? FakeFavoritesService();
      final questionService =
          MockQuestionService(initialQuestions: sampleQuestions);
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              ChangeNotifierProvider<FavoritesService>.value(value: fav),
              Provider<QuestionService>.value(value: questionService),
            ],
            child: const FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('État vide : affiche "Tu n\'as pas encore de favoris"',
        (tester) async {
      await pumpFavorites(tester);
      expect(find.text("Tu n'as pas encore de favoris"), findsOneWidget);
      expect(find.text('Commencer a reviser'), findsOneWidget);
    });

    testWidgets('État vide : icône favorite_border visible (illustration)',
        (tester) async {
      await pumpFavorites(tester);
      // The empty state shows a large favorite_border icon inside a circle.
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('État rempli : compteur + bouton "Tout reviser" visibles',
        (tester) async {
      final fav = FakeFavoritesService();
      // Seed 2 favorites pointing to questions present in the sample pool.
      fav.seedFavorite('user_demo', 'TG-BEPC-MATHS-2022-Q01');
      fav.seedFavorite('user_demo', 'TG-BEPC-MATHS-2021-Q02');

      await pumpFavorites(tester, favoritesService: fav);

      // Header shows the count.
      expect(find.textContaining('2'), findsWidgets);
      expect(find.text('Tout reviser'), findsOneWidget);
      // No empty state.
      expect(find.text("Tu n'as pas encore de favoris"), findsNothing);
    });
  });
}
