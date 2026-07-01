// lib/screens/classroom/services/classroom_rest_service.dart
// Client REST pour le module Classe Temps Reel.
//
// Utilise pour :
//   - creer une session (POST /classroom/create) -> retourne le code
//   - verifier le statut d'une session (GET /classroom/{code}/status)
//   - recuperer les resultats finaux (GET /classroom/{code}/results)
//   - terminer une session (POST /classroom/{code}/end)
//
// La WebSocket gere le temps reel, ce service gere les appels HTTP
// ponctuels. On utilise dio (deja dans pubspec) pour profiter du
// interceptor / timeout / retry standard.

import 'package:dio/dio.dart';

import '../models/classroom_player.dart';
import '../models/classroom_session.dart';

class ClassroomRestService {
  final Dio _dio;

  ClassroomRestService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ));

  /// Cree une session et retourne le code a 6 chiffres.
  ///
  /// [baseUrl] : ex. ``http://10.0.2.2:8000``.
  /// Retourne le code + le mode + le nombre de questions.
  Future<CreateSessionResponse> createSession({
    required String baseUrl,
    required String teacherId,
    String teacherName = 'Enseignant',
    required String exam,
    String? matiere,
    required List<String> questionIds,
    ClassroomMode mode = ClassroomMode.live,
    int timeLimitSeconds = 30,
    int homeworkDays = 7,
  }) async {
    final url = '$baseUrl/classroom/create';
    final resp = await _dio.post(url, data: {
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'exam': exam,
      'matiere': matiere,
      'question_ids': questionIds,
      'mode': mode.name,
      'time_limit_seconds': timeLimitSeconds,
      'homework_days': homeworkDays,
    });
    if (resp.statusCode != 200) {
      throw ClassroomRestException(
        'Erreur creation session: ${resp.statusCode} ${resp.data}',
      );
    }
    final data = resp.data as Map<String, dynamic>;
    return CreateSessionResponse(
      sessionCode: data['session_code'].toString(),
      wsUrl: data['ws_url']?.toString() ?? '',
      mode: data['mode'] == 'homework'
          ? ClassroomMode.homework
          : ClassroomMode.live,
      questionCount: (data['question_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Recupere le statut public d'une session.
  Future<ClassroomSessionStatus> getStatus({
    required String baseUrl,
    required String code,
  }) async {
    final url = '$baseUrl/classroom/$code/status';
    final resp = await _dio.get(url);
    if (resp.statusCode != 200) {
      throw ClassroomRestException(
        'Session introuvable ou terminee (${resp.statusCode})',
      );
    }
    final data = resp.data as Map<String, dynamic>;
    return ClassroomSessionStatus(
      code: data['code'].toString(),
      exists: data['exists'] == true,
      status: _parseStatus(data['status']),
      mode: data['mode'] == 'homework'
          ? ClassroomMode.homework
          : ClassroomMode.live,
      playersCount: (data['players_count'] as num?)?.toInt() ?? 0,
      currentQuestionIndex: (data['current_question_index'] as num?)?.toInt() ?? -1,
      totalQuestions: (data['total_questions'] as num?)?.toInt() ?? 0,
      teacherName: data['teacher_name']?.toString() ?? '',
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      homeworkExpiresAt: DateTime.tryParse(
          data['homework_expires_at'] ?? ''),
    );
  }

  /// Recupere les resultats finaux d'une session.
  Future<ClassroomSessionResults> getResults({
    required String baseUrl,
    required String code,
  }) async {
    final url = '$baseUrl/classroom/$code/results';
    final resp = await _dio.get(url);
    if (resp.statusCode != 200) {
      throw ClassroomRestException(
        'Resultats introuvables (${resp.statusCode})',
      );
    }
    return ClassroomSessionResults.fromJson(
        resp.data as Map<String, dynamic>);
  }

  /// Termine une session via REST (alternative au message WS end_session).
  Future<ClassroomSessionResults> endSession({
    required String baseUrl,
    required String code,
  }) async {
    final url = '$baseUrl/classroom/$code/end';
    final resp = await _dio.post(url);
    if (resp.statusCode != 200) {
      throw ClassroomRestException(
        'Impossible de terminer la session (${resp.statusCode})',
      );
    }
    return ClassroomSessionResults.fromJson(
        resp.data as Map<String, dynamic>);
  }

  static ClassroomStatus _parseStatus(dynamic v) {
    if (v == 'live') return ClassroomStatus.live;
    if (v == 'ended') return ClassroomStatus.ended;
    return ClassroomStatus.waiting;
  }
}

/// Reponse de creation de session.
class CreateSessionResponse {
  final String sessionCode;
  final String wsUrl;
  final ClassroomMode mode;
  final int questionCount;

  const CreateSessionResponse({
    required this.sessionCode,
    required this.wsUrl,
    required this.mode,
    required this.questionCount,
  });
}

/// Statut public d'une session (leger, sans liste de joueurs).
class ClassroomSessionStatus {
  final String code;
  final bool exists;
  final ClassroomStatus status;
  final ClassroomMode mode;
  final int playersCount;
  final int currentQuestionIndex;
  final int totalQuestions;
  final String teacherName;
  final DateTime createdAt;
  final DateTime? homeworkExpiresAt;

  const ClassroomSessionStatus({
    required this.code,
    required this.exists,
    required this.status,
    required this.mode,
    this.playersCount = 0,
    this.currentQuestionIndex = -1,
    this.totalQuestions = 0,
    this.teacherName = '',
    required this.createdAt,
    this.homeworkExpiresAt,
  });
}

/// Exception metier du service REST.
class ClassroomRestException implements Exception {
  final String message;
  ClassroomRestException(this.message);
  @override
  String toString() => message;
}
