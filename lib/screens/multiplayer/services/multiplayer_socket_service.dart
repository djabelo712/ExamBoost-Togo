// lib/screens/multiplayer/services/multiplayer_socket_service.dart
// Service multijoueur : etat + canal WebSocket (ou simulation locale).
//
// Responsabilites :
//   - Créer / rejoindre une room (code 6 chiffres)
//   - Synchroniser la liste des joueurs (mock 5 joueurs togolais en démo)
//   - Diffuser les questions une par une (synchronisées)
//   - Timer 30s par question + décrément local
//   - Recevoir les réponses du joueur local + simuler les autres
//   - Chat live (messages stockés en local pour la démo)
//   - Calculer les résultats finaux (podium + stats)
//
// En mode "simulation" (par défaut, sans backend), le service utilise
// des Timer pour simuler l'arrivée d'événements (joueurs qui rejoignent,
// joueurs qui répondent). En mode "réseau", il ouvrirait une
// WebSocketChannel vers /multiplayer/{code} — code prêt mais backend
// non encore implémenté (TODO backend FastAPI).
//
// Le service hérite de ChangeNotifier : les écrans écoutent via
// AnimatedBuilder / ListenableBuilder et rebuild au notifyListeners().
//
// Usage :
//   final svc = MultiplayerSocketService();
//   await svc.createRoom(matiere: 'maths', nbQuestions: 10, mode: ...);
//   svc.toggleReady();
//   svc.startGame();  // host uniquement
//   svc.sendAnswer(selectedIndex: 2);
//   svc.sendChatMessage(text: 'Bonjour !');
//   svc.dispose();

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/multiplayer_player.dart';
import '../models/multiplayer_room.dart';

/// Etat de la connexion (réseau ou simulation).
enum MultiplayerConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Service principal multijoueur.
class MultiplayerSocketService extends ChangeNotifier {
  static const _uuidGen = Uuid();

  /// En mode simulation, on utilise ces prénoms togolais pour les
  /// joueurs fictifs qui rejoignent la room. 5 prénoms pour respecter
  /// le cahier des charges (max 6 joueurs = moi + 5 invités).
  static const List<String> _mockPlayerNames = [
    'Kossi',
    'Aya',
    'Komlan',
    'Délali',
    'Mawuko',
  ];

  // ─── Etat exposé ───────────────────────────────────────────────
  MultiplayerConnectionState _connectionState =
      MultiplayerConnectionState.disconnected;
  MultiplayerRoom? _room;
  MultiplayerPlayer? _me;
  String? _errorMessage;
  int _timeRemaining = 0;
  MultiplayerAnswerResult? _lastAnswerResult;
  bool _allAnswered = false;

  // ─── Internes ──────────────────────────────────────────────────
  /// Si true (par défaut), on simule tout en local sans backend.
  /// Si false, on ouvre une vraie WebSocket vers [baseUrl].
  final bool simulateMode;
  final String? baseUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _timer;
  Timer? _simJoinTimer;
  Timer? _simAnswerTimer;
  DateTime? _questionStartedAt;
  final String _playerId = _uuidGen.v4();
  String _playerName = 'Moi';

  // Stocke les réponses de la question courante (playerId -> index).
  final Map<String, int> _currentAnswers = {};

  // ─── Getters ───────────────────────────────────────────────────
  MultiplayerConnectionState get connectionState => _connectionState;
  MultiplayerRoom? get room => _room;
  MultiplayerPlayer? get me => _me;
  String get playerId => _playerId;
  String get playerName => _playerName;
  String? get errorMessage => _errorMessage;
  int get timeRemaining => _timeRemaining;
  int get timeLimit => _room?.timeLimitSeconds ?? 30;
  MultiplayerAnswerResult? get lastAnswerResult => _lastAnswerResult;
  bool get allAnswered => _allAnswered;
  bool get hasAnsweredCurrent => _me?.hasAnswered ?? false;
  List<MultiplayerPlayer> get players => _room?.players ?? const [];
  List<MultiplayerChatMessage> get chatMessages =>
      _room?.chatMessages ?? const [];
  MultiplayerQuestion? get currentQuestion => _room?.currentQuestion;
  int get currentQuestionNumber => _room?.currentQuestionNumber ?? 0;
  int get totalQuestions => _room?.totalQuestions ?? 0;
  bool get isHost => _me?.isHost ?? false;
  bool get allReady => _room?.allReady ?? false;

  MultiplayerSocketService({
    this.simulateMode = true,
    this.baseUrl,
  });

  // ─── Création / Rejoindre ──────────────────────────────────────

