// lib/screens/tutor/services/tutor_service.dart
// Service Flutter d'appel au backend FastAPI /tutor/ask.
//
// Dépendances (déjà présentes dans pubspec.yaml) :
//   - dio (HTTP client)
//   - connectivity_plus (détection offline)
//
// Aucune dépendance externe supplémentaire n'est requise pour ce service.
// Le token JWT est injecté depuis le UserProvider par le TutorController.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';

/// Réponse du backend /tutor/ask.
class TutorAnswer {
  final String answer;
  final List<String> suggestedFollowup;
  final int tokensUsed;
  final bool fallback;

  const TutorAnswer({
    required this.answer,
    required this.suggestedFollowup,
    required this.tokensUsed,
    this.fallback = false,
  });

  factory TutorAnswer.fromJson(Map<String, dynamic> json) {
    return TutorAnswer(
      answer: json['answer'] as String? ?? '',
      suggestedFollowup: (json['suggested_followup'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tokensUsed: (json['tokens_used'] as num?)?.toInt() ?? 0,
      fallback: (json['fallback'] as bool?) ?? false,
    );
  }
}

class TutorService {
  TutorService({
    String? baseUrl,
    Dio? dio,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              headers: {'Content-Type': 'application/json'},
            )),
        _baseUrl = baseUrl ?? _defaultBaseUrl();

  final Dio _dio;
  final String _baseUrl;

  // Token JWT courant (set par TutorController après login).
  String? _authToken;
  String? get authToken => _authToken;
  set authToken(String? token) => _authToken = token;

  /// URL de base du backend selon la plateforme cible.
  /// Android emulator : 10.0.2.2 = host loopback.
  /// iOS sim / desktop / web : localhost.
  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Vérifie la connectivité réseau (WiFi / mobile data).
  /// En cas d'erreur (connectivity_plus indisponible sur desktop Linux),
  /// on suppose connecté pour ne pas bloquer la démo.
  Future<bool> hasNetwork() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((c) => c != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /// Pose une question au tuteur IA.
  ///
  /// Lance [DioException] si réseau KO ou backend injoignable.
  Future<TutorAnswer> ask({
    required String question,
    required List<ChatMessage> conversationHistory,
    String? matiere,
    String? chapitre,
    String? competenceId,
  }) async {
    // Historique : on exclut les messages d'erreur et on garde les 10 derniers
    // tours (pour rester dans le contexte Claude, qui a un cout lineaire).
    final filteredHistory = conversationHistory
        .where((m) => !m.isError)
        .toList();
    final recentHistory = filteredHistory.length <= 10
        ? filteredHistory
        : filteredHistory.sublist(filteredHistory.length - 10);
    final historyPayload = recentHistory
        .map((m) => {
              'role': m.role,
              'content': m.content,
            })
        .toList();

    final body = <String, dynamic>{
      'question': question,
      'conversation_history': historyPayload,
      if (matiere != null || chapitre != null || competenceId != null)
        'context': <String, dynamic>{
          if (matiere != null) 'matiere': matiere,
          if (chapitre != null) 'chapitre': chapitre,
          if (competenceId != null) 'competence_id': competenceId,
        },
    };

    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };

    final response = await _dio.post(
      '$_baseUrl/tutor/ask',
      data: body,
      options: Options(headers: headers),
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Backend a renvoyé ${response.statusCode}',
      );
    }

    return TutorAnswer.fromJson(response.data as Map<String, dynamic>);
  }
}
