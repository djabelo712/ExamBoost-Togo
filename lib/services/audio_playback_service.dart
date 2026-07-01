// lib/services/audio_playback_service.dart
// Orchestrateur de lecture audio : play/pause/stop/replay.
//
// Couche au-dessus de TtsService qui abstrait la logique d'etat
// (play = toggle selon contexte). Sert a :
//   - Simplifier les widgets (AudioPlayerButton n'a qu'une methode play()).
//   - Centraliser la logique replay (reprend depuis le debut).
//   - Garder un historique court des textes lus (pour bouton "precedent").
//
// Pas de persistance propre : delegue a TtsService pour les settings.
// ChangeNotifier pour rebuild reactif des boutons et barre de progression.

import 'package:flutter/foundation.dart';

import 'tts_service.dart';

/// Orchestrateur de lecture audio.
///
/// Differe de TtsService : TtsService expose les primitives (speak, pause,
/// stop), AudioPlaybackService expose la logique metier (play = toggle
/// play/pause selon contexte, replay = relire depuis debut, next/previous
/// dans la file d'attente).
class AudioPlaybackService extends ChangeNotifier {
  final TtsService _ttsService;

  /// File d'attente des textes lus (cap 10, LRU). Sert au bouton "rejouer
  /// le precedent" dans AudioPlayerBar.
  final List<String> _history = [];

  AudioPlaybackService(this._ttsService) {
    // Re-propage les notifications de TtsService vers les widgets abonnes a
    // AudioPlaybackService (un seul Consumer suffit).
    _ttsService.addListener(_onTtsChanged);
  }

  void _onTtsChanged() {
    notifyListeners();
  }

  // ─── Getters ──────────────────────────────────────────────────

  TtsService get ttsService => _ttsService;

  /// True si on est en train de lire (et pas en pause).
  bool get isPlaying => _ttsService.isSpeaking && !_ttsService.isPaused;

  /// True si lecture en pause.
  bool get isPaused => _ttsService.isPaused;

  /// True si lecture en cours (play ou pause).
  bool get isActive => _ttsService.isSpeaking;

  /// Texte en cours de lecture (ou '' si rien).
  String get currentText => _ttsService.currentlySpokenText;

  /// Historique des textes lus (le plus recent en premier).
  List<String> get history => List.unmodifiable(_history);

  /// Offset du mot courant dans le texte en lecture. Sert au surlignage.
  int get currentWordStart => _ttsService.currentWordStartOffset;
  int get currentWordEnd => _ttsService.currentWordEndOffset;

  /// True si le texte passe est celui en cours de lecture (play ou pause).
  bool isPlayingText(String text) =>
      _ttsService.isSpeaking && _ttsService.currentlySpokenText == text;

  /// True si le texte passe est en cours ET en pause.
  bool isPausedText(String text) =>
      _ttsService.isSpeaking &&
      _ttsService.isPaused &&
      _ttsService.currentlySpokenText == text;

  // ─── API publique ─────────────────────────────────────────────

  /// Bouton play/pause universel :
  ///   - Si ce texte n'est pas en lecture -> speak(text) + ajout historique.
  ///   - Si en lecture et pas en pause -> pause.
  ///   - Si en pause -> resume.
  ///
  /// Ne fait rien si TTS desactive (settings.enabled == false).
  Future<void> play(String text) async {
    if (!_ttsService.settings.enabled) return;

    final isCurrent = _ttsService.currentlySpokenText == text;
    if (_ttsService.isSpeaking && isCurrent) {
      if (_ttsService.isPaused) {
        await _ttsService.resume();
      } else {
        await _ttsService.pause();
      }
      return;
    }

    // Nouveau texte : stoppe l'eventuelle lecture en cours et lance la nouvelle.
    if (_ttsService.isSpeaking) {
      await _ttsService.stop();
    }

    // Ajoute a l'historique (cap 10).
    _history.remove(text);
    _history.insert(0, text);
    if (_history.length > 10) {
      _history.removeLast();
    }
    notifyListeners();

    await _ttsService.speak(text);
  }

  /// Bascule play/pause pour le texte en cours de lecture. No-op si rien
  /// n'est en cours.
  Future<void> togglePlayPause() async {
    if (!_ttsService.isSpeaking) return;
    if (_ttsService.isPaused) {
      await _ttsService.resume();
    } else {
      await _ttsService.pause();
    }
  }

  /// Stoppe completement la lecture.
  Future<void> stop() async {
    await _ttsService.stop();
  }

  /// Relit le texte en cours depuis le debut. Si rien n'etait en cours,
  /// relit le dernier texte de l'historique.
  Future<void> replay() async {
    final text = _ttsService.currentlySpokenText.isNotEmpty
        ? _ttsService.currentlySpokenText
        : (_history.isNotEmpty ? _history.first : '');
    if (text.isEmpty) return;
    await _ttsService.stop();
    await _ttsService.speak(text);
  }

  /// Relit un texte specifique de l'historique (par index).
  Future<void> replayFromHistory(int index) async {
    if (index < 0 || index >= _history.length) return;
    final text = _history[index];
    await _ttsService.stop();
    _history.removeAt(index);
    _history.insert(0, text);
    notifyListeners();
    await _ttsService.speak(text);
  }

  @override
  void dispose() {
    _ttsService.removeListener(_onTtsChanged);
    super.dispose();
  }
}
