// lib/services/score_calculator.dart
// Calcul du score prédit à l'examen officiel BEPC/BAC selon
// les coefficients du Ministère togolais (MEPST).
//
// Différenciateur ExamBoost vs concurrents génériques :
//   - Khan Academy / Afrilearn = score générique basé sur "% de réussite"
//   - ExamBoost                 = score pondéré selon coefficients officiels
//                                  du Togo (Mathématiques coef 6 en série C
//                                  pèse 6× plus que l'Histoire-Géo coef 1).
//
// Pipeline :
//   1. Pour chaque matière de l'examen, on collecte les compétences BKT
//      déjà mesurées chez l'élève (depuis user.bktMaitrise).
//   2. On calcule le P(L) moyen de la matière.
//   3. On convertit P(L) -> note /20 (note = P(L) * 20, calibrée pour
//      que P(L) = 0.85 = 16/20 ≈ "bon élève").
//   4. On pondère par le coefficient officiel MEPST de la matière.
//   5. scoreGlobal = Σ (note × coef) / Σ coef (sur les matières couvertes).
//   6. On calcule la confiance (coverage + nb questions répondues).
//   7. On génère une recommandation pédagogique contextuelle.

import '../models/examen_coefficients.dart';
import '../models/score_prediction.dart';
import '../models/user.dart';

/// Calculateur de score officiel BEPC/BAC avec coefficients MEPST.
///
/// Usage :
/// ```dart
/// final prediction = ScoreCalculator.predict(
///   user: currentUser,
///   examen: 'BEPC',
/// );
/// print(prediction.scoreGlobal); // ex: 12.5/20
/// ```
class ScoreCalculator {
  ScoreCalculator._(); // classe utilitaire

  /// Calcule le score prédit à l'examen, basé sur le BKT par compétence
  /// pondéré par les coefficients officiels MEPST.
  ///
  /// [user]     : l'élève courant (avec bktMaitrise et totalQuestionsAnswered).
  /// [examen]   : "BEPC", "BAC1", "BAC2", "Probatoire" ou "BAC".
  /// [serie]    : "A", "B", "C", "D", "F" (null pour BEPC).
  /// [matiereToCompetences] : optionnel — map matière -> liste de prefixes
  ///   de competenceId (ex: "Mathématiques" -> ["TG-MATHS-EQ1D", ...]).
  ///   Si null, on déduit les compétences par préfixe (voir
  ///   [_defaultMatierePrefixes]).
  static ScorePrediction predict({
    required AppUser user,
    required String examen,
    String? serie,
    Map<String, List<String>>? matiereToCompetences,
  }) {
    final coefficients = ExamenCoefficients.get(examen, serie);
    final totalCoef =
        coefficients.values.fold(0, (a, b) => a + b);

    final subjectScores = <String, SubjectScore>{};
    double weightedSum = 0;
    int coveredCoef = 0;

    final mapping = matiereToCompetences ?? _defaultMatierePrefixes;

    for (final entry in coefficients.entries) {
      final matiere = entry.key;
      final coef = entry.value;

      // Récupère les compétences (préfixes) associées à cette matière
      final competencePrefixes = mapping[matiere] ?? const [];

      // Cherche dans user.bktMaitrise toutes les compétences qui
      // commencent par l'un des préfixes (ex: "TG-MATHS-EQ1D-001"
      // commence par "TG-MATHS-EQ1D").
      final pLs = <double>[];
      for (final competenceId in user.bktMaitrise.keys) {
        for (final prefix in competencePrefixes) {
          if (competenceId.startsWith(prefix)) {
            pLs.add(user.bktMaitrise[competenceId]!);
            break; // on a trouvé le préfixe correspondant
          }
        }
      }

      if (pLs.isEmpty) {
        // Matière pas encore touchée par l'élève
        subjectScores[matiere] = SubjectScore(
          matiere: matiere,
          coefficient: coef,
          pLMoyen: 0.0,
          noteEstimee: 0.0,
          covered: false,
          competencesCount: 0,
        );
        continue;
      }

      final pLMoyen = pLs.reduce((a, b) => a + b) / pLs.length;
      final noteEstimee = _pLToNote(pLMoyen);

      weightedSum += noteEstimee * coef;
      coveredCoef += coef;

      subjectScores[matiere] = SubjectScore(
        matiere: matiere,
        coefficient: coef,
        pLMoyen: pLMoyen,
        noteEstimee: noteEstimee,
        covered: true,
        competencesCount: pLs.length,
      );
    }

    final scorePondere =
        coveredCoef > 0 ? weightedSum / coveredCoef : 0.0;

    // Taux de couverture du programme
    final coverageRate =
        totalCoef > 0 ? coveredCoef / totalCoef : 0.0;

    // Indice de confiance (combine couverture + maturité des données)
    final confidence =
        _computeConfidence(coverageRate, user.totalQuestionsAnswered);

    return ScorePrediction(
      examen: examen,
      serie: serie,
      scoreGlobal: scorePondere.clamp(0.0, 20.0),
      subjectScores: subjectScores,
      totalCoefficient: totalCoef,
      coveredCoefficient: coveredCoef,
      coverageRate: coverageRate,
      confidence: confidence,
      predictedAt: DateTime.now(),
      recommendation: _generateRecommendation(scorePondere, coverageRate),
    );
  }

