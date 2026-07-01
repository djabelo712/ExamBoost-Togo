// lib/screens/classroom/services/classroom_socket_service.dart
// Service WebSocket pour le module Classe Temps Reel.
//
// Responsabilites :
//   - Connecter/deconnecter la WebSocket vers /classroom/{code}
//   - Envoyer les messages sortants (join, answer, next_question, etc.)
//   - Parser les messages entrants et exposer l'etat via ChangeNotifier
//
// Le service ne depend PAS de Flutter UI : il peut etre instancie dans
// un test ou un Provider. Les ecrans ecoutent via notifyListeners().
//
// Usage :
//   final service = ClassroomSocketService();
//   await service.connect(
//     baseUrl: 'ws://10.0.2.2:8000',
//     sessionCode: '123456',
//     playerId: 'uuid-v4',
//     playerName: 'Awa',
//     role: PlayerRole.student,
//   );
//   service.sendAnswer(questionId: '...', answer: 'A');
//   service.addListener(() { /* maj UI */ });
//   await service.disconnect();

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/classroom_event.dart';
import '../models/classroom_player.dart';
import '../models/classroom_session.dart';

/// Etat de la connexion WebSocket.
enum ClassroomConnectionState { disconnected, connecting, connected, error }

/// Service principal : etat + canal WebSocket.
class ClassroomSocketService extends ChangeNotifier {
  static const _uuidGen = Uuid();

  // ─── Etat expose ───────────────────────────────────────────────
  ClassroomConnectionState _connectionState =
      ClassroomConnectionState.disconnected;
  ClassroomSession? _session;
  List<ClassroomPlayer> _players = const [];
  ClassroomPlayer? _me;
  int _currentQuestionNum = 0;
  int _totalQuestions = 0;
  ClassroomQuestion? _currentQuestion;
  int _timeRemaining = 0;
  int _timeLimit = 30;
  ClassroomMode _mode = ClassroomMode.live;
  ClassroomAnswerResult? _lastAnswerResult;
  bool _allAnswered = false;
  ClassroomQuestionStats? _lastStats;
  ClassroomSessionResults? _results;
  String? _errorMessage;

  // ─── Internes ──────────────────────────────────────────────────
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _timer;
  DateTime? _questionStartedAt;
  final String _playerId = _uuidGen.v4();

  // ─── Getters ───────────────────────────────────────────────────
  ClassroomConnectionState get connectionState => _connectionState;
  ClassroomSession? get session => _session;
  List<ClassroomPlayer> get players => _players;
  ClassroomPlayer? get me => _me;
  String get playerId => _playerId;
  int get currentQuestionNum => _currentQuestionNum;
  int get totalQuestions => _totalQuestions;
  ClassroomQuestion? get currentQuestion => _currentQuestion;
  int get timeRemaining => _timeRemaining;
  int get timeLimit => _timeLimit;
  ClassroomMode get mode => _mode;
  ClassroomAnswerResult? get lastAnswerResult => _lastAnswerResult;
  bool get allAnswered => _allAnswered;
  ClassroomQuestionStats? get lastStats => _lastStats;
  ClassroomSessionResults? get results => _results;
  String? get errorMessage => _errorMessage;
  bool get hasAnsweredCurrent =>
      _me?.hasAnswered ?? _lastAnswerResult != null;

