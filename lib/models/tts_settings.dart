// lib/models/tts_settings.dart
// Preferences de lecture audio (TTS) de l'utilisateur (persistees via Hive).
//
// Contient : activation, langue, voix preferentielle, vitesse, ton, volume,
// lecture auto des questions, lecture des reponses, surlignage synchro.
//
// Attention : pour fonctionner, l'adaptateur TtsSettingsAdapter doit etre
// enregistre dans main.dart (Hive.registerAdapter) AVANT l'ouverture de la
// box "tts_settings". Voir lib/screens/settings/README.md pour le wiring.
//
// Package requis (a ajouter dans pubspec.yaml) :
//   flutter_tts: ^4.0.2
//
// Conventions :
//   - Langue par defaut 'fr-FR' (Togo = pays francophone).
//   - speechRate / pitch : plage [0.5 ; 2.0] imposee par flutter_tts.
//   - volume : plage [0.0 ; 1.0].
//   - Tout est persiste localement (offline-first, RGPD-friendly).

import 'package:hive/hive.dart';

part 'tts_settings.g.dart';

/// Preferences de synthese vocale (Text-To-Speech) de l'utilisateur.
///
/// Ces preferences pilotent la lecture audio des enonces et reponses dans
/// l'ecran de revision (question_card.dart) et l'ecran d'examen authentique.
/// Persistees via Hive dans la box "tts_settings" (cle : "settings").
///
/// Cas d'usage : eleves dyslexiques, malvoyants, revision en marchant /
/// transport, apprentissage auditif.
@HiveType(typeId: 17)
class TtsSettings extends HiveObject {
  /// Active ou desactive globalement la lecture audio. Si false, aucun bouton
  /// TTS ne declenche la parole (mais les boutons restent affiches et gris).
  @HiveField(0)
  bool enabled;

  /// Code locale BCP-47 (ex : 'fr-FR', 'en-US', 'es-ES'). Le TTS utilisera
  /// cette langue pour choisir le moteur de synthese approprie.
  @HiveField(1)
  String language;

  /// Vitesse de lecture. Plage [0.5 ; 2.0] impossee par flutter_tts.
  ///   0.5 = tres lent (apprentissage)
  ///   1.0 = normal
  ///   2.0 = rapide (revision criblee)
  @HiveField(2)
  double speechRate;

  /// Hauteur tonale (pitch). Plage [0.5 ; 2.0].
  ///   < 1.0 = voix grave (concentration)
  ///   1.0 = normal
  ///   > 1.0 = voix aigue (dynamique)
  @HiveField(3)
  double pitch;

  /// Volume. Plage [0.0 ; 1.0]. 1.0 = volume max du systeme.
  @HiveField(4)
  double volume;

  /// Identifiant de voix preferentielle (renvoye par FlutterTts.getVoices).
  /// null = voix par defaut du moteur TTS pour la langue selectionnee.
  @HiveField(5)
  String? preferredVoice;

  /// Lecture automatique de l'enonce des qu'une question s'ouvre dans l'ecran
  /// de revision. Useful pour les eleves malvoyants. false par defaut (peut
  /// surprendre / deranger en transport).
  @HiveField(6)
  bool autoPlayOnQuestionOpen;

  /// Lire egalement la reponse apres l'enonce (ou apres que l'eleve a tape
  /// "Voir la reponse"). Permet la revision purement auditive.
  @HiveField(7)
  bool autoPlayAnswers;

  /// Surligner les mots au fur et a mesure de la lecture (synchronisation
  /// visuelle). Aide la comprehension (lecture + ecoute simultanees).
  @HiveField(8)
  bool highlightTextAsSpoken;

  TtsSettings({
    this.enabled = true,
    this.language = 'fr-FR',
    this.speechRate = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.preferredVoice,
    this.autoPlayOnQuestionOpen = false,
    this.autoPlayAnswers = false,
    this.highlightTextAsSpoken = true,
  });

  /// Cree une copie avec des champs modifies. Sert pour les mises a jour
  /// immutables dans TtsService.updateSettings().
  TtsSettings copyWith({
    bool? enabled,
    String? language,
    double? speechRate,
    double? pitch,
    double? volume,
    String? preferredVoice,
    bool clearVoice = false,
    bool? autoPlayOnQuestionOpen,
    bool? autoPlayAnswers,
    bool? highlightTextAsSpoken,
  }) {
    return TtsSettings(
      enabled: enabled ?? this.enabled,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      preferredVoice:
          clearVoice ? null : (preferredVoice ?? this.preferredVoice),
      autoPlayOnQuestionOpen:
          autoPlayOnQuestionOpen ?? this.autoPlayOnQuestionOpen,
      autoPlayAnswers: autoPlayAnswers ?? this.autoPlayAnswers,
      highlightTextAsSpoken:
          highlightTextAsSpoken ?? this.highlightTextAsSpoken,
    );
  }

  /// Reinitalise toutes les preferences a leurs valeurs par defaut.
  void reset() {
    enabled = true;
    language = 'fr-FR';
    speechRate = 1.0;
    pitch = 1.0;
    volume = 1.0;
    preferredVoice = null;
    autoPlayOnQuestionOpen = false;
    autoPlayAnswers = false;
    highlightTextAsSpoken = true;
    save();
  }

  /// True si au moins une option "comportement" est activee (auto-play ou
  /// surlignage). Sert a masquer l'intro "TTS actif mais aucun comportement
  /// specifique" dans l'ecran de reglages.
  bool get hasAnyBehavior =>
      autoPlayOnQuestionOpen || autoPlayAnswers || highlightTextAsSpoken;

  /// Code langue court sans region (ex : 'fr-FR' -> 'fr'). Sert a filtrer
  /// les voix disponibles retournees par FlutterTts.getVoices().
  String get languageCode => language.split('-').first.toLowerCase();

  @override
  String toString() =>
      'TtsSettings(enabled=$enabled, lang=$language, rate=$speechRate, '
      'pitch=$pitch, volume=$volume, voice=${preferredVoice ?? "default"}, '
      'autoQ=$autoPlayOnQuestionOpen, autoA=$autoPlayAnswers, '
      'highlight=$highlightTextAsSpoken)';
}
