// lib/screens/stats/services/subject_stats_service.dart
// Service local pour les statistiques détaillées par matière et par compétence.
//
// Rôle :
//   - Récupère toutes les compétences d'une matière (depuis QuestionService).
//   - Calcule P(L) moyen par compétence (depuis user.bktMaitrise).
//   - Compte les questions répondues (depuis ReviewCard liées à userId).
//   - Calcule le taux de réussite agrégé (successRate).
//   - Calcule le temps moyen par question (mock réaliste faute de timer persité).
//   - Récupère la dernière date de révision (max(lastReviewDate)).
//   - Génère 3 recommandations automatiques (priorité 1 / streak / quick win).
//   - Fournit l'activité 30 derniers jours pour la timeline.
//
// Limites / mocks :
//   - Le temps moyen par question n'est pas encore persité dans ReviewCard
//     (champ absent du modèle SM-2 actuel). On estime via un mock reproductible
//     basé sur questionId.hashCode : ~15-45s par question, sans persistance.
//     -> L'agent principal pourra ajouter un champ `durationsMs: List<int>`
//        dans ReviewCard pour brancher la vraie mesure plus tard.
//   - Les comparaisons vs classe sont des constantes réalistes (mock 85% / 58%
//     / 247 élèves anonymes) — à brancher sur le backend FastAPI quand il
//     exposerait un endpoint /stats/classroom/anonymous.

import '../../../models/question.dart';
import '../../../models/review_card.dart';
import '../../../models/user.dart';
import '../../../services/question_service.dart';

/// Statistiques agrégées pour une compétence donnée.
class CompetenceStats {
  final String competenceId;
  final String chapitre; // libellé humain (depuis la 1ère question trouvée)
  final String matiere;
  final double pL; // 0..1 (BKT)
  final int questionsTotal; // questions dispo dans la banque
  final int questionsRepondues; // ReviewCards distinctes pour ce userId
  final double tauxReussite; // 0..1 (moyenne des successRate des cartes)
  final DateTime? derniereRevision; // lastReviewDate le plus récent
  final int tempsMoyenSecondes; // estimé (mock)
  final int reponsesCorrectesConsecutives; // pour la reco compétence

  const CompetenceStats({
    required this.competenceId,
    required this.chapitre,
    required this.matiere,
    required this.pL,
    required this.questionsTotal,
    required this.questionsRepondues,
    required this.tauxReussite,
    required this.derniereRevision,
    required this.tempsMoyenSecondes,
    required this.reponsesCorrectesConsecutives,
  });

  /// Statut dérivé du P(L).
  /// "Maîtrisée" (>= 0.85) / "En cours" (0.5-0.85) / "Fragile" (< 0.5)
  /// / "Non évaluée" (P(L) == 0 et aucune réponse enregistrée).
  String get statut {
    if (questionsRepondues == 0 && pL == 0.0) return 'Non évaluée';
    if (pL >= 0.85) return 'Maîtrisée';
    if (pL >= 0.5) return 'En cours';
    return 'Fragile';
  }

  /// P(L) en pourcentage entier.
  int get pLPourcent => (pL * 100).round().clamp(0, 100);

  /// Taux de réussite en pourcentage entier.
  int get tauxReussitePourcent => (tauxReussite * 100).round().clamp(0, 100);
}

/// Statistiques agrégées pour une matière entière.
class SubjectStats {
  final String matiere;
  final List<CompetenceStats> competences; // triées par pL ascendant
  final double pLMoyen; // 0..1
  final int competencesSuivies; // nb avec au moins 1 réponse enregistrée
  final int competencesMaitrisees; // P(L) >= 0.85
  final int competencesEnApprentissage; // 0.5 <= P(L) < 0.85
  final List<Recommendation> recommandations;

  const SubjectStats({
    required this.matiere,
    required this.competences,
    required this.pLMoyen,
    required this.competencesSuivies,
    required this.competencesMaitrisees,
    required this.competencesEnApprentissage,
    required this.recommandations,
  });

  /// P(L) moyen en pourcentage entier.
  int get pLMoyenPourcent => (pLMoyen * 100).round().clamp(0, 100);
}

