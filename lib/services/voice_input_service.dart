// lib/services/voice_input_service.dart
// Service de reconnaissance vocale (speech-to-text) pour les réponses.
//
// Wrapper autour du package `speech_to_text: ^7.0.0` (déjà déclaré dans
// pubspec.yaml — voir ligne "speech_to_text: ^7.0.0  # Agent BL").
//
// Fonctionnalités :
//   - Initialisation paresseuse (au premier appel à startListening)
//   - Langue FR par défaut (configurable via VoiceSettings.language)
//   - Détection de fin de parole via silence de 2 s (configurable)
//   - Transcription live (partialResults) via callback onPartial
//   - Transcription finale via callback onFinal
//   - États : notInitialized, ready, listening, error, unsupported
//   - Gestion plateformes non supportées (web/desktop) : available=false
//
// Sécurité :
//   - Ne crash jamais si le package speech_to_text n'est pas disponible
//   - Catch toutes les erreurs et les expose via onError
//   - Le service est conçu pour être utilisé via Provider (singleton)
//
// Permissions requises (à ajouter par l'utilisateur final) :
//   - Android : AndroidManifest.xml
//       <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//   - iOS : Info.plist
//       <key>NSMicrophoneUsageDescription</key>
//       <string>ExamBoost utilise le micro pour la saisie vocale des réponses.</string>
//
// Cas d'usage : mode "Révision vocale" (voice_answer_mode.dart), où l'élève
// peut DIRE sa réponse au lieu de la taper (révision en marchant, dyslexiques).

import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../models/voice_settings.dart';

/// États possibles du service de reconnaissance vocale.
enum VoiceInputState {
  /// Le service n'a pas encore été initialisé.
  notInitialized,

  /// Le service est initialisé et prêt à écouter.
  ready,

  /// Le service est en train d'écouter (micro actif).
  listening,

  /// Une erreur est survenue (voir lastError).
  error,

  /// Plateforme non supportée (web, desktop, simulateur sans micro).
  unsupported,
}

/// Service singleton de reconnaissance vocale (speech-to-text).
///
/// Utilisation typique (via Provider) :
/// ```dart
/// final voice = context.read<VoiceInputService>();
/// await voice.startListening(
///   onPartial: (text) => debugPrint('Partiel : $text'),
///   onFinal: (text) => debugPrint('Final : $text'),
/// );
/// // Plus tard :
/// await voice.stopListening();
/// ```
class VoiceInputService extends ChangeNotifier {
  VoiceInputService({VoiceSettings? settings})
      : _settings = settings ?? VoiceSettings() {
    _detectPlatformSupport();
  }

  // ─── Dépendances internes ──────────────────────────────────────
  final SpeechToText _speech = SpeechToText();

  // ─── État observable ───────────────────────────────────────────
  VoiceInputState _state = VoiceInputState.notInitialized;
  VoiceInputState get state => _state;

  bool _speechAvailable = false;
  bool get speechAvailable => _speechAvailable;

  /// True si le service est actuellement en train d'écouter.
  bool get isListening => _state == VoiceInputState.listening;

  String? _lastError;
  String? get lastError => _lastError;

  /// Dernière transcription partielle (live).
  String _partialTranscription = '';
  String get partialTranscription => _partialTranscription;

  /// Dernière transcription finale.
  String _finalTranscription = '';
  String get finalTranscription => _finalTranscription;

  /// Préférences vocales (langue, seuils, comportements).
  VoiceSettings _settings;
  VoiceSettings get settings => _settings;

  // ─── Callbacks (assignés par startListening) ──────────────────
  void Function(String partial)? _onPartial;
  void Function(String finalText)? _onFinal;
  void Function(String error)? _onError;
  void Function(VoiceInputState state)? _onStateChange;

  // ─── Timer de sécurité : arrêt forcé après maxListenSeconds ──
  Timer? _maxListenTimer;

  // ─── Détection de la plateforme ───────────────────────────────

