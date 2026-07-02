// lib/models/voice_settings.dart
// Préférences de saisie vocale (speech-to-text) de l'utilisateur.
//
// Contient : activation, langue de reconnaissance, seuil de silence pour
// la détection de fin de parole, seuil de similarité pour juger une réponse
// correcte, seuil partiel, durée max d'enregistrement, lecture auto de la
// transcription, retour haptique.
//
// Persistance : SharedPreferences (JSON sérialisé). On n'utilise PAS Hive ici
// pour éviter d'avoir à enregistrer un adaptateur dans main.dart (contrainte
// de la tâche BL-voice-answers : ne pas toucher au router/main.dart/pubspec).
// SharedPreferences est déjà déclaré dans pubspec.yaml.
//
// Package requis (déjà déclaré dans pubspec.yaml) :
//   speech_to_text: ^7.0.0
//   shared_preferences: ^2.2.3
//
// Conventions :
//   - Langue par défaut 'fr_FR' (Togo = pays francophone).
//   - Seuil similarité 0.80 (>=80% = correct, 50-80% = partiel, <50% = incorrect).
//   - Silence 2000 ms = détection fin de parole (valeur issue de la littérature
//     pour la parole continue en français).
//   - Tout est persisté localement (offline-first, RGPD-friendly).

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences de reconnaissance vocale (Speech-to-Text) pour les réponses.
///
/// Ces préférences pilotent le mode "Révision vocale" (voice_answer_mode.dart)
/// où l'élève peut DIRE sa réponse au lieu de la taper. Cas d'usage :
///   - Révision en marchant / dans les transports
///   - Élèves dyslexiques (saisie textuelle pénible)
///   - Élèves malvoyants (couplé au TTS pour une révision 100% audio)
///
/// Persistance : clé "voice_settings" dans SharedPreferences (JSON).
class VoiceSettings {
  /// Active ou désactive globalement la saisie vocale. Si false, le bouton
  /// micro est masqué dans le mode révision vocale.
  bool enabled;

  /// Code locale BCP-47 (ex : 'fr_FR', 'en_US', 'es_ES'). Le moteur
  /// speech_to_text utilisera cette langue pour la reconnaissance.
  /// 'fr_FR' par défaut (Togo francophone).
  String language;

  /// Durée de silence (ms) qui déclenche la fin de la reconnaissance.
  /// 2000 ms = valeur standard pour la parole continue en français.
  /// Plus court (1000 ms) = réponse rapide attendue (calcul mental).
  /// Plus long (3000 ms) = énoncé long, hésitations acceptées.
  int silenceThresholdMs;

  /// Durée maximale d'écoute (secondes) avant arrêt forcé. 30 s par défaut
  /// (sécurité : évite une écoute infinie si le silence n'est pas détecté).
  int maxListenSeconds;

  /// Seuil de similarité (0.0 - 1.0) au-dessus duquel la réponse est jugée
  /// CORRECTE. 0.80 par défaut (>=80% de similarité après normalisation).
  double similarityThreshold;

  /// Seuil de similarité (0.0 - 1.0) au-dessus duquel la réponse est jugée
  /// PARTIELLEMENT CORRECTE. En dessous = incorrecte.
  /// 0.50 par défaut (50% de similarité).
  double partialThreshold;

  /// Afficher la transcription en temps réel pendant l'écoute (partialResults).
  /// true par défaut : feedback visuel immédiat pour l'élève.
  bool showPartialTranscription;

  /// Retour haptique (vibration) au début et à la fin de l'écoute.
  /// true par défaut : utile en marchand (l'élève n'a pas l'écran sous les yeux).
  bool hapticFeedback;

  /// Jouer un son court au début/fin de l'écoute (bip discret).
  /// false par défaut : peut gêner en classe.
  bool soundFeedback;

  /// Si true, le verdict (correct/incorrect) est prononcé à voix haute via
  /// le service TTS après chaque réponse vocale. Nécessite TtsService.
  /// false par défaut (le TTS peut être activé séparément).
  bool speakVerdict;

  /// Auto-passer à la question suivante après un verdict correct.
  /// false par défaut : l'élève voit d'abord le verdict et la réponse
  /// attendue avant de passer.
  bool autoNextOnCorrect;

