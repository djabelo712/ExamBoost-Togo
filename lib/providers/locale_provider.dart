// lib/providers/locale_provider.dart
// Provider global qui gere la locale courante (FR / EN) au runtime.
//
// - Au demarrage : lit SharedPreferences 'user_locale' (par defaut 'fr').
// - setLocale() : sauvegarde + notifyListeners → MaterialApp rebuild avec
//   la nouvelle locale (via context.watch<LocaleProvider>() dans main.dart).
//
// Utilisation :
//   final lp = Provider.of<LocaleProvider>(context, listen: false);
//   lp.setLocale(const Locale('en'));

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  /// Locale par defaut : francais (langue d'enseignement au Togo).
  static const String _kPrefKey = 'user_locale';
  static const String _kDefaultLanguageCode = 'fr';

  Locale _locale = const Locale(_kDefaultLanguageCode);
  bool _initialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _initialized;

  /// Initialise la locale depuis SharedPreferences. A appeler dans main.dart
  /// avant runApp() (await) pour eviter un flash FR au demarrage si l'user
  /// avait choisi EN.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kPrefKey);
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
      }
    } catch (_) {
      // En cas d'erreur, on garde la locale par defaut (FR).
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Change la locale courante, persiste en SharedPreferences, et notifie
  /// les widgets qui ecoutent (notamment MaterialApp via themeMode).
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKey, newLocale.languageCode);
    } catch (_) {
      // Erreur non bloquante : la locale a deja ete changee en memoire.
    }
  }

  /// Bascule FR <-> EN (utilise par un bouton "Switch langue" rapide).
  Future<void> toggleFrEn() async {
    final next =
        _locale.languageCode == 'fr' ? const Locale('en') : const Locale('fr');
    await setLocale(next);
  }
}
