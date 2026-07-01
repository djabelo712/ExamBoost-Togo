// lib/screens/tutor/models/chat_message.dart
// Modèle d'un message de conversation avec le tuteur IA ExamBoost.
//
// Persistance Hive : sérialisation manuelle en Map<String, dynamic> (pas
// d'adaptateur Hive à enregistrer dans main.dart — on reste dans le
// périmètre lib/screens/tutor/ sans modifier l'initialisation de l'app).
// La box Hive "tutor_conversations" stocke directement les Maps.

import 'package:flutter/foundation.dart';

class ChatMessage {
  /// Identifiant unique (uuid v4).
  final String id;

  /// Rôle : 'user' ou 'assistant'.
  final String role;

  /// Contenu textuel (markdown léger pour l'assistant).
  final String content;

  /// Horodatage du message.
  final DateTime timestamp;

  /// Matière associée à la question (si connue).
  final String? matiere;

  /// Vrai si le message est un message d'erreur (bulle rouge).
  final bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.matiere,
    this.isError = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.user({
    required String id,
    required String content,
    required DateTime timestamp,
    String? matiere,
  }) {
    return ChatMessage(
      id: id,
      role: 'user',
      content: content,
      timestamp: timestamp,
      matiere: matiere,
    );
  }

  factory ChatMessage.assistant({
    required String id,
    required String content,
    required DateTime timestamp,
    String? matiere,
    bool isError = false,
  }) {
    return ChatMessage(
      id: id,
      role: 'assistant',
      content: content,
      timestamp: timestamp,
      matiere: matiere,
      isError: isError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (matiere != null) 'matiere': matiere,
        'isError': isError,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      matiere: json['matiere'] as String?,
      isError: (json['isError'] as bool?) ?? false,
    );
  }

  ChatMessage copyWith({
    String? content,
    bool? isError,
    String? matiere,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      matiere: matiere ?? this.matiere,
      isError: isError ?? this.isError,
    );
  }

  @override
  String toString() {
    final preview =
        content.length > 40 ? '${content.substring(0, 40)}...' : content;
    return 'ChatMessage(role=$role, content="$preview", isError=$isError)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
