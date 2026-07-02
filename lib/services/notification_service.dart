// lib/services/notification_service.dart
// Service principal des notifications locales ExamBoost.
//
// Responsabilites :
//   - Initialiser le plugin flutter_local_notifications
//   - Creer les channels Android (reminders / streak / social / updates)
//   - Exposer showNow() / scheduleAt() / scheduleDaily() / cancel() / cancelAll()
//   - Brancher le callback de tap (onDidReceiveNotificationResponse)
//   - Enregistrer chaque notification envoyee dans l'historique Hive
//
// Usage typique (a brancher dans main.dart par l'agent principal) :
//   await NotificationService().init();
//   NotificationService().onTap = (payload) { ... };
//
// Contraintes :
//   - Le package `timezone` est une dependance transitive de
//     flutter_local_notifications (voir pubspec.lock). Il est importable
//     directement, mais l'agent principal devrait l'ajouter en dependance
//     directe de pubspec.yaml (timezone: ^0.9.4) pour respecter les bonnes
//     pratiques Dart.

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_history.dart';
import '../utils/app_logger.dart';
import 'notification_templates.dart' show NotificationTemplates;

// Re-export de l'enum pour respecter la spec : "enum NotificationCategory"
// est defini dans notification_history.dart (persiste via Hive) et re-exporte
// ici pour les consommateurs qui importent notification_service.dart.
export '../models/notification_history.dart' show NotificationCategory;

/// Service principal des notifications locales.
///
/// Singleton : `NotificationService()` renvoie toujours la meme instance.
class NotificationService {
  // ─── Singleton ────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─── Identifiants de channels Android ─────────────────────────
  static const String channelRemindersId = 'examboost_reminders';
  static const String channelRemindersName = 'Rappels ExamBoost';
  static const String channelRemindersDesc =
      'Rappels quotidiens pour t\'aider a reviser regulierement.';

  static const String channelStreakId = 'examboost_streak';
  static const String channelStreakName = 'Alertes streak';
  static const String channelStreakDesc =
      'Alertes urgentes quand ton streak est en danger.';

  static const String channelSocialId = 'examboost_social';
  static const String channelSocialName = 'Notifications sociales';
  static const String channelSocialDesc =
      'Comparaison amicale avec d\'autres eleves.';

  static const String channelUpdatesId = 'examboost_updates';
  static const String channelUpdatesName = 'Nouveautes';
  static const String channelUpdatesDesc =
      'Nouvelles questions et fonctionnalites disponibles.';

  /// Callback de tap — settable par l'app (typiquement dans main.dart).
  /// Recoit le payload String de la notification (peut etre null).
  void Function(String? payload)? onTap;

