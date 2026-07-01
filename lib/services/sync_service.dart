// lib/services/sync_service.dart
// Orchestrateur principal de synchronisation cloud offline-first.
//
// Responsabilites :
//   1. Maintenir un [SyncState] expose a l'UI (ChangeNotifier).
//   2. Ecouter la connectivite reseau (WiFi/donnees/none) via connectivity_plus.
//   3. Pousser les [SyncAction] en attente vers le backend avec backoff
//      exponentiel en cas d'echec.
//   4. Appliquer la resolution de conflits (ConflictResolver) sur les
//      reponses serveur.
//   5. Persister l'historique des syncs (SyncHistoryEntry) pour l'ecran
//      de parametres.
//
// Integration (voir README de la task AC-sync-cloud) :
//   final syncService = SyncService();
//   await syncService.init();
//   // apres chaque action utilisateur :
//   await syncService.recordAction(
//     SyncActionType.reviewAnswer,
//     payload: {'question_id': '...', 'quality': 4, ...},
//   );

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sync_action.dart';
import '../models/sync_status.dart';
import '../utils/app_logger.dart';
import 'sync_queue.dart';

// Re-export pour que les consommateurs de SyncService aient acces aux types
// SyncStatus / SyncState / SyncSettings / SyncHistoryEntry sans avoir a
// importer explicitement models/sync_status.dart.
export '../models/sync_status.dart';
export '../models/sync_action.dart' show SyncActionType;

/// Signature du callback pour recuperer le token JWT courant.
/// Permet d'eviter un couplage direct avec UserProvider / AuthService.
typedef AuthTokenProvider = String? Function();

/// Signature du callback pour recuperer l'ID utilisateur courant.
typedef UserIdProvider = String? Function();

class SyncService extends ChangeNotifier {
  SyncService({
    required SyncQueue queue,
    required Dio dio,
    required Connectivity connectivity,
    String baseUrl = 'http://localhost:8000',
    AuthTokenProvider? authTokenProvider,
    UserIdProvider? userIdProvider,
  })  : _queue = queue,
        _dio = dio,
        _connectivity = connectivity,
        _baseUrl = baseUrl,
        _authTokenProvider = authTokenProvider,
        _userIdProvider = userIdProvider;

  // ─── Deps ────────────────────────────────────────────────────────
  final SyncQueue _queue;
  final Dio _dio;
  final Connectivity _connectivity;
  final String _baseUrl;
  final AuthTokenProvider? _authTokenProvider;
  final UserIdProvider? _userIdProvider;

  // ─── Etat ────────────────────────────────────────────────────────
  SyncState _state = SyncState.initial();
  SyncSettings _settings = SyncSettings.defaultSettings;
  SyncState get state => _state;
  SyncSettings get settings => _settings;

  // Alias pratiques pour l'UI
  SyncStatus get status => _state.status;
  int get pendingCount => _state.pendingCount;
  DateTime? get lastSyncAt => _state.lastSyncAt;
  String? get lastError => _state.lastError;
  int? get retryInSeconds => _state.retryInSeconds;
  int get abandonedCount => _queue.abandonedCount;
  int get syncedCount => _queue.syncedCount;

  // ─── Subscriptions & timers ──────────────────────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _autoSyncTimer;
  Timer? _retryTimer;
  Timer? _statusResetTimer;
  Timer? _retryCountdownTimer;

  bool _disposed = false;
  bool _isSyncing = false; // garde anti-reentrance

  // Box Hive pour l'historique de sync (max 20 entrees).
  static const String _historyBoxName = 'sync_history';
  static const int _historyMaxEntries = 20;
  Box<SyncHistoryEntry>? _historyBox;

  // Cles SharedPreferences pour les settings
  static const String _prefsKeySettings = 'sync_settings_v1';
  static const String _prefsKeyLastSync = 'sync_last_sync_at_v1';

  // ─── Init ────────────────────────────────────────────────────────

