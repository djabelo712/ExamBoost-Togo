// lib/providers/user_provider.dart
// Provider global qui gère l'utilisateur connecté (AppUser)
// - Au démarrage : lit SharedPreferences "current_user_id" et charge l'AppUser depuis Hive
// - Si pas d'utilisateur : redirect vers /onboarding (géré par le router)
// - Expose l'utilisateur courant + méthodes login/logout

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _initialized = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _initialized;

  /// ID de l'utilisateur courant (fallback 'user_demo' pour la démo)
  String get currentUserId => _currentUser?.id ?? 'user_demo';

  /// Initialise le provider au démarrage de l'app
  /// À appeler dans main.dart avant runApp()
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');

      if (userId != null) {
        final userBox = Hive.isBoxOpen('users')
            ? Hive.box<AppUser>('users')
            : await Hive.openBox<AppUser>('users');

        if (userBox.containsKey(userId)) {
          _currentUser = userBox.get(userId);
        }
      }
    } catch (e) {
      debugPrint('UserProvider.initialize() error: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Connecte un utilisateur (après onboarding ou login)
  Future<void> setCurrentUser(AppUser user) async {
    try {
      final userBox = Hive.isBoxOpen('users')
          ? Hive.box<AppUser>('users')
          : await Hive.openBox<AppUser>('users');

      await userBox.put(user.id, user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', user.id);

      _currentUser = user;
      notifyListeners();
    } catch (e) {
      debugPrint('UserProvider.setCurrentUser() error: $e');
    }
  }

  /// Déconnecte l'utilisateur courant
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    _currentUser = null;
    notifyListeners();
  }

  /// Rafraîchit l'utilisateur depuis Hive (utile après mise à jour BKT par d'autres écrans)
  Future<void> refresh() async {
    if (_currentUser == null) return;
    try {
      final userBox = Hive.isBoxOpen('users')
          ? Hive.box<AppUser>('users')
          : await Hive.openBox<AppUser>('users');

      if (userBox.containsKey(_currentUser!.id)) {
        _currentUser = userBox.get(_currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UserProvider.refresh() error: $e');
    }
  }
}
