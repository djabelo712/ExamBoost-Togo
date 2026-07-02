// lib/providers/theme_provider.dart
// Provider global qui gere le ThemeMode (clair / sombre / systeme) au runtime.
//
// - Au demarrage : lit SharedPreferences 'theme_mode' (par defaut 'system').
// - setThemeMode() : sauvegarde + notifyListeners → MaterialApp rebuild avec
//   themeMode mis a jour (via context.watch<ThemeProvider>() dans main.dart).
//
// Utilisation :
//   final tp = Provider.of<ThemeProvider>(context, listen: false);
//   tp.setThemeMode(ThemeMode.dark);

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _kPrefKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _initialized;

  /// Raccourcis pratiques pour la UI (SegmentedControl).
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isSystem => _themeMode == ThemeMode.system;

  /// Initialise le ThemeMode depuis SharedPreferences. A appeler dans
  /// main.dart avant runApp().
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kPrefKey);
      if (stored != null) {
        _themeMode = _parseThemeMode(stored) ?? ThemeMode.system;
      }
    } catch (_) {
      // Erreur non bloquante : on garde ThemeMode.system par defaut.
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Change le ThemeMode courant, persiste, et notifie.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKey, mode.name);
    } catch (_) {
      // Erreur non bloquante.
    }
  }

  /// Convertit une String ('light' | 'dark' | 'system') en ThemeMode.
  static ThemeMode? _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}