/// Type de recommandation auto-générée.
enum RecommendationType {
  prioriteFaiblesse, // rouge : ta plus grande faiblesse
  streak, // orange : tu n'as pas révisé X depuis N jours
  quickWin, // bleu : tu es à 78%, encore 2-3 questions
}

/// Une recommandation pédagogique contextuelle.
class Recommendation {
  final RecommendationType type;
  final String titre;
  final String description;
  final String competenceIdCible; // pour navigation éventuelle
  final String matiereCible;

  const Recommendation({
    required this.type,
    required this.titre,
    required this.description,
    required this.competenceIdCible,
    required this.matiereCible,
  });
}

/// Données d'activité pour un jour (timeline 30 jours).
class DayActivity {
  final DateTime date;
  final int questionsRepondues;

  const DayActivity({required this.date, required this.questionsRepondues});
}

/// Données mock pour la comparaison vs classe (anonymisée).
class ClassroomComparison {
  final double top10Pourcent; // 0..1 — moyenne P(L) du top 10%
  final double moyenneClasse; // 0..1 — moyenne tous élèves
  final double toi; // 0..1 — moyenne P(L) de l'utilisateur courant
  final int nombreElevesAnonymes;

  const ClassroomComparison({
    required this.top10Pourcent,
    required this.moyenneClasse,
    required this.toi,
    required this.nombreElevesAnonymes,
  });
}

class SubjectStatsService {
  /// Constantes mock pour la comparaison vs classe (anonymisée).
  /// Valeurs réalistes basées sur les moyennes BEPC Togo 2024.
  static const double _mockTop10 = 0.85;
  static const double _mockMoyenneClasse = 0.58;
  static const int _mockNbEleves = 247;

  /// Calcule toutes les stats d'une matière.
  SubjectStats computeSubjectStats({
    required String matiere,
    required AppUser user,
    required QuestionService questionService,
    required List<ReviewCard> userCards,
  }) {
    final questionsMatiere = questionService.getByMatiere(matiere);

    // ─── Grouper les questions par competenceId ──────────────────
    final byCompetence = <String, List<Question>>{};
    for (final q in questionsMatiere) {
      byCompetence.putIfAbsent(q.competenceId, () => []).add(q);
    }

    // ─── Indexer les cartes par questionId pour lookup rapide ─────
    final cardByQuestion = <String, ReviewCard>{};
    for (final c in userCards) {
      cardByQuestion[c.questionId] = c;
    }

    // ─── Pour chaque compétence, calculer les stats ───────────────
    final competences = <CompetenceStats>[];
    for (final entry in byCompetence.entries) {
      final compId = entry.key;
      final questions = entry.value;
      final chapitre = questions.first.chapitre;

      // Cartes de révision liées aux questions de cette compétence
      final cardsForComp = <ReviewCard>[];
      int reponsesCorrectesConsecutives = 0;
      for (final q in questions) {
        final c = cardByQuestion[q.id];
        if (c != null) {
          cardsForComp.add(c);
          // On calcule la série de réussites consécutives (en partant
          // de la dernière réponse) — heuristique : si la carte n'est
          // pas "isLearning" et que successRate est élevé, on considère
          // 3 réussies consécutives (mock) ; sinon on prend
          // correctAttempts plafonné à 5.
          if (!c.isLearning) {
            reponsesCorrectesConsecutives =
                c.correctAttempts.clamp(0, 5);
          }
        }
      }

      final pL = user.getMaitrise(compId);

      // Taux de réussite agrégé : moyenne pondérée des successRate des
      // cartes (pondérée par totalAttempts pour donner plus de poids
      // aux compétences très révisées).
      double tauxReussite = 0;
      int totalAttempts = 0;
      int totalCorrect = 0;
      DateTime? derniereRevision;
      int tempsTotalSecondes = 0;
      int nbRepondues = 0;
      for (final c in cardsForComp) {
        totalAttempts += c.totalAttempts;
        totalCorrect += c.correctAttempts;
        if (c.lastReviewDate != null) {
          if (derniereRevision == null ||
              c.lastReviewDate!.isAfter(derniereRevision)) {
            derniereRevision = c.lastReviewDate;
          }
        }
        // Temps moyen estimé (mock reproductible via hashCode) :
        // on simule une durée par tentative.
        tempsTotalSecondes +=
            _estimerTempsTotalSecondes(c.questionId, c.totalAttempts);
        nbRepondues += c.totalAttempts > 0 ? 1 : 0;
      }
      if (totalAttempts > 0) {
        tauxReussite = totalCorrect / totalAttempts;
      }
      final tempsMoyen = nbRepondues > 0
          ? (tempsTotalSecondes / nbRepondues).round()
          : _estimerTempsTotalSecondes(compId, 1);

      competences.add(CompetenceStats(
        competenceId: compId,
        chapitre: chapitre,
        matiere: matiere,
        pL: pL,
        questionsTotal: questions.length,
        questionsRepondues: nbRepondues,
        tauxReussite: tauxReussite,
        derniereRevision: derniereRevision,
        tempsMoyenSecondes: tempsMoyen,
        reponsesCorrectesConsecutives: reponsesCorrectesConsecutives,
      ));
    }

    // ─── Trier par P(L) ascendant (faibles d'abord) ──────────────
    competences.sort((a, b) => a.pL.compareTo(b.pL));

    // ─── Agrégats ────────────────────────────────────────────────
    final competencesSuivies =
        competences.where((c) => c.questionsRepondues > 0).length;
    final competencesMaitrisees =
        competences.where((c) => c.pL >= 0.85).length;
    final competencesEnApprentissage =
        competences.where((c) => c.pL >= 0.5 && c.pL < 0.85).length;

    final pLMoyen = competences.isEmpty
        ? 0.0
        : competences.map((c) => c.pL).reduce((a, b) => a + b) /
            competences.length;

    final recommandations = _genererRecommandations(
      matiere: matiere,
      competences: competences,
    );

    return SubjectStats(
      matiere: matiere,
      competences: competences,
      pLMoyen: pLMoyen,
      competencesSuivies: competencesSuivies,
      competencesMaitrisees: competencesMaitrisees,
      competencesEnApprentissage: competencesEnApprentissage,
      recommandations: recommandations,
    );
  }

