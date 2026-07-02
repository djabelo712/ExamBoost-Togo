// test/widget/widgets/favorite_button_test.dart
// Tests for the FavoriteButton widget — bouton coeur réutilisable.
//
// The button consumes FavoritesService via Provider.of(context). We use
// FakeFavoritesService (in-memory) so no Hive box is required.
//
// We test:
//   - Inactive state: favorite_border icon visible (grey).
//   - Active state (seeded favorite): favorite icon visible (red).
//   - Tap toggles the favorite state + snackbar appears.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/screens/favorites/services/favorites_service.dart';
import 'package:examboost_togo/screens/favorites/widgets/favorite_button.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('FavoriteButton widget', () {
    Future<void> pumpFavoriteButton(
      WidgetTester tester, {
      required FakeFavoritesService favoritesService,
      required String questionId,
      required String userId,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FavoritesService>.value(
            value: favoritesService,
            child: Scaffold(
              body: FavoriteButton(
                questionId: questionId,
                userId: userId,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('État inactif : icône favorite_border visible', (tester) async {
      final fav = FakeFavoritesService();
      await pumpFavoriteButton(
        tester,
        favoritesService: fav,
        questionId: 'q1',
        userId: 'u1',
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('État actif (favori pré-existant) : icône favorite pleine visible',
        (tester) async {
      final fav = FakeFavoritesService();
      fav.seedFavorite('u1', 'q1');

      await pumpFavoriteButton(
        tester,
        favoritesService: fav,
        questionId: 'q1',
        userId: 'u1',
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('Tap : bascule l\'état + affiche un snackbar de feedback',
        (tester) async {
      final fav = FakeFavoritesService();
      await pumpFavoriteButton(
        tester,
        favoritesService: fav,
        questionId: 'q1',
        userId: 'u1',
      );

      // Initially inactive.
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Tap to favorite.
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // Now active.
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      // Snackbar feedback.
      expect(find.text('Ajoute aux favoris'), findsOneWidget);
    });

    // Added by Agent BU2 (Session 4 — reduced widget scope).
    // Verifies the round-trip: a second tap toggles the favorite back off
    // and shows the "Retire des favoris" snackbar (with the undo action).
    testWidgets('Second tap : retire le favori + affiche "Retire des favoris"',
        (tester) async {
      final fav = FakeFavoritesService();
      fav.seedFavorite('u1', 'q1');

      await pumpFavoriteButton(
        tester,
        favoritesService: fav,
        questionId: 'q1',
        userId: 'u1',
      );

      // Initially active (seeded).
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Tap to unfavorite.
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      // Now inactive.
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      // Snackbar feedback for the removal.
      expect(find.text('Retire des favoris'), findsOneWidget);
      // Undo action available (only shown when removing an existing fav).
      expect(find.text('Annuler'), findsOneWidget);
    });

    // Added by Agent BU2 (Session 4 — reduced widget scope).
    // Verifies that silent mode suppresses the snackbar while still
    // toggling the underlying service state — used by parent widgets
    // that already provide their own feedback.
    testWidgets('Mode silent : bascule l\'état mais n\'affiche pas de snackbar',
        (tester) async {
      final fav = FakeFavoritesService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FavoritesService>.value(
            value: fav,
            child: Scaffold(
              body: FavoriteButton(
                questionId: 'q1',
                userId: 'u1',
                silent: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially inactive.
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // The service state was toggled.
      expect(fav.isFavorite('u1', 'q1'), isTrue);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      // But no snackbar is shown in silent mode.
      expect(find.text('Ajoute aux favoris'), findsNothing);
    });
  });
}