  // ─── Connexion ─────────────────────────────────────────────────
  /// Connecte la WebSocket et envoie le message ``join``.
  ///
  /// [baseUrl] : URL de base sans le path (ex: ``ws://10.0.2.2:8000``).
  /// [sessionCode] : code a 6 chiffres.
  /// [playerName] : prenom de l'eleve ou nom de l'enseignant.
  /// [role] : student ou teacher.
  Future<void> connect({
    required String baseUrl,
    required String sessionCode,
    required String playerName,
    PlayerRole role = PlayerRole.student,
  }) async {
    if (_connectionState == ClassroomConnectionState.connecting ||
        _connectionState == ClassroomConnectionState.connected) {
      return;
    }

    _connectionState = ClassroomConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    final url = '$baseUrl/classroom/$sessionCode';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _sub = _channel.stream.listen(
        _onData,
        onError: (Object e) => _onError('Erreur WebSocket: $e'),
        onDone: _onDone,
      );

      // Envoie le join
      _send(ClassroomOutgoing.join(
        playerId: _playerId,
        playerName: playerName,
        role: role,
      ));

      // Timeout si pas de joined dans les 5s
      Timer(const Duration(seconds: 5), () {
        if (_connectionState == ClassroomConnectionState.connecting) {
          _onError('Timeout : serveur injoignable');
        }
      });
    } catch (e) {
      _onError('Connexion impossible : $e');
    }
  }

  /// Ferme la WebSocket proprement.
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
    _connectionState = ClassroomConnectionState.disconnected;
    notifyListeners();
  }

  // ─── Envoi de messages ─────────────────────────────────────────
  void _send(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  /// Eleve : envoie sa reponse a la question courante.
  void sendAnswer({
    required String questionId,
    required String answer,
  }) {
    final timeTaken = _questionStartedAt == null
        ? 0.0
        : DateTime.now().difference(_questionStartedAt!).inMilliseconds /
            1000.0;
    _send(ClassroomOutgoing.answer(
      questionId: questionId,
      answer: answer,
      timeTakenSeconds: timeTaken,
    ));
  }

  /// Enseignant : demarre le quiz.
  void startQuiz() => _send(ClassroomOutgoing.startQuiz());

  /// Enseignant : passe a la question suivante.
  void nextQuestion() => _send(ClassroomOutgoing.nextQuestion());

  /// Enseignant : force le passage (sans attendre tous les eleves).
  void forceNext() => _send(ClassroomOutgoing.forceNext());

  /// Enseignant : termine la session.
  void endSession() => _send(ClassroomOutgoing.endSession());

  // ─── Reception ─────────────────────────────────────────────────
  void _onData(dynamic data) {
    Map<String, dynamic> json;
    try {
      final decoded = data is String ? data : data.toString();
      json = jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final ev = parseClassroomEvent(json);
    _handleEvent(ev);
  }

  void _handleEvent(ClassroomEvent ev) {
    switch (ev.type) {
      case ClassroomEventType.joined:
        _session = extractSession(ev);
        _me = extractMe(ev);
        _mode = _session?.mode ?? ClassroomMode.live;
        _connectionState = ClassroomConnectionState.connected;
        break;

      case ClassroomEventType.playerJoined:
        final player = extractPlayer(ev);
        if (player != null && player.id != _playerId) {
          // Ajoute ou met a jour
          final idx = _players.indexWhere((p) => p.id == player.id);
          if (idx == -1) {
            _players = [..._players, player];
          } else {
            _players = List.of(_players)..[idx] = player;
          }
        }
        // Met a jour la liste complete si fournie
        final lb = extractLeaderboard(ev);
        if (lb.isNotEmpty) {
          _players = lb;
        }
        final count = ev.raw['players_count'];
        if (count is num && _session != null) {
          _session = _session!.copyWith(playersCount: count.toInt());
        }
        break;

      case ClassroomEventType.playerLeft:
        final pid = ev.raw['player_id']?.toString();
        if (pid != null) {
          _players = _players
              .map((p) => p.id == pid
                  ? p.copyWith(status: PlayerStatus.disconnected)
                  : p)
              .toList();
        }
        final count = ev.raw['players_count'];
        if (count is num && _session != null) {
          _session = _session!.copyWith(playersCount: count.toInt());
        }
        break;

      case ClassroomEventType.quizStarted:
        _session = extractSession(ev) ?? _session;
        if (_session != null) {
          _session = _session!.copyWith(status: ClassroomStatus.live);
        }
        _results = null;
        break;

      case ClassroomEventType.newQuestion:
        final payload = extractNewQuestion(ev);
        if (payload != null) {
          _currentQuestion = payload.question;
          _currentQuestionNum = payload.questionNumber;
          _totalQuestions = payload.totalQuestions;
          _timeLimit = payload.timeLimit;
          _timeRemaining = payload.timeLimit;
          _mode = payload.mode;
          _lastAnswerResult = null;
          _allAnswered = false;
          _lastStats = null;
          _questionStartedAt = DateTime.now();
          _startTimer();
        }
        break;

      case ClassroomEventType.answerConfirmed:
        _lastAnswerResult = extractAnswerResult(ev);
        // Met a jour mon score dans _me
        if (_me != null && _lastAnswerResult != null) {
          _me = _me!.copyWith(
            score: _lastAnswerResult!.totalScore,
            status: PlayerStatus.answered,
            lastAnswerCorrect: _lastAnswerResult!.correct,
            answeredCount: (_me!.answeredCount) + 1,
          );
        }
        _timer?.cancel();
        break;

      case ClassroomEventType.leaderboardUpdate:
        _players = extractLeaderboard(ev);
        // Met a jour mon score depuis le leaderboard
        if (_me != null) {
          final meInBoard =
              _players.where((p) => p.id == _playerId).firstOrNull;
          if (meInBoard != null) {
            _me = _me!.copyWith(score: meInBoard.score);
          }
        }
        break;

      case ClassroomEventType.allAnswered:
        _allAnswered = true;
        _lastStats = extractQuestionStats(ev);
        _timer?.cancel();
        break;

      case ClassroomEventType.sessionEnded:
        _results = extractSessionResults(ev);
        if (_session != null) {
          _session =
              _session!.copyWith(status: ClassroomStatus.ended);
        }
        _timer?.cancel();
        break;

      case ClassroomEventType.error:
        _errorMessage = ev.errorMessage;
        break;

      case ClassroomEventType.unknown:
        if (kDebugMode) {
          debugPrint('Classroom event inconnu: ${ev.raw}');
        }
        break;
    }
    notifyListeners();
  }

  void _onError(String message) {
    _errorMessage = message;
    _connectionState = ClassroomConnectionState.error;
    _timer?.cancel();
    notifyListeners();
  }

  void _onDone() {
    _timer?.cancel();
    if (_connectionState == ClassroomConnectionState.connected) {
      _connectionState = ClassroomConnectionState.disconnected;
      notifyListeners();
    }
  }

  // ─── Timer local (UI) ──────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    // En mode devoir, pas de timer
    if (_mode == ClassroomMode.homework) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining <= 0) {
        t.cancel();
        return;
      }
      _timeRemaining = max(0, _timeRemaining - 1);
      notifyListeners();
    });
  }

  /// Reinitialise l'etat (avant une nouvelle session).
  void reset() {
    _timer?.cancel();
    _timer = null;
    _session = null;
    _players = const [];
    _me = null;
    _currentQuestion = null;
    _currentQuestionNum = 0;
    _totalQuestions = 0;
    _timeRemaining = 0;
    _lastAnswerResult = null;
    _allAnswered = false;
    _lastStats = null;
    _results = null;
    _errorMessage = null;
    _connectionState = ClassroomConnectionState.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