  /// Crée une nouvelle room (joueur local = hôte).
  Future<void> createRoom({
    required String matiere,
    required int nbQuestions,
    required MultiplayerMode mode,
    required MultiplayerVisibility visibility,
    String? playerName,
  }) async {
    if (playerName != null && playerName.trim().isNotEmpty) {
      _playerName = playerName.trim();
    }

    _connectionState = MultiplayerConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      if (simulateMode) {
        // Génère un code 6 chiffres aléatoire.
        final code = _generateRoomCode();
        final questions = _generateQuestions(matiere: matiere, count: nbQuestions);
        final now = DateTime.now();
        final me = MultiplayerPlayer(
          id: _playerId,
          name: _playerName,
          isHost: true,
          isReady: false,
          status: MultiplayerPlayerStatus.connected,
          joinedAt: now,
        );
        _room = MultiplayerRoom(
          code: code,
          hostId: _playerId,
          matiere: matiere,
          nbQuestions: nbQuestions,
          mode: mode,
          visibility: visibility,
          status: MultiplayerRoomStatus.waiting,
          players: [me],
          questions: questions,
          timeLimitSeconds: 30,
          createdAt: now,
        );
        _me = me;
        _connectionState = MultiplayerConnectionState.connected;

        // Simule l'arrivée progressive des autres joueurs.
        _scheduleMockPlayerJoins();

        // Message système de bienvenue.
        _addSystemMessage('Room $code créée. Partage le code avec tes amis !');
      } else {
        // Mode réseau : envoie la requête de création au backend.
        // TODO backend : POST /multiplayer/rooms -> {code, ...}
        await _connectWebSocket(code: '', isCreate: true);
      }
    } catch (e) {
      _onError('Création de room impossible : $e');
    }

