// lib/models/question.dart
// Modèle d'une question de la banque de données ExamBoost

import 'package:hive/hive.dart';

part 'question.g.dart';

@HiveType(typeId: 0)
class Question extends HiveObject {
  @HiveField(0)
  final String id; // ex: "TG-BEPC-MATHS-2022-Q01"

  @HiveField(1)
  final String enonce;

  @HiveField(2)
  final String reponse;

  @HiveField(3)
  final String? explication; // Explication détaillée pour l'élève

  @HiveField(4)
  final String matiere; // "Mathematiques", "Francais", etc.

  @HiveField(5)
  final String chapitre; // "Equations 1er degre", etc.

  @HiveField(6)
  final String competenceId; // "TG-MATHS-EQ1D-001"

  @HiveField(7)
  final String examen; // "BEPC", "BAC1", "BAC2", "Probatoire"

  @HiveField(8)
  final String? serie; // "A", "C", "D", etc. (null pour BEPC)

  @HiveField(9)
  final int? annee;

  @HiveField(10)
  final QuestionType type; // ouvert, qcm, redaction

  @HiveField(11)
  final List<String>? choix; // Pour les QCM uniquement

  @HiveField(12)
  final int? points;

  // ─── Paramètres IRT ───────────────────────────────────────────
  @HiveField(13)
  double? irtA; // Discrimination (a)

  @HiveField(14)
  double? irtB; // Difficulté (b)

  @HiveField(15)
  double? irtC; // Chance/guessing (c)

  @HiveField(16)
  bool irtCalibrated;

  Question({
    required this.id,
    required this.enonce,
    required this.reponse,
    this.explication,
    required this.matiere,
    required this.chapitre,
    required this.competenceId,
    required this.examen,
    this.serie,
    this.annee,
    required this.type,
    this.choix,
    this.points,
    this.irtA,
    this.irtB,
    this.irtC,
    this.irtCalibrated = false,
  });

  /// Difficulté estimée pour affichage (basée sur irtB ou estimation manuelle)
  DifficulteNiveau get difficulte {
    final b = irtB ?? 0.0;
    if (b < -0.5) return DifficulteNiveau.facile;
    if (b < 0.8)  return DifficulteNiveau.moyen;
    return DifficulteNiveau.difficile;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'enonce': enonce,
    'reponse': reponse,
    'explication': explication,
    'matiere': matiere,
    'chapitre': chapitre,
    'competence_id': competenceId,
    'examen': examen,
    'serie': serie,
    'annee': annee,
    'type': type.name,
    'choix': choix,
    'points': points,
    'irt': {'a': irtA, 'b': irtB, 'c': irtC, 'calibre': irtCalibrated},
  };

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      enonce: json['enonce'],
      reponse: json['reponse'],
      explication: json['explication'],
      matiere: json['matiere'],
      chapitre: json['chapitre'],
      competenceId: json['competence_id'] ?? '',
      examen: json['examen'] ?? 'BEPC',
      serie: json['serie'],
      annee: json['annee'],
      type: QuestionType.values.byName(json['type'] ?? 'ouvert'),
      choix: json['choix'] != null
          ? List<String>.from(json['choix'])
          : null,
      points: json['points'],
      irtA: json['irt']?['a']?.toDouble(),
      irtB: json['irt']?['b']?.toDouble(),
      irtC: json['irt']?['c']?.toDouble(),
      irtCalibrated: json['irt']?['calibre'] ?? false,
    );
  }
}

@HiveType(typeId: 1)
enum QuestionType {
  @HiveField(0) ouvert,
  @HiveField(1) qcm,
  @HiveField(2) redaction,
  @HiveField(3) calcul,
  @HiveField(4) vraiFaux,
}

enum DifficulteNiveau { facile, moyen, difficile }
