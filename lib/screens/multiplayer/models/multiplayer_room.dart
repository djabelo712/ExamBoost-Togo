// lib/screens/multiplayer/models/multiplayer_room.dart
// Modele d'une room multijoueur et des objets associes.
//
// Une room multijoueur est une session de revision collaborative :
//   - code a 6 chiffres partageable
//   - matiere (Maths, FR, etc.)
//   - nombre de questions (5, 10, 15)
//   - mode competitif ou cooperatif
//   - visibilite publique ou privee
//   - liste des joueurs (max 6)
//   - liste des questions diffusees
//   - statut : en attente / en cours / terminee
//
// On definit aussi :
//   - MultiplayerQuestion : question synchronisee (meme enonce pour tous)
//   - MultiplayerChatMessage : message du chat live
//   - MultiplayerRoomResults : resultats finaux (podium + stats)
//
// Contrainte : les reponses correctes sont connues du client dans ce
// modele (demo locale). En production, seul le serveur connaitrait
// l'index correct et renverrait un booleen "correct" apres chaque
// reponse (cf. modele ClassroomQuestion du module Classe temps reel).

import 'multiplayer_player.dart';

/// Mode de jeu multijoueur.
enum MultiplayerMode {
  /// Chacun pour soi, classement individuel.
  competitive,

  /// Equipe, score cumule, questions plus difficiles.
  cooperative,
}

/// Visibilite de la room.
enum MultiplayerVisibility { public, private }

/// Statut d'une room.
enum MultiplayerRoomStatus { waiting, playing, ended }

/// Matieres disponibles pour le multijoueur.
/// On se limite aux matieres BEPC/BAC les plus demandees au Togo.
class MultiplayerSubject {
  final String id;
  final String label;
  final String icon; // nom d'icone Material (utilise par les ecrans)

  const MultiplayerSubject({
    required this.id,
    required this.label,
    required this.icon,
  });

  static const List<MultiplayerSubject> all = [
    MultiplayerSubject(id: 'maths', label: 'Mathematiques', icon: 'calculate'),
    MultiplayerSubject(id: 'francais', label: 'Francais', icon: 'menu_book'),
    MultiplayerSubject(id: 'philo', label: 'Philosophie', icon: 'psychology'),
    MultiplayerSubject(id: 'pc', label: 'Physique-Chimie', icon: 'science'),
    MultiplayerSubject(id: 'svt', label: 'SVT', icon: 'biotech'),
    MultiplayerSubject(id: 'hg', label: 'Histoire-Geo', icon: 'public'),
    MultiplayerSubject(id: 'anglais', label: 'Anglais', icon: 'translate'),
  ];

  static MultiplayerSubject byId(String id) {
    return all.firstWhere(
      (s) => s.id == id,
      orElse: () => all.first,
    );
  }
}

/// Une question diffusee dans la room (synchronisee pour tous les joueurs).
class MultiplayerQuestion {
  final String id;
  final String enonce;
  final List<String> choices;
  final int correctIndex;
  final String? explanation;
  final String matiere;

  const MultiplayerQuestion({
    required this.id,
    required this.enonce,
    required this.choices,
    required this.correctIndex,
    this.explanation,
    required this.matiere,
  });

  bool get isQcm => choices.length >= 2;
  String get correctAnswer => choices[correctIndex];

