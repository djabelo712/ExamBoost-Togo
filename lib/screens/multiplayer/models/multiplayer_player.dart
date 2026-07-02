// lib/screens/multiplayer/models/multiplayer_player.dart
// Modele d'un joueur dans une room multijoueur (mode etude entre eleves).
//
// Reflete un participant d'une room de revision collaborative :
//   - id : identifiant unique (UUID v4 cote client)
//   - name : prenom du joueur (Kossi, Aya, Komlan, ...)
//   - score : score cumule pendant la partie
//   - isReady : pret a demarrer (lobby)
//   - isHost : createur de la room (peut demarrer la partie)
//   - status : connecte / a-repondu / deconnecte
//   - answeredCount : nombre de questions auxquelles il a repondu
//   - correctCount : nombre de reponses correctes
//   - totalTimeSeconds : temps cumule de reponse (pour stats)
//
// Ce modele est volontairement independant du modele ClassroomPlayer
// (module Classe temps reel) car les besoins du multijoueur etude
// different (champ "ready", statut "host", pas de role enseignant).

import 'dart:ui' show Color;

/// Statut d'un joueur pendant une partie multijoueur.
enum MultiplayerPlayerStatus { connected, answered, disconnected }

class MultiplayerPlayer {
  final String id;
  final String name;
  final int score;
  final bool isReady;
  final bool isHost;
  final MultiplayerPlayerStatus status;
  final int answeredCount;
  final int correctCount;
  final int totalTimeSeconds;
  final DateTime joinedAt;

  const MultiplayerPlayer({
    required this.id,
    required this.name,
    this.score = 0,
    this.isReady = false,
    this.isHost = false,
    this.status = MultiplayerPlayerStatus.connected,
    this.answeredCount = 0,
    this.correctCount = 0,
    this.totalTimeSeconds = 0,
    required this.joinedAt,
  });

  /// Initiales du joueur (pour l'avatar circulaire).
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Couleur d'avatar derivee du nom (palette stable).
  /// On utilise un hash simple du nom pour choisir parmi 6 couleurs
  /// pre-definies aux couleurs du Togo (vert/orange) et complementaires.
  Color get avatarColor {
    const colors = [
      Color(0xFF006837), // Vert Togo
      Color(0xFFD97700), // Orange
      Color(0xFF1565C0), // Bleu
      Color(0xFF6A1B9A), // Violet
      Color(0xFFC62828), // Rouge
      Color(0xFF2E7D32), // Vert fonce
    ];
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return colors[hash % colors.length];
  }

  bool get hasAnswered => status == MultiplayerPlayerStatus.answered;
  bool get isConnected => status != MultiplayerPlayerStatus.disconnected;

  /// Temps moyen par question repondue (en secondes), 0 si aucune reponse.
  double get averageTimeSeconds =>
      answeredCount == 0 ? 0.0 : totalTimeSeconds / answeredCount;

  /// Taux de bonnes reponses (0.0 - 1.0).
  double get successRate =>
      answeredCount == 0 ? 0.0 : correctCount / answeredCount;

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> json) {
    return MultiplayerPlayer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Joueur',
      score: (json['score'] as num?)?.toInt() ?? 0,
      isReady: json['is_ready'] == true,
      isHost: json['is_host'] == true,
      status: _parseStatus(json['status']),
      answeredCount: (json['answered_count'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      totalTimeSeconds: (json['total_time_seconds'] as num?)?.toInt() ?? 0,
      joinedAt:
          DateTime.tryParse(json['joined_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': score,
        'is_ready': isReady,
        'is_host': isHost,
        'status': status.name,
        'answered_count': answeredCount,
        'correct_count': correctCount,
        'total_time_seconds': totalTimeSeconds,
        'joined_at': joinedAt.toIso8601String(),
      };

  MultiplayerPlayer copyWith({
    String? id,
    String? name,
    int? score,
    bool? isReady,
    bool? isHost,
    MultiplayerPlayerStatus? status,
    int? answeredCount,
    int? correctCount,
    int? totalTimeSeconds,
    DateTime? joinedAt,
  }) {
    return MultiplayerPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
      status: status ?? this.status,
      answeredCount: answeredCount ?? this.answeredCount,
      correctCount: correctCount ?? this.correctCount,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  static MultiplayerPlayerStatus _parseStatus(dynamic v) {
    if (v == 'answered') return MultiplayerPlayerStatus.answered;
    if (v == 'disconnected') return MultiplayerPlayerStatus.disconnected;
    return MultiplayerPlayerStatus.connected;
  }
}