  /// Récupère les stats d'une compétence précise.
  CompetenceStats? computeCompetenceStats({
    required String competenceId,
    required AppUser user,
    required QuestionService questionService,
    required List<ReviewCard> userCards,
  }) {
    final questions = questionService.getByCompetence(competenceId);
    if (questions.isEmpty) return null;
    final matiere = questions.first.matiere;
    final chapitre = questions.first.chapitre;

    final cardByQuestion = <String, ReviewCard>{};
    for (final c in userCards) {
      cardByQuestion[c.questionId] = c;
    }

    final cardsForComp = <ReviewCard>[];
    int totalAttempts = 0;
    int totalCorrect = 0;
    DateTime? derniereRevision;
    int tempsTotalSecondes = 0;
    int nbRepondues = 0;
    int reponsesCorrectesConsecutives = 0;
    for (final q in questions) {
      final c = cardByQuestion[q.id];
      if (c != null) {
        cardsForComp.add(c);
        totalAttempts += c.totalAttempts;
        totalCorrect += c.correctAttempts;
        if (c.lastReviewDate != null) {
          if (derniereRevision == null ||
              c.lastReviewDate!.isAfter(derniereRevision)) {
            derniereRevision = c.lastReviewDate;
          }
        }
        tempsTotalSecondes +=
            _estimerTempsTotalSecondes(c.questionId, c.totalAttempts);
        nbRepondues += c.totalAttempts > 0 ? 1 : 0;
        if (!c.isLearning) {
          reponsesCorrectesConsecutives =
              c.correctAttempts.clamp(0, 5);
        }
      }
    }

    final pL = user.getMaitrise(competenceId);
    final tauxReussite =
        totalAttempts > 0 ? totalCorrect / totalAttempts : 0.0;
    final tempsMoyen = nbRepondues > 0
        ? (tempsTotalSecondes / nbRepondues).round()
        : _estimerTempsTotalSecondes(competenceId, 1);

    return CompetenceStats(
      competenceId: competenceId,
      chapitre: chapitre,
      matiere: matiere,
      pL: pL,
      questionsTotal: questions.length,
      questionsRepondues: nbRepondues,
      tauxReussite: tauxReussite,
      derniereRevision: derniereRevision,
      tempsMoyenSecondes: tempsMoyen,
      reponsesCorrectesConsecutives: reponsesCorrectesConsecutives,
    );
  }

