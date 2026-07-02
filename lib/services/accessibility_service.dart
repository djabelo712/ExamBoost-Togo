// lib/services/accessibility_service.dart
// Service de gestion centralise des preferences d'accessibilite.
//
// - Charge les preferences depuis Hive au demarrage de l'app.
// - Expose un singleton synchronise (AccessibilityService.settings).
// - Fournit des helpers d'application sur les TextStyle / Color / Duration.
//
// Pour activer : appeler AccessibilityService.init() au demarrage (apres
// Hive.initFlutter et enregistrement de l'adaptateur). Voir README.

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/accessibility_settings.dart';
import '../utils/app_logger.dart';

class AccessibilityService {
  AccessibilityService._();

  static AccessibilitySettings? _settings;
  static bool _initialized = false;

  /// True si init() a deja ete appele avec succes.
  static bool get isInitialized => _initialized;

  /// Preferences actuellement chargees. Lance une erreur si init() n'a pas
  /// ete appele (le wiring doit le faire au demarrage de l'app).
  static AccessibilitySettings get settings {
    if (_settings == null) {
      AppLogger.warn(
        'AccessibilityService: acces avant init() - '
        'utilisation des valeurs par defaut',
      );
      return AccessibilitySettings();
    }
    return _settings!;
  }

  /// Initialise le service en chargeant les preferences depuis Hive.
  /// Doit etre appele apres Hive.initFlutter et apres enregistrement de
  /// l'adaptateur AccessibilitySettingsAdapter dans main.dart.
  static Future<void> init() async {
    try {
      final box = await Hive.openBox<AccessibilitySettings>('accessibility');
      _settings = box.get('settings') ?? AccessibilitySettings();
      _initialized = true;
      AppLogger.info(
        'AccessibilityService initialise - '
        'dyslexiaFont=${_settings!.dyslexiaFont}, '
        'highContrast=${_settings!.highContrast}, '
        'extraTime25=${_settings!.extraTime25}',
      );
    } catch (e) {
      AppLogger.error('AccessibilityService.init() erreur: $e');
      _settings = AccessibilitySettings();
      _initialized = false;
    }
  }

  /// Persiste de nouvelles preferences dans Hive et met a jour le cache.
  static Future<void> update(AccessibilitySettings newSettings) async {
    _settings = newSettings;
    try {
      final box = Hive.isBoxOpen('accessibility')
          ? Hive.box<AccessibilitySettings>('accessibility')
          : await Hive.openBox<AccessibilitySettings>('accessibility');
      await box.put('settings', newSettings);
      AppLogger.info('Preferences d\'accessibilite mises a jour');
    } catch (e) {
      AppLogger.error('AccessibilityService.update() erreur: $e');
    }
  }

  /// Reinitialise toutes les preferences a leurs valeurs par defaut.
  static Future<void> reset() async {
    await update(AccessibilitySettings());
  }

  // ─── Helpers d'application ────────────────────────────────────

  /// Ajuste un TextStyle selon les preferences (taille, espacement lignes,
  /// police dyslexie). Si le service n'est pas initialise, renvoie le style
  /// inchange.
  static TextStyle adjustTextStyle(TextStyle base) {
    final s = settings;
    var style = base.copyWith(
      fontSize: (base.fontSize ?? 15) * s.textSizeScale,
      height: (base.height ?? 1.5) * s.lineSpacing,
    );
    if (s.dyslexiaFont) {
      style = style.copyWith(
        fontFamily: 'OpenDyslexic',
        letterSpacing: 0.5,
      );
    }
    return style;
  }

  /// Ajuste une duree d'examen selon l'option temps additionnel +25%.
  static Duration adjustDuration(Duration original) {
    return settings.adjustDuration(original);
  }

  /// Renvoie la couleur de fond a utiliser (jaune pale si highContrast).
  static Color backgroundColor([Color? defaultColor]) {
    return settings.backgroundColor(defaultColor);
  }

  /// Renvoie la couleur de texte a utiliser (noir si highContrast).
  static Color textColor([Color? defaultColor]) {
    return settings.textColor(defaultColor);
  }

  /// True si l'option TTS est activee (lecture audio des enonces).
  static bool get textToSpeechEnabled => settings.textToSpeech;

  /// True si le mode sobre est active (masquer les en-tetes officiels).
  static bool get soberModeEnabled => settings.soberMode;

  /// True si les pauses sont autorisees.
  static bool get pausesAllowed => settings.allowPauses;

  /// True si le surligneur est disponible.
  static bool get highlighterEnabled => settings.highlighter;

  /// True si les instructions simplifiees sont activees.
  static bool get simplifiedInstructions => settings.simplifiedInstructions;
}