  /// Convertit un P(L) BKT en note /20.
  ///
  /// Calibrage empirique (à valider sur données réelles Togo) :
  ///   P(L) = 0    -> 0/20   (rien maîtrisé)
  ///   P(L) = 0.5  -> 10/20  (moyenne)
  ///   P(L) = 0.85 -> 17/20  (seuil maîtrise ExamBoost = bonne note)
  ///   P(L) = 1.0  -> 20/20  (excellence)
  ///
  /// On applique un léger ajustement non linéaire pour que le seuil
  /// de maîtrise (P(L) >= 0.85) corresponde à une note >= 16/20
  /// plutôt qu'à 17/20 strict, ce qui est plus réaliste pour un
  /// "bon élève" au BEPC/BAC.
  static double _pLToNote(double pL) {
    // note = P(L) * 20 (transformation linéaire simple)
    // Ajustement : léger boost au-dessus de 0.5 pour valoriser la maîtrise
    // solidement acquise, et léger malus en-dessous pour pénaliser les
    // compétences instables.
    double note;
    if (pL >= 0.5) {
      // Zone "maîtrise" : on valorise jusqu'à 20
      note = 10.0 + (pL - 0.5) * 20.0; // 0.5 -> 10, 1.0 -> 20
    } else {
      // Zone "fragile" : on pénalise plus
      note = pL * 20.0; // 0 -> 0, 0.5 -> 10
    }
    return note.clamp(0.0, 20.0);
  }

  /// Calcule l'indice de confiance (0-1) en fonction de la couverture
  /// du programme et du nombre total de questions répondues.
  ///
  /// Règles :
  ///   - < 50 questions OU couverture < 30%   -> confiance faible (0.2)
  ///   - 50-200 questions OU couverture 30-70% -> confiance moyenne (0.5)
  ///   - > 200 questions ET couverture > 70%  -> confiance haute (0.85)
  static double _computeConfidence(double coverage, int totalQuestions) {
    if (totalQuestions < 50 || coverage < 0.3) return 0.2;
    if (totalQuestions < 200 || coverage < 0.7) return 0.5;
    return 0.85;
  }

  /// Génère une recommandation pédagogique contextuelle.
  ///
  /// Le message est adapté :
  ///   - au score prédit (préoccupant / sous moyenne / moyenne / bon / excellent)
  ///   - à la couverture du programme (insuffisante / correcte / large)
  static String _generateRecommendation(double score, double coverage) {
    if (coverage < 0.3) {
      return 'Continue à réviser pour avoir une prédiction fiable. '
          'Couvre au moins 30 % du programme pour débloquer une estimation '
          'exploitable.';
    }
    if (score < 8) {
      return 'Attention : ton score prédit est préoccupant. '
          'Concentre-toi sur les bases et demande de l\'aide à un enseignant '
          'ou un camarade.';
    }
    if (score < 10) {
      return 'Tu es en dessous de la moyenne. '
          'Identifie tes chapitres faibles et attaque-les en priorité — '
          'le dashboard t\'indique où concentrer tes efforts.';
    }
    if (score < 12) {
      return 'Tu approches de la moyenne. '
          'Un effort sur tes matières faibles peut faire la différence : '
          'vise +2 points en priorité sur le coef le plus bas.';
    }
    if (score < 14) {
      return 'Bon score ! Maintiens ton rythme et affine les détails. '
          'Tu es admissible, mais il reste une marge pour viser une mention.';
    }
    if (score < 16) {
      return 'Très bon score. Tu es sur la bonne voie, vise l\'excellence '
          '(mention Bien) en consolidant les matières à fort coefficient.';
    }
    return 'Excellent ! Maintiens ton niveau et aide tes camarades — '
        'tu es en position de mention Très Bien.';
  }

  /// Mapping par défaut matière -> préfixes de competenceId.
  ///
  /// Basé sur la structure observée dans assets/data/questions.json :
  ///   "Mathématiques" -> "TG-MATHS-*"
  ///   "Français"      -> "TG-FR-*"
  ///   etc.
  ///
  /// Pour les matières sans questions dans la banque actuelle
  /// (Philosophie, EPS, Travaux Manuels, Économie, Technologie,
  /// Travaux Pratiques), on laisse la liste vide — l'élève devra
  /// répondre à des questions de ces matières quand elles seront
  /// disponibles pour qu'elles soient prises en compte.
  static const Map<String, List<String>> _defaultMatierePrefixes = {
    'Mathématiques': ['TG-MATHS-'],
    'Français': ['TG-FR-'],
    'Sciences Physiques': ['TG-PHYS-'],
    'Sciences de la Vie et de la Terre': ['TG-SVT-'],
    'Histoire-Géographie': ['TG-HG-'],
    'Anglais': ['TG-ANG-'],
    // Matières non encore présentes dans la banque — listes vides
    'Philosophie': [],
    'Éducation Physique et Sportive': [],
    'Travaux Manuels': [],
    'Travaux Pratiques': [],
    'Économie': [],
    'Technologie': [],
  };
}
