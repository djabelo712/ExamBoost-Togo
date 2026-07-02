// lib/models/notification_settings.dart
// Préférences de notifications de l'utilisateur (persistées via Hive).
//
// Contient : rappel quotidien (heure), alertes streak, notifications sociales,
// alertes nouvelles questions, statut permission, derniere notification sociale.
//
// Attention : pour fonctionner, l'adaptateur NotificationSettingsAdapter doit
// etre enregistre dans main.dart (Hive.registerAdapter) avant ouverture de la
// box "notification_settings". Voir README notifications pour le wiring.

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hive/hive.dart';

part 'notification_settings.g.dart';

/// Preferences de notifications locales de l'utilisateur.
///
/// Chaque champ est editable individuellement ; l'objet est persiste via Hive
/// dans la box "notification_settings" (cle : "current").
@HiveType(typeId: 5)
class NotificationSettings extends HiveObject {
  /// Active/desactive le rappel quotidien a heure fixe.
  @HiveField(0)
  bool dailyReminderEnabled;

  /// Heure du rappel quotidien (0-23).
  @HiveField(1)
  int preferredHour;

  /// Minute du rappel quotidien (0-59).
  @HiveField(2)
  int preferredMinute;

  /// Active les alertes "streak en danger".
  @HiveField(3)
  bool streakAlertsEnabled;

  /// Active les notifications sociales (comparaison avec autres eleves).
  @HiveField(4)
  bool socialNudgesEnabled;

  /// Active les alertes "nouvelles questions disponibles".
  @HiveField(5)
  bool newQuestionsAlertsEnabled;

  /// Derniere fois qu'on a pousse une notification sociale (anti-spam hebdo).
  @HiveField(6)
  DateTime? lastSocialNudgeDate;

  /// Vrai si la permission OS a deja ete demandee au moins une fois.
  /// Permet de ne pas re-poser la question a chaque lancement.
  @HiveField(7)
  bool permissionRequested;

  /// Date a laquelle on peut re-demander la permission (si refus initial).
  @HiveField(8)
  DateTime? nextPermissionPromptDate;

  NotificationSettings({
    this.dailyReminderEnabled = true,
    this.preferredHour = 18,
    this.preferredMinute = 0,
    this.streakAlertsEnabled = true,
    this.socialNudgesEnabled = false,
    this.newQuestionsAlertsEnabled = true,
    this.lastSocialNudgeDate,
    this.permissionRequested = false,
    this.nextPermissionPromptDate,
  });

  /// Renvoie l'heure preferree sous forme de TimeOfDay (Material).
  TimeOfDay get preferredReminderTime =>
      TimeOfDay(hour: preferredHour, minute: preferredMinute);

  /// Met a jour l'heure preferree depuis un TimeOfDay.
  void setPreferredTime(TimeOfDay t) {
    preferredHour = t.hour;
    preferredMinute = t.minute;
    save();
  }

  /// Marque la permission comme demandee et programme un rappel dans 7 jours
  /// si l'utilisateur a refuse (pour re-demander poliment plus tard).
  void markPermissionRequested({required bool granted}) {
    permissionRequested = true;
    if (!granted) {
      nextPermissionPromptDate =
          DateTime.now().add(const Duration(days: 7));
    } else {
      nextPermissionPromptDate = null;
    }
    save();
  }

  /// Indique si on peut re-demander la permission maintenant.
  bool get canRePromptPermission {
    if (permissionRequested && nextPermissionPromptDate == null) return false;
    if (nextPermissionPromptDate == null) return true;
    return DateTime.now().isAfter(nextPermissionPromptDate!);
  }

  /// Met a jour la date de derniere notification sociale (apres envoi).
  void markSocialNudgeSent() {
    lastSocialNudgeDate = DateTime.now();
    save();
  }

  /// Copie defensive pour eviter les effets de bord lors d'editions temporaires.
  NotificationSettings copy() => NotificationSettings(
        dailyReminderEnabled: dailyReminderEnabled,
        preferredHour: preferredHour,
        preferredMinute: preferredMinute,
        streakAlertsEnabled: streakAlertsEnabled,
        socialNudgesEnabled: socialNudgesEnabled,
        newQuestionsAlertsEnabled: newQuestionsAlertsEnabled,
        lastSocialNudgeDate: lastSocialNudgeDate,
        permissionRequested: permissionRequested,
        nextPermissionPromptDate: nextPermissionPromptDate,
      );

  @override
  String toString() =>
      'NotificationSettings(daily=$dailyReminderEnabled @ $preferredHour:$preferredMinute, '
      'streak=$streakAlertsEnabled, social=$socialNudgesEnabled, '
      'newQ=$newQuestionsAlertsEnabled, permissionAsked=$permissionRequested)';
}
