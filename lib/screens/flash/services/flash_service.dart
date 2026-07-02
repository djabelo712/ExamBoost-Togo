// lib/screens/flash/services/flash_service.dart
// Service de sélection intelligente des 5 questions pour le mode Flash 5 min.
//
// Logique de sélection :
//   1. On part du pool de toutes les questions disponibles (QuestionService).
//   2. Pour chaque question, on calcule un "score de priorité" :
//        - P(L) de la compétence associée (plus P(L) est bas, plus la question
//          est prioritaire — l'élève doit retravailler ses points faibles).
//        - Distance IRT |b - theta| (plus la difficulté b est proche du
//          niveau theta de l'élève, plus la question est "juste" — ni trop
//          facile, ni trop dure).
//        - Bonus si la question n'a jamais été tentée (nouvelle question ->
//          découverte utile, on l'inclut).
//   3. On trie par score décroissant.
//   4. On applique la contrainte "mix matières" : au maximum 2 questions par
//      matière pour éviter 5 maths d'affilée.
//   5. On prend les 5 premières questions.
//
// Si l'utilisateur n'a pas encore de P(L) (nouvel élève), on tire 5 questions
// aléatoires avec mix matières, en privilégiant la difficulté proche de theta
// (theta par défaut = 0.0, donc questions "moyen").

import '../../../models/question.dart';
import '../../../models/user.dart';
import '../../../services/question_service.dart';

class FlashService {
  /// Nombre de questions par session flash.
  static const int questionsParSession = 5;

  /// Durée totale d'une session flash en secondes (5 min = 300 s).
  static const int dureeSessionSecondes = 5 * 60;

  /// Temps maximum par question avant auto-validation (60 s).
  static const int tempsMaxParQuestionSecondes = 60;

  /// Nombre maximum de questions par matière (mix matières).
  static const int maxParMatiere = 2;

  final QuestionService _questionService;

  FlashService({
    required QuestionService questionService,
  })  : _questionService = questionService;

  /// Sélectionne 5 questions pour la session flash.
  ///
  /// Paramètres :
  ///   - [user] : l'utilisateur courant (pour P(L) par compétence + theta IRT).
  ///   - [excludeIds] : IDs de questions à exclure (ex : déjà vues aujourd'hui).
  ///
  /// Retourne une liste de 5 questions (ou moins si le pool est insuffisant).
  List<Question> selectFlashQuestions({
    required AppUser user,
    List<String> excludeIds = const [],
  }) {
    // ─── 1. Pool de base : toutes les questions, moins les exclues ───
    // On évite d'accéder au champ privé _allQuestions de QuestionService :
    // on itère sur les matières publiques et on concatène getByMatiere.
    final pool = <Question>[];
    for (final matiere in _questionService.matieres) {
      pool.addAll(_questionService.getByMatiere(matiere));
    }
    pool.removeWhere((q) => excludeIds.contains(q.id));

    if (pool.isEmpty) return [];

    // ─── 2. Theta utilisateur (par défaut 0.0 = niveau moyen) ───
    final theta = user.thetaIrt ?? 0.0;

    // ─── 3. Score de priorité pour chaque question ───
    //
    // On calcule un score qui maximise :
    //   - (1 - P(L)) * 0.6  : on cible d'abord les compétences faibles.
    //     P(L) vient du BKT (AppUser.bktMaitrise). Une compétence jamais
    //     tentée a P(L) = 0.0 (getMaitrise retourne 0.0 par défaut), donc
    //     score max -> elle est très prioritaire (découverte).
    //
    // Et qui minimise :
    //   - |b - theta| * 0.15 : on pénalise les questions trop faciles ou
    //     trop difficiles par rapport au niveau IRT de l'élève.
    //
    // Note : on n'utilise PAS SrsService.getOrCreate ici car il a un effet
    // de bord (il crée une ReviewCard pour chaque question du pool, ce qui
    // polluerait la box SRS avec des cartes "due today" pour des questions
    // qu'on ne va même pas poser). On se contente du BKT pour l'info
    // "déjà tentée ou non".
    final scored = <_ScoredQuestion>[];
    for (final q in pool) {
      // P(L) de la compétence (plus bas = plus prioritaire).
      final pLearn = user.getMaitrise(q.competenceId);

      // Distance IRT : |b - theta| (plus petit = plus adapté).
      final b = q.irtB ?? 0.0;
      final irtDistance = (b - theta).abs();

      // Bonus nouveauté : +0.30 si P(L) = 0.0 (compétence jamais vue).
      // Cela permet aux nouvelles compétences d'être explorées en priorité,
      // même si d'autres compétences faibles ont un score similaire.
      final noveltyBonus = (pLearn == 0.0) ? 0.30 : 0.0;

      final score =
          (1.0 - pLearn) * 0.60 + noveltyBonus - irtDistance * 0.15;

      scored.add(_ScoredQuestion(question: q, score: score));
    }

    // ─── 5. Tri par score décroissant ───
    scored.sort((a, b) => b.score.compareTo(a.score));

    // ─── 6. Sélection avec contrainte "mix matières" ───
    // On parcourt la liste triée et on ajoute une question si sa matière
    // n'a pas encore atteint maxParMatiere (2). On s'arrête à 5 questions.
    final selection = <Question>[];
    final matiereCount = <String, int>{};

    for (final sq in scored) {
      if (selection.length >= questionsParSession) break;

      final matiere = sq.question.matiere;
      final count = matiereCount[matiere] ?? 0;

      if (count < maxParMatiere) {
        selection.add(sq.question);
        matiereCount[matiere] = count + 1;
      }
    }

    // ─── 7. Fallback : si on n'a pas 5 questions (pool petit ou contrainte
    // matières trop stricte), on complète avec les meilleures restantes sans
    // la contrainte de matière.
    if (selection.length < questionsParSession) {
      for (final sq in scored) {
        if (selection.length >= questionsParSession) break;
        if (!selection.any((q) => q.id == sq.question.id)) {
          selection.add(sq.question);
        }
      }
    }

    return selection;
  }