    notifyListeners();
  }

  /// Rejoint une room existante à partir du code.
  Future<void> joinRoom({
    required String code,
    String? playerName,
  }) async {
    if (playerName != null && playerName.trim().isNotEmpty) {
      _playerName = playerName.trim();
    }

    _connectionState = MultiplayerConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      if (simulateMode) {
        // En mode simulation, on génère une room "déjà existante"
        // avec 1-3 joueurs déjà présents (mocks) et on s'y ajoute.
        final existing = _generateMockExistingRoom(code: code);
        final now = DateTime.now();
        final me = MultiplayerPlayer(
          id: _playerId,
          name: _playerName,
          isHost: false,
          isReady: false,
          status: MultiplayerPlayerStatus.connected,
          joinedAt: now,
        );
        _room = existing.copyWith(
          players: [...existing.players, me],
        );
        _me = me;
        _connectionState = MultiplayerConnectionState.connected;

        _addSystemMessage('${_playerName} a rejoint la room.');

        // Simule encore 1-2 arrivées supplémentaires aléatoires.
        _scheduleMockPlayerJoins(delaySeconds: 3);
      } else {
        await _connectWebSocket(code: code, isCreate: false);
      }
    } catch (e) {
      _onError('Impossible de rejoindre : $e');
    }

    notifyListeners();
  }

  // ─── Lobby : prêt / chat ───────────────────────────────────────

  /// Bascule le statut "prêt" du joueur local.
  void toggleReady() {
    if (_me == null || _room == null) return;
    final newReady = !_me!.isReady;
    _updateLocalPlayer(_me!.copyWith(isReady: newReady));
    _addSystemMessage(
      newReady
          ? '${_me!.name} est prêt.'
          : '${_me!.name} n\'est plus prêt.',
    );

    // En simulation, les mock joueurs deviennent prêts aléatoirement
    // 1 à 3 s après que l'hôte a basculé son statut.
    if (simulateMode) {
      _scheduleMockReadyToggles();
    }
  }

  /// Envoie un message de chat.
  void sendChatMessage({required String text}) {
    if (_room == null || text.trim().isEmpty) return;
    final msg = MultiplayerChatMessage(
      id: _uuidGen.v4(),
      playerId: _playerId,
      playerName: _playerName,
      text: text.trim(),
      sentAt: DateTime.now(),
      isSystem: false,
    );
    _room = _room!.copyWith(
      chatMessages: [..._room!.chatMessages, msg],
    );
    notifyListeners();

    // Simulation : 1 chance sur 2 qu'un mock réponde.
    if (simulateMode && _room!.players.length > 1 && Random().nextBool()) {
      Timer(const Duration(seconds: 2), () {
        if (_room == null || _room!.status != MultiplayerRoomStatus.waiting) {
          return;
        }
        _addMockChatReply();
      });
    }
  }

  // ─── Partie : démarrage / réponse / next ───────────────────────

  /// L'hôte démarre la partie.
  void startGame() {
    if (_room == null || _me == null || !_me!.isHost) return;
    if (!_room!.allReady) {
      _errorMessage = 'Tous les joueurs ne sont pas prêts.';
      notifyListeners();
      return;
    }
    _room = _room!.copyWith(
      status: MultiplayerRoomStatus.playing,
      currentQuestionIndex: 0,
      startedAt: DateTime.now(),
    );
    _currentAnswers.clear();
    _allAnswered = false;
    _lastAnswerResult = null;
    _addSystemMessage('Partie démarrée !');
    _startTimer();
    notifyListeners();
  }

  /// Envoie la réponse du joueur local à la question courante.
  void sendAnswer({required int selectedIndex}) {
    if (_room == null || _me == null || _room!.currentQuestion == null) {
      return;
    }
    if (_me!.hasAnswered) return; // déjà répondu

    final question = _room!.currentQuestion!;
    final now = DateTime.now();
    final timeTaken = _questionStartedAt == null
        ? 0
        : now.difference(_questionStartedAt!).inSeconds;

    final correct = selectedIndex == question.correctIndex;
    // Points : 100 si correct + bonus vitesse (jusqu'à 50 si < 10s).
    final points = correct ? (100 + _speedBonus(timeTaken)) : 0;

    final newAnswered = _me!.answeredCount + 1;
    final newCorrect = _me!.correctCount + (correct ? 1 : 0);
    final newTotalTime = _me!.totalTimeSeconds + timeTaken;
    final newScore = _me!.score + points;

    final result = MultiplayerAnswerResult(
      questionId: question.id,
      playerId: _playerId,
      selectedIndex: selectedIndex,
      correct: correct,
      pointsEarned: points,
      timeTakenSeconds: timeTaken,
      totalScore: newScore,
    );
    _lastAnswerResult = result;

    _updateLocalPlayer(_me!.copyWith(
      score: newScore,
      status: MultiplayerPlayerStatus.answered,
      answeredCount: newAnswered,
      correctCount: newCorrect,
      totalTimeSeconds: newTotalTime,
    ));

    _currentAnswers[_playerId] = selectedIndex;

    // En simulation, les mock joueurs répondent aléatoirement
    // 2 à 8 s après le joueur local (ou à l'expiration du timer).
    if (simulateMode) {
      _scheduleMockAnswers();
    }

    _checkAllAnswered();
    notifyListeners();
  }

  /// Passe à la question suivante (auto quand tous ont répondu, ou
  /// par l'hôte via "Passer").
  void nextQuestion() {
    if (_room == null || _room!.status != MultiplayerRoomStatus.playing) {
      return;
    }
    final nextIdx = _room!.currentQuestionIndex + 1;
    if (nextIdx >= _room!.questions.length) {
      endGame();
      return;
    }
    _room = _room!.copyWith(currentQuestionIndex: nextIdx);
    _currentAnswers.clear();
    _allAnswered = false;
    _lastAnswerResult = null;
    _questionStartedAt = DateTime.now();

    // Réinitialise le statut "answered" de tous les joueurs.
    _room = _room!.copyWith(
      players: _room!.players
          .map((p) => p.copyWith(
                status: p.status == MultiplayerPlayerStatus.disconnected
                    ? MultiplayerPlayerStatus.disconnected
                    : MultiplayerPlayerStatus.connected,
              ))
          .toList(),
    );
    _me = _room!.players.where((p) => p.id == _playerId).firstOrNull ?? _me;

    _startTimer();

    // En simulation, les mocks répondent aléatoirement.
    if (simulateMode) {
      _scheduleMockAnswers();
    }

    notifyListeners();
  }

  /// Termine la partie et calcule les résultats.
  void endGame() {
    if (_room == null) return;
    _timer?.cancel();
    _simAnswerTimer?.cancel();
    _room = _room!.copyWith(
      status: MultiplayerRoomStatus.ended,
      endedAt: DateTime.now(),
    );
    _addSystemMessage('Partie terminée !');
    notifyListeners();
  }

  /// Quitte la room (libère les ressources).
  void leaveRoom() {
    _timer?.cancel();
    _simJoinTimer?.cancel();
    _simAnswerTimer?.cancel();
    _room = null;
    _me = null;
    _currentAnswers.clear();
    _lastAnswerResult = null;
    _allAnswered = false;
    _errorMessage = null;
    _connectionState = MultiplayerConnectionState.disconnected;
    notifyListeners();
  }

  /// Réinitialise l'état (avant une nouvelle partie).
  void reset() {
    leaveRoom();
  }

  // ─── Connexion réseau (mode non-simulation) ────────────────────
  Future<void> _connectWebSocket({
    required String code,
    required bool isCreate,
  }) async {
    final url = '$baseUrl/multiplayer/$code';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _sub = _channel.stream.listen(
        _onNetworkData,
        onError: (Object e) => _onError('Erreur WebSocket : $e'),
        onDone: _onNetworkDone,
      );
      _send({
        'type': isCreate ? 'create' : 'join',
        'player_id': _playerId,
        'player_name': _playerName,
      });
      // Timeout 5s
      Timer(const Duration(seconds: 5), () {
        if (_connectionState == MultiplayerConnectionState.connecting) {
          _onError('Timeout : serveur injoignable');
        }
      });
    } catch (e) {
      _onError('Connexion WebSocket impossible : $e');
    }
  }

  void _onNetworkData(dynamic data) {
    Map<String, dynamic> json;
    try {
      final decoded = data is String ? data : data.toString();
      json = jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    // TODO backend : parser les événements réseau (joined, player_joined,
    // game_started, new_question, answer_confirmed, leaderboard_update,
    // all_answered, game_ended, chat_message).
    if (kDebugMode) {
      debugPrint('Multiplayer event réseau : $json');
    }
  }

  void _onNetworkDone() {
    if (_connectionState == MultiplayerConnectionState.connected) {
      _connectionState = MultiplayerConnectionState.disconnected;
      notifyListeners();
    }
  }

  void _send(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  // ─── Timer local ───────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    if (_room == null) return;
    _timeRemaining = _room!.timeLimitSeconds;
    _questionStartedAt = DateTime.now();
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining <= 0) {
        t.cancel();
        _onTimeoutExpired();
        return;
      }
      _timeRemaining = max(0, _timeRemaining - 1);
      notifyListeners();
    });
  }

  /// Quand le timer atteint 0 : force la réponse des joueurs qui n'ont
  /// pas répondu (considéré comme faux / 0 point) puis passe à la suite.
  void _onTimeoutExpired() {
    if (_me != null && !_me!.hasAnswered) {
      // Marque le joueur local comme ayant "répondu" (incorrect).
      _updateLocalPlayer(_me!.copyWith(
        status: MultiplayerPlayerStatus.answered,
        answeredCount: _me!.answeredCount + 1,
      ));
    }
    // Simule les réponses manquantes des mocks immédiatement.
    _simAnswerTimer?.cancel();
    _forceMockAnswers();
    _checkAllAnswered();
    notifyListeners();
  }

  // ─── Helpers internes ──────────────────────────────────────────

  /// Génère un code room à 6 chiffres.
  String _generateRoomCode() {
    final rng = Random();
    final sb = StringBuffer();
    for (var i = 0; i < 6; i++) {
      sb.write(rng.nextInt(10));
    }
    return sb.toString();
  }

  /// Bonus de vitesse : 50 pts si <= 5s, 30 si <= 10s, 10 si <= 20s, 0 sinon.
  int _speedBonus(int timeTakenSeconds) {
    if (timeTakenSeconds <= 5) return 50;
    if (timeTakenSeconds <= 10) return 30;
    if (timeTakenSeconds <= 20) return 10;
    return 0;
  }

  /// Met à jour le joueur local et synchronise dans la liste des joueurs.
  void _updateLocalPlayer(MultiplayerPlayer updated) {
    _me = updated;
    if (_room == null) return;
    final players = _room!.players.map((p) {
      return p.id == updated.id ? updated : p;
    }).toList();
    _room = _room!.copyWith(players: players);
  }

  /// Ajoute un message système au chat.
  void _addSystemMessage(String text) {
    if (_room == null) return;
    final msg = MultiplayerChatMessage(
      id: _uuidGen.v4(),
      playerId: 'system',
      playerName: 'Système',
      text: text,
      sentAt: DateTime.now(),
      isSystem: true,
    );
    _room = _room!.copyWith(
      chatMessages: [..._room!.chatMessages, msg],
    );
  }

  /// Vérifie si tous les joueurs connectés ont répondu.
  void _checkAllAnswered() {
    if (_room == null) return;
    final connected = _room!.players
        .where((p) => p.status != MultiplayerPlayerStatus.disconnected)
        .toList();
    if (connected.isEmpty) return;
    final allAnswered = connected.every((p) => p.hasAnswered);
    if (allAnswered && !_allAnswered) {
      _allAnswered = true;
      _timer?.cancel();
      // Auto-next après 2.5 s pour laisser le temps de voir le résultat.
      Timer(const Duration(milliseconds: 2500), () {
        if (_room != null && _room!.status == MultiplayerRoomStatus.playing) {
          nextQuestion();
        }
      });
    }
  }

  // ─── Simulation : mock joueurs ─────────────────────────────────

  /// Programme l'arrivée échelonnée des mock joueurs dans le lobby.
  void _scheduleMockPlayerJoins({int delaySeconds = 2}) {
    if (!simulateMode) return;
    var delay = delaySeconds;
    for (final name in _mockPlayerNames) {
      _simJoinTimer = Timer(Duration(seconds: delay), () {
        _addMockPlayer(name);
      });
      delay += 2;
    }
  }

  void _addMockPlayer(String name) {
    if (_room == null || _room!.isFull) return;
    // Évite les doublons de nom.
    if (_room!.players.any((p) => p.name == name)) return;
    final player = MultiplayerPlayer(
      id: _uuidGen.v4(),
      name: name,
      isHost: false,
      isReady: false,
      status: MultiplayerPlayerStatus.connected,
      joinedAt: DateTime.now(),
    );
    _room = _room!.copyWith(players: [..._room!.players, player]);
    _addSystemMessage('$name a rejoint la room.');
    notifyListeners();
  }

  /// Génère une room mock "déjà existante" avec 1 à 3 joueurs.
  MultiplayerRoom _generateMockExistingRoom({required String code}) {
    final rng = Random();
    final hostName = _mockPlayerNames[rng.nextInt(_mockPlayerNames.length)];
    final hostId = _uuidGen.v4();
    final now = DateTime.now();
    final host = MultiplayerPlayer(
      id: hostId,
      name: hostName,
      isHost: true,
      isReady: true,
      status: MultiplayerPlayerStatus.connected,
      joinedAt: now.subtract(const Duration(minutes: 2)),
    );
    final players = <MultiplayerPlayer>[host];

    // 0 à 2 joueurs supplémentaires (pour simuler une room active).
    final extraCount = rng.nextInt(3);
    final availableNames = _mockPlayerNames
        .where((n) => n != hostName)
        .toList()
      ..shuffle(rng);
    for (var i = 0; i < extraCount && i < availableNames.length; i++) {
      players.add(MultiplayerPlayer(
        id: _uuidGen.v4(),
        name: availableNames[i],
        isHost: false,
        isReady: rng.nextBool(),
        status: MultiplayerPlayerStatus.connected,
        joinedAt: now.subtract(Duration(minutes: 1, seconds: i * 30)),
      ));
    }

    final matiere = ['maths', 'francais', 'pc', 'svt'][rng.nextInt(4)];
    final nbQuestions = [5, 10, 15][rng.nextInt(3)];
    final mode = rng.nextBool()
        ? MultiplayerMode.competitive
        : MultiplayerMode.cooperative;

    return MultiplayerRoom(
      code: code,
      hostId: hostId,
      matiere: matiere,
      nbQuestions: nbQuestions,
      mode: mode,
      visibility: MultiplayerVisibility.public,
      status: MultiplayerRoomStatus.waiting,
      players: players,
      questions: _generateQuestions(matiere: matiere, count: nbQuestions),
      timeLimitSeconds: 30,
      createdAt: now.subtract(const Duration(minutes: 3)),
    );
  }

  /// Programme les mock joueurs pour qu'ils basculent "prêt" aléatoirement.
  void _scheduleMockReadyToggles() {
    if (!simulateMode || _room == null) return;
    for (final p in _room!.players) {
      if (p.id == _playerId || p.isReady) continue;
      Timer(Duration(seconds: 1 + Random().nextInt(3)), () {
        if (_room == null || _room!.status != MultiplayerRoomStatus.waiting) {
          return;
        }
        final players = _room!.players.map((q) {
          if (q.id == p.id) {
            return q.copyWith(isReady: Random().nextBool());
          }
          return q;
        }).toList();
        _room = _room!.copyWith(players: players);
        notifyListeners();
      });
    }
  }

  /// Programme les réponses aléatoires des mock joueurs (2 à 8 s).
  void _scheduleMockAnswers() {
    if (!simulateMode || _room == null) return;
    final rng = Random();
    // Capture l'ID de la question courante pour ignorer les timers
    // qui se déclencheraient après un changement de question.
    final currentQId = _room!.currentQuestion?.id;
    for (final p in _room!.players) {
      if (p.id == _playerId || p.status == MultiplayerPlayerStatus.disconnected) {
        continue;
      }
      final delaySeconds = 2 + rng.nextInt(7);
      Timer(Duration(seconds: delaySeconds), () {
        if (_room == null || _room!.status != MultiplayerRoomStatus.playing) {
          return;
        }
        // Ignore si la question a changé depuis la planification.
        if (_room!.currentQuestion?.id != currentQId) return;
        // Ignore si le mock a déjà répondu (anti-double-réponse).
        if (p.hasAnswered) return;
        _simulateMockAnswer(p);
      });
    }
  }

  /// Force les mocks à répondre immédiatement (timeout expiré).
  void _forceMockAnswers() {
    if (_room == null) return;
    for (final p in _room!.players) {
      if (p.id == _playerId) continue;
      if (p.hasAnswered) continue;
      _simulateMockAnswer(p);
    }
  }

  void _simulateMockAnswer(MultiplayerPlayer mockPlayer) {
    if (_room == null || _room!.currentQuestion == null) return;
    // Recherche le joueur courant dans la room (peut avoir été mis à jour
    // depuis la planification du timer — les objets MultiplayerPlayer sont
    // immuables donc on doit re-fetcher par id).
    final current = _room!.players
        .where((p) => p.id == mockPlayer.id)
        .firstOrNull;
    if (current == null) return;
    // Si le mock a déjà répondu à cette question, on ignore l'appel.
    if (current.hasAnswered) return;
    final question = _room!.currentQuestion!;
    final rng = Random();

    // Probabilité de bonne réponse dépendante du nom (stats variées).
    final skill = _mockSkill(current.name);
    final isCorrect = rng.nextDouble() < skill;

    int selected;
    if (isCorrect) {
      selected = question.correctIndex;
    } else {
      // Choix incorrect aléatoire différent du bon.
      final wrong = List.generate(question.choices.length, (i) => i)
          .where((i) => i != question.correctIndex)
          .toList();
      selected = wrong.isEmpty ? question.correctIndex : wrong[rng.nextInt(wrong.length)];
    }

    final timeTaken = 3 + rng.nextInt(20);
    final points = isCorrect ? (100 + _speedBonus(timeTaken)) : 0;
    final newScore = current.score + points;

    final players = _room!.players.map((p) {
      if (p.id != current.id) return p;
      return p.copyWith(
        score: newScore,
        status: MultiplayerPlayerStatus.answered,
        answeredCount: p.answeredCount + 1,
        correctCount: p.correctCount + (isCorrect ? 1 : 0),
        totalTimeSeconds: p.totalTimeSeconds + timeTaken,
      );
    }).toList();
    _room = _room!.copyWith(players: players);
    _currentAnswers[current.id] = selected;

    _checkAllAnswered();
    notifyListeners();
  }

  /// Compétence simulée d'un mock joueur (0.3 à 0.8).
  /// On associe un niveau par nom pour avoir une variance stable.
  double _mockSkill(String name) {
    const skills = {
      'Kossi': 0.75,
      'Aya': 0.65,
      'Komlan': 0.55,
      'Délali': 0.45,
      'Mawuko': 0.35,
    };
    return skills[name] ?? 0.5;
  }

  /// Ajoute une réponse de chat d'un mock joueur.
  void _addMockChatReply() {
    if (_room == null || _room!.players.length < 2) return;
    final others = _room!.players.where((p) => p.id != _playerId).toList();
    if (others.isEmpty) return;
    final rng = Random();
    final author = others[rng.nextInt(others.length)];
    const replies = [
      'Salut !',
      'On commence quand ?',
      'Bonne chance à tous',
      'Trop facile celle-là',
      'Je suis prêt',
      'Allez Kossi !',
      'Je révise encore un peu',
      'Go go go',
    ];
    final msg = MultiplayerChatMessage(
      id: _uuidGen.v4(),
      playerId: author.id,
      playerName: author.name,
      text: replies[rng.nextInt(replies.length)],
      sentAt: DateTime.now(),
      isSystem: false,
    );
    _room = _room!.copyWith(
      chatMessages: [..._room!.chatMessages, msg],
    );
    notifyListeners();
  }

  // ─── Banque de questions mock ──────────────────────────────────

  /// Génère une liste de [count] questions pour la matière demandée.
  /// On utilise une banque locale statique (par matière) puis on
  /// complète aléatoirement si count dépasse la taille de la banque.
  List<MultiplayerQuestion> _generateQuestions({
    required String matiere,
    required int count,
  }) {
    final bank = _questionBank[matiere] ?? _questionBank['maths']!;
    final rng = Random();
    final picked = <MultiplayerQuestion>[];
    final indices = List.generate(bank.length, (i) => i)..shuffle(rng);
    for (var i = 0; i < count; i++) {
      final q = bank[indices[i % bank.length]];
      picked.add(MultiplayerQuestion(
        id: '${matiere}_${i}_${_uuidGen.v4().substring(0, 8)}',
        enonce: q.enonce,
        choices: q.choices,
        correctIndex: q.correctIndex,
        explanation: q.explanation,
        matiere: matiere,
      ));
    }
    return picked;
  }

  void _onError(String message) {
    _errorMessage = message;
    _connectionState = MultiplayerConnectionState.error;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _simJoinTimer?.cancel();
    _simAnswerTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  // ─── Banque de questions (mock) ────────────────────────────────
  // Banque courte par matière — assez pour 5/10/15 questions avec
  // répétition possible (démo). En production, viendrait du backend.
  static const _mockQuestionsMaths = <_MockQuestion>[
    _MockQuestion(
      enonce: 'Combien font 7 x 8 ?',
      choices: ['54', '56', '58', '64'],
      correctIndex: 1,
      explanation: '7 x 8 = 56.',
    ),
    _MockQuestion(
      enonce: 'Quelle est la racine carrée de 144 ?',
      choices: ['10', '11', '12', '14'],
      correctIndex: 2,
      explanation: '12 x 12 = 144.',
    ),
    _MockQuestion(
      enonce: 'Quel est le PGCD de 12 et 18 ?',
      choices: ['2', '3', '6', '9'],
      correctIndex: 2,
      explanation: 'Les diviseurs communs sont 1, 2, 3, 6. Le plus grand est 6.',
    ),
    _MockQuestion(
      enonce: 'Combien font 15% de 200 ?',
      choices: ['15', '25', '30', '45'],
      correctIndex: 2,
      explanation: '15/100 x 200 = 30.',
    ),
    _MockQuestion(
      enonce: 'Résoudre : 2x + 5 = 11. x = ?',
      choices: ['2', '3', '4', '6'],
      correctIndex: 1,
      explanation: '2x = 6 donc x = 3.',
    ),
    _MockQuestion(
      enonce: 'Quel est le périmètre d\'un carré de côté 5 cm ?',
      choices: ['10 cm', '15 cm', '20 cm', '25 cm'],
      correctIndex: 2,
      explanation: '4 x 5 = 20 cm.',
    ),
    _MockQuestion(
      enonce: 'Quelle est l\'aire d\'un triangle de base 6 et hauteur 4 ?',
      choices: ['10', '12', '20', '24'],
      correctIndex: 1,
      explanation: '(base x hauteur) / 2 = (6 x 4) / 2 = 12.',
    ),
    _MockQuestion(
      enonce: 'Combien font 9² ?',
      choices: ['18', '72', '81', '99'],
      correctIndex: 2,
      explanation: '9 x 9 = 81.',
    ),
    _MockQuestion(
      enonce: 'Quel nombre est premier ?',
      choices: ['15', '21', '23', '27'],
      correctIndex: 2,
      explanation: '23 n\'a que 2 diviseurs : 1 et 23.',
    ),
    _MockQuestion(
      enonce: 'Convertir 3/4 en décimal.',
      choices: ['0.25', '0.5', '0.75', '0.8'],
      correctIndex: 2,
      explanation: '3 / 4 = 0.75.',
    ),
  ];

  static const _mockQuestionsFrancais = <_MockQuestion>[
    _MockQuestion(
      enonce: 'Quel est le pluriel de "cheval" ?',
      choices: ['chevals', 'chevaux', 'cheveux', 'chevales'],
      correctIndex: 1,
      explanation: 'Les noms en -al font leur pluriel en -aux.',
    ),
    _MockQuestion(
      enonce: 'Qui a écrit "Cahier d\'un retour au pays natal" ?',
      choices: ['Senghor', 'Césaire', 'Sartre', 'Camus'],
      correctIndex: 1,
      explanation: 'Aimé Césaire, 1939.',
    ),
    _MockQuestion(
      enonce: 'Quel temps utilise "je finirai" ?',
      choices: ['Présent', 'Futur simple', 'Passé composé', 'Imparfait'],
      correctIndex: 1,
      explanation: 'Terminaison -ai à la 1re personne = futur simple.',
    ),
    _MockQuestion(
      enonce: 'Quel est le contraire de "généreux" ?',
      choices: ['Avare', 'Loyal', 'Honnête', 'Brave'],
      correctIndex: 0,
      explanation: 'L\'avare ne donne pas ; contraire de généreux.',
    ),
    _MockQuestion(
      enonce: 'Dans "il mange une pomme", "une pomme" est :',
      choices: ['Sujet', 'Verbe', 'COD', 'COI'],
      correctIndex: 2,
      explanation: 'Complément d\'objet direct (sans préposition).',
    ),
    _MockQuestion(
      enonce: 'Qui a écrit "Une si longue lettre" ?',
      choices: ['Mariama Bâ', 'Aminata Sow Fall', 'Cheikh Hamidou Kane', 'Sembène'],
      correctIndex: 0,
      explanation: 'Mariama Bâ, 1979.',
    ),
    _MockQuestion(
      enonce: 'Le mot "bonheur" est dérivé de :',
      choices: ['bon', 'bien', 'heure', 'bonne'],
      correctIndex: 0,
      explanation: 'bon + -heur (suffixe).',
    ),
    _MockQuestion(
      enonce: 'Quel est le participe passé du verbe "aller" ?',
      choices: ['allé', 'allée', 'allés', 'toutes ces formes'],
      correctIndex: 3,
      explanation: 'Le participe passé s\'accorde en genre et en nombre.',
    ),
    _MockQuestion(
      enonce: 'Une strophe de 4 vers s\'appelle :',
      choices: ['Un tercet', 'Un quatrain', 'Un distique', 'Un sizain'],
      correctIndex: 1,
      explanation: '4 vers = un quatrain.',
    ),
    _MockQuestion(
      enonce: 'Quel figure de style : "les murs ont des oreilles" ?',
      choices: ['Métaphore', 'Comparaison', 'Métonymie', 'Antithèse'],
      correctIndex: 0,
      explanation: 'Image sans mot de comparaison.',
    ),
  ];

  static const _mockQuestionsPC = <_MockQuestion>[
    _MockQuestion(
      enonce: 'Unité de la résistance électrique ?',
      choices: ['Volt', 'Ampère', 'Ohm', 'Watt'],
      correctIndex: 2,
      explanation: 'L\'ohm (Ω) mesure la résistance.',
    ),
    _MockQuestion(
      enonce: 'Formule de l\'eau ?',
      choices: ['H2O', 'CO2', 'O2', 'NaCl'],
      correctIndex: 0,
      explanation: '2 atomes H + 1 atome O.',
    ),
    _MockQuestion(
      enonce: 'Quel gaz respire-t-on ?',
      choices: ['Azote', 'Oxygène', 'CO2', 'Hydrogène'],
      correctIndex: 1,
      explanation: 'L\'oxygène (O2) est nécessaire à la respiration.',
    ),
    _MockQuestion(
      enonce: 'Unité de l\'intensité du courant ?',
      choices: ['Volt', 'Watt', 'Ampère', 'Ohm'],
      correctIndex: 2,
      explanation: 'L\'ampère (A) mesure l\'intensité.',
    ),
    _MockQuestion(
      enonce: 'La vitesse de la lumière est environ :',
      choices: ['3 000 km/s', '30 000 km/s', '300 000 km/s', '3 000 000 km/s'],
      correctIndex: 2,
      explanation: '~ 300 000 km/s dans le vide.',
    ),
    _MockQuestion(
      enonce: 'Quel métal est attiré par un aimant ?',
      choices: ['Cuivre', 'Fer', 'Aluminium', 'Or'],
      correctIndex: 1,
      explanation: 'Le fer est ferromagnétique.',
    ),
    _MockQuestion(
      enonce: 'Quel est le pH de l\'eau pure ?',
      choices: ['0', '7', '14', '1'],
      correctIndex: 1,
      explanation: 'pH neutre = 7.',
    ),
    _MockQuestion(
      enonce: 'Unité de la force ?',
      choices: ['Joule', 'Newton', 'Pascal', 'Watt'],
      correctIndex: 1,
      explanation: 'Le newton (N) mesure la force.',
    ),
  ];

  static const _mockQuestionsSVT = <_MockQuestion>[
    _MockQuestion(
      enonce: 'L\'ADN contient l\'information :',
      choices: ['Génétique', 'Chimique', 'Physique', 'Électrique'],
      correctIndex: 0,
      explanation: 'L\'ADN porte l\'information génétique.',
    ),
    _MockQuestion(
      enonce: 'Combien de chromosomes chez l\'humain ?',
      choices: ['23', '46', '48', '64'],
      correctIndex: 1,
      explanation: '46 chromosomes (23 paires).',
    ),
    _MockQuestion(
      enonce: 'Quel organe pompe le sang ?',
      choices: ['Foie', 'Cœur', 'Poumon', 'Rein'],
      correctIndex: 1,
      explanation: 'Le cœur est le muscle qui pompe le sang.',
    ),
    _MockQuestion(
      enonce: 'La photosynthèse se fait dans :',
      choices: ['Racines', 'Tige', 'Feuilles', 'Fleurs'],
      correctIndex: 2,
      explanation: 'Les feuilles contiennent la chlorophylle.',
    ),
    _MockQuestion(
      enonce: 'Quel gaz rejetons-nous en expirant ?',
      choices: ['Oxygène', 'Azote', 'CO2', 'Hélium'],
      correctIndex: 2,
      explanation: 'On rejette du dioxyde de carbone.',
    ),
    _MockQuestion(
      enonce: 'Quel est le plus grand organe du corps humain ?',
      choices: ['Foie', 'Cerveau', 'Peau', 'Poumon'],
      correctIndex: 2,
      explanation: 'La peau couvre toute la surface du corps.',
    ),
  ];

  static const _mockQuestionsHG = <_MockQuestion>[
    _MockQuestion(
      enonce: 'Capitale du Togo ?',
      choices: ['Sokodé', 'Lomé', 'Kara', 'Atakpamé'],
      correctIndex: 1,
      explanation: 'Lomé est la capitale politique et économique.',
    ),
    _MockQuestion(
      enonce: 'Le Togo a obtenu son indépendance en :',
      choices: ['1958', '1960', '1962', '1975'],
      correctIndex: 1,
      explanation: '27 avril 1960.',
    ),
    _MockQuestion(
      enonce: 'Quel fleuve traverse Lomé ?',
      choices: ['Oti', 'Mono', 'Zio', 'Aucun'],
      correctIndex: 2,
      explanation: 'La Zio coule non loin de Lomé.',
    ),
    _MockQuestion(
      enonce: 'Combien de régions compte le Togo ?',
      choices: ['5', '6', '7', '8'],
      correctIndex: 0,
      explanation: '5 régions économiques.',
    ),
    _MockQuestion(
      enonce: 'Qui a dirigé le Togo de 1967 à 2005 ?',
      choices: ['Olympio', 'Eyadéma', 'Gnassingbé', 'Grunitzky'],
      correctIndex: 1,
      explanation: 'Gnassingbé Eyadéma.',
    ),
  ];

  /// Banque mappée par matière. Clé = id matière.
  static const Map<String, List<_MockQuestion>> _questionBank = {
    'maths': _mockQuestionsMaths,
    'francais': _mockQuestionsFrancais,
    'pc': _mockQuestionsPC,
    'svt': _mockQuestionsSVT,
    'hg': _mockQuestionsHG,
  };
}

/// Structure interne pour la banque de questions mock.
class _MockQuestion {
  final String enonce;
  final List<String> choices;
  final int correctIndex;
  final String? explanation;

  const _MockQuestion({
    required this.enonce,
    required this.choices,
    required this.correctIndex,
    this.explanation,
  });
}