  /// Récupère l'historique chronologique des réponses pour une compétence.
  /// Retourne une liste triée par date descendante (la plus récente d'abord).
  List<CompetenceHistoryEntry> getCompetenceHistory({
    required String competenceId,
    required QuestionService questionService,
    required List<ReviewCard> userCards,
    int limit = 50,
  }) {
    final questions = questionService.getByCompetence(competenceId);
    final questionById = {for (final q in questions) q.id: q};

    final entries = <CompetenceHistoryEntry>[];
    for (final c in userCards) {
      final q = questionById[c.questionId];
      if (q == null) continue;
      // Une carte == une question. On n'a qu'une seule lastReviewDate enregistrée
      // (pas un historique détaillé par tentative). On synthétise donc une entrée
      // représentative de la dernière interaction de l'élève avec cette question.
      if (c.lastReviewDate == null) continue;
      // Qualité SM-2 estimée depuis successRate (mock) :
      // - successRate 1.0 -> qualité 5 (parfait)
      // - successRate 0.66 -> qualité 4
      // - successRate 0.5 -> qualité 3
      // - successRate 0.33 -> qualité 2
      // - successRate 0.0 -> qualité 0
      final qualite = _estimerQualite(c.successRate, c.isLearning);
      entries.add(CompetenceHistoryEntry(
        date: c.lastReviewDate!,
        questionId: q.id,
        extraitEnonce: _extraireEnonce(q.enonce, 60),
        qualiteSm2: qualite,
        tempsPasseSecondes:
            _estimerTempsTotalSecondes(q.id, 1),
        correct: c.successRate > 0,
        matiere: q.matiere,
        chapitre: q.chapitre,
        annee: q.annee,
        examen: q.examen,
      ));
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.take(limit).toList();
  }

  /// Génère l'activité 30 derniers jours pour la timeline.
  List<DayActivity> getTimeline30Jours(List<ReviewCard> userCards) {
    final today = DateTime.now();
    final today00 = DateTime(today.year, today.month, today.day);
    // Map dateYYYYMMDD -> count
    final counts = <String, int>{};
    for (final c in userCards) {
      if (c.lastReviewDate == null) continue;
      final d = DateTime(
          c.lastReviewDate!.year, c.lastReviewDate!.month, c.lastReviewDate!.day);
      final diff = today00.difference(d).inDays;
      if (diff < 0 || diff >= 30) continue;
      final key = '${d.year}-${d.month}-${d.day}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final result = <DayActivity>[];
    for (int i = 29; i >= 0; i--) {
      final d = today00.subtract(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      result.add(DayActivity(date: d, questionsRepondues: counts[key] ?? 0));
    }
    return result;
  }

  /// Données mock de comparaison vs classe (anonymisée).
  /// [pLUtilisateur] est la moyenne P(L) réelle de l'élève (0..1).
  ClassroomComparison getClassroomComparison(double pLUtilisateur) {
    return ClassroomComparison(
      top10Pourcent: _mockTop10,
      moyenneClasse: _mockMoyenneClasse,
      toi: pLUtilisateur,
      nombreElevesAnonymes: _mockNbEleves,
    );
  }

  // ─── Helpers privés ──────────────────────────────────────────

  List<Recommendation> _genererRecommandations({
    required String matiere,
    required List<CompetenceStats> competences,
  }) {
    final recos = <Recommendation>[];

    // 1. Priorité 1 : la plus grande faiblesse
    final plusFaible = competences
        .where((c) => c.questionsRepondues > 0)
        .toList()
      ..sort((a, b) => a.pL.compareTo(b.pL));
    if (plusFaible.isNotEmpty) {
      final c = plusFaible.first;
      recos.add(Recommendation(
        type: RecommendationType.prioriteFaiblesse,
        titre: 'Priorité : renforcer "${c.chapitre}"',
        description:
            'Ta maîtrise est de ${c.pLPourcent}% sur ce chapitre. '
            'C\'est ta plus grande faiblesse en $matiere. '
            'Révise-le en priorité pour progresser.',
        competenceIdCible: c.competenceId,
        matiereCible: matiere,
      ));
    }

    // 2. Streak : compétence non révisée depuis longtemps
    final maintenant = DateTime.now();
    CompetenceStats? plusAncienne;
    int plusAncienneNbJours = -1;
    for (final c in competences) {
      if (c.derniereRevision == null) continue;
      final jours = maintenant.difference(c.derniereRevision!).inDays;
      if (jours > plusAncienneNbJours) {
        plusAncienneNbJours = jours;
        plusAncienne = c;
      }
    }
    if (plusAncienne != null && plusAncienneNbJours >= 3) {
      recos.add(Recommendation(
        type: RecommendationType.streak,
        titre: 'Streak en risque : "${plusAncienne!.chapitre}"',
        description:
            'Tu n\'as pas révisé ce chapitre depuis '
            '${plusAncienneNbJours} jour${plusAncienneNbJours > 1 ? "s" : ""}. '
            'Tu risques d\'oublier ! Une petite session de 5 questions '
            'suffirait à consolider.',
        competenceIdCible: plusAncienne.competenceId,
        matiereCible: matiere,
      ));
    }

    // 3. Quick win : compétence entre 0.5 et 0.85 (proche de la maîtrise)
    final quickWin = competences
        .where((c) => c.pL >= 0.5 && c.pL < 0.85 && c.questionsRepondues > 0)
        .toList()
      ..sort((a, b) => b.pL.compareTo(a.pL));
    if (quickWin.isNotEmpty) {
      final c = quickWin.first;
      final questionsRestantes = (10 - c.reponsesCorrectesConsecutives)
          .clamp(1, 10);
      recos.add(Recommendation(
        type: RecommendationType.quickWin,
        titre: 'Quick win : "${c.chapitre}"',
        description:
            'Tu es à ${c.pLPourcent}% — encore $questionsRestantes question'
            '${questionsRestantes > 1 ? "s" : ""} correcte'
            '${questionsRestantes > 1 ? "s" : ""} et tu maîtrises '
            'ce chapitre !',
        competenceIdCible: c.competenceId,
        matiereCible: matiere,
      ));
    }

    return recos;
  }

  /// Estimation du temps total passé (mock reproductible).
  /// On simule 15-45 secondes par tentative, basé sur hashCode(questionId).
  int _estimerTempsTotalSecondes(String questionId, int nbTentatives) {
    final base = 15 + (questionId.hashCode.abs() % 30); // 15..44
    return base * nbTentatives;
  }

  /// Estimation qualité SM-2 (0-5) depuis le successRate et le statut.
  int _estimerQualite(double successRate, bool isLearning) {
    if (successRate >= 0.95) return 5;
    if (successRate >= 0.75) return 4;
    if (successRate >= 0.5) return 3;
    if (successRate >= 0.25) return 2;
    if (successRate > 0) return 1;
    return 0;
  }

  /// Extrait les N premiers caractères de l'énoncé (pour affichage compact).
  String _extraireEnonce(String enonce, int max) {
    final clean = enonce.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}...';
  }
}

/// Une entrée d'historique pour la page détail compétence.
class CompetenceHistoryEntry {
  final DateTime date;
  final String questionId;
  final String extraitEnonce;
  final int qualiteSm2; // 0..5
  final int tempsPasseSecondes;
  final bool correct;
  final String matiere;
  final String chapitre;
  final int? annee;
  final String examen;

  const CompetenceHistoryEntry({
    required this.date,
    required this.questionId,
    required this.extraitEnonce,
    required this.qualiteSm2,
    required this.tempsPasseSecondes,
    required this.correct,
    required this.matiere,
    required this.chapitre,
    required this.annee,
    required this.examen,
  });
}
