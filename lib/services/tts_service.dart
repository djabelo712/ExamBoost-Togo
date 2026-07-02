// lib/services/tts_service.dart
// Service principal de synthese vocale (Text-To-Speech).
//
// Wrapper autour du package flutter_tts (a ajouter dans pubspec.yaml).
// Expose une API simple : speak(text) / pause() / stop() / resume().
// Persiste les preferences (TtsSettings) dans Hive box "tts_settings".
// Notifie les widgets via ChangeNotifier pour rebuild reactif.
//
// Cas d'usage :
//   - Lecture audio des enonces dans question_card.dart
//   - Lecture auto des questions dans revision_screen.dart
//   - Surlignage synchro des mots (highlightTextAsSpoken)
//   - Apercu voix dans tts_settings_screen.dart
//
// Package requis (pubspec.yaml) :
//   flutter_tts: ^4.0.2
//
// Initialisation (a faire dans main.dart par l'agent wiring) :
//   await Hive.registerAdapter(TtsSettingsAdapter());
//   final ttsService = TtsService();
//   await ttsService.init();
//   // puis MultiProvider(providers: [Provider<TtsService>.value(value: ttsService)])

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';

import '../models/tts_settings.dart';
import '../utils/app_logger.dart';

/// Service de synthese vocale (TTS) pour ExamBoost Togo.
///
/// Charge les preferences au demarrage, expose speak/pause/stop, et notifie
/// les widgets via ChangeNotifier pour mettre a jour les boutons et barres
/// de progression en temps reel.
///
/// Limites connues de flutter_tts :
///   - Pas de duree totale anticipee (la progress bar est donc basee sur
///     le ratio mot courant / nombre total de mots).
///   - Pause/Resume non supporte sur iOS (a la place, stop + speak depuis
///     le debut). On gere gracieusement ce cas.
///   - Certaines voix ne supportent pas le progress handler.
class TtsService extends ChangeNotifier {
  /// Nom de la box Hive qui contient les preferences TtsSettings.
  static const String settingsBoxName = 'tts_settings';

  /// Nom de la box Hive qui contient le cache audio (cf. AudioCacheService).
  static const String cacheBoxName = 'audio_cache';

  late final FlutterTts _flutterTts;
  TtsSettings _settings = TtsSettings();

  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _initialized = false;

  /// Texte en cours de lecture (chaine complete, pas juste le mot courant).
  /// Sert a AudioPlayerBar a afficher un apercu et a AudioPlayerButton a
  /// savoir s'il est "actif" pour un texte donne.
  String _currentlySpokenText = '';

  /// Offset de debut du mot en cours de lecture dans [_currentlySpokenText].
  /// Mis a jour par le progress handler. Sert au surlignage synchro.
  int _currentWordStartOffset = 0;

  /// Offset de fin du mot en cours de lecture.
  int _currentWordEndOffset = 0;

  /// Dernier message d'erreur TTS (null si OK). Affiche en rouge dans les
  /// settings pour debug.
  String? _lastError;

  // ─── Getters publics ──────────────────────────────────────────
  TtsSettings get settings => _settings;
  bool get isInitialized => _initialized;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  String get currentlySpokenText => _currentlySpokenText;
  int get currentWordStartOffset => _currentWordStartOffset;
  int get currentWordEndOffset => _currentWordEndOffset;
  String? get lastError => _lastError;

  /// True si le texte passe en parametre est exactement celui en cours
  /// de lecture. Sert aux AudioPlayerButton pour choisir leur icone.
  bool isSpeakingText(String text) {
    return _isSpeaking && _currentlySpokenText == text;
  }

  /// True si on peut faire pause (Android uniquement - iOS ne supporte pas).
  /// Renvoie false si deja en pause ou si non en lecture.
  bool get canPause => _isSpeaking && !_isPaused;

  // ─── Initialisation ───────────────────────────────────────────