  VoiceSettings({
    this.enabled = true,
    this.language = 'fr_FR',
    this.silenceThresholdMs = 2000,
    this.maxListenSeconds = 30,
    this.similarityThreshold = 0.80,
    this.partialThreshold = 0.50,
    this.showPartialTranscription = true,
    this.hapticFeedback = true,
    this.soundFeedback = false,
    this.speakVerdict = false,
    this.autoNextOnCorrect = false,
  });

  /// Crée une copie avec des champs modifiés. Sert pour les mises à jour
  /// immuables dans VoiceInputService.updateSettings().
  VoiceSettings copyWith({
    bool? enabled,
    String? language,
    int? silenceThresholdMs,
    int? maxListenSeconds,
    double? similarityThreshold,
    double? partialThreshold,
    bool? showPartialTranscription,
    bool? hapticFeedback,
    bool? soundFeedback,
    bool? speakVerdict,
    bool? autoNextOnCorrect,
  }) {
    return VoiceSettings(
      enabled: enabled ?? this.enabled,
      language: language ?? this.language,
      silenceThresholdMs: silenceThresholdMs ?? this.silenceThresholdMs,
      maxListenSeconds: maxListenSeconds ?? this.maxListenSeconds,
      similarityThreshold: similarityThreshold ?? this.similarityThreshold,
      partialThreshold: partialThreshold ?? this.partialThreshold,
      showPartialTranscription:
          showPartialTranscription ?? this.showPartialTranscription,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundFeedback: soundFeedback ?? this.soundFeedback,
      speakVerdict: speakVerdict ?? this.speakVerdict,
      autoNextOnCorrect: autoNextOnCorrect ?? this.autoNextOnCorrect,
    );
  }

  /// Réinitialise toutes les préférences à leurs valeurs par défaut.
  void reset() {
    enabled = true;
    language = 'fr_FR';
    silenceThresholdMs = 2000;
    maxListenSeconds = 30;
    similarityThreshold = 0.80;
    partialThreshold = 0.50;
    showPartialTranscription = true;
    hapticFeedback = true;
    soundFeedback = false;
    speakVerdict = false;
    autoNextOnCorrect = false;
  }

  // ─── Sérialisation JSON pour SharedPreferences ──────────────────

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'language': language,
        'silenceThresholdMs': silenceThresholdMs,
        'maxListenSeconds': maxListenSeconds,
        'similarityThreshold': similarityThreshold,
        'partialThreshold': partialThreshold,
        'showPartialTranscription': showPartialTranscription,
        'hapticFeedback': hapticFeedback,
        'soundFeedback': soundFeedback,
        'speakVerdict': speakVerdict,
        'autoNextOnCorrect': autoNextOnCorrect,
      };

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      enabled: json['enabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'fr_FR',
      silenceThresholdMs: json['silenceThresholdMs'] as int? ?? 2000,
      maxListenSeconds: json['maxListenSeconds'] as int? ?? 30,
      similarityThreshold:
          (json['similarityThreshold'] as num?)?.toDouble() ?? 0.80,
      partialThreshold: (json['partialThreshold'] as num?)?.toDouble() ?? 0.50,
      showPartialTranscription:
          json['showPartialTranscription'] as bool? ?? true,
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      soundFeedback: json['soundFeedback'] as bool? ?? false,
      speakVerdict: json['speakVerdict'] as bool? ?? false,
      autoNextOnCorrect: json['autoNextOnCorrect'] as bool? ?? false,
    );
  }

  // ─── Chargement / sauvegarde via SharedPreferences ──────────────

  static const String _prefsKey = 'voice_settings';

  /// Charge les préférences depuis SharedPreferences.
  /// Retourne les valeurs par défaut si aucune préférence n'est enregistrée.
  static Future<VoiceSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return VoiceSettings();
      return VoiceSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Erreur non bloquante : on retourne les valeurs par défaut
      return VoiceSettings();
    }
  }

  /// Sauvegarde les préférences dans SharedPreferences.
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(toJson()));
    } catch (_) {
      // Erreur non bloquante : les préférences restent en mémoire
    }
  }

  @override
  String toString() =>
      'VoiceSettings(enabled=$enabled, lang=$language, silence=${silenceThresholdMs}ms, '
      'simThresh=$similarityThreshold, partialThresh=$partialThreshold, '
      'partial=$showPartialTranscription, haptic=$hapticFeedback)';
}
