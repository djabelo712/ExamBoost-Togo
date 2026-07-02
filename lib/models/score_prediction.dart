// lib/models/score_prediction.dart
// Modèle de prédiction de score officiel BEPC/BAC.
//
// Produit par [ScoreCalculator.predict] à partir :
//   - du BKT par compétence (user.bktMaitrise)
//   - des coefficients officiels MEPST (ExamenCoefficients)
//
// Le score prédit est sur 20 (échelle officielle togolaise).
// Chaque matière a une note estimée sur 20, pondérée par son coefficient.
//
// Persistance : modèle plain Dart avec toJson/fromJson.
// L'historique est stocké dans une Hive box "score_predictions"
// sous forme de JSON String (voir ScoreHistoryStore dans
// lib/services/score_predictor.dart). On évite ainsi les adapters
// Hive générés et la dépendance build_runner à l'exécution.

/// Prédiction de score à l'examen officiel, avec détail par matière.
///
/// [scoreGlobal] est sur 20, pondéré par les coefficients MEPST.
/// La couverture [coverageRate] indique la proportion du programme
/// effectivement évaluée par l'élève (matières où au moins une
/// compétence a un P(L) mesuré).
class ScorePrediction {
  /// Examen cible ("BEPC", "BAC1", "BAC2", "Probatoire").
  final String examen;

  /// Série BAC ("A", "B", "C", "D", "F") — null pour BEPC.
  final String? serie;

  /// Score global prédit sur 20.
  final double scoreGlobal;

  /// Détail par matière (clé = nom matière).
  final Map<String, SubjectScore> subjectScores;

  /// Somme totale des coefficients officiels.
  final int totalCoefficient;

  /// Somme des coefficients des matières effectivement couvertes.
  final int coveredCoefficient;

  /// Taux de couverture du programme (0-1).
  final double coverageRate;

  /// Indice de confiance dans la prédiction (0-1).
  /// Faible (< 0.3), moyenne (0.3-0.7), haute (> 0.7).
  final double confidence;

  /// Date de calcul de la prédiction.
  final DateTime predictedAt;

  /// Recommandation pédagogique contextuelle.
  final String recommendation;

  ScorePrediction({
    required this.examen,
    this.serie,
    required this.scoreGlobal,
    required this.subjectScores,
    required this.totalCoefficient,
    required this.coveredCoefficient,
    required this.coverageRate,
    required this.confidence,
    required this.predictedAt,
    required this.recommendation,
  });

  /// True si le score prédit est >= 10 (admissible).
  bool get isPassing => scoreGlobal >= 10.0;

  /// Points manquants pour atteindre la moyenne (10/20).
  /// 0 si déjà admissible.
  double get pointsToPassing => (10.0 - scoreGlobal).clamp(0.0, 20.0);

  /// Niveau de confiance lisible.
  String get confidenceLabel {
    if (confidence < 0.3) return 'Faible';
    if (confidence < 0.7) return 'Moyenne';
    return 'Haute';
  }

  /// Liste des matières ordonnées par coefficient descendant.
  List<SubjectScore> get subjectsSortedByCoefDesc {
    final list = subjectScores.values.toList();
    list.sort((a, b) => b.coefficient.compareTo(a.coefficient));
    return list;
  }

  /// Matières non couvertes (où l'élève n'a pas encore répondu).
  List<SubjectScore> get uncoveredSubjects =>
      subjectScores.values.where((s) => !s.covered).toList();

  /// Matières couvertes (ayant au moins une compétence mesurée).
  List<SubjectScore> get coveredSubjects =>
      subjectScores.values.where((s) => s.covered).toList();

