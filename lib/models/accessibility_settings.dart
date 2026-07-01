// lib/models/accessibility_settings.dart
// Preferences d'accessibilite de l'utilisateur (persistees via Hive).
//
// Contient : police dyslexie, contraste eleve, taille texte, espacement lignes,
// temps additionnel +25%, pauses autorisees, instructions simplifiees,
// surligneur, lecture audio (TTS).
//
// Attention : pour fonctionner, l'adaptateur AccessibilitySettingsAdapter doit
// etre enregistre dans main.dart (Hive.registerAdapter) avant ouverture de la
// box "accessibility". Voir lib/screens/simulation/README.md pour le wiring.

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'accessibility_settings.g.dart';

/// Preferences d'accessibilite de l'utilisateur (dyslexie, contraste, temps
/// additionnel, TTS, etc.). Persistees via Hive dans la box "accessibility"
/// (cle : "settings").
///
/// Par defaut, TOUTES les options sont desactivees (utilisateur standard sans
/// besoin specifique). L'eleve active manuellement ce dont il a besoin.
@HiveType(typeId: 8)
class AccessibilitySettings extends HiveObject {
  /// Utiliser une police adaptee aux dyslexiques (OpenDyslexic si disponible,
  /// sinon Roboto avec espacement augmente).
  @HiveField(0)
  bool dyslexiaFont;

  /// Contraste eleve : texte noir sur fond jaune clair (ou noir sur blanc pur).
  @HiveField(1)
  bool highContrast;

  /// Facteur d'echelle de la taille du texte (1.0 = normal, 1.5 = 150%...).
  /// Plage recommandee : 0.85 (S) a 2.0 (XXL).
  @HiveField(2)
  double textSizeScale;

  /// Facteur d'espacement entre les lignes (1.0 = normal, 2.0 = double).
  @HiveField(3)
  double lineSpacing;

  /// Temps additionnel +25% pour les eleves avec handicap. Prolonge la duree
  /// officielle de l'examen (ex : 2h -> 2h30).
  @HiveField(4)
  bool extraTime25;

  /// Autoriser l'eleve a mettre l'examen en pause (le temps continue de
  /// compter, mais l'ecran peut etre masque temporairement).
  @HiveField(5)
  bool allowPauses;

  /// Reecrire les enonces en version simplifiee (phrases courtes, vocabulaire
  /// reduit). Necessite un fichier de reecriture (non inclus v1).
  @HiveField(6)
  bool simplifiedInstructions;

  /// Autoriser l'eleve a surligner des mots dans l'enonce.
  @HiveField(7)
  bool highlighter;

  /// Lecture audio (TTS) des enonces. Affiche un bouton "lire" a cote de
  /// chaque question.
  @HiveField(8)
  bool textToSpeech;

  /// Mode sobre : masque les en-tetes officiels (Republicque Togolaise, etc.)
  /// pour les eleves qui preferent un affichage minimaliste.
  @HiveField(9)
  bool soberMode;

  /// Vibration lors des alertes de temps (30min, 10min, 5min, 1min, 0:00).
  /// Mobile uniquement (ignore sur desktop/web).
  @HiveField(10)
  bool vibrationAlerts;

  AccessibilitySettings({
    this.dyslexiaFont = false,
    this.highContrast = false,
    this.textSizeScale = 1.0,
    this.lineSpacing = 1.0,
    this.extraTime25 = false,
    this.allowPauses = false,
    this.simplifiedInstructions = false,
    this.highlighter = false,
    this.textToSpeech = false,
    this.soberMode = false,
    this.vibrationAlerts = true,
  });

  /// Cree une copie avec des champs modifies.
  AccessibilitySettings copyWith({
    bool? dyslexiaFont,
    bool? highContrast,
    double? textSizeScale,
    double? lineSpacing,
    bool? extraTime25,
    bool? allowPauses,
    bool? simplifiedInstructions,
    bool? highlighter,
    bool? textToSpeech,
    bool? soberMode,
    bool? vibrationAlerts,
  }) {
    return AccessibilitySettings(
      dyslexiaFont: dyslexiaFont ?? this.dyslexiaFont,
      highContrast: highContrast ?? this.highContrast,
      textSizeScale: textSizeScale ?? this.textSizeScale,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      extraTime25: extraTime25 ?? this.extraTime25,
      allowPauses: allowPauses ?? this.allowPauses,
      simplifiedInstructions: simplifiedInstructions ?? this.simplifiedInstructions,
      highlighter: highlighter ?? this.highlighter,
      textToSpeech: textToSpeech ?? this.textToSpeech,
      soberMode: soberMode ?? this.soberMode,
      vibrationAlerts: vibrationAlerts ?? this.vibrationAlerts,
    );
  }

  /// Ajuste une duree d'examen en fonction de l'option temps additionnel.
  /// Si extraTime25 est true, renvoie original * 1.25 (arrondi a la seconde).
  Duration adjustDuration(Duration original) {
    if (!extraTime25) return original;
    return Duration(
      seconds: (original.inSeconds * 1.25).round(),
    );
  }

  /// Renvoie la couleur de fond a utiliser pour un container selon le
  /// contraste. Si highContrast est true, on utilise du jaune pale pour
  /// maximiser la lisibilite (texte noir sur jaune).
  Color backgroundColor([Color? defaultColor]) {
    if (highContrast) {
      return const Color(0xFFFFF9C4); // Jaune pale
    }
    return defaultColor ?? Colors.white;
  }

  /// Renvoie la couleur de texte a utiliser selon le contraste.
  Color textColor([Color? defaultColor]) {
    if (highContrast) {
      return Colors.black;
    }
    return defaultColor ?? const Color(0xFF1A1A1A);
  }

  /// True si au moins une option d'accessibilite est activee.
  bool get hasAnyAdjustment =>
      dyslexiaFont ||
      highContrast ||
      textSizeScale != 1.0 ||
      lineSpacing != 1.0 ||
      extraTime25 ||
      simplifiedInstructions ||
      highlighter ||
      textToSpeech;
}