  /// speech_to_text n'est supporté que sur Android et iOS (natif).
  /// Sur web/desktop, on marque le service comme unsupported pour que
  /// l'UI puisse masquer le bouton micro.
  void _detectPlatformSupport() {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile) {
      _state = VoiceInputState.unsupported;
    }
  }

  // ─── Mise à jour des préférences ──────────────────────────────

  /// Met à jour les préférences (langue, seuils, etc.) et persiste.
  Future<void> updateSettings(VoiceSettings newSettings) async {
    _settings = newSettings;
    await _settings.save();
    notifyListeners();
  }

  // ─── Initialisation paresseuse ────────────────────────────────

  /// Initialise le moteur speech_to_text (appelé automatiquement au premier
  /// startListening). Retourne true si le service est disponible.
  Future<bool> _ensureInitialized() async {
    if (_state == VoiceInputState.unsupported) return false;
    if (_speechAvailable) return true;

    try {
      _speechAvailable = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: false,
      );
      if (_speechAvailable) {
        _state = VoiceInputState.ready;
      } else {
        _state = VoiceInputState.error;
        _lastError = 'Initialisation échouée (micro indisponible ou permission refusée)';
      }
    } catch (e) {
      _state = VoiceInputState.error;
      _lastError = e.toString();
    }
    notifyListeners();
    return _speechAvailable;
  }

  // ─── Démarrage / arrêt de l'écoute ────────────────────────────

  /// Démarre l'écoute du micro.
  ///
  /// Paramètres :
  ///   - onPartial : appelé à chaque transcription partielle (live)
  ///   - onFinal   : appelé à la transcription finale (silence détecté)
  ///   - onError   : appelé en cas d'erreur de reconnaissance
  ///   - onStateChange : appelé à chaque changement d'état du service
  Future<bool> startListening({
    void Function(String partial)? onPartial,
    void Function(String finalText)? onFinal,
    void Function(String error)? onError,
    void Function(VoiceInputState state)? onStateChange,
  }) async {
    // Stocke les callbacks pour les appels ultérieurs
    _onPartial = onPartial;
    _onFinal = onFinal;
    _onError = onError;
    _onStateChange = onStateChange;

    // Si pas encore initialisé, on tente l'initialisation
    if (!_speechAvailable) {
      final ok = await _ensureInitialized();
      if (!ok) {
        _onError?.call(_lastError ?? 'Speech-to-text indisponible');
        return false;
      }
    }

    // Si déjà en écoute, on ne relance pas
    if (_state == VoiceInputState.listening) return true;

    _partialTranscription = '';
    _finalTranscription = '';

    try {
      await _speech.listen(
        localeId: _settings.language,
        partialResults: _settings.showPartialTranscription,
        listenMode: ListenMode.dictation,
        // listenFor : durée max d'écoute avant arrêt forcé (sécurité)
        listenFor: Duration(seconds: _settings.maxListenSeconds),
        // pauseFor : durée de silence déclenchant la fin de parole (2 s par
        // défaut dans VoiceSettings). speech_to_text 7.x supporte ce paramètre
        // sur Android et iOS natifs.
        pauseFor: Duration(milliseconds: _settings.silenceThresholdMs),
        onResult: _handleResult,
      );
      _setState(VoiceInputState.listening);

      // Timer de sécurité : arrêt forcé après maxListenSeconds
      _maxListenTimer?.cancel();
      _maxListenTimer = Timer(
        Duration(seconds: _settings.maxListenSeconds),
        () {
          if (_state == VoiceInputState.listening) {
            stopListening();
          }
        },
      );
      return true;
    } catch (e) {
      _lastError = e.toString();
      _setState(VoiceInputState.error);
      _onError?.call(e.toString());
      return false;
    }
  }

  /// Arrête l'écoute du micro. Déclenche le callback onFinal avec la
  /// transcription accumulée (si non vide).
  Future<void> stopListening() async {
    _maxListenTimer?.cancel();
    _maxListenTimer = null;
    if (_state != VoiceInputState.listening) return;

    try {
      await _speech.stop();
    } catch (_) {
      // Erreur non bloquante : on continue
    }

    // Si on a une transcription partielle non finalisée, on l'envoie comme
    // finale (le moteur ne déclenche pas toujours finalResult sur stop()).
    if (_finalTranscription.isEmpty && _partialTranscription.isNotEmpty) {
      _finalTranscription = _partialTranscription;
      _onFinal?.call(_finalTranscription);
    } else if (_finalTranscription.isNotEmpty) {
      _onFinal?.call(_finalTranscription);
    }

    _setState(VoiceInputState.ready);
  }

  /// Annule l'écoute sans déclencher le callback onFinal (l'élève a annulé).
  Future<void> cancelListening() async {
    _maxListenTimer?.cancel();
    _maxListenTimer = null;
    if (_state != VoiceInputState.listening) return;

    try {
      await _speech.cancel();
    } catch (_) {
      // Erreur non bloquante
    }
    _partialTranscription = '';
    _finalTranscription = '';
    _setState(VoiceInputState.ready);
  }

  // ─── Handlers internes (appelés par speech_to_text) ───────────

  void _handleResult(SpeechRecognitionResult result) {
    _partialTranscription = result.recognizedWords;
    _onPartial?.call(_partialTranscription);

    if (result.finalResult) {
      _finalTranscription = result.recognizedWords;
      _onFinal?.call(_finalTranscription);
      // Le moteur a détecté la fin de parole (silence) : on repasse à ready
      _setState(VoiceInputState.ready);
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _lastError = error.errorMsg;
    _setState(VoiceInputState.error);
    _onError?.call(error.errorMsg);
    // Après une erreur, on tente de revenir à l'état ready pour permettre
    // une nouvelle tentative
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_state == VoiceInputState.error && _speechAvailable) {
        _setState(VoiceInputState.ready);
      }
    });
  }

  void _handleStatus(String status) {
    // États possibles : 'listening', 'notListening', 'done', 'unavailable'
    if (status == 'done' || status == 'notListening') {
      if (_state == VoiceInputState.listening) {
        // Le moteur s'est arrêté (silence détecté ou stop() appelé)
        _maxListenTimer?.cancel();
        _maxListenTimer = null;
        if (_finalTranscription.isEmpty && _partialTranscription.isNotEmpty) {
          _finalTranscription = _partialTranscription;
          _onFinal?.call(_finalTranscription);
        }
        _setState(VoiceInputState.ready);
      }
    }
  }

  void _setState(VoiceInputState newState) {
    if (_state == newState) return;
    _state = newState;
    _onStateChange?.call(newState);
    notifyListeners();
  }

  // ─── Langues disponibles ──────────────────────────────────────

  /// Retourne la liste des locales supportées par le moteur speech_to_text
  /// (ex : fr_FR, en_US). Sert à alimenter le sélecteur de langue dans les
  /// réglages. Retourne une liste vide si le service n'est pas initialisé.
  Future<List<LocaleName>> availableLocales() async {
    if (!_speechAvailable) {
      final ok = await _ensureInitialized();
      if (!ok) return [];
    }
    try {
      return await _speech.locales();
    } catch (_) {
      return [];
    }
  }

  // ─── Nettoyage ────────────────────────────────────────────────

  @override
  void dispose() {
    _maxListenTimer?.cancel();
    if (_state == VoiceInputState.listening) {
      _speech.cancel(); // fire-and-forget
    }
    super.dispose();
  }
}
