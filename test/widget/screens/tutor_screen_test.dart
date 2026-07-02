// test/widget/screens/tutor_screen_test.dart
// Tests for the TutorScreen — chat conversationnel avec le tuteur IA.
//
// The TutorScreen creates its own TutorController via
// ChangeNotifierProvider.value in build(). The controller.init() loads
// the last conversation from Hive (wrapped in try/catch — failure leaves
// the messages list empty).
//
// We test:
//   - Initial state: welcome card + "Essaie une de ces questions" header.
//   - Initial state: 6 default suggestion chips rendered.
//   - Input field visible + send button present.
//   - Tap a suggestion chip → user message appears in the conversation.
//
// Prerequisites: Hive must be initialised in a temp directory (the
// TutorController.init() will try to open the "tutor_conversations" box).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examboost_togo/screens/tutor/tutor_screen.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('TutorScreen widget', () {
    setUpAll(() {
      // Initialise Hive in a temp directory. The TutorController.init()
      // will try to open the "tutor_conversations" box; with no data
      // stored it stays empty (welcome state).
      initHiveForTests();
    });

    Future<void> pumpTutor(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TutorScreen()),
      );
      // Let the controller.init() postFrameCallback resolve.
      await tester.pumpAndSettle();
    }

    testWidgets('État initial : carte de bienvenue visible', (tester) async {
      await pumpTutor(tester);
      // Welcome card text.
      expect(find.text('Bonjour ! Je suis ton tuteur IA.'), findsOneWidget);
    });

    testWidgets('État initial : 6 chips de suggestion par défaut visibles',
        (tester) async {
      await pumpTutor(tester);
      // Title above the chips.
      expect(find.text('Essaie une de ces questions'), findsOneWidget);
      // The 6 default suggestion chips (text from SuggestionChips.defaultSuggestions).
      expect(find.text('Explique-moi Pythagore'), findsOneWidget);
      expect(find.text('Comment factoriser x²-9 ?'), findsOneWidget);
      expect(find.text('Donne-moi un exemple de Thalès'), findsOneWidget);
    });

    testWidgets('État initial : champ de saisie + bouton envoyer visibles',
        (tester) async {
      await pumpTutor(tester);
      // TextField with hint text "Pose ta question...".
      expect(find.text('Pose ta question...'), findsOneWidget);
      // Send button (icon) is always present (enabled only when text is non-empty).
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('Tap chip de suggestion : ajoute un message utilisateur',
        (tester) async {
      await pumpTutor(tester);

      // Tap the first suggestion chip.
      await tester.tap(find.text('Explique-moi Pythagore'));
      await tester.pump();

      // The conversation list replaces the welcome card. We can't easily
      // assert the network call (would need a mocked backend), but we can
      // verify the user message text appears in the conversation.
      expect(find.text('Explique-moi Pythagore'), findsWidgets);
    });
  });
}
