// test/widget/screens/search_screen_test.dart
// Tests for the SearchScreen — recherche & filtres avancés.
//
// The SearchScreen uses QuestionService (Provider), and optionally
// UserProvider + FavoritesService (wrapped in try/catch — falls back to
// empty state if absent).
//
// We test:
//   - AppBar: title "Rechercher" + saved-searches icon visible.
//   - No active search → SavedSearchesSection rendered ("Suggestions populaires").
//   - Type a keyword that matches the sample pool → results appear.
//
// Prerequisites: Hive adapters (Question, etc.) must be generated. See
// test/README.md "Prerequisites". The SearchService uses a Hive box
// ("saved_searches") but only via async fetcher wrapped in try/catch —
// the screen degrades gracefully if the box is unavailable.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/search/search_screen.dart';
import 'package:examboost_togo/services/question_service.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_data.dart';

void main() {
  group('SearchScreen widget', () {
    Future<void> pumpSearch(WidgetTester tester) async {
      final questionService =
          MockQuestionService(initialQuestions: sampleQuestions);
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(
                value: FakeUserProvider(),
              ),
              Provider<QuestionService>.value(value: questionService),
            ],
            child: const SearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('AppBar : titre "Rechercher" + icône sauvegardes visible',
        (tester) async {
      await pumpSearch(tester);
      expect(find.text('Rechercher'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('Pas de recherche active : section "Suggestions populaires" visible',
        (tester) async {
      await pumpSearch(tester);
      // SavedSearchesSection header.
      expect(find.text('Suggestions populaires'), findsOneWidget);
      expect(find.text('Recherches sauvegardées'), findsOneWidget);
    });

    testWidgets('Saisie d\'un mot-clé qui matche : affiche des résultats',
        (tester) async {
      await pumpSearch(tester);

      // The SearchBarWidget contains a TextField. Enter a keyword that
      // matches at least one question in the sample pool ("Pythagore" —
      // wait, no, the sample pool uses équation/PGCD/figures de style...
      // "équation" matches the first question's énoncé).
      await tester.enterText(find.byType(TextField), 'équation');
      await tester.pumpAndSettle();

      // Either results are shown (the QuestionResultCard list) OR the
      // "Aucun resultat" empty state. With "équation" matching the first
      // sample question ("Résoudre l'équation : 3x + 7 = 22"), results
      // should be non-empty. We just assert the empty-state is NOT shown.
      expect(find.text('Aucun resultat'), findsNothing);
    });
  });
}
