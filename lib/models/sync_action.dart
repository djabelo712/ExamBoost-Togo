// lib/models/sync_action.dart
// Modele d'une action utilisateur a synchroniser vers le cloud.
//
// Une SyncAction est enregistree localement (Hive) des qu'elle est produite
// (reponse SRS, mise a jour BKT, resultat de simulation, etc.) puis envoyee
// au backend des que le reseau est disponible. La file d'attente persistante
// permet une utilisation 100 % offline-first.
//
// Generation de l'adaptateur Hive :
//   dart run build_runner build --delete-conflicting-outputs
//
// Note : typeId 10 choisi car 0-9 sont deja pris par Question, QuestionType,
// ReviewCard, AppUser, ScorePrediction, NotificationSettings,
// NotificationHistory, NotificationType, BadgeCategory, BadgeLevel, UserBadge.
// (voir README a la fin du fichier pour l'inventaire complet)

import 'package:hive/hive.dart';

part 'sync_action.g.dart';

/// Types d'actions synchronisables vers le cloud.
///
/// Chaque type correspond a une mutation de l'etat utilisateur qui doit etre
/// refletée côté serveur (BKT, SM-2, simulations, badges, compteurs).
@HiveType(typeId: 11)
enum SyncActionType {
  /// Reponse SRS (quality 0-5, question_id, time_spent_sec).
  ///
  /// Declenche cote serveur : apply_sm2() + update_bkt() + insertion Response.
  @HiveField(0)
  reviewAnswer,

  /// Mise a jour BKT isolee (competence_id, correct).
  /// Utilise quand une reponse n'est pas liee a une question SRS classique.
  @HiveField(1)
  bktUpdate,

  /// Resultat de simulation d'examen (score, examen, serie, duree, nb_questions).
  @HiveField(2)
  simulationResult,

  /// Progres general (compteurs questions answered, sessions count).
  @HiveField(3)
  userProgress,

  /// Badge debloque (badge_id, unlocked_at).
  /// Cote serveur : un badge debloque ne peut jamais etre re-verrouille.
  @HiveField(4)
  badgeUnlock,
}

/// Action a synchroniser vers le cloud.
///
/// Concept offline-first : chaque interaction utilisateur produit une
/// SyncAction immediatement persistee dans Hive. Le [SyncService] la pousse
/// ensuite au backend des que possible (WiFi/donnees), avec retry et backoff
/// exponentiel en cas d'echec.
///
/// Politique de retention :
///   - Actions non synchronisees : conservees indefiniment (jusqu'a 5 retries).
///   - Actions synchronisees : purgees apres 7 jours via cleanupOldSynced().
@HiveType(typeId: 10)
class SyncAction extends HiveObject {
  /// Identifiant unique (UUID v4) — sert de cle primaire dans Hive et
  /// d'idempotency key cote serveur.
  @HiveField(0)
  final String id;

  /// Type d'action (determine le traitement backend).
  @HiveField(1)
  final SyncActionType type;

  /// Donnees de l'action (format variable selon [type]).
  ///
  /// Exemples :
  ///   - reviewAnswer : {quality, question_id, time_spent_sec, correct, competence_id}
  ///   - bktUpdate : {competence_id, correct, pL_before, pL_after}
  ///   - simulationResult : {examen, serie, score, duration_sec, nb_questions}
  ///   - userProgress : {questions_answered_delta, sessions_count_delta}
  ///   - badgeUnlock : {badge_id, unlocked_at}
  @HiveField(2)
  final Map<String, dynamic> payload;

  /// Horodatage de creation (cote client). Sert pour le tri FIFO de la file
  /// et pour la resolution de conflits CRDT (Last-Write-Wins).
  @HiveField(3)
  final DateTime createdAt;

  /// Horodatage de la confirmation de sync cote serveur.
  /// null = pas encore synchronise.
  @HiveField(4)
  DateTime? syncedAt;

  /// Nombre de tentatives de sync effectuees (0 au depart).
  /// Au-dela de 5 retries, l'action est marquee comme "abandonnee" et ne sera
  /// plus reessayee automatiquement (peut etre forcee via l'ecran de parametres).
  @HiveField(5)
  int retryCount;

  /// Dernier message d'erreur rencontre (null si succes).
  /// utile pour afficher dans l'ecran de parametres de sync.
  @HiveField(6)
  String? errorMessage;

  SyncAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.syncedAt,
    this.retryCount = 0,
    this.errorMessage,
  });

  // ─── Getters de commodite ──────────────────────────────────────────

  /// True si l'action a ete confirmee par le serveur.
  bool get isSynced => syncedAt != null;

  /// True si l'action peut encore etre tente (pas synchronisee et moins de
  /// 5 echecs). Au-dela, on considere l'action comme corrompue / obsolete.
  bool get shouldRetry => !isSynced && retryCount < 5;

  /// True si l'action a ete definitivement abandonnee apres trop d'echecs.
  bool get isAbandoned => !isSynced && retryCount >= 5;

  // ─── Serialisation JSON (pour logs / debug / payloads reseau) ──────

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
        'retry_count': retryCount,
        'error_message': errorMessage,
      };

  @override
  String toString() =>
      'SyncAction(id=$id, type=$type, createdAt=$createdAt, '
      'synced=${isSynced}, retries=$retryCount)';
}

/*
   Inventaire des typeIds Hive (a jour au 30 juin 2026) :

   0  Question                lib/models/question.dart
   1  QuestionType            lib/models/question.dart
   2  ReviewCard              lib/models/review_card.dart
   3  AppUser                 lib/models/user.dart
   4  (libre)
   5  NotificationSettings    lib/models/notification_settings.dart
   6  NotificationHistory     lib/models/notification_history.dart
   7  NotificationType        lib/models/notification_history.dart
   7  BadgeCategory           lib/models/badge.dart (conflit potentiel a verifier)
   8  BadgeLevel              lib/models/badge.dart
   9  UserBadge               lib/models/badge.dart
   10 SyncAction              lib/models/sync_action.dart       <-- ce fichier
   11 SyncActionType          lib/models/sync_action.dart       <-- ce fichier

   TODO agent wiring : verifier la duplication typeId 7 entre
   NotificationType et BadgeCategory et ajuster si besoin.
*/
