// lib/models/sync_status.dart
// Statut de synchronisation : enum + model rich pour UI et logs.
//
// Ce fichier centralise toute la semantique de statut :
//   - SyncStatus : etat courant du SyncService (idle, syncing, success, ...)
//   - SyncHistoryEntry : entree d'historique persistee pour l'ecran de parametres
//   - SyncSettings : preferences utilisateur (auto-sync, WiFi only, frequence)
//
// Separe de sync_service.dart pour eviter les imports circulaires
// (les widgets et l'ecran de parametres importent uniquement ce fichier).

import 'package:hive/hive.dart';

part 'sync_status.g.dart';

/// Etat courant du SyncService.
///
/// Transitions principales :
///   idle -> syncing -> success -> idle (apres 5s)
///   idle -> syncing -> partialError -> idle
///   idle -> syncing -> error -> (retry backoff) -> syncing -> ...
///   *  -> idle (annulation manuelle via cancelAll)
enum SyncStatus {
  /// Aucune sync en cours, aucune action en attente.
  idle,

  /// Sync en cours (envoi des actions au serveur).
  syncing,

  /// Toutes les actions ont ete synchronisees avec succes.
  success,

  /// Certaines actions ont echoue (mais pas assez pour bloquer la file).
  partialError,

  /// Trop d'echecs consecutifs — backoff exponentiel en cours.
  error,

  /// Mode hors-ligne : aucune connexion reseau detectee.
  offline,
}

/// Etat complet du SyncService pour affichage UI.
///
/// [SyncStatus] seul ne suffit pas a afficher un bandeau informatif : il faut
/// aussi le nombre d'actions en attente, le timestamp de la derniere sync
/// et le message d'erreur eventuel.
class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? lastError;
  final int? retryInSeconds;

  const SyncState({
    required this.status,
    this.pendingCount = 0,
    this.lastSyncAt,
    this.lastError,
    this.retryInSeconds,
  });

  factory SyncState.initial() => const SyncState(status: SyncStatus.idle);

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncAt,
    String? lastError,
    int? retryInSeconds,
    bool clearError = false,
    bool clearRetry = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      retryInSeconds: clearRetry ? null : (retryInSeconds ?? this.retryInSeconds),
    );
  }

  /// True si une sync est en cours ou imminente.
  bool get isActive => status == SyncStatus.syncing;

  /// True si on devrait afficher un indicateur d'erreur a l'utilisateur.
  bool get hasError =>
      status == SyncStatus.error || status == SyncStatus.partialError;

  /// True si on devrait afficher un bandeau non-idle.
  bool get shouldShowBanner => status != SyncStatus.idle;
}

/// Entree d'historique de sync (persistee en Hive pour l'ecran de parametres).
///
/// On garde les 20 dernieres entrees pour debug + transparence utilisateur.
@HiveType(typeId: 12)
class SyncHistoryEntry extends HiveObject {
  /// Horodatage de la tentative de sync.
  @HiveField(0)
  final DateTime timestamp;

  /// Statut final de la tentative.
  @HiveField(1)
  final SyncHistoryStatus status;

  /// Nombre d'actions envoyees avec succes.
  @HiveField(2)
  final int successCount;

  /// Nombre d'actions en echec.
  @HiveField(3)
  final int failCount;

  /// Nombre d'actions restantes apres la tentative.
  @HiveField(4)
  final int remainingCount;

  /// Message d'erreur (si status != success).
  @HiveField(5)
  final String? errorMessage;

  SyncHistoryEntry({
    required this.timestamp,
    required this.status,
    required this.successCount,
    required this.failCount,
    required this.remainingCount,
    this.errorMessage,
  });

  /// Nombre total d'actions traitees pendant cette sync.
  int get totalProcessed => successCount + failCount;
}

/// Statut simplifie pour l'historique (subset de SyncStatus utile pour
/// le recap utilisateur).
@HiveType(typeId: 13)
enum SyncHistoryStatus {
  @HiveField(0)
  success,
  @HiveField(1)
  partialError,
  @HiveField(2)
  error,
  @HiveField(3)
  offline,
}

/// Preferences de sync utilisateur (persistees en SharedPreferences, pas Hive,
/// pour rester leger — mais on definit le modele ici pour centraliser).
class SyncSettings {
  /// Si true, declenche la sync automatique quand le WiFi revient.
  final bool autoSyncOnWifi;

  /// Si true, declenche la sync automatique sur donnees mobiles.
  /// Default false : on evite de consommer le forfait data sans accord.
  final bool autoSyncOnMobile;

  /// Frequence de sync automatique en minutes (1, 5, 15 ou 0 = manuel).
  final int autoSyncIntervalMinutes;

  const SyncSettings({
    this.autoSyncOnWifi = true,
    this.autoSyncOnMobile = false,
    this.autoSyncIntervalMinutes = 5,
  });

  SyncSettings copyWith({
    bool? autoSyncOnWifi,
    bool? autoSyncOnMobile,
    int? autoSyncIntervalMinutes,
  }) {
    return SyncSettings(
      autoSyncOnWifi: autoSyncOnWifi ?? this.autoSyncOnWifi,
      autoSyncOnMobile: autoSyncOnMobile ?? this.autoSyncOnMobile,
      autoSyncIntervalMinutes:
          autoSyncIntervalMinutes ?? this.autoSyncIntervalMinutes,
    );
  }

  /// True si l'auto-sync est completement desactive (manuel uniquement).
  bool get isManual =>
      !autoSyncOnWifi && !autoSyncOnMobile ||
      autoSyncIntervalMinutes == 0;

  static const SyncSettings defaultSettings = SyncSettings();
}
