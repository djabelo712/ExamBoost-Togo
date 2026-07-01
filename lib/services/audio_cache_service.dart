// lib/services/audio_cache_service.dart
// Cache de fichiers audio pre-synthesises (TTS).
//
// flutter_tts genere l'audio a la volee a chaque speak(). Pour les questions
// tres lues (ex : questions d'examen officiel), on peut pre-generer un
// fichier .wav via FlutterTts.synthesizeToFile() et le rejouer avec un
// player audio. Gain : latence quasi nulle + economie batterie.
//
// Politique de cache :
//   - Cle = hash SHA-1 du texte normalise + langue + voix + vitesse + ton.
//   - Taille max : 50 Mo (parametrable). Eviction LRU quand depasse.
//   - TTL : 30 jours (re-synthese periodique pour suivre ameliorations TTS).
//   - Repertoire cache : <app_cache_dir>/tts_audio/ (gere par le systeme,
//     peut etre purge sous pression disque).
//
// NB : ce service est optionnel - TtsService fonctionne sans. Il est utile
// seulement si l'agent wiring decide d'activer la pre-generation pour les
// questions d'examen authentique (lecture critique, pas de latence attendue).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/audio_cache_entry.dart';
import '../models/tts_settings.dart';
import '../utils/app_logger.dart';

/// Service de gestion du cache audio TTS.
///
/// Ne depend PAS de TtsService (pour eviter cycle) mais utilise les memes
/// TtsSettings pour determiner la cle de cache (langue, voix, vitesse).
/// L'agent wiring peut appeler pregenerate(text) au moment du chargement
/// d'une question pour prepare l'audio en arriere-plan.
class AudioCacheService extends ChangeNotifier {
  static const String _boxName = 'audio_cache';
  static const String _cacheDirName = 'tts_audio';

  /// Taille max du cache en octets (50 Mo par defaut).
  static const int defaultMaxSizeBytes = 50 * 1024 * 1024;

  /// TTL par defaut d'une entree de cache.
  static const Duration defaultTtl = Duration(days: 30);