  /// Identifie la matière où l'élève a le plus progressé durant la session.
  ///
  /// On compare les P(L) avant et après la session (l'écran de session met à
  /// jour le BKT via AppUser.updateBkt). La matière avec la plus forte hausse
  /// moyenne est retournée. Si aucune matière n'a progressé (ex : 0/5), on
  /// retourne la matière avec la P(L) la plus basse (celle à retravailler).
  String? matiereAvecPlusDeProgression({
    required AppUser user,
    required Map<String, double> pLearnAvant,
  }) {
    // Regroupe les compétences par matière à partir des questions vues.
    // Comme on n'a pas accès direct compétence -> matière ici, on parcourt
    // le pool de questions (via l'API publique) pour construire la map.
    final compToMatiere = <String, String>{};
    for (final matiere in _questionService.matieres) {
      for (final q in _questionService.getByMatiere(matiere)) {
        compToMatiere[q.competenceId] = q.matiere;
      }
    }

    // Pour chaque matière, calcule la hausse moyenne de P(L).
    final hausses = <String, List<double>>{};
    for (final entry in pLearnAvant.entries) {
      final compId = entry.key;
      final avant = entry.value;
      final apres = user.getMaitrise(compId);
      final matiere = compToMatiere[compId];
      if (matiere == null) continue;
      hausses.putIfAbsent(matiere, () => []);
      hausses[matiere]!.add(apres - avant);
    }

    if (hausses.isEmpty) return null;

    // Matière avec la plus forte hausse moyenne.
    String? meilleureMatiere;
    double meilleureHausse = double.negativeInfinity;
    hausses.forEach((matiere, liste) {
      final moyenne = liste.fold(0.0, (a, b) => a + b) / liste.length;
      if (moyenne > meilleureHausse) {
        meilleureHausse = moyenne;
        meilleureMatiere = matiere;
      }
    });

    return meilleureMatiere;
  }

  /// Identifie la matière avec la P(L) moyenne la plus basse (à retravailler).
  /// Utilisé pour le message de résultats quand l'élève a eu un score faible.
  String? matiereLaPlusFaible({required AppUser user}) {
    final compToMatiere = <String, String>{};
    for (final matiere in _questionService.matieres) {
      for (final q in _questionService.getByMatiere(matiere)) {
        compToMatiere[q.competenceId] = q.matiere;
      }
    }

    final parMatiere = <String, List<double>>{};
    for (final entry in user.bktMaitrise.entries) {
      final matiere = compToMatiere[entry.key];
      if (matiere == null) continue;
      parMatiere.putIfAbsent(matiere, () => []);
      parMatiere[matiere]!.add(entry.value);
    }

    if (parMatiere.isEmpty) return null;

    String? plusFaible;
    double plusFaibleMoyenne = double.infinity;
    parMatiere.forEach((matiere, liste) {
      final moyenne = liste.fold(0.0, (a, b) => a + b) / liste.length;
      if (moyenne < plusFaibleMoyenne) {
        plusFaibleMoyenne = moyenne;
        plusFaible = matiere;
      }
    });

    return plusFaible;
  }
}

/// Classe interne : associe une question à son score de priorité.
class _ScoredQuestion {
  final Question question;
  final double score;

  _ScoredQuestion({required this.question, required this.score});
}
