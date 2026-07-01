// lib/utils/notification_actions.dart
// Gestion des actions au tap sur une notification.
//
// Le payload des notifications est encode en JSON (Map<String, String>).
// Ce fichier decode le payload et renvoie la route GoRouter ciblee.
//
// Usage (a brancher dans main.dart par l'agent principal) :
//
//   NotificationService().onTap = (payloadStr) {
//     final route = NotificationActions.routeFromPayload(payloadStr);
//     if (route != null) appRouter.go(route);
//   };
//
// + au lancement (cold-start), dans main.dart apres runApp :
//
//   final launchDetails = await NotificationService().launchDetails();
//   if (launchDetails?.didNotificationLaunchApp ?? false) {
//     final route = NotificationActions.routeFromPayload(
//       launchDetails!.notificationResponse?.payload,
//     );
//     if (route != null) appRouter.go(route);
//   }

import 'dart:convert';

import 'app_logger.dart';

/// Actions possibles au tap sur une notification.
enum NotificationAction {
  /// Ouvrir l'ecran de revision (matiere optionnelle dans le payload).
  openRevision,

  /// Ouvrir le dashboard.
  openDashboard,

  /// Ouvrir l'accueil.
  openHome,

  /// Ouvrir l'ecan de simulation.
  openSimulation,

  /// Ouvrir les settings notifications.
  openSettingsNotifications,

  /// Action inconnue / pas de routage.
  none,
}

class NotificationActions {
  NotificationActions._();

  /// Parse un payload JSON String en Map.
  /// Renvoie null si le payload est null ou invalide.
  static Map<String, dynamic>? parsePayload(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) return null;
    try {
      return jsonDecode(payloadStr) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.warn('Payload non-JSON, tentative format simple: $e');
      // Tentative : peut-etre un format "action:value"
      final parts = payloadStr.split(':');
      if (parts.length >= 2) {
        return {'action': parts[0], 'value': parts.sublist(1).join(':')};
      }
      return null;
    }
  }

  /// Determine l'action a partir du payload decode.
  static NotificationAction actionFromPayload(String? payloadStr) {
    final payload = parsePayload(payloadStr);
    if (payload == null) return NotificationAction.none;

    final action = payload['action']?.toString();
    switch (action) {
      case 'open_revision':
        return NotificationAction.openRevision;
      case 'open_dashboard':
        return NotificationAction.openDashboard;
      case 'open_home':
        return NotificationAction.openHome;
      case 'open_simulation':
        return NotificationAction.openSimulation;
      case 'open_settings_notifications':
        return NotificationAction.openSettingsNotifications;
      default:
        return NotificationAction.none;
    }
  }

  /// Renvoie la route GoRouter ciblee a partir du payload.
  /// Retourne null si aucune route a suivre (action = none).
  ///
  /// Pour openRevision : si le payload contient 'matiere', on encode l'URL.
  /// Sinon, on ouvre la revision sur "Mathematiques" par defaut.
  static String? routeFromPayload(String? payloadStr) {
    final action = actionFromPayload(payloadStr);
    switch (action) {
      case NotificationAction.openRevision:
        final payload = parsePayload(payloadStr);
        final matiere = payload?['matiere']?.toString() ?? 'Mathematiques';
        return '/revision/${Uri.encodeComponent(matiere)}';
      case NotificationAction.openDashboard:
        return '/dashboard';
      case NotificationAction.openHome:
        return '/';
      case NotificationAction.openSimulation:
        return '/simulation';
      case NotificationAction.openSettingsNotifications:
        return '/settings/notifications';
      case NotificationAction.none:
        return null;
    }
  }

  /// Verifie que la route cible est bien une route valide de l'app.
  /// (utile pour eviter d'envoyer l'utilisateur vers une route inexistante
  /// lors d'un cold-start avec un payload stale.)
  static bool isKnownRoute(String? route) {
    if (route == null) return false;
    // Routes simples
    if (route == '/' ||
        route == '/dashboard' ||
        route == '/simulation' ||
        route == '/settings/notifications' ||
        route == '/onboarding') {
      return true;
    }
    // Routes parametrees (ex: /revision/Mathematiques)
    if (route.startsWith('/revision/')) return true;
    return false;
  }
}