  /// Initialise le service : ouvre les boxes, charge les settings,
  /// demarre l'ecoute connectivite + auto-sync.
  ///
  /// Doit etre appele une seule fois au demarrage de l'app, apres
  /// Hive.initFlutter() et l'enregistrement des adapters.
  Future<void> init() async {
    if (_disposed) return;

    // 1. File d'attente
    await _queue.init();

    // 2. Box historique
    _historyBox = await Hive.openBox<SyncHistoryEntry>(_historyBoxName);

    // 3. Charge les settings persistes
    await _loadSettings();

    // 4. Charge le dernier timestamp de sync
    await _loadLastSyncAt();

    // 5. Maj etat initial
    _state = _state.copyWith(pendingCount: _queue.pendingCount);
    notifyListeners();

    // 6. Ecoute connectivite
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (Object e) =>
          AppLogger.error('SyncService: erreur stream connectivite : $e'),
    );

    // 7. Auto-sync timer (frequence depuis settings)
    _scheduleAutoSync();

    // 8. Tente une sync initiale si online
    final initial = await _connectivity.checkConnectivity();
    if (_hasConnection(initial)) {
      // Sync asynchrone pour ne pas bloquer init()
      unawaited(syncNow(reason: 'init'));
    }

    AppLogger.info(
      'SyncService initialise — baseUrl=$_baseUrl, '
      'pending=${_queue.pendingCount}, settings=$_settings',
    );
  }

  // ─── Sync principale ─────────────────────────────────────────────

  /// Lance une sync immediate. Si une sync est deja en cours, retourne
  /// immediatement (anti-reentrance).
  ///
  /// [reason] : motif de sync pour logs (init, manual, networkRestored, auto).
  Future<void> syncNow({String reason = 'manual'}) async {
    if (_disposed) return;
    if (_isSyncing) {
      AppLogger.debug('SyncService.syncNow: deja en cours (reason=$reason), skip');
      return;
    }

    // Verifie connectivite
    final conn = await _connectivity.checkConnectivity();
    if (!_hasConnection(conn)) {
      _state = _state.copyWith(
        status: SyncStatus.offline,
        pendingCount: _queue.pendingCount,
        clearRetry: true,
      );
      notifyListeners();
      AppLogger.debug('SyncService.syncNow: hors-ligne, skip (reason=$reason)');
      return;
    }

    // Respecte les settings : WiFi-only ou WiFi+mobile
    if (!_shouldSyncOn(conn)) {
      AppLogger.debug(
        'SyncService.syncNow: connexion ${conn.last} non autorisee par settings, skip',
      );
      return;
    }

    // Recupere les actions a envoyer
    final pending = _queue.getPending(limit: 50);
    if (pending.isEmpty) {
      _state = _state.copyWith(
        status: SyncStatus.idle,
        pendingCount: 0,
        clearError: true,
        clearRetry: true,
      );
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _state = _state.copyWith(
      status: SyncStatus.syncing,
      pendingCount: pending.length,
      clearError: true,
      clearRetry: true,
    );
    notifyListeners();

    AppLogger.info(
      'SyncService.syncNow: debut (reason=$reason, ${pending.length} actions)',
    );

    int successCount = 0;
    int failCount = 0;
    String? firstError;

    for (final action in pending) {
      if (_disposed) break;
      try {
        await _sendAction(action);
        await _queue.markSynced(action.id);
        successCount++;
      } catch (e) {
        await _queue.markFailed(action.id, e.toString());
        failCount++;
        firstError ??= e.toString();

        // Backoff exponentiel : si trop d'erreurs consecutives, on arrete.
        if (failCount >= 5) {
          final backoffSec = _backoffSeconds(action.retryCount);
          AppLogger.warn(
            'SyncService.syncNow: $failCount echecs, backoff ${backoffSec}s',
          );
          _state = _state.copyWith(
            status: SyncStatus.error,
            pendingCount: _queue.pendingCount,
            lastError: 'Trop d\'echecs. Reessai dans ${backoffSec}s',
            retryInSeconds: backoffSec,
          );
          notifyListeners();

          // Planifie retry avec countdown
          _scheduleRetry(backoffSec);

          // Persiste l'entree d'historique
          await _addHistoryEntry(
            SyncHistoryEntry(
              timestamp: DateTime.now(),
              status: SyncHistoryStatus.error,
              successCount: successCount,
              failCount: failCount,
              remainingCount: _queue.pendingCount,
              errorMessage: firstError,
            ),
          );

          _isSyncing = false;
          return;
        }
      }
    }

    // Finalisation
    final remaining = _queue.pendingCount;
    final newStatus = failCount == 0
        ? SyncStatus.success
        : (successCount > 0
            ? SyncStatus.partialError
            : SyncStatus.error);

    _state = _state.copyWith(
      status: newStatus,
      pendingCount: remaining,
      lastError: newStatus == SyncStatus.success ? null : firstError,
      lastSyncAt: DateTime.now(),
      clearRetry: true,
    );
    notifyListeners();

    // Persiste le timestamp
    await _saveLastSyncAt(DateTime.now());

    // Persiste l'entree d'historique
    await _addHistoryEntry(
      SyncHistoryEntry(
        timestamp: DateTime.now(),
        status: _toHistoryStatus(newStatus),
        successCount: successCount,
        failCount: failCount,
        remainingCount: remaining,
        errorMessage: newStatus == SyncStatus.success ? null : firstError,
      ),
    );

    // Cleanup anciennes actions sync (retention 7 jours)
    await _queue.cleanupOldSynced();

    // Auto-reset status apres 5s si success
    if (newStatus == SyncStatus.success) {
      _statusResetTimer?.cancel();
      _statusResetTimer = Timer(const Duration(seconds: 5), () {
        if (_disposed) return;
        if (_state.status == SyncStatus.success) {
          _state = _state.copyWith(status: SyncStatus.idle);
          notifyListeners();
        }
      });
    }

    _isSyncing = false;
    AppLogger.info(
      'SyncService.syncNow: fin — success=$successCount, fail=$failCount, '
      'remaining=$remaining, status=$newStatus',
    );
  }

  // ─── Hook pour les actions utilisateur ───────────────────────────

  /// Hook a appeler apres chaque action utilisateur (reponse SRS, simulation,
  /// maj BKT, deblocage badge, ...).
  ///
  /// 1. Enfile l'action dans la queue persistante.
  /// 2. Si online et settings l'autorisent, declenche une sync immediate.
  ///
  /// Ne bloque JAMAIS l'UI : si une sync est lancee, elle s'execute en
  /// arriere-plan. Retourne l'action creee (utile pour tests / logs).
  Future<SyncAction> recordAction(
    SyncActionType type,
    Map<String, dynamic> payload, {
    bool immediateSync = true,
  }) async {
    if (_disposed) {
      // Si dispose, on enfile quand meme pour ne pas perdre l'action
      // (mais la sync ne se fera pas tant que init() n'est pas rappele).
    }
    final action = await _queue.enqueue(type, payload);

    // Maj pendingCount sans notifier excessivement
    _state = _state.copyWith(pendingCount: _queue.pendingCount);
    notifyListeners();

    if (immediateSync && !_isSyncing) {
      final conn = await _connectivity.checkConnectivity();
      if (_hasConnection(conn) && _shouldSyncOn(conn)) {
        // Sync async — ne bloque pas l'appelant
        unawaited(syncNow(reason: 'recordAction'));
      }
    }
    return action;
  }

  // ─── Settings ────────────────────────────────────────────────────

  /// Met a jour les settings et persiste en SharedPreferences.
  /// Replanifie aussi l'auto-sync timer avec la nouvelle frequence.
  Future<void> updateSettings(SyncSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    _scheduleAutoSync();
    AppLogger.info('SyncService: settings mis a jour — $newSettings');
  }

  // ─── Actions manuelles (ecran de parametres) ─────────────────────

  /// Annule toutes les actions en attente + abandonnees (DANGER).
  /// Retourne le nombre d'actions supprimees.
  Future<int> cancelAllPending() async {
    final count = await _queue.clearPending();
    _state = _state.copyWith(
      pendingCount: _queue.pendingCount,
      status: SyncStatus.idle,
      clearError: true,
      clearRetry: true,
    );
    notifyListeners();
    return count;
  }

  /// Reinitialise les retries de toutes les actions abandonnees et
  /// tente une sync immediate.
  Future<void> retryAbandoned() async {
    final count = await _queue.resetAllAbandoned();
    if (count > 0) {
      AppLogger.info('SyncService: $count actions abandonnees reinitialisees');
      _state = _state.copyWith(pendingCount: _queue.pendingCount);
      notifyListeners();
      unawaited(syncNow(reason: 'retryAbandoned'));
    }
  }

  /// Historique des syncs pour l'ecran de parametres.
  List<SyncHistoryEntry> getHistory({int limit = 20}) {
    if (_historyBox == null) return [];
    final entries = _historyBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }

  // ─── Connectivite ────────────────────────────────────────────────

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (_disposed) return;
    if (_hasConnection(results)) {
      // Reseau de retour — sync si settings l'autorisent
      if (_shouldSyncOn(results) && _queue.pendingCount > 0) {
        unawaited(syncNow(reason: 'networkRestored'));
      } else {
        // On a un reseau mais pas autorise par settings -> reste idle/offline
        _state = _state.copyWith(status: SyncStatus.idle);
        notifyListeners();
      }
    } else {
      // Perte reseau
      _state = _state.copyWith(
        status: SyncStatus.offline,
        pendingCount: _queue.pendingCount,
      );
      notifyListeners();
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  bool _shouldSyncOn(List<ConnectivityResult> results) {
    final hasWifi = results.contains(ConnectivityResult.wifi);
    final hasMobile = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet);
    final hasVpn = results.contains(ConnectivityResult.vpn);

    // Si auto-sync completement off, on n'auto-sync jamais (manuel uniquement).
    if (_settings.isManual) return true; // sync manuelle autorisee sur tout reseau

    if (hasWifi || hasVpn) return _settings.autoSyncOnWifi;
    if (hasMobile) return _settings.autoSyncOnMobile;
    return false;
  }

  // ─── Auto-sync timer ─────────────────────────────────────────────

  void _scheduleAutoSync() {
    _autoSyncTimer?.cancel();
    final minutes = _settings.autoSyncIntervalMinutes;
    if (minutes == 0) return; // manuel uniquement

    _autoSyncTimer = Timer.periodic(
      Duration(minutes: minutes),
      (_) {
        if (_disposed) return;
        if (_queue.pendingCount > 0 && !_isSyncing) {
          unawaited(syncNow(reason: 'autoTimer'));
        }
      },
    );
  }

  // ─── Retry avec backoff exponentiel ──────────────────────────────

  void _scheduleRetry(int backoffSeconds) {
    _retryTimer?.cancel();
    _retryCountdownTimer?.cancel();

    int remaining = backoffSeconds;
    _retryCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_disposed) {
        t.cancel();
        return;
      }
      remaining--;
      if (remaining <= 0) {
        t.cancel();
      } else {
        _state = _state.copyWith(retryInSeconds: remaining);
        notifyListeners();
      }
    });

    _retryTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (_disposed) return;
      unawaited(syncNow(reason: 'backoffRetry'));
    });
  }

  int _backoffSeconds(int retryCount) {
    // 1, 2, 4, 8, 16, 32 (clamp 1..60)
    return (1 << retryCount).clamp(1, 60);
  }

  // ─── Envoi reseau ────────────────────────────────────────────────

  Future<void> _sendAction(SyncAction action) async {
    final token = _authTokenProvider?.call();
    final userId = _userIdProvider?.call();

    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = <String, dynamic>{
      'action_id': action.id,
      'type': action.type.name,
      'payload': action.payload,
      'created_at': action.createdAt.toIso8601String(),
      if (userId != null) 'user_id': userId,
      // Idempotency : retry_count envoye pour que le serveur puisse log
      'retry_count': action.retryCount,
    };

    try {
      final response = await _dio.post(
        '$_baseUrl/sync/action',
        data: jsonEncode(body),
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'HTTP ${response.statusCode}',
        );
      }

      // Le serveur peut retourner une valeur resolue (conflit) — on l'ignore
      // ici : la resolution cote client se fait au moment du pull (future tache).
      // Pour cette version, on se contente de marquer l'action comme sync.
    } on DioException catch (e) {
      // Erreurs reseau : timeout, pas de connexion, 5xx...
      final code = e.type.name;
      final status = e.response?.statusCode;
      throw Exception('Dio $code (HTTP $status): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // ─── Persistence (settings + last sync) ──────────────────────────

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeySettings);
      if (raw != null) {
        final json = const JsonDecoder().convert(raw) as Map<String, dynamic>;
        _settings = SyncSettings(
          autoSyncOnWifi: json['autoSyncOnWifi'] as bool? ?? true,
          autoSyncOnMobile: json['autoSyncOnMobile'] as bool? ?? false,
          autoSyncIntervalMinutes:
              (json['autoSyncIntervalMinutes'] as num?)?.toInt() ?? 5,
        );
      }
    } catch (e) {
      AppLogger.warn('SyncService._loadSettings: echec ($e), garde defaut');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = const JsonEncoder().convert({
        'autoSyncOnWifi': _settings.autoSyncOnWifi,
        'autoSyncOnMobile': _settings.autoSyncOnMobile,
        'autoSyncIntervalMinutes': _settings.autoSyncIntervalMinutes,
      });
      await prefs.setString(_prefsKeySettings, json);
    } catch (e) {
      AppLogger.error('SyncService._saveSettings: $e');
    }
  }

  Future<void> _loadLastSyncAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final iso = prefs.getString(_prefsKeyLastSync);
      if (iso != null) {
        _state = _state.copyWith(lastSyncAt: DateTime.parse(iso));
      }
    } catch (_) {
      // ignore — pas grave si on perd le dernier timestamp
    }
  }

  Future<void> _saveLastSyncAt(DateTime dt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyLastSync, dt.toIso8601String());
    } catch (_) {}
  }

  // ─── Historique ──────────────────────────────────────────────────

  Future<void> _addHistoryEntry(SyncHistoryEntry entry) async {
    if (_historyBox == null) return;
    final id = '${entry.timestamp.millisecondsSinceEpoch}_${entry.status.name}';
    await _historyBox!.put(id, entry);

    // Trim au-delà de _historyMaxEntries
    if (_historyBox!.length > _historyMaxEntries) {
      final all = _historyBox!.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toDelete = all.take(all.length - _historyMaxEntries);
      for (final e in toDelete) {
        await _historyBox!.delete(e.key);
      }
    }
  }

  Future<void> clearHistory() async {
    if (_historyBox == null) return;
    await _historyBox!.clear();
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  SyncHistoryStatus _toHistoryStatus(SyncStatus s) {
    switch (s) {
      case SyncStatus.success:
        return SyncHistoryStatus.success;
      case SyncStatus.partialError:
        return SyncHistoryStatus.partialError;
      case SyncStatus.error:
        return SyncHistoryStatus.error;
      case SyncStatus.offline:
        return SyncHistoryStatus.offline;
      case SyncStatus.idle:
      case SyncStatus.syncing:
        return SyncHistoryStatus.success; // ne devrait pas arriver
    }
  }

  // ─── Dispose ─────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    _autoSyncTimer?.cancel();
    _retryTimer?.cancel();
    _statusResetTimer?.cancel();
    _retryCountdownTimer?.cancel();
    super.dispose();
  }
}

/// Helper static pour formatter un delai humain (utilise par les widgets).
String formatLastSync(DateTime? lastSyncAt) {
  if (lastSyncAt == null) return 'Jamais synchronise';
  final delta = DateTime.now().difference(lastSyncAt);
  if (delta.inSeconds < 60) return 'A l\'instant';
  if (delta.inMinutes < 60) return 'Il y a ${delta.inMinutes} min';
  if (delta.inHours < 24) return 'Il y a ${delta.inHours} h';
  if (delta.inDays < 7) return 'Il y a ${delta.inDays} j';
  return lastSyncAt.toLocal().toString().substring(0, 16);
}