  /// Conversion en Map pour persistance JSON.
  Map<String, dynamic> toJson() => {
        'examen': examen,
        'serie': serie,
        'scoreGlobal': scoreGlobal,
        'subjectScores': Map.fromEntries(
          subjectScores.entries.map(
            (e) => MapEntry(e.key, e.value.toJson()),
          ),
        ),
        'totalCoefficient': totalCoefficient,
        'coveredCoefficient': coveredCoefficient,
        'coverageRate': coverageRate,
        'confidence': confidence,
        'predictedAt': predictedAt.toIso8601String(),
        'recommendation': recommendation,
      };

  factory ScorePrediction.fromJson(Map<String, dynamic> json) {
    final subjectScoresJson =
        (json['subjectScores'] as Map<String, dynamic>?) ?? {};
    return ScorePrediction(
      examen: json['examen'] as String? ?? 'BEPC',
      serie: json['serie'] as String?,
      scoreGlobal: (json['scoreGlobal'] as num?)?.toDouble() ?? 0.0,
      subjectScores: Map.fromEntries(
        subjectScoresJson.entries.map(
          (e) => MapEntry(
            e.key,
            SubjectScore.fromJson(e.value as Map<String, dynamic>),
          ),
        ),
      ),
      totalCoefficient: (json['totalCoefficient'] as num?)?.toInt() ?? 0,
      coveredCoefficient:
          (json['coveredCoefficient'] as num?)?.toInt() ?? 0,
      coverageRate: (json['coverageRate'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      predictedAt: json['predictedAt'] != null
          ? DateTime.parse(json['predictedAt'] as String)
          : DateTime.now(),
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'ScorePrediction(${examen}${serie != null ? ' série $serie' : ''}: '
      '${scoreGlobal.toStringAsFixed(1)}/20, '
      'couverture ${(coverageRate * 100).round()}%, '
      'confiance $confidenceLabel)';
}

/// Note estimée d'une matière à l'examen officiel.
///
/// [pLMoyen] est le niveau moyen de maîtrise BKT des compétences
/// de la matière (0 = non maîtrisé, 1 = totalement maîtrisé).
/// [noteEstimee] est la conversion en note sur 20.
class SubjectScore {
  /// Nom de la matière (ex: "Mathématiques").
  final String matiere;

  /// Coefficient officiel MEPST pour cette matière.
  final int coefficient;

  /// P(L) moyen (0-1) des compétences mesurées dans cette matière.
  final double pLMoyen;

  /// Note estimée sur 20.
  final double noteEstimee;

  /// True si l'élève a au moins une compétence mesurée dans la matière.
  final bool covered;

  /// Nombre de compétences mesurées dans la matière.
  final int competencesCount;

  SubjectScore({
    required this.matiere,
    required this.coefficient,
    required this.pLMoyen,
    required this.noteEstimee,
    required this.covered,
    required this.competencesCount,
  });

  /// Contribution pondérée au score global (note × coef).
  double get weightedContribution => noteEstimee * coefficient;

  /// Pourcentage (0-100) pour affichage barre de progression.
  double get notePercent => (noteEstimee / 20.0).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'matiere': matiere,
        'coefficient': coefficient,
        'pLMoyen': pLMoyen,
        'noteEstimee': noteEstimee,
        'covered': covered,
        'competencesCount': competencesCount,
      };

  factory SubjectScore.fromJson(Map<String, dynamic> json) {
    return SubjectScore(
      matiere: json['matiere'] as String? ?? '',
      coefficient: (json['coefficient'] as num?)?.toInt() ?? 0,
      pLMoyen: (json['pLMoyen'] as num?)?.toDouble() ?? 0.0,
      noteEstimee: (json['noteEstimee'] as num?)?.toDouble() ?? 0.0,
      covered: json['covered'] as bool? ?? false,
      competencesCount:
          (json['competencesCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() =>
      'SubjectScore($matiere coef=$coefLabel: ${noteEstimee.toStringAsFixed(1)}/20, '
      'P(L)=$pLMoyen${covered ? '' : ' [non couvert]'})';

  String get coefLabel =>
      coefficient == 0 ? '0' : 'coefficient $coefficient';
}
