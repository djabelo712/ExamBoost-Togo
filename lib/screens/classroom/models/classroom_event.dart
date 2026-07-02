// lib/screens/classroom/models/classroom_event.dart
// Modeles des evenements WebSocket echanges avec le backend.
//
// Convention : tous les messages ont un champ ``type``. On definit ici :
//   - Les evenements entrants (client -> server) : WSOutgoing*
//   - Les evenements sortants (server -> client) : WSIncoming* (parsed)
//   - Une fonction utilitaire parseIncoming() qui dispatch le type
//
// Cette separation permet de garder le service WebSocket leger : il se
// contente d'appeler parseIncoming() et d'emettre le bon evenement
// via ChangeNotifier.

import 'classroom_player.dart';
import 'classroom_session.dart';

/// Types d'evenements entrants (recus du serveur).
enum ClassroomEventType {
  joined,             // Connexion confirmee
  playerJoined,       // Un autre joueur a rejoint
  playerLeft,         // Un joueur s'est deconnecte
  quizStarted,        // Le quiz demarre
  newQuestion,        // Nouvelle question diffusee
  answerConfirmed,    // Confirmation de notre reponse
  leaderboardUpdate,  // Classement mis a jour
  allAnswered,        // Tous les eleves ont repondu
  sessionEnded,       // Session terminee
  error,              // Erreur
  unknown,
}

/// Un evenement WebSocket entrant, deja parse.
class ClassroomEvent {
  final ClassroomEventType type;
  final Map<String, dynamic> raw;

  const ClassroomEvent(this.type, this.raw);

  /// Donnees specifiques selon le type.
  dynamic get payload => raw;

  /// Message d'erreur (pour type == error).
  String? get errorMessage => raw['message']?.toString();
}

/// Evenements sortants (client -> server).
class ClassroomOutgoing {
  /// Demande de connexion a la session.
  static Map<String, dynamic> join({
    required String playerId,
    required String playerName,
    PlayerRole role = PlayerRole.student,
  }) =>
      {
        'type': 'join',
        'player_id': playerId,
        'player_name': playerName,
        'role': role.name,
      };

  /// Reponse de l'eleve a une question.
  static Map<String, dynamic> answer({
    required String questionId,
    required String answer,
    double timeTakenSeconds = 0.0,
  }) =>
      {
        'type': 'answer',
        'question_id': questionId,
        'answer': answer,
        'time_taken_seconds': timeTakenSeconds,
      };

  /// Demande de demarrage du quiz (enseignant).
  static Map<String, dynamic> startQuiz() => {'type': 'start_quiz'};

  /// Demande de question suivante (enseignant).
  static Map<String, dynamic> nextQuestion() => {'type': 'next_question'};

  /// Force le passage a la question suivante sans attendre tous les eleves.
  static Map<String, dynamic> forceNext() => {'type': 'force_next'};

  /// Termine la session (enseignant).
  static Map<String, dynamic> endSession() => {'type': 'end_session'};
}

/// Parse un message brut recu du serveur en [ClassroomEvent].
ClassroomEvent parseClassroomEvent(Map<String, dynamic> json) {
  final type = json['type']?.toString() ?? '';
  switch (type) {
    case 'joined':
      return ClassroomEvent(ClassroomEventType.joined, json);
    case 'player_joined':
      return ClassroomEvent(ClassroomEventType.playerJoined, json);
    case 'player_left':
      return ClassroomEvent(ClassroomEventType.playerLeft, json);
    case 'quiz_started':
      return ClassroomEvent(ClassroomEventType.quizStarted, json);
    case 'new_question':
      return ClassroomEvent(ClassroomEventType.newQuestion, json);
    case 'answer_confirmed':
      return ClassroomEvent(ClassroomEventType.answerConfirmed, json);
    case 'leaderboard_update':
      return ClassroomEvent(ClassroomEventType.leaderboardUpdate, json);
    case 'all_answered':
      return ClassroomEvent(ClassroomEventType.allAnswered, json);
    case 'session_ended':
      return ClassroomEvent(ClassroomEventType.sessionEnded, json);
    case 'error':
      return ClassroomEvent(ClassroomEventType.error, json);
    default:
      return ClassroomEvent(ClassroomEventType.unknown, json);
  }
}

// ─── Helpers d'extraction de payloads specifiques ──────────────────

/// Extrait la session depuis un evenement ``joined`` ou ``quiz_started``.
ClassroomSession? extractSession(ClassroomEvent ev) {
  final s = ev.raw['session'];
  if (s is Map<String, dynamic>) {
    return ClassroomSession.fromJson(s);
  }
  return null;
}

/// Extrait le joueur "me" depuis un evenement ``joined``.
ClassroomPlayer? extractMe(ClassroomEvent ev) {
  final p = ev.raw['player'];
  if (p is Map<String, dynamic>) return ClassroomPlayer.fromJson(p);
  return null;
}

/// Extrait le joueur qui vient de rejoindre depuis ``player_joined``.
ClassroomPlayer? extractPlayer(ClassroomEvent ev) {
  final p = ev.raw['player'];
  if (p is Map<String, dynamic>) return ClassroomPlayer.fromJson(p);
  return null;
}

/// Extrait la liste des joueurs depuis ``leaderboard_update`` ou
/// ``player_joined``.
List<ClassroomPlayer> extractLeaderboard(ClassroomEvent ev) {
  final list = ev.raw['leaderboard'];
  if (list is List) {
    return list
        .map((e) => e is Map<String, dynamic>
            ? ClassroomPlayer.fromJson(e)
            : null)
        .whereType<ClassroomPlayer>()
        .toList();
  }
  return const [];
}

/// Extrait la question diffusee depuis ``new_question``.
class NewQuestionPayload {
  final ClassroomQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final int timeLimit;
  final ClassroomMode mode;

  const NewQuestionPayload({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.timeLimit,
    required this.mode,
  });
}

NewQuestionPayload? extractNewQuestion(ClassroomEvent ev) {
  final q = ev.raw['question'];
  if (q is! Map<String, dynamic>) return null;
  return NewQuestionPayload(
    question: ClassroomQuestion.fromJson(q),
    questionNumber: (ev.raw['question_number'] as num?)?.toInt() ?? 1,
    totalQuestions: (ev.raw['total_questions'] as num?)?.toInt() ?? 1,
    timeLimit: (ev.raw['time_limit'] as num?)?.toInt() ?? 30,
    mode: ev.raw['mode'] == 'homework'
        ? ClassroomMode.homework
        : ClassroomMode.live,
  );
}

/// Extrait le resultat de la reponse depuis ``answer_confirmed``.
ClassroomAnswerResult? extractAnswerResult(ClassroomEvent ev) {
  return ClassroomAnswerResult.fromJson(ev.raw);
}

/// Extrait les resultats finaux depuis ``session_ended``.
ClassroomSessionResults? extractSessionResults(ClassroomEvent ev) {
  final r = ev.raw['results'];
  if (r is Map<String, dynamic>) {
    return ClassroomSessionResults.fromJson(r);
  }
  return null;
}

/// Extrait les stats depuis ``all_answered``.
ClassroomQuestionStats? extractQuestionStats(ClassroomEvent ev) {
  final s = ev.raw['stats'];
  if (s is Map<String, dynamic>) {
    return ClassroomQuestionStats.fromJson(s);
  }
  return null;
}
