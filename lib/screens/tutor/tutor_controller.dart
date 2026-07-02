// lib/screens/tutor/tutor_controller.dart
// Logique d'état du tuteur IA : liste des messages, gestion du chargement,
// persistance Hive, détection hors-ligne, retry.
//
// Fourni via ChangeNotifierProvider dans tutor_screen.dart.
//
// Persistance :
//   - Box Hive "tutor_conversations"
//   - Clé "active_conv_id" -> String (uuid de la conversation courante)
//   - Clé "conv_<uuid>" -> List<Map> (messages sérialisés)
//
// Au démarrage, charge la dernière conversation active pour continuité.

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'models/chat_message.dart';
import 'services/tutor_service.dart';

/// États possibles du tuteur.
enum TutorStatus { idle, loading, error, offline }

class TutorController extends ChangeNotifier {
  TutorController({required TutorService service}) : _service = service;

  final TutorService _service;
  static const String _boxName = 'tutor_conversations';
  static const String _activeConvKey = 'active_conv_id';

  final Uuid _uuid = const Uuid();

  // ─── État observable ────────────────────────────────────────────
  List<ChatMessage> _messages = const [];
  TutorStatus _status = TutorStatus.idle;
  String? _lastErrorMessage;
  String? _activeConversationId;
  List<String> _suggestedFollowups = const [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  TutorStatus get status => _status;
  bool get isLoading => _status == TutorStatus.loading;
  bool get isOffline => _status == TutorStatus.offline;
  bool get hasError => _status == TutorStatus.error;
  String? get lastErrorMessage => _lastErrorMessage;
  List<String> get suggestedFollowups =>
      List.unmodifiable(_suggestedFollowups);
  bool get isEmpty => _messages.isEmpty;

  /// Charge la dernière conversation au démarrage.
  Future<void> init() async {
    try {
      final box = await _openBox();
      final activeId = box.get(_activeConvKey) as String?;
      if (activeId != null) {
        _activeConversationId = activeId;
        final raw = box.get('conv_$activeId');
        if (raw is List) {
          _messages = raw
              .map((e) =>
                  ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('TutorController.init() error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }

  Future<void> _persist() async {
    try {
      final box = await _openBox();
      if (_activeConversationId == null) {
        _activeConversationId = _uuid.v4();
      }
      await box.put(_activeConvKey, _activeConversationId);
      await box.put(
        'conv_$_activeConversationId',
        _messages.map((m) => m.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('TutorController._persist() error: $e');
    }
  }

  /// Pose une question au tuteur.
  ///
  /// Ajoute immédiatement le message utilisateur, déclenche l'appel backend,
  /// puis ajoute la réponse IA. En cas d'erreur, ajoute un message d'erreur
  /// (bulle rouge) avec possibilité de retry.
  Future<void> ask({
    required String question,
    String? matiere,
    String? chapitre,
    String? competenceId,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    // Ajoute immédiatement le message utilisateur
    final userMsg = ChatMessage.user(
      id: _uuid.v4(),
      content: trimmed,
      timestamp: DateTime.now(),
      matiere: matiere,
    );
    _messages = [..._messages, userMsg];
    _status = TutorStatus.loading;
    _lastErrorMessage = null;
    notifyListeners();
    await _persist();

    await _callBackend(
      question: trimmed,
      matiere: matiere,
      chapitre: chapitre,
      competenceId: competenceId,
    );
  }

  /// Réessaie la dernière question utilisateur (après une erreur).
  Future<void> retryLast() async {
    if (_messages.isEmpty) return;

    // Cherche le dernier message user
    ChatMessage? lastUser;
    int lastUserIdx = -1;
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        lastUser = _messages[i];
        lastUserIdx = i;
        break;
      }
    }
    if (lastUser == null) return;

    // Retire les messages après le dernier message user
    // (en pratique : le message d'erreur à réessayer)
    _messages = _messages.sublist(0, lastUserIdx + 1);
    _status = TutorStatus.loading;
    _lastErrorMessage = null;
    notifyListeners();
    await _persist();

    await _callBackend(
      question: lastUser.content,
      matiere: lastUser.matiere,
      // Pas de chapitre/competenceId après retry (on n'a pas cette info
      // dans le message persisté — on garde juste la matière).
    );
  }

  Future<void> _callBackend({
    required String question,
    String? matiere,
    String? chapitre,
    String? competenceId,
  }) async {
    // Vérifie la connectivité
    final hasNet = await _service.hasNetwork();
    if (!hasNet) {
      _status = TutorStatus.offline;
      _lastErrorMessage =
          'Le tuteur nécessite Internet. Connecte-toi pour poser des questions.';
      // Pas de message d'erreur dans la conversation pour offline — juste
      // le bandeau d'avertissement en haut de l'écran.
      notifyListeners();
      return;
    }

    try {
      // Historique = tous les messages sauf le dernier (la question courante)
      final history = List<ChatMessage>.from(_messages)..removeLast();
      final answer = await _service.ask(
        question: question,
        conversationHistory: history,
        matiere: matiere,
        chapitre: chapitre,
        competenceId: competenceId,
      );
      final aiMsg = ChatMessage.assistant(
        id: _uuid.v4(),
        content: answer.answer,
        timestamp: DateTime.now(),
        matiere: matiere,
      );
      _messages = [..._messages, aiMsg];
      _suggestedFollowups = answer.suggestedFollowup;
      _status = TutorStatus.idle;
      notifyListeners();
      await _persist();
    } catch (e) {
      _status = TutorStatus.error;
      _lastErrorMessage = 'Désolé, je n\'ai pas pu répondre. Réessaie.';
      // Ajoute un message d'erreur dans la conversation (bulle rouge)
      final errMsg = ChatMessage.assistant(
        id: _uuid.v4(),
        content: _lastErrorMessage!,
        timestamp: DateTime.now(),
        matiere: matiere,
        isError: true,
      );
      _messages = [..._messages, errMsg];
      notifyListeners();
      await _persist();
    }
  }

  /// Démarre une nouvelle conversation (vide l'historique courant).
  Future<void> startNewConversation() async {
    _messages = const [];
    _status = TutorStatus.idle;
    _lastErrorMessage = null;
    _suggestedFollowups = const [];
    _activeConversationId = _uuid.v4();
    notifyListeners();
    await _persist();
  }

  /// Efface la conversation courante (alias de startNewConversation).
  Future<void> clearConversation() => startNewConversation();

  /// Met à jour le token JWT (appelé depuis l'extérieur après login).
  set authToken(String? token) {
    _service.authToken = token;
  }
}
