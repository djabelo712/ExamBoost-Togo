// test/integration/tutor_conversation_flow_test.dart
// Integration scenario: tap suggestion -> user message (right) -> typing
// indicator -> assistant message (left).
//
// The full TutorScreen pumps a real TutorController that hits the backend
// via dio (TutorService.ask). Without a backend, the controller emits an
// error bubble. To keep the integration test deterministic and fast, we:
//   - Test the FakeTutorController (from test_app.dart) at the logic level:
//     ask() -> user message -> loading -> assistant message.
//   - Test the visual components (SuggestionChips, MessageBubble, TypingIndicator)
//     at the widget level.
//   - Test a composed conversation: a Column of MessageBubbles driven by the
//     FakeTutorController's messages list, mimicking what the real
//     TutorScreen renders.
//
// When the TutorScreen is updated to accept an injected TutorController (or
// TutorService), the test should be extended to pump the real screen end-to-end.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/screens/tutor/models/chat_message.dart';
import 'package:examboost_togo/screens/tutor/tutor_controller.dart';
import 'package:examboost_togo/screens/tutor/widgets/message_bubble.dart';
import 'package:examboost_togo/screens/tutor/widgets/suggestion_chips.dart';
import 'package:examboost_togo/screens/tutor/widgets/typing_indicator.dart';
import 'package:examboost_togo/theme/app_theme.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: tutor conversation flow', () {
    // ─── Step 1: SuggestionChips renders the Pythagore suggestion ──
    // Spec: Step 2 (aller à TutorScreen — suggestion visible).
    testWidgets('Step 1 : SuggestionChips affiche "Explique-moi Pythagore"',
        (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionChips(
              onSelected: (s) => selected = s,
            ),
          ),
        ),
      );

      // Default suggestions include the Pythagore chip.
      expect(find.text('Explique-moi Pythagore'), findsOneWidget);
      expect(find.text('Essaie une de ces questions'), findsOneWidget);

      // Tap the Pythagore chip.
      await tester.tap(find.text('Explique-moi Pythagore'));
      await tester.pumpAndSettle();

      // The callback was fired with the chip text.
      expect(selected, 'Explique-moi Pythagore');
    });

    // ─── Step 2: MessageBubble for user message is right-aligned ──
    // Spec: Step 3 (message utilisateur affiché à droite).
    testWidgets('Step 2 : MessageBubble user aligné à droite (primary)',
        (tester) async {
      final msg = ChatMessage.user(
        id: 'm1',
        content: 'Explique-moi Pythagore',
        timestamp: DateTime(2026, 7, 1, 14, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: msg)),
        ),
      );

      // The user's text is visible.
      expect(find.text('Explique-moi Pythagore'), findsOneWidget);

      // The Row containing the bubble uses MainAxisAlignment.end (right
      // alignment for user messages). We verify by inspecting the widget
      // tree.
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });

    // ─── Step 3: MessageBubble for assistant is left-aligned ──────
    // Spec: Step 5 (réponse IA affichée à gauche).
    testWidgets('Step 3 : MessageBubble assistant aligné à gauche',
        (tester) async {
      final msg = ChatMessage.assistant(
        id: 'm2',
        content: 'Le théorème de Pythagore : a² + b² = c².',
        timestamp: DateTime(2026, 7, 1, 14, 30, 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: msg)),
        ),
      );

      // The assistant text is visible.
      expect(find.textContaining('Pythagore'), findsOneWidget);

      // The Row uses MainAxisAlignment.start (left alignment).
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
    });

    // ─── Step 4: TypingIndicator renders while loading ───────────
    // Spec: Step 4 (typing indicator affiché).
    testWidgets('Step 4 : TypingIndicator affiche "Le tuteur écrit"',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator()),
        ),
      );

      // The label is visible.
      expect(find.text('Le tuteur écrit'), findsOneWidget);

      // The avatar (smart_toy icon) is present.
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    // ─── Step 5: FakeTutorController full conversation flow ──────
    // Spec: Steps 2-5 combined — tap suggestion -> user msg -> loading
    // -> assistant msg. We drive the FakeTutorController (from test_app.dart)
    // and assert the message sequence.
    testWidgets('Step 5 : FakeTutorController — question -> user -> loading -> assistant',
        (tester) async {
      final controller = FakeTutorController();

      // Initially empty.
      expect(controller.messages, isEmpty);
      expect(controller.isEmpty, isTrue);
      expect(controller.isLoading, isFalse);

      // Pump a minimal widget that listens to the controller so that
      // notifyListeners() drives a rebuild (mimicking the real screen).
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TutorController>.value(
            value: controller,
            child: Consumer<TutorController>(
              builder: (context, c, _) {
                return Scaffold(
                  body: Column(
                    children: [
                      ...c.messages.map((m) => MessageBubble(message: m)),
                      if (c.isLoading) const TypingIndicator(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Step 5a — Tap the suggestion (simulated by calling ask directly).
      // In the real screen, tapping a chip calls _sendMessage which calls
      // controller.ask. We bypass the UI and call ask directly.
      await controller.ask(question: 'Explique-moi Pythagore');

      // During the ask() call, the user message is added immediately,
      // then status becomes loading (typing indicator visible), then
      // after the simulated network delay the assistant message is added.
      // We pumpAndSettle to drain all the microtasks + the 10ms delay.
      await tester.pumpAndSettle();

      // Step 5b — User message is visible (right-aligned).
      expect(find.text('Explique-moi Pythagore'), findsOneWidget);

      // Step 5c — Assistant response is visible (contains "Pythagore").
      expect(find.textContaining('Pythagore'), findsNWidgets(2));
      // (One in the user message, one in the assistant response.)

      // Step 5d — The controller state is back to idle.
      expect(controller.isLoading, isFalse);
      expect(controller.messages.length, 2);
      expect(controller.messages.first.isUser, isTrue);
      expect(controller.messages.last.isAssistant, isTrue);
    });

    // ─── Step 6: Error bubble renders with retry ─────────────────
    // Bonus: verify the error bubble visual (red border + "Réessayer"
    // link). The real controller produces these on backend failure.
    testWidgets('Step 6 : MessageBubble erreur affiche "Réessayer"',
        (tester) async {
      final msg = ChatMessage.assistant(
        id: 'm_err',
        content: 'Désolé, je n\'ai pas pu répondre. Réessaie.',
        timestamp: DateTime.now(),
        isError: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: msg,
              onRetry: () {},
            ),
          ),
        ),
      );

      // The error text is visible.
      expect(find.textContaining('Désolé'), findsOneWidget);
      // The "Réessayer" link is visible (only for error bubbles with onRetry).
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });
}
