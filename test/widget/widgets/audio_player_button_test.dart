// test/widget/widgets/audio_player_button_test.dart
// Tests for the AudioPlayerButton widget — bouton play/pause TTS.
//
// The button consumes TtsService + AudioPlaybackService via Consumer2.
// We use FakeTtsService + FakeAudioPlaybackService (in-memory, no
// FlutterTts engine, no Hive box).
//
// We test:
//   - Default state (TTS enabled, idle): volume_up icon visible.
//   - Tap with TTS enabled: AudioPlaybackService.play is called.
//   - While playing the same text: pause icon replaces volume_up.
//   - TTS disabled: tap shows a snackbar hint (no play call).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/models/tts_settings.dart';
import 'package:examboost_togo/services/audio_playback_service.dart';
import 'package:examboost_togo/services/tts_service.dart';
import 'package:examboost_togo/widgets/audio_player_button.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('AudioPlayerButton widget', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      required FakeTtsService tts,
      required FakeAudioPlaybackService playback,
      required String text,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<TtsService>.value(value: tts),
              ChangeNotifierProvider<AudioPlaybackService>.value(
                value: playback,
              ),
            ],
            child: Scaffold(
              body: AudioPlayerButton(text: text),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('État idle (TTS activé) : icône volume_up visible',
        (tester) async {
      final tts = FakeTtsService();
      final playback = FakeAudioPlaybackService(tts);
      await pumpButton(
        tester,
        tts: tts,
        playback: playback,
        text: 'Bonjour le monde',
      );

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('Tap (TTS activé) : appelle AudioPlaybackService.play(text)',
        (tester) async {
      final tts = FakeTtsService();
      final playback = FakeAudioPlaybackService(tts);
      await pumpButton(
        tester,
        tts: tts,
        playback: playback,
        text: 'Bonjour le monde',
      );

      // Tap the button (it's a GestureDetector wrapping an Icon).
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pumpAndSettle();

      expect(playback.playCalls, ['Bonjour le monde']);
    });

    testWidgets('Pendant la lecture du même texte : icône pause visible',
        (tester) async {
      final tts = FakeTtsService();
      final playback = FakeAudioPlaybackService(tts);
      await pumpButton(
        tester,
        tts: tts,
        playback: playback,
        text: 'Bonjour le monde',
      );

      // Simulate the TTS engine currently playing this text.
      tts.simulatePlaying('Bonjour le monde');
      await tester.pump();

      // The button should now show the pause icon.
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    });

    testWidgets('TTS désactivé : tap affiche un snackbar (pas d\'appel play)',
        (tester) async {
      final tts = FakeTtsService();
      tts.setSettings(TtsSettings(enabled: false));
      final playback = FakeAudioPlaybackService(tts);
      await pumpButton(
        tester,
        tts: tts,
        playback: playback,
        text: 'Bonjour le monde',
      );

      // Tap the disabled-TTS button.
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pumpAndSettle();

      // Snackbar hint shown.
      expect(
        find.textContaining('Lecture audio désactivée'),
        findsOneWidget,
      );
      // No play call was made.
      expect(playback.playCalls, isEmpty);
    });
  });
}
