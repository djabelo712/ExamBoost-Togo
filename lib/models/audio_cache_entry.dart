// lib/models/audio_cache_entry.dart
// Entree du cache audio (synthese TTS pre-generee).
//
// flutter_tts genere l'audio a la volee a chaque appel de speak(). Pour les
// questions tres lues (ex : questions d'examen officiel revisees plusieurs
// fois), on peut pre-generer un fichier .wav/.mp3 via FlutterTts.synthesizeToFile()
// et le rejouer avec un AudioCacheService. Gain : eviter la latence TTS et
// preserver la batterie.
//
// Attention : pour fonctionner, l'adaptateur AudioCacheEntryAdapter doit etre
// enregistre dans main.dart (Hive.registerAdapter) AVANT l'ouverture de la
// box "audio_cache". Voir lib/screens/settings/README.md pour le wiring.

import 'package:hive/hive.dart';

part 'audio_cache_entry.g.dart';

/// Une entree du cache audio TTS. Cle technique : hash SHA-1 du texte +
/// langue + voix + vitesse (cf. AudioCacheService.computeKey).
///
/// Persistee via Hive dans la box "audio_cache" (cle : <hash>).
@HiveType(typeId: 18)
class AudioCacheEntry extends HiveObject {
  /// Cle de cache (hash du texte normalise + params voix). Sert d'identifiant
  /// unique pour retrouver le fichier audio sans re-synthesiser.
  @HiveField(0)
  final String key;

  /// Texte source exact ayant servi a la synthese. Stocke pour verification
  /// (en cas de collision de hash improbable).
  @HiveField(1)
  final String sourceText;

  /// Chemin absolu du fichier audio genere sur le disque (cache dir app).
  @HiveField(2)
  final String filePath;

  /// Locale BCP-47 utilisee (ex : 'fr-FR').
  @HiveField(3)
  final String language;

  /// Voix utilisee (null = voix par defaut).
  @HiveField(4)
  final String? voice;

  /// Vitesse de synthese (0.5 - 2.0).
  @HiveField(5)
  final double speechRate;

  /// Hauteur tonale (0.5 - 2.0).
  @HiveField(6)
  final double pitch;

  /// Duree estimee en millisecondes (renvoyee par le moteur TTS si dispo).
  /// Sert a afficher une progress bar precise dans AudioPlayerBar.
  @HiveField(7)
  final int? estimatedDurationMs;

  /// Date de creation du cache (pour eviction LRU).
  @HiveField(8)
  final DateTime createdAt;

  /// Date du dernier acces (pour eviction LRU). Mise a jour a chaque replay.
  @HiveField(9)
  DateTime lastAccessedAt;

  /// Nombre de fois que ce cache a ete rejoue. Indicateur de pertinence.
  @HiveField(10)
  int playCount;

  /// Taille du fichier en octets (pour evict quand taille totale > seuil).
  @HiveField(11)
  final int fileSizeBytes;

  AudioCacheEntry({
    required this.key,
    required this.sourceText,
    required this.filePath,
    required this.language,
    this.voice,
    required this.speechRate,
    required this.pitch,
    this.estimatedDurationMs,
    required this.createdAt,
    required this.lastAccessedAt,
    this.playCount = 0,
    required this.fileSizeBytes,
  });

  /// Duree estimee en Duration (null si inconnue).
  Duration? get estimatedDuration => estimatedDurationMs == null
      ? null
      : Duration(milliseconds: estimatedDurationMs!);

  /// Marque un nouvel acces (rejoue ou rejoue-partiel). Met a jour
  /// lastAccessedAt et incremente playCount. Persiste immediatement.
  void markAccessed() {
    lastAccessedAt = DateTime.now();
    playCount += 1;
    save();
  }

  /// True si le cache est expire (plus de [maxAge] depuis la creation).
  /// Par defaut 30 jours (pour forcer une re-synthese periodique et suivre
  /// les eventuelles ameliorations du moteur TTS systeme).
  bool isExpired({Duration maxAge = const Duration(days: 30)}) {
    return DateTime.now().difference(createdAt) > maxAge;
  }

  @override
  String toString() =>
      'AudioCacheEntry(key=$key, lang=$language, voice=${voice ?? "default"}, '
      'rate=$speechRate, size=${fileSizeBytes}B, plays=$playCount, '
      'created=${createdAt.toIso8601String()})';
}