  factory MultiplayerQuestion.fromJson(Map<String, dynamic> json) {
    return MultiplayerQuestion(
      id: json['id']?.toString() ?? '',
      enonce: json['enonce']?.toString() ?? '',
      matiere: json['matiere']?.toString() ?? 'maths',
      choices: (json['choices'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correctIndex: (json['correct_index'] as num?)?.toInt() ?? 0,
      explanation: json['explanation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enonce': enonce,
        'matiere': matiere,
        'choices': choices,
        'correct_index': correctIndex,
        'explanation': explanation,
      };
}

/// Message du chat live.
class MultiplayerChatMessage {
  final String id;
  final String playerId;
  final String playerName;
  final String text;
  final DateTime sentAt;
  final bool isSystem;

  const MultiplayerChatMessage({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.text,
    required this.sentAt,
    this.isSystem = false,
  });

  factory MultiplayerChatMessage.fromJson(Map<String, dynamic> json) {
    return MultiplayerChatMessage(
      id: json['id']?.toString() ?? '',
      playerId: json['player_id']?.toString() ?? '',
      playerName: json['player_name']?.toString() ?? 'Joueur',
      text: json['text']?.toString() ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ??
          DateTime.now(),
      isSystem: json['is_system'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'player_name': playerName,
        'text': text,
        'sent_at': sentAt.toIso8601String(),
        'is_system': isSystem,
      };
}

/// Resultat d'une question pour un joueur (apres reponse).
class MultiplayerAnswerResult {
  final String questionId;
  final String playerId;
  final int selectedIndex;
  final bool correct;
  final int pointsEarned;
  final int timeTakenSeconds;
  final int totalScore;

  const MultiplayerAnswerResult({
    required this.questionId,
    required this.playerId,
    required this.selectedIndex,
    required this.correct,
    required this.pointsEarned,
    required this.timeTakenSeconds,
    required this.totalScore,
  });

  factory MultiplayerAnswerResult.fromJson(Map<String, dynamic> json) {
    return MultiplayerAnswerResult(
      questionId: json['question_id']?.toString() ?? '',
      playerId: json['player_id']?.toString() ?? '',
      selectedIndex: (json['selected_index'] as num?)?.toInt() ?? -1,
      correct: json['correct'] == true,
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
      timeTakenSeconds: (json['time_taken_seconds'] as num?)?.toInt() ?? 0,
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Room multijoueur complete.
class MultiplayerRoom {
  final String code;
  final String hostId;
  final String matiere;
  final int nbQuestions;
  final MultiplayerMode mode;
  final MultiplayerVisibility visibility;
  final MultiplayerRoomStatus status;
  final List<MultiplayerPlayer> players;
  final List<MultiplayerQuestion> questions;
  final List<MultiplayerChatMessage> chatMessages;
  final int currentQuestionIndex;
  final int timeLimitSeconds;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const MultiplayerRoom({
    required this.code,
    required this.hostId,
    required this.matiere,
    required this.nbQuestions,
    required this.mode,
    required this.visibility,
    required this.status,
    this.players = const [],
    this.questions = const [],
    this.chatMessages = const [],
    this.currentQuestionIndex = -1,
    this.timeLimitSeconds = 30,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  /// Index humain de la question courante (1-based, 0 si pas commence).
  int get currentQuestionNumber => currentQuestionIndex + 1;
  int get totalQuestions => questions.length;
  bool get isWaiting => status == MultiplayerRoomStatus.waiting;
  bool get isPlaying => status == MultiplayerRoomStatus.playing;
  bool get isEnded => status == MultiplayerRoomStatus.ended;
  bool get isCompetitive => mode == MultiplayerMode.competitive;
  bool get isCooperative => mode == MultiplayerMode.cooperative;

  /// Nombre maximum de joueurs par room (cahier des charges).
  static const int maxPlayers = 6;

  bool get isFull => players.length >= maxPlayers;

  /// Joueur host (peut etre null si l'hote a quitte).
  MultiplayerPlayer? get host =>
      players.where((p) => p.id == hostId).firstOrNull;

  /// Tous les joueurs sont-ils prets ? (host inclus pour demarrer).
  bool get allReady =>
      players.isNotEmpty &&
      players.every((p) => p.isReady || p.isHost);

  MultiplayerQuestion? get currentQuestion {
    if (currentQuestionIndex < 0 ||
        currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  factory MultiplayerRoom.fromJson(Map<String, dynamic> json) {
    return MultiplayerRoom(
      code: json['code']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      matiere: json['matiere']?.toString() ?? 'maths',
      nbQuestions: (json['nb_questions'] as num?)?.toInt() ?? 5,
      mode: json['mode'] == 'cooperative'
          ? MultiplayerMode.cooperative
          : MultiplayerMode.competitive,
      visibility: json['visibility'] == 'private'
          ? MultiplayerVisibility.private
          : MultiplayerVisibility.public,
      status: _parseStatus(json['status']),
      players: (json['players'] as List?)
              ?.map((e) =>
                  MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      questions: (json['questions'] as List?)
              ?.map((e) =>
                  MultiplayerQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      chatMessages: (json['chat_messages'] as List?)
              ?.map((e) =>
                  MultiplayerChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentQuestionIndex:
          (json['current_question_index'] as num?)?.toInt() ?? -1,
      timeLimitSeconds:
          (json['time_limit_seconds'] as num?)?.toInt() ?? 30,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      startedAt: _tryParseDate(json['started_at']),
      endedAt: _tryParseDate(json['ended_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'host_id': hostId,
        'matiere': matiere,
        'nb_questions': nbQuestions,
        'mode': mode.name,
        'visibility': visibility.name,
        'status': status.name,
        'players': players.map((p) => p.toJson()).toList(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'chat_messages': chatMessages.map((m) => m.toJson()).toList(),
        'current_question_index': currentQuestionIndex,
        'time_limit_seconds': timeLimitSeconds,
        'created_at': createdAt.toIso8601String(),
        'started_at': startedAt?.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
      };

  MultiplayerRoom copyWith({
    String? code,
    String? hostId,
    String? matiere,
    int? nbQuestions,
    MultiplayerMode? mode,
    MultiplayerVisibility? visibility,
    MultiplayerRoomStatus? status,
    List<MultiplayerPlayer>? players,
    List<MultiplayerQuestion>? questions,
    List<MultiplayerChatMessage>? chatMessages,
    int? currentQuestionIndex,
    int? timeLimitSeconds,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return MultiplayerRoom(
      code: code ?? this.code,
      hostId: hostId ?? this.hostId,
      matiere: matiere ?? this.matiere,
      nbQuestions: nbQuestions ?? this.nbQuestions,
      mode: mode ?? this.mode,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      players: players ?? this.players,
      questions: questions ?? this.questions,
      chatMessages: chatMessages ?? this.chatMessages,
      currentQuestionIndex:
          currentQuestionIndex ?? this.currentQuestionIndex,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  static MultiplayerRoomStatus _parseStatus(dynamic v) {
    if (v == 'playing') return MultiplayerRoomStatus.playing;
    if (v == 'ended') return MultiplayerRoomStatus.ended;
    return MultiplayerRoomStatus.waiting;
  }

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// Resultats finaux d'une room (apres end).
class MultiplayerRoomResults {
  final String roomCode;
  final MultiplayerMode mode;
  final List<MultiplayerPlayer> podium; // top 3 (ou moins)
  final List<MultiplayerPlayer> leaderboard; // classement complet
  final int totalQuestions;

  /// En mode cooperatif, score cumule de l'equipe.
  final int teamScore;

  final DateTime? endedAt;

  const MultiplayerRoomResults({
    required this.roomCode,
    required this.mode,
    this.podium = const [],
    this.leaderboard = const [],
    this.totalQuestions = 0,
    this.teamScore = 0,
    this.endedAt,
  });

  factory MultiplayerRoomResults.fromRoom(MultiplayerRoom room) {
    // Trie par score decroissant pour le classement final.
    final sorted = [...room.players]
      ..sort((a, b) => b.score.compareTo(a.score));
    final podium = sorted.take(3).toList();
    final teamScore = room.players.fold<int>(0, (s, p) => s + p.score);
    return MultiplayerRoomResults(
      roomCode: room.code,
      mode: room.mode,
      podium: podium,
      leaderboard: sorted,
      totalQuestions: room.totalQuestions,
      teamScore: teamScore,
      endedAt: room.endedAt ?? DateTime.now(),
    );
  }
}