  // ─── Initialization ───────────────────────────────────────────
  /// Initialise le plugin + timezone + channels Android.
  /// Idempotent : peut etre appele plusieurs fois sans danger.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // ─── Timezone (necessaire pour zonedSchedule) ────────────
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Lome'));
      } catch (_) {
        // Fallback : UTC. Le Togo est a UTC+0 sans DST donc ok.
      }

      // ─── Settings Android + Linux (desktop pour test) ────────
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Linux : pour tests desktop uniquement. On tente, on ignore si
      // la plateforme ne supporte pas.
      LinuxInitializationSettings? linuxInit;
      try {
        linuxInit = const LinuxInitializationSettings(
          defaultActionName: 'Ouvrir ExamBoost',
        );
      } catch (_) {
        linuxInit = null;
      }

      // iOS / macOS : placeholders pour le futur (pas critique V1).
      // const darwinInit = DarwinInitializationSettings();

      final initSettings = InitializationSettings(
        android: androidInit,
        linux: linuxInit,
        // iOS / macOS laisses a null : non supportes en V1.
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTap,
      );

      // ─── Creation des channels Android ───────────────────────
      await _createChannels();

      _initialized = true;
      AppLogger.info('NotificationService initialise avec succes');
    } catch (e, st) {
      AppLogger.error('NotificationService.init() erreur: $e\n$st');
    }
  }

  /// Cree les 4 channels Android (importance + descriptions differentes).
  Future<void> _createChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return; // pas Android, on skip

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      channelRemindersId,
      channelRemindersName,
      description: channelRemindersDesc,
      importance: Importance.defaultImportance,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      channelStreakId,
      channelStreakName,
      description: channelStreakDesc,
      importance: Importance.high, // streak = urgent
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      channelSocialId,
      channelSocialName,
      description: channelSocialDesc,
      importance: Importance.low,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      channelUpdatesId,
      channelUpdatesName,
      description: channelUpdatesDesc,
      importance: Importance.defaultImportance,
    ));
  }

  // ─── Notification immediate ───────────────────────────────────
  /// Affiche une notification immediatement.
  ///
  /// [payload] : map libre encodee en JSON et passee au callback de tap.
  /// Ex: {'action': 'open_revision', 'matiere': 'Mathematiques'}.
  Future<int> showNow({
    required String title,
    required String body,
    required NotificationCategory category,
    Map<String, String>? payload,
    int? id,
  }) async {
    if (!_initialized) {
      AppLogger.warn('NotificationService.showNow() appele avant init()');
      await init();
    }

    final notifId = id ?? _generateId();
    final payloadStr = payload != null ? jsonEncode(payload) : null;

    final androidDetails = _androidDetailsFor(category);
    final notifDetails = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        notifId,
        title,
        body,
        notifDetails,
        payload: payloadStr,
      );
      await _recordHistory(
        id: notifId,
        title: title,
        body: body,
        category: category,
        payload: payloadStr,
      );
    } catch (e) {
      AppLogger.error('NotificationService.showNow() erreur: $e');
    }
    return notifId;
  }

  // ─── Notification planifiee a une date/heure ──────────────────
  /// Planifie une notification unique a [scheduledTime].
  ///
  /// [id] doit etre fourni pour pouvoir l'annuler plus tard. Si non fourni,
  /// un ID auto-genere est utilise (mais on ne pourra pas l'annuler
  /// precisement — utiliser cancelAll() dans ce cas).
  Future<int> scheduleAt({
    required DateTime scheduledTime,
    required String title,
    required String body,
    required NotificationCategory category,
    Map<String, String>? payload,
    int id = 0,
  }) async {
    if (!_initialized) await init();

    final payloadStr = payload != null ? jsonEncode(payload) : null;
    final androidDetails = _androidDetailsFor(category);
    final notifDetails = NotificationDetails(android: androidDetails);

    final tzDateTime = _toTz(scheduledTime);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payloadStr,
      );
      await _recordHistory(
        id: id,
        title: title,
        body: body,
        category: category,
        payload: payloadStr,
        scheduled: true,
        scheduledFor: scheduledTime,
      );
    } catch (e) {
      AppLogger.error('NotificationService.scheduleAt() erreur: $e');
    }
    return id;
  }

  // ─── Notification quotidienne repetitive ──────────────────────
  /// Planifie une notification qui se repete chaque jour a [time].
  ///
  /// Utilise DateTimeComponents.time pour matcher uniquement l'heure + minute.
  /// [id] doit etre fixe (sinon on ecrase le rappel precedent).
  Future<int> scheduleDaily({
    required TimeOfDay time,
    required String title,
    required String body,
    required NotificationCategory category,
    required int id,
    Map<String, String>? payload,
  }) async {
    if (!_initialized) await init();

    final payloadStr = payload != null ? jsonEncode(payload) : null;
    final androidDetails = _androidDetailsFor(category);
    final notifDetails = NotificationDetails(android: androidDetails);

    // Construire la prochaine occurence (aujourd'hui si l'heure n'est pas
    // encore passee, sinon demain).
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final tzDateTime = _toTz(scheduled);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payloadStr,
        matchDateComponents: const DateTimeComponents(
          TimeOfDayComponents.hourAndMinute,
        ),
      );
      AppLogger.info(
          'scheduleDaily #$id a ${time.hour}:${time.minute} - "$title"');
    } catch (e) {
      AppLogger.error('NotificationService.scheduleDaily() erreur: $e');
    }
    return id;
  }

  // ─── Annulations ──────────────────────────────────────────────
  /// Annule une notification planifiee par son ID.
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      AppLogger.error('NotificationService.cancel($id) erreur: $e');
    }
  }

  /// Annule TOUTES les notifications planifiees.
  /// Utilise par le bouton "Desactiver toutes les notifications" dans settings.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
      AppLogger.info('Toutes les notifications annulees');
    } catch (e) {
      AppLogger.error('NotificationService.cancelAll() erreur: $e');
    }
  }

  /// Renvoie les details de lancement (si l'app a ete ouverte via une notif).
  /// A appeler dans main.dart au demarrage pour gerer le tap cold-start.
  Future<NotificationAppLaunchDetails?> launchDetails() async {
    if (!_initialized) return null;
    try {
      return await _plugin.getNotificationAppLaunchDetails();
    } catch (_) {
      return null;
    }
  }

  // ─── Handlers de tap ──────────────────────────────────────────
  /// Handler de tap (foreground / warm start).
  void _onNotificationTap(NotificationResponse response) {
    try {
      _markHistoryTapped(response.id);
      onTap?.call(response.payload);
    } catch (e) {
      AppLogger.error('onNotificationTap erreur: $e');
    }
  }

  /// Handler de tap en background (top-level static, requis par le plugin).
  /// En background, on ne peut pas acceder a l'instance singleton (le runtime
  /// peut etre isole). On se contente de logguer.
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    AppLogger.info('Notif background tappee: id=${response.id}');
  }

  // ─── Helpers internes ─────────────────────────────────────────
  /// Genere un ID unique base sur l'horodatage (evite les collisions).
  int _generateId() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// Convertit un DateTime en TZDateTime dans la zone locale.
  tz.TZDateTime _toTz(DateTime dt) {
    final loc = tz.local;
    return tz.TZDateTime.from(dt, loc);
  }

  /// Renvoie les AndroidNotificationDetails appropries pour la categorie.
  AndroidNotificationDetails _androidDetailsFor(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.reminders:
        return const AndroidNotificationDetails(
          channelRemindersId,
          channelRemindersName,
          channelDescription: channelRemindersDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        );
      case NotificationCategory.streak:
        return const AndroidNotificationDetails(
          channelStreakId,
          channelStreakName,
          channelDescription: channelStreakDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
      case NotificationCategory.social:
        return const AndroidNotificationDetails(
          channelSocialId,
          channelSocialName,
          channelDescription: channelSocialDesc,
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
        );
      case NotificationCategory.updates:
        return const AndroidNotificationDetails(
          channelUpdatesId,
          channelUpdatesName,
          channelDescription: channelUpdatesDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        );
    }
  }

  // ─── Historique Hive ──────────────────────────────────────────
  /// Enregistre une notification dans la box "notification_history".
  Future<void> _recordHistory({
    required int id,
    required String title,
    required String body,
    required NotificationCategory category,
    String? payload,
    bool scheduled = false,
    DateTime? scheduledFor,
  }) async {
    try {
      final box = Hive.isBoxOpen('notification_history')
          ? Hive.box<NotificationHistory>('notification_history')
          : await Hive.openBox<NotificationHistory>('notification_history');

      final entry = NotificationHistory(
        id: id,
        title: title,
        body: body,
        category: category,
        sentAt: scheduledFor ?? DateTime.now(),
        payload: payload,
      );
      await box.put('notif_$id', entry);
    } catch (e) {
      // L'historique est best-effort : on ne casse pas l'envoi de notif
      // si l'enregistrement echoue.
      AppLogger.warn('Impossible d\'enregistrer dans l\'historique: $e');
    }
  }

  /// Marque une notification comme "tapee" dans l'historique.
  Future<void> _markHistoryTapped(int? id) async {
    if (id == null) return;
    try {
      final box = Hive.isBoxOpen('notification_history')
          ? Hive.box<NotificationHistory>('notification_history')
          : await Hive.openBox<NotificationHistory>('notification_history');
      final entry = box.get('notif_$id');
      if (entry != null) {
        entry.markTapped();
      }
    } catch (_) {
      // best-effort
    }
  }

  // ─── Helper de test (UI bouton "envoyer test") ────────────────
  /// Envoie une notification test (bouton dans l'ecran de settings).
  Future<void> sendTestNotification() async {
    final msg = NotificationTemplates.testMessage();
    await showNow(
      title: msg.title,
      body: msg.body,
      category: NotificationCategory.updates,
      payload: {'action': 'test'},
    );
  }

  /// Plateforme courante supporte-t-elle les notifications locales ?
  /// (Linux desktop = oui pour test, Android = oui, iOS = futur).
  bool get isSupported {
    if (kIsWeb) return false; // notifications web non supportees
    return Platform.isAndroid || Platform.isLinux || Platform.isIOS;
  }
}
