// test/integration/favorites_and_notes_flow_test.dart
// Integration scenario: tap heart on a question -> favori ajouté -> Mes Favoris
// -> tap note icon -> NoteEditorSheet -> write note -> save -> Mes Notes -> note visible.
//
// Uses FakeFavoritesService (in-memory, no Hive) + MockQuestionService +
// FakeUserProvider. The full revision-screen -> FavoriteButton wiring is
// not yet implemented in revision_screen.dart, so we drive the FavoriteButton
// directly with a pre-set context to simulate the revision-screen scenario.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/favorites/favorites_screen.dart';
import 'package:examboost_togo/screens/favorites/notes_screen.dart';
import 'package:examboost_togo/screens/favorites/services/favorites_service.dart';
import 'package:examboost_togo/screens/favorites/widgets/favorite_button.dart';
import 'package:examboost_togo/screens/favorites/widgets/favorite_question_card.dart';
import 'package:examboost_togo/screens/favorites/widgets/note_editor_sheet.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';
import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: favorites and notes flow', () {
    late FakeFavoritesService favService;
    late MockQuestionService questionService;
    late FakeUserProvider userProvider;
    late MockSrsService srsService;

    setUp(() {
      favService = FakeFavoritesService();
      questionService = MockQuestionService(initialQuestions: sampleQuestions);
      userProvider = FakeUserProvider(user: createTestUser());
      srsService = MockSrsService();
    });

    List<SingleChildWidget> providers() => [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          Provider<QuestionService>.value(value: questionService),
          Provider<SrsService>.value(value: srsService),
          ChangeNotifierProvider<FavoritesService>.value(value: favService),
        ];

    // The first maths question (used as the "question 1" of the spec).
    Question get q1 => sampleQuestions.firstWhere((q) => q.matiere == 'Mathématiques');

    // ─── Step 1: FavoriteButton tap adds the favorite ────────────
    // Spec: Step 1-2 (user en révision -> tap coeur -> favori ajouté).
    testWidgets('Step 1 : Tap coeur ajoute la question aux favoris',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: providers(),
            child: Scaffold(
              body: FavoriteButton(
                questionId: q1.id,
                userId: 'test-user',
              ),
            ),
          ),
        ),
      );

      // Initially not a favorite (border icon).
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Tap the heart.
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // Now it's a favorite (filled icon).
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // The service agrees.
      expect(favService.isFavorite('test-user', q1.id), isTrue);
      expect(favService.favoritesCount('test-user'), 1);
    });

    // ─── Step 2: FavoritesScreen shows the favorited question ────
    // Spec: Step 3 (aller à Mes Favoris -> question 1 visible).
    testWidgets('Step 2 : FavoritesScreen affiche la question favorite',
        (tester) async {
      // Pre-populate the favorite.
      await favService.toggleFavorite('test-user', q1.id);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: providers(),
            child: const FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The AppBar shows "Mes favoris".
      expect(find.text('Mes favoris'), findsOneWidget);

      // The header counter shows "1 question favorite".
      expect(find.textContaining('1'), findsWidgets);

      // The question's enonce (truncated to 60 chars) is visible via
      // FavoriteQuestionCard. We check for a substring of the enonce.
      expect(find.textContaining(q1.enonce.substring(0, 10)), findsOneWidget);

      // The "Reviser" button is visible on the card.
      expect(find.text('Reviser'), findsOneWidget);
    });

    // ─── Step 3: tap note icon opens NoteEditorSheet ─────────────
    // Spec: Step 4 (tap icône note -> ouvre NoteEditorSheet).
    testWidgets('Step 3 : Tap icône note ouvre le NoteEditorSheet',
        (tester) async {
      // Pre-populate the favorite.
      await favService.toggleFavorite('test-user', q1.id);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: providers(),
            child: const FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The FavoriteQuestionCard shows the "note_add_outlined" icon (no
      // existing note). Tap it to open the NoteEditorSheet.
      final noteIcon = find.byIcon(Icons.note_add_outlined);
      expect(noteIcon, findsOneWidget);
      await tester.tap(noteIcon);
      await tester.pumpAndSettle();

      // The NoteEditorSheet is now visible. Its header reads
      // "Ajouter une note".
      expect(find.text('Ajouter une note'), findsOneWidget);
      // The "Sauvegarder" button is present (disabled until text is entered).
      expect(find.text('Sauvegarder'), findsOneWidget);
      // The "Annuler" button is present.
      expect(find.text('Annuler'), findsOneWidget);
    });

    // ─── Step 4: write a note + save ─────────────────────────────
    // Spec: Steps 5-6 (écrire note "Astuce : factoriser d'abord" -> sauver).
    testWidgets('Step 4 : Écrire + sauvegarder une note via NoteEditorSheet',
        (tester) async {
      // Pre-populate the favorite.
      await favService.toggleFavorite('test-user', q1.id);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: providers(),
            child: const FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the NoteEditorSheet.
      await tester.tap(find.byIcon(Icons.note_add_outlined));
      await tester.pumpAndSettle();

      // Type the note text.
      const noteText = 'Astuce : factoriser d\'abord';
      await tester.enterText(find.byType(TextField), noteText);
      await tester.pumpAndSettle();

      // Tap "Sauvegarder".
      await tester.tap(find.text('Sauvegarder'));
      await tester.pumpAndSettle();

      // The sheet is closed.
      expect(find.text('Ajouter une note'), findsNothing);

      // The service now has the note.
      final note = favService.getNote('test-user', q1.id);
      expect(note, isNotNull);
      expect(note!.content, noteText);
    });

    // ─── Step 5: NotesScreen shows the saved note ────────────────
    // Spec: Step 7-8 (aller à Mes Notes -> note visible).
    testWidgets('Step 5 : NotesScreen affiche la note sauvegardée',
        (tester) async {
      // Pre-populate the favorite + note.
      await favService.toggleFavorite('test-user', q1.id);
      await favService.saveNote(
        userId: 'test-user',
        questionId: q1.id,
        content: 'Astuce : factoriser d\'abord',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: providers(),
            child: const NotesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The AppBar shows "Mes notes".
      expect(find.text('Mes notes'), findsOneWidget);

      // The counter shows "1 note affichee".
      expect(find.textContaining('1'), findsWidgets);

      // The note content is visible.
      expect(find.textContaining('Astuce'), findsOneWidget);
      expect(find.textContaining('factoriser'), findsOneWidget);
    });

    // ─── Step 6: favorite can be removed ─────────────────────────
    // Bonus: tap the filled heart to remove the favorite.
    testWidgets('Step 6 : Tap coeur rempli retire le favori', (tester) async {
      // Pre-populate the favorite.
      await favService.toggleFavorite('test-user', q1.id);
      expect(favService.isFavorite('test-user', q1.id), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: providers(),
            child: Scaffold(
              body: FavoriteButton(
                questionId: q1.id,
                userId: 'test-user',
              ),
            ),
          ),
        ),
      );

      // The filled heart is visible.
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Tap to remove.
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      // The border heart is back.
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(favService.isFavorite('test-user', q1.id), isFalse);
    });

    // ─── Step 7: FavoriteQuestionCard with existing note ────────
    // Bonus: when a note exists, the FavoriteQuestionCard shows the
    // "sticky_note_2" icon (instead of note_add_outlined).
    testWidgets('Step 7 : FavoriteQuestionCard avec note existante affiche sticky_note_2',
        (tester) async {
      // Pre-populate favorite + note.
      await favService.toggleFavorite('test-user', q1.id);
      await favService.saveNote(
        userId: 'test-user',
        questionId: q1.id,
        content: 'Astuce test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: providers(),
            child: const FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The "sticky_note_2" icon is shown (note exists).
      expect(find.byIcon(Icons.sticky_note_2), findsOneWidget);
      // The "note_add_outlined" icon is NOT shown.
      expect(find.byIcon(Icons.note_add_outlined), findsNothing);
    });

    // ─── Step 8: NoteEditorSheet edit mode ───────────────────────
    // Bonus: opening the NoteEditorSheet with an existing note shows
    // "Modifier la note" and the "Supprimer" button.
    testWidgets('Step 8 : NoteEditorSheet mode édition affiche "Modifier la note" + Supprimer',
        (tester) async {
      // Pre-populate favorite + note.
      await favService.toggleFavorite('test-user', q1.id);
      await favService.saveNote(
        userId: 'test-user',
        questionId: q1.id,
        content: 'Note initiale',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: providers(),
            child: const FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the NoteEditorSheet (now in edit mode since a note exists).
      await tester.tap(find.byIcon(Icons.sticky_note_2));
      await tester.pumpAndSettle();

      // The header reads "Modifier la note" (not "Ajouter une note").
      expect(find.text('Modifier la note'), findsOneWidget);
      // The "Supprimer" button is visible (edit mode only).
      expect(find.text('Supprimer'), findsOneWidget);
      // The existing note content is pre-filled in the TextField.
      expect(find.text('Note initiale'), findsOneWidget);
    });
  });
}