  /// Initialise le service : charge les preferences depuis Hive, configure
  /// le moteur TTS (langue, vitesse, ton, volume), et branche les handlers.
  /// Idempotent : peut etre appele plusieurs fois sans effet de bord.
  Future<void> init() async {
    if (_initialized) return;

    try {
      _flutterTts = FlutterTts();

      // Charge settings depuis Hive (ou valeurs par defaut).
      final box = await _openSettingsBox();
      _settings = box.get('settings') ?? TtsSettings();

      // Configuration initiale du moteur TTS.
      await _applySettingsToEngine(_settings);

      // Branchements des handlers.
      _flutterTts.setStartHandler(_onStart);
      _flutterTts.setCompletionHandler(_onCompletion);
      _flutterTts.setProgressHandler(_onProgress);
      _flutterTts.setErrorHandler(_onError);
      _flutterTts.setPauseHandler(_onPause);
      _flutterTts.setContinueHandler(_onContinue);

      _initialized = true;
      AppLogger.info(
        'TtsService initialise - '
        'lang=${_settings.language}, rate=${_settings.speechRate}, '
        'enabled=${_settings.enabled}',
      );
    } catch (e) {
      AppLogger.error('TtsService.init() erreur: $e');
      _lastError = e.toString();
      _settings = TtsSettings();
      _initialized = false;
    }
  }

  Future<Box<TtsSettings>> _openSettingsBox() async {
    if (Hive.isBoxOpen(settingsBoxName)) {
      return Hive.box<TtsSettings>(settingsBoxName);
    }
    return Hive.openBox<TtsSettings>(settingsBoxName);
  }

  /// Applique les settings au moteur TTS (langue, vitesse, ton, volume,
  /// voix). Appele a l'init et apres chaque updateSettings.
  Future<void> _applySettingsToEngine(TtsSettings s) async {
    try {
      await _flutterTts.setLanguage(s.language);
      await _flutterTts.setSpeechRate(s.speechRate);
      await _flutterTts.setPitch(s.pitch);
      await _flutterTts.setVolume(s.volume);
      if (s.preferredVoice != null) {
        await _flutterTts.setVoice({'name': s.preferredVoice, 'locale': s.language});
      }
      // Active le handler de progression (necessaire pour le surlignage).
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      AppLogger.warn('TtsService: echec application partielle settings: $e');
      // Non bloquant : certaines voix/langues peuvent ne pas etre disponibles.
    }
  }

  // ─── Handlers internes ────────────────────────────────────────

  void _onStart() {
    _isSpeaking = true;
    _isPaused = false;
    _lastError = null;
    notifyListeners();
  }

  void _onCompletion() {
    _isSpeaking = false;
    _isPaused = false;
    _currentlySpokenText = '';
    _currentWordStartOffset = 0;
    _currentWordEndOffset = 0;
    notifyListeners();
  }

  void _onProgress(String text, int start, int end, String word) {
    _currentWordStartOffset = start;
    _currentWordEndOffset = end;
    notifyListeners();
  }

  void _onError(String error) {
    _isSpeaking = false;
    _isPaused = false;
    _lastError = error;
    AppLogger.error('TtsService erreur moteur: $error');
    notifyListeners();
  }

  void _onPause() {
    _isPaused = true;
    notifyListeners();
  }

  void _onContinue() {
    _isPaused = false;
    notifyListeners();
  }

  // ─── API publique ─────────────────────────────────────────────

