// lib/screens/classroom/models/classroom_player.dart
// Modele d'un joueur (eleve ou enseignant) dans une session classe.
//
// Reflete le backend ClassroomPlayerOut. Un joueur a :
//   - un id (genere cote client, UUID v4)
//   - un nom (prenom saisi par l'eleve)
//   - un score cumule
//   - un role (student / teacher)
//   - un statut (connected / answered / disconnected)

/// Role d'un joueur dans la session.
enum PlayerRole { student, teacher }

/// Statut d'un joueur pendant une question.
enum PlayerStatus { connected, answered, disconnected }

class ClassroomPlayer {
  final String id;
  final String name;
  final int score;
  final PlayerRole role;
  final PlayerStatus status;
  final bool? lastAnswerCorrect;
  final int answeredCount;
  final DateTime joinedAt;

  const ClassroomPlayer({
    required this.id,
    required this.name,
    this.score = 0,
    this.role = PlayerRole.student,
    this.status = PlayerStatus.connected,
    this.lastAnswerCorrect,
    this.answeredCount = 0,
    required this.joinedAt,
  });

  /// Initiales du joueur (pour l'avatar).
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  bool get isTeacher => role == PlayerRole.teacher;
  bool get hasAnswered => status == PlayerStatus.answered;
  bool get isConnected => status != PlayerStatus.disconnected;

  factory ClassroomPlayer.fromJson(Map<String, dynamic> json) {
    return ClassroomPlayer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Joueur',
      score: (json['score'] as num?)?.toInt() ?? 0,
      role: json['role'] == 'teacher' ? PlayerRole.teacher : PlayerRole.student,
      status: _parseStatus(json['status']),
      lastAnswerCorrect: json['last_answer_correct'],
      answeredCount: (json['answered_count'] as num?)?.toInt() ?? 0,
      joinedAt: DateTime.tryParse(json['joined_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': score,
        'role': role.name,
        'status': status.name,
        'last_answer_correct': lastAnswerCorrect,
        'answered_count': answeredCount,
        'joined_at': joinedAt.toIso8601String(),
      };

  ClassroomPlayer copyWith({
    String? id,
    String? name,
    int? score,
    PlayerRole? role,
    PlayerStatus? status,
    bool? lastAnswerCorrect,
    int? answeredCount,
    DateTime? joinedAt,
  }) {
    return ClassroomPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      role: role ?? this.role,
      status: status ?? this.status,
      lastAnswerCorrect: lastAnswerCorrect ?? this.lastAnswerCorrect,
      answeredCount: answeredCount ?? this.answeredCount,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  static PlayerStatus _parseStatus(dynamic v) {
    if (v == 'answered') return PlayerStatus.answered;
    if (v == 'disconnected') return PlayerStatus.disconnected;
    return PlayerStatus.connected;
  }
}

/// Resultat de la reponse d'un eleve (renvoye par answer_confirmed).
class ClassroomAnswerResult {
  final bool correct;
  final int pointsEarned;
  final int totalScore;
  final String questionId;
  final String? expectedAnswer;
  final String? explanation;

  const ClassroomAnswerResult({
    required this.correct,
    required this.pointsEarned,
    required this.totalScore,
    required this.questionId,
    this.expectedAnswer,
    this.explanation,
  });

  factory ClassroomAnswerResult.fromJson(Map<String, dynamic> json) {
    return ClassroomAnswerResult(
      correct: json['correct'] == true,
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      questionId: json['question_id']?.toString() ?? '',
      expectedAnswer: json['expected_answer']?.toString(),
      explanation: json['explanation']?.toString(),
    );
  }
}