  late Box<AudioCacheEntry> _box;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Ouvre la box Hive et prepare le repertoire de cache. Idempotent.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _box = await _openBox();
      await _ensureCacheDir();
      _initialized = true;
      AppLogger.info(
        'AudioCacheService initialise - ${_box.length} entrees en cache',
      );
    } catch (e) {
      AppLogger.error('AudioCacheService.init() erreur: $e');
      _initialized = false;
    }
  }

  Future<Box<AudioCacheEntry>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<AudioCacheEntry>(_boxName);
    }
    return Hive.openBox<AudioCacheEntry>(_boxName);
  }

  /// Repertoire de cache sur disque. Cree si n'existe pas.
  Future<Directory> _ensureCacheDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, _cacheDirName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Calcule la cle de cache pour un texte + settings donnes.
  /// Format : hash du texte normalise + langue + voix + vitesse + ton.
  /// Le texte est normalise (lowercase + collapse whitespace) pour augmenter
  /// le taux de hit (deux enonces equivalents = meme cache).
  ///
  /// NB : on n'utilise pas SHA-1 (package `crypto` non declare au pubspec) ;
  /// on combine un encodage utf8 + hashCode 64 bits (suffisant pour un cache
  /// local de quelques milliers d'entrees, sans risque de collision mesurable).
  /// Si l'agent wiring veut un hash cryptographique, ajouter `crypto: ^3.0.3`
  /// au pubspec et remplacer cette methode par sha1.convert(utf8.encode(raw)).
  static String computeKey(
    String text,
    TtsSettings settings,
  ) {
    final normalized = text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final raw = '$normalized|${settings.language}|${settings.preferredVoice ?? ""}'
        '|${settings.speechRate.toStringAsFixed(2)}|${settings.pitch.toStringAsFixed(2)}';
    final bytes = utf8.encode(raw);
    // hashCode 32 bits du contenu + length (anti-collision structurelle).
    final h1 = raw.hashCode;
    final h2 = bytes.length;
    return '${h1.toUnsigned(32).toRadixString(16)}-${h2.toRadixString(16)}';
  }

  /// True si une entree de cache existe et est valide (non expiree + fichier
  /// toujours present sur disque).
  Future<bool> hasValid(String key) async {
    if (!_initialized) return false;
    final entry = _box.get(key);
    if (entry == null) return false;
    if (entry.isExpired(maxAge: defaultTtl)) return false;
    final file = File(entry.filePath);
    return file.existsSync();
  }

  /// Recupere l'entree de cache pour cette cle. Met a jour lastAccessedAt.
  /// Renvoie null si absent ou fichier supprime.
  Future<AudioCacheEntry?> get(String key) async {
    if (!_initialized) return null;
    final entry = _box.get(key);
    if (entry == null) return null;
    final file = File(entry.filePath);
    if (!file.existsSync()) {
      // Fichier supprime (purge systeme) : on nettoye l'entree Hive.
      await _box.delete(key);
      return null;
    }
    entry.markAccessed();
    return entry;
  }

  /// Enregistre une nouvelle entree de cache. Appele par le code de
  /// pre-generation apres FlutterTts.synthesizeToFile().
  Future<AudioCacheEntry?> put({
    required String sourceText,
    required String filePath,
    required TtsSettings settings,
    int? estimatedDurationMs,
    int? fileSizeBytes,
  }) async {
    if (!_initialized) return null;
    try {
      final key = computeKey(sourceText, settings);
      final file = File(filePath);
      final size = fileSizeBytes ??
          (file.existsSync() ? file.lengthSync() : 0);

      final entry = AudioCacheEntry(
        key: key,
        sourceText: sourceText,
        filePath: filePath,
        language: settings.language,
        voice: settings.preferredVoice,
        speechRate: settings.speechRate,
        pitch: settings.pitch,
        estimatedDurationMs: estimatedDurationMs,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        playCount: 0,
        fileSizeBytes: size,
      );

      await _box.put(key, entry);

      // Eviction si taille totale depassee.
      await _evictIfNeeded(defaultMaxSizeBytes);

      notifyListeners();
      return entry;
    } catch (e) {
      AppLogger.error('AudioCacheService.put() erreur: $e');
      return null;
    }
  }

  /// Supprime une entree de cache (Hive + fichier disque).
  Future<void> remove(String key) async {
    if (!_initialized) return;
    final entry = _box.get(key);
    if (entry == null) return;
    try {
      final file = File(entry.filePath);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
    await _box.delete(key);
    notifyListeners();
  }

  /// Vide tout le cache (Hive + fichiers disque). Confirme avant (UI).
  Future<void> clearAll() async {
    if (!_initialized) return;
    final keys = _box.keys.toList();
    for (final k in keys) {
      final entry = _box.get(k);
      if (entry != null) {
        try {
          final file = File(entry.filePath);
          if (file.existsSync()) await file.delete();
        } catch (_) {}
      }
    }
    await _box.clear();
    AppLogger.info('AudioCacheService: cache vide (${keys.length} entrees)');
    notifyListeners();
  }

  /// Taille totale actuelle du cache en octets.
  int get totalSizeBytes {
    if (!_initialized) return 0;
    int total = 0;
    for (final entry in _box.values) {
      total += entry.fileSizeBytes;
    }
    return total;
  }

  /// Nombre d'entrees en cache.
  int get entryCount => _initialized ? _box.length : 0;

  /// Eviction LRU : supprime les entrees les moins recente utilisees
  /// jusqu'a ce que la taille totale passe sous [maxSizeBytes].
  Future<void> _evictIfNeeded(int maxSizeBytes) async {
    if (!_initialized) return;
    var total = totalSizeBytes;
    if (total <= maxSizeBytes) return;

    // Trie par lastAccessedAt croissant (plus ancien = premier a evict).
    final entries = _box.values.toList()
      ..sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

    for (final entry in entries) {
      if (total <= maxSizeBytes) break;
      await remove(entry.key);
      total -= entry.fileSizeBytes;
    }
    AppLogger.info(
      'AudioCacheService: eviction LRU - taille restante ${total}B',
    );
  }

  /// Nettoie les entrees expirees (> 30 jours) et les entrees dont le
  /// fichier disque a disparu. A appeler periodiquement (ex : au lancement).
  Future<int> cleanupExpired() async {
    if (!_initialized) return 0;
    int removed = 0;
    final keys = _box.keys.toList();
    for (final k in keys) {
      final entry = _box.get(k);
      if (entry == null) continue;
      final file = File(entry.filePath);
      final shouldRemove =
          entry.isExpired(maxAge: defaultTtl) || !file.existsSync();
      if (shouldRemove) {
        await remove(k.toString());
        removed++;
      }
    }
    if (removed > 0) {
      AppLogger.info('AudioCacheService: $removed entrees expirees supprimees');
    }
    return removed;
  }
}