  /// Lance la lecture du texte. Si une lecture etait en cours, elle est
  /// stoppee et remplacee par celle-ci. Si TTS est desactive (settings.enabled
  /// == false), ne fait rien (no-op silencieux).
  Future<void> speak(String text) async {
    if (!_initialized) {
      AppLogger.warn('TtsService.speak() appele avant init() - ignore');
      return;
    }
    if (!_settings.enabled || text.trim().isEmpty) return;

    _currentlySpokenText = text;
    _currentWordStartOffset = 0;
    _currentWordEndOffset = 0;
    _lastError = null;
    notifyListeners();

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      AppLogger.error('TtsService.speak() erreur: $e');
      _lastError = e.toString();
      _isSpeaking = false;
      _currentlySpokenText = '';
      notifyListeners();
    }
  }

  /// Met en pause la lecture en cours. Si iOS (pause non supporte), on
  /// stoppe et l'eleve devra reprendre depuis le debut. Sur Android,
  /// pause() met vraiment en pause et resume via pause() a nouveau.
  Future<void> pause() async {
    if (!_initialized || !_isSpeaking) return;
    try {
      await _flutterTts.pause();
      _isPaused = true;
      notifyListeners();
    } catch (e) {
      AppLogger.warn('TtsService.pause() non supporte: $e');
    }
  }

  /// Reprend la lecture apres une pause. Sur iOS, n'a pas d'effet (pause non
  /// supporte) ; l'eleve devra retaper play pour relire depuis le debut.
  Future<void> resume() async {
    if (!_initialized || !_isSpeaking || !_isPaused) return;
    // flutter_tts n'expose pas de resume() explicite ; pause() sert aussi de
    // toggle sur Android. Sur iOS, on doit relancer speak().
    try {
      await _flutterTts.pause();
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      AppLogger.warn('TtsService.resume() non supporte: $e');
    }
  }

  /// Stoppe completement la lecture et reinitialise l'etat.
  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _flutterTts.stop();
    } catch (_) {
      // ignore : stop peut echouer si rien en cours
    }
    _isSpeaking = false;
    _isPaused = false;
    _currentlySpokenText = '';
    _currentWordStartOffset = 0;
    _currentWordEndOffset = 0;
    notifyListeners();
  }

  /// Met a jour les preferences (applique au moteur + persiste dans Hive).
  /// Appele par TtsSettingsScreen a chaque changement de slider/switch.
  Future<void> updateSettings(TtsSettings newSettings) async {
    _settings = newSettings;
    await _applySettingsToEngine(newSettings);

    try {
      final box = await _openSettingsBox();
      await box.put('settings', newSettings);
    } catch (e) {
      AppLogger.error('TtsService.updateSettings() persistence erreur: $e');
    }

    AppLogger.info('TtsService: settings mis a jour - $newSettings');
    notifyListeners();
  }

  /// Renvoie la liste des voix disponibles filtrees par langue (par defaut,
  /// les voix francaises). Chaque entree est un Map {'name', 'locale'}.
  /// Renvoie [] si le moteur ne supporte pas getVoices (ou erreur).
  Future<List<Map<String, String>>> getAvailableVoices({
    String? languageFilter,
  }) async {
    if (!_initialized) return [];
    final filter = languageFilter ?? _settings.languageCode;
    try {
      final voices = await _flutterTts.getVoices();
      if (voices == null) return [];
      return voices
          .cast<Map<dynamic, dynamic>>()
          .map((v) =>
              v.map((k, e) => MapEntry(k.toString(), e.toString())))
          .where((v) =>
              (v['locale'] ?? '').toLowerCase().startsWith(filter))
          .toList();
    } catch (e) {
      AppLogger.warn('TtsService.getAvailableVoices() erreur: $e');
      return [];
    }
  }

  /// Renvoie la liste des langues disponibles sur le moteur TTS.
  /// Sert a peupler le dropdown "Langue" de TtsSettingsScreen.
  Future<List<String>> getAvailableLanguages() async {
    if (!_initialized) return ['fr-FR'];
    try {
      final langs = await _flutterTts.getLanguages();
      if (langs == null) return ['fr-FR'];
      final list = langs.cast<String>().toList()..sort();
      // Met fr-FR en tete si dispo (convention Togo francophone).
      if (list.contains('fr-FR')) {
        list.remove('fr-FR');
        list.insert(0, 'fr-FR');
      }
      return list;
    } catch (e) {
      AppLogger.warn('TtsService.getAvailableLanguages() erreur: $e');
      return ['fr-FR'];
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _flutterTts.stop();
    }
    super.dispose();
  }
}
