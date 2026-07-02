// lib/models/notification_history.dart
// Historique des notifications locales envoyees par ExamBoost.
//
// Sert pour :
//   - debug (voir ce qui a ete pousse)
//   - anti-spam (eviter de re-pousser le meme message trop souvent)
//   - analytics futures (taux d'ouverture par categorie)
//
// Persiste dans la box Hive "notification_history".
// L'adaptateur NotificationHistoryAdapter + NotificationCategoryAdapter doivent
// etre enregistres dans main.dart (voir README notifications).
//
// Note typeIds : typeId 6 = NotificationCategory (enum, sans conflit).
//   typeId 7 etait utilise ici pour NotificationHistory MAIS entrait en conflit
//   avec BadgeCategory (lib/models/badge.dart) qui utilise aussi typeId 7.
//   On a deplace NotificationHistory vers typeId 19 pour eviter le conflit
//   (BadgeCategory et BadgeLevel sont ancrees historiquement sur 7 et 8).

import 'package:hive/hive.dart';

part 'notification_history.g.dart';

/// Categorie d'une notification — determine le channel Android utilise et le
/// comportement au tap (routing).
@HiveType(typeId: 6)
enum NotificationCategory {
  /// Rappel quotidien "c'est l'heure de reviser".
  @HiveField(0)
  reminders,

  /// Alerte "ton streak est en danger".
  @HiveField(1)
  streak,

  /// Comparaison sociale (mock backend).
  @HiveField(2)
  social,

  /// Nouvelles questions / features disponibles.
  @HiveField(3)
  updates,
}

/// Une entree de l'historique des notifications.
@HiveType(typeId: 19)
class NotificationHistory extends HiveObject {
  /// Identifiant unique (horodatage en millisecondes, stable suffisamment).
  @HiveField(0)
  final int id;

  /// Titre affiche dans la notification.
  @HiveField(1)
  final String title;

  /// Corps affiche dans la notification.
  @HiveField(2)
  final String body;

  /// Categorie (channel).
  @HiveField(3)
  final NotificationCategory category;

  /// Date/heure d'envoi effectif.
  @HiveField(4)
  final DateTime sentAt;

  /// Vrai si l'utilisateur a tape sur la notification.
  @HiveField(5)
  bool wasTapped;

  /// Date/heure du tap (null si pas encore tape).
  @HiveField(6)
  DateTime? tappedAt;

  /// Payload libre (action ciblee, ex: "open_revision:Mathematiques").
  /// Stocke sous forme de String pour rester compatible Hive facilement.
  @HiveField(7)
  final String? payload;

  NotificationHistory({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.sentAt,
    this.wasTapped = false,
    this.tappedAt,
    this.payload,
  });

  /// Marque la notification comme ouverte (appele quand l'utilisateur tape).
  void markTapped() {
    wasTapped = true;
    tappedAt = DateTime.now();
    save();
  }

  @override
  String toString() =>
      'NotificationHistory(#$id, $category, "$title", sent=$sentAt, '
      'tapped=$wasTapped)';
}
