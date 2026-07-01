// lib/screens/classroom/models/classroom_session.dart
// Modele d'une session classe temps reel (cote Flutter).
//
// Reflete le backend Pydantic ClassroomSessionOut. Utilise pour :
//   - afficher le statut de la session (waiting/live/ended)
//   - savoir combien de joueurs sont connectes
//   - connaitre la question courante (en mode live)
//
// Attention : ce modele ne contient PAS les reponses attendues (cote serveur
// uniquement). Cote client on ne recoit que l'enonce + les choix.

import 'classroom_player.dart';

/// Statut d'une session classe.
enum ClassroomStatus { waiting, live, ended }

/// Mode de la session : live (Kahoot-like) ou devoir (asynchrone).
enum ClassroomMode { live, homework }

/// Session classe temps reel.
class ClassroomSession {
  final String code;
  final String teacherId;
  final String teacherName;
  final String exam;
  final String? matiere;
  final ClassroomMode mode;
  final ClassroomStatus status;
  final int timeLimitSeconds;
  final List<String> questionIds;
  final int currentQuestionIndex;
  final String? currentQuestionId;
  final int playersCount;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? homeworkExpiresAt;

  const ClassroomSession({
    required this.code,
    required this.teacherId,
    required this.teacherName,
    required this.exam,
    this.matiere,
    required this.mode,
    required this.status,
    this.timeLimitSeconds = 30,
    this.questionIds = const [],
    this.currentQuestionIndex = -1,
    this.currentQuestionId,
    this.playersCount = 0,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.homeworkExpiresAt,
  });

  /// Index humain de la question courante (1-based, 0 si pas commence).
  int get currentQuestionNumber => currentQuestionIndex + 1;
  int get totalQuestions => questionIds.length;
  bool get isWaiting => status == ClassroomStatus.waiting;
  bool get isLive => status == ClassroomStatus.live;
  bool get isEnded => status == ClassroomStatus.ended;
  bool get isHomework => mode == ClassroomMode.homework;

  factory ClassroomSession.fromJson(Map<String, dynamic> json) {
    return ClassroomSession(
      code: json['code'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      teacherName: json['teacher_name'] ?? 'Enseignant',
      exam: json['exam'] ?? 'BEPC',
      matiere: json['matiere'],
      mode: _parseMode(json['mode']),
      status: _parseStatus(json['status']),
      timeLimitSeconds: (json['time_limit_seconds'] as num?)?.toInt() ?? 30,
      questionIds: (json['question_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      currentQuestionIndex: (json['current_question_index'] as num?)?.toInt() ?? -1,
      currentQuestionId: json['current_question_id'],
      playersCount: (json['players_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      startedAt: _tryParseDate(json['started_at']),
      endedAt: _tryParseDate(json['ended_at']),
      homeworkExpiresAt: _tryParseDate(json['homework_expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'teacher_id': teacherId,
        'teacher_name': teacherName,
        'exam': exam,
        'matiere': matiere,
        'mode': mode.name,
        'status': status.name,
        'time_limit_seconds': timeLimitSeconds,
        'question_ids': questionIds,
        'current_question_index': currentQuestionIndex,
        'current_question_id': currentQuestionId,
        'players_count': playersCount,
        'created_at': createdAt.toIso8601String(),
        'started_at': startedAt?.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'homework_expires_at': homeworkExpiresAt?.toIso8601String(),
      };

  ClassroomSession copyWith({
    String? code,
    String? teacherId,
    String? teacherName,
    String? exam,
    String? matiere,
    ClassroomMode? mode,
    ClassroomStatus? status,
    int? timeLimitSeconds,
    List<String>? questionIds,
    int? currentQuestionIndex,
    String? currentQuestionId,
    int? playersCount,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? homeworkExpiresAt,
  }) {
    return ClassroomSession(
      code: code ?? this.code,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      exam: exam ?? this.exam,
      matiere: matiere ?? this.matiere,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      questionIds: questionIds ?? this.questionIds,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      playersCount: playersCount ?? this.playersCount,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      homeworkExpiresAt: homeworkExpiresAt ?? this.homeworkExpiresAt,
    );
  }

  static ClassroomMode _parseMode(dynamic v) {
    if (v == 'homework') return ClassroomMode.homework;
    return ClassroomMode.live;
  }

  static ClassroomStatus _parseStatus(dynamic v) {
    if (v == 'live') return ClassroomStatus.live;
    if (v == 'ended') return ClassroomStatus.ended;
    return ClassroomStatus.waiting;
  }

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// Question publique diffusee en live (sans la reponse attendue).
class ClassroomQuestion {
  final String id;
  final String enonce;
  final String type; // "ouvert", "qcm", "vraiFaux", etc.
  final List<String>? choix;

  const ClassroomQuestion({
    required this.id,
    required this.enonce,
    required this.type,
    this.choix,
  });

  bool get isQcm => type == 'qcm' && (choix?.isNotEmpty ?? false);
  bool get isVraiFaux => type == 'vraiFaux';
  bool get isOuvert => type == 'ouvert' || type == 'calcul' || type == 'redaction';

  factory ClassroomQuestion.fromJson(Map<String, dynamic> json) {
    return ClassroomQuestion(
      id: json['id']?.toString() ?? '',
      enonce: json['enonce']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ouvert',
      choix: (json['choix'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

/// Statistiques d'une question (apres reponse de tous).
class ClassroomQuestionStats {
  final String questionId;
  final int answeredCount;
  final int correctCount;
  final double successRate;
  final double averageTimeSeconds;

  const ClassroomQuestionStats({
    required this.questionId,
    required this.answeredCount,
    required this.correctCount,
    required this.successRate,
    required this.averageTimeSeconds,
  });

  factory ClassroomQuestionStats.fromJson(Map<String, dynamic> json) {
    return ClassroomQuestionStats(
      questionId: json['question_id']?.toString() ?? '',
      answeredCount: (json['answered_count'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      averageTimeSeconds: (json['average_time_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Resultats finaux d'une session (apres end).
class ClassroomSessionResults {
  final String sessionCode;
  final ClassroomStatus status;
  final List<ClassroomPlayer> podium;
  final List<ClassroomPlayer> leaderboard;
  final List<ClassroomQuestionStats> questionStats;
  final int totalPlayers;
  final int totalQuestions;
  final DateTime? endedAt;

  const ClassroomSessionResults({
    required this.sessionCode,
    required this.status,
    this.podium = const [],
    this.leaderboard = const [],
    this.questionStats = const [],
    this.totalPlayers = 0,
    this.totalQuestions = 0,
    this.endedAt,
  });

  factory ClassroomSessionResults.fromJson(Map<String, dynamic> json) {
    return ClassroomSessionResults(
      sessionCode: json['session_code']?.toString() ?? '',
      status: ClassroomSession._parseStatus(json['status']),
      podium: (json['podium'] as List?)
              ?.map((e) => ClassroomPlayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      leaderboard: (json['leaderboard'] as List?)
              ?.map((e) => ClassroomPlayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      questionStats: (json['question_stats'] as List?)
              ?.map((e) =>
                  ClassroomQuestionStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalPlayers: (json['total_players'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      endedAt: ClassroomSession._tryParseDate(json['ended_at']),
    );
  }
}
