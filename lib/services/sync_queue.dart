// lib/services/sync_queue.dart
// File d'attente persistante des actions offline a synchroniser.
//
// Architecture :
//   - Stockage Hive (box 'sync_queue') — cle = action.id, valeur = SyncAction.
//   - Tri FIFO par createdAt pour l'envoi.
//   - Persistance garantie meme si l'app est tuee / redemarree.
//
// Invariants :
//   - Une action marquee syncedAt n'est jamais renvoyee.
//   - Une action avec retryCount >= 5 est "abandonnee" (skip automatique).
//   - cleanupOldSynced() purge les actions syncedAt > 7 jours (audit DB leger).
//
// Cette classe est volontairement sans logique reseau : elle ne fait que
// stocker / lister / marquer. La logique d'envoi est dans SyncService.

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/sync_action.dart';
import '../utils/app_logger.dart';

class SyncQueue {
  static const String boxName = 'sync_queue';
  static const Duration defaultRetention = Duration(days: 7);

  final Uuid _uuid = const Uuid();

  late Box<SyncAction> _box;
  bool _initialized = false;

  // ─── Initialisation ──────────────────────────────────────────────

  /// Ouvre la box Hive (doit etre appele avant toute autre methode).
  /// Idempotent : peut etre appele plusieurs fois sans effet de bord.
  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<SyncAction>(boxName);
    _initialized = true;
    AppLogger.info(
      'SyncQueue initialise — ${_box.length} actions en file '
      '(${pendingCount} en attente, ${syncedCount} synchronisees)',
    );
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError(
        'SyncQueue.init() doit etre appele avant toute operation. '
        'Verifiez que SyncService.init() est bien appele au démarrage.',
      );
    }
  }

  // ─── Enqueue ─────────────────────────────────────────────────────

  /// Ajoute une action a la file.
  ///
  /// [type] : type d'action (reviewAnswer, bktUpdate, ...).
  /// [payload] : donnees specifiques au type (voir SyncAction doc).
  ///
  /// Retourne l'action creee (utile pour les tests et les logs).
  Future<SyncAction> enqueue(
    SyncActionType type,
    Map<String, dynamic> payload,
  ) async {
    _ensureInit();
    final action = SyncAction(
      id: _uuid.v4(),
      type: type,
      payload: Map<String, dynamic>.from(payload),
      createdAt: DateTime.now(),
      retryCount: 0,
    );
    await _box.put(action.id, action);
    AppLogger.debug(
      'SyncQueue: action ${action.type.name} enfilee (id=${action.id.substring(0, 8)}...) — '
      '${pendingCount} actions en attente',
    );
    return action;
  }

  // ─── Lecture ─────────────────────────────────────────────────────

  /// Retourne les actions en attente de sync, triees FIFO (createdAt asc).
  ///
  /// [limit] : nombre max d'actions a retourner (defaut 50, max 200).
  /// Les actions abandonnees (retryCount >= 5) sont exclues.
  List<SyncAction> getPending({int limit = 50}) {
    _ensureInit();
    final clampedLimit = limit.clamp(1, 200);
    final pending = _box.values.where((a) => a.shouldRetry).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pending.take(clampedLimit).toList();
  }

  /// Retourne les actions abandonnees (trop de retries).
  /// Utile pour l'ecran de parametres (permet a l'utilisateur de les
  /// reinitialiser ou de les supprimer manuellement).
  List<SyncAction> getAbandoned() {
    _ensureInit();
    return _box.values.where((a) => a.isAbandoned).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Retourne l'historique des actions sync (les plus recentes d'abord).
  /// Utilise pour l'ecran de parametres (debug / transparence).
  List<SyncAction> getSynced({int limit = 50}) {
    _ensureInit();
    final synced = _box.values.where((a) => a.isSynced).toList()
      ..sort((a, b) => b.syncedAt!.compareTo(a.syncedAt!));
    return synced.take(limit).toList();
  }

  // ─── Mise a jour d'etat ──────────────────────────────────────────

  /// Marque une action comme synchronisee avec succes.
  Future<void> markSynced(String actionId) async {
    _ensureInit();
    final action = _box.get(actionId);
    if (action == null) {
      AppLogger.warn('SyncQueue.markSynced: action $actionId introuvable');
      return;
    }
    action.syncedAt = DateTime.now();
    action.errorMessage = null;
    await action.save();
  }

  /// Marque une action comme echouee (incremente retryCount + enregistre
  /// l'erreur). Si retryCount atteint 5, l'action devient "abandonnee".
  Future<void> markFailed(String actionId, String error) async {
    _ensureInit();
    final action = _box.get(actionId);
    if (action == null) {
      AppLogger.warn('SyncQueue.markFailed: action $actionId introuvable');
      return;
    }
    action.retryCount++;
    action.errorMessage = error;
    await action.save();
    AppLogger.debug(
      'SyncQueue: action ${action.id.substring(0, 8)}... echec #${action.retryCount} — $error',
    );
  }

  /// Reinitialise le compteur de retries d'une action abandonnee
  /// (permet de la re-tenter manuellement).
  Future<void> resetRetry(String actionId) async {
    _ensureInit();
    final action = _box.get(actionId);
    if (action == null) return;
    action.retryCount = 0;
    action.errorMessage = null;
    await action.save();
  }

  // ─── Suppression ─────────────────────────────────────────────────

  /// Purge les actions synchronisees de plus de [retention] jours.
  /// Par defaut : 7 jours. A appeler periodiquement apres chaque sync.
  Future<int> cleanupOldSynced({
    Duration retention = defaultRetention,
  }) async {
    _ensureInit();
    final cutoff = DateTime.now().subtract(retention);
    final toDelete = _box.values
        .where((a) => a.isSynced && a.syncedAt!.isBefore(cutoff))
        .toList();

    for (final action in toDelete) {
      await _box.delete(action.id);
    }

    if (toDelete.isNotEmpty) {
      AppLogger.info(
        'SyncQueue.cleanupOldSynced: ${toDelete.length} actions purgees '
        '(> ${retention.inDays} jours)',
      );
    }
    return toDelete.length;
  }

  /// Supprime une action specifique (par id).
  Future<void> delete(String actionId) async {
    _ensureInit();
    await _box.delete(actionId);
  }

  /// Supprime toutes les actions en attente + abandonnees (DANGER).
  /// Utilise par le bouton "Annuler toutes les actions en attente" dans
  /// l'ecran de parametres. Les actions deja synchronisees sont conservees
  /// pour l'historique (jusqu'a cleanupOldSynced).
  ///
  /// Retourne le nombre d'actions supprimees.
  Future<int> clearPending() async {
    _ensureInit();
    final toDelete = _box.values.where((a) => !a.isSynced).toList();
    for (final action in toDelete) {
      await _box.delete(action.id);
    }
    AppLogger.warn(
      'SyncQueue.clearPending: ${toDelete.length} actions supprimees (annulation manuelle)',
    );
    return toDelete.length;
  }

  /// Reinitialise le compteur de retries de toutes les actions abandonnees.
  /// Permet de re-tenter un batch apres une panne reseau prolongee.
  Future<int> resetAllAbandoned() async {
    _ensureInit();
    final abandoned = getAbandoned();
    for (final action in abandoned) {
      action.retryCount = 0;
      action.errorMessage = null;
      await action.save();
    }
    return abandoned.length;
  }

  // ─── Compteurs ───────────────────────────────────────────────────

  /// Nombre d'actions en attente (non synchronisees, retryable).
  int get pendingCount =>
      _box.values.where((a) => !a.isSynced && a.shouldRetry).length;

  /// Nombre d'actions abandonnees (trop de retries).
  int get abandonedCount =>
      _box.values.where((a) => a.isAbandoned).length;

  /// Nombre d'actions synchronisees avec succes.
  int get syncedCount =>
      _box.values.where((a) => a.isSynced).length;

  /// Nombre total d'actions dans la file (tous statuts confondus).
  int get totalCount => _box.length;

  /// True si aucune action en attente.
  bool get isEmpty => pendingCount == 0 && abandonedCount == 0;

  // ─── Diagnostic ──────────────────────────────────────────────────

  /// Retourne un recap pour debug / logs.
  Map<String, dynamic> snapshot() {
    _ensureInit();
    final byType = <String, int>{};
    for (final action in _box.values) {
      final key = action.type.name;
      byType[key] = (byType[key] ?? 0) + 1;
    }
    return {
      'total': totalCount,
      'pending': pendingCount,
      'abandoned': abandonedCount,
      'synced': syncedCount,
      'by_type': byType,
    };
  }
}
