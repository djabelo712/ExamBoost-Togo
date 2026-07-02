// lib/screens/homework/services/homework_service.dart
// Service central du module Devoirs ExamBoost.
//
// Responsabilités :
//   - Charger les devoirs (mock local pour l'instant, API plus tard),
//   - Suivre les soumissions des élèves (commencer / répondre / soumettre),
//   - Calculer scores + auto-correction QCM,
//   - Fournir les stats agrégées par classe pour l'enseignant,
//   - Exporter un CSV simple pour le rapport classe.
//
// Le service est un [ChangeNotifier] : les écrans écoutent les changements
// via `Provider.of<HomeworkService>(context)` et se rebuild quand une
// soumission est enregistrée ou un devoir créé.
//
// Mock : 5 devoirs (Maths, FR, Sciences, SVT, Histoire) + 30 élèves
// répartis sur 3 classes (3e A, 3e B, Terminale C) avec soumissions
// pré-remplies pour démontrer tous les statuts (aFaire / enCours / rendu
// / manque) et toutes les notes (de 4/20 à 19/20).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/homework.dart';
import '../models/homework_submission.dart';

/// Élève fictif (mock) — distinct de AppUser car la persistance Hive
/// n'est pas encore câblée pour les devoirs.
class MockEleve {
  final String id;
  final String prenom;
  final String nom;
  final String classe;

  const MockEleve({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.classe,
  });

  String get nomComplet => '$prenom $nom';
  String get initiales {
    final i1 = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final i2 = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$i1$i2';
  }
}

class HomeworkService extends ChangeNotifier {
  HomeworkService() {
    _initMockData();
  }

  // ─── ÉTAT INTERNE ──────────────────────────────────────────────

  final List<Homework> _homeworks = [];
  final List<HomeworkSubmission> _submissions = [];
  final List<MockEleve> _eleves = [];

  /// Identifiant de l'élève courant (mock). Sera remplacé par
  /// `Provider.of<UserProvider>(context).userId` lors du wiring final.
  static const String currentEleveId = 'eleve_moi';

  /// Identifiant de l'enseignant courant (mock).
  static const String currentEnseignantId = 'prof_kossi';

  List<Homework> get homeworks => List.unmodifiable(_homeworks);
  List<MockEleve> get eleves => List.unmodifiable(_eleves);

  // ─── ACCÈS ÉLÈVE ───────────────────────────────────────────────

  /// Tous les devoirs assignés à l'élève courant.
  /// (Mock : l'élève est en "3e A" donc on retourne les devoirs
  /// qui ciblent 3e A. Pour la démo on suppose que tous les devoirs
  /// le ciblent, sauf si on veut filtrer par classe réelle.)
  List<Homework> getHomeworksForCurrentEleve() {
    // L'élève démo est en "3e A" — on filtre sur cette classe.
    return _homeworks.where((h) => h.classes.contains('3e A')).toList();
  }

  /// Récupère la soumission de l'élève courant pour un devoir donné
  /// (null si l'élève n'a jamais ouvert le devoir).
  HomeworkSubmission? getSoumissionForCurrentEleve(String homeworkId) {
    for (final s in _submissions) {
      if (s.homeworkId == homeworkId && s.eleveId == currentEleveId) {
        return s;
      }
    }
    return null;
  }

  /// Crée une soumission "en cours" quand l'élève ouvre un devoir
  /// pour la première fois.
  HomeworkSubmission commencerHomework(String homeworkId) {
    final existing = getSoumissionForCurrentEleve(homeworkId);
    if (existing != null) return existing;

    final eleve = _eleves.firstWhere(
      (e) => e.id == currentEleveId,
      orElse: () => const MockEleve(
        id: currentEleveId,
        prenom: 'Moi',
        nom: 'Élève',
        classe: '3e A',
      ),
    );

    final sub = HomeworkSubmission(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      homeworkId: homeworkId,
      eleveId: currentEleveId,
      eleveNom: eleve.nom,
      elevePrenom: eleve.prenom,
      classe: eleve.classe,
      dateDebut: DateTime.now(),
      enCours: true,
      termine: false,
      reponses: {},
      score: 0,
      tempsPasseSecondes: 0,
    );
    _submissions.add(sub);
    notifyListeners();
    return sub;
  }

  /// Enregistre / met à jour une réponse de l'élève pour une question.
  /// Calcule immédiatement si la réponse est correcte (auto-correction QCM).
  void enregistrerReponse({
    required String homeworkId,
    required String questionId,
    int? qcmIndex,
    String? texteOuvert,
    bool? autoEvalueCorrect,
  }) {
    final homework = _homeworks.firstWhere((h) => h.id == homeworkId);
    final question = homework.questions.firstWhere((q) => q.id == questionId);

    // Auto-correction
    bool isCorrect = false;
    int pointsObtenus = 0;
    if (question.isQcm) {
      isCorrect = qcmIndex == question.bonIndex;
      pointsObtenus = isCorrect ? question.points : 0;
    } else if (texteOuvert != null && question.bonneReponseOuverte != null) {
      // Comparaison souple (minuscules, sans espaces superflus)
      final a = texteOuvert.trim().toLowerCase();
      final b = question.bonneReponseOuverte!.trim().toLowerCase();
      isCorrect = a.isNotEmpty && a == b;
      pointsObtenus = isCorrect ? question.points : 0;
    } else if (autoEvalueCorrect != null) {
      // Question ouverte sans réponse stricte : l'élève auto-évalue
      isCorrect = autoEvalueCorrect;
      pointsObtenus = isCorrect ? question.points : 0;
    }

    final answer = HomeworkAnswer(
      questionId: questionId,
      qcmIndex: qcmIndex,
      texteOuvert: texteOuvert,
      autoEvalueCorrect: autoEvalueCorrect,
      isCorrect: isCorrect,
      pointsObtenus: pointsObtenus,
    );

    // Met à jour la soumission
    final subIndex = _submissions.indexWhere(
      (s) => s.homeworkId == homeworkId && s.eleveId == currentEleveId,
    );
    if (subIndex >= 0) {
      final sub = _submissions[subIndex];
      final newReponses = Map<String, HomeworkAnswer>.from(sub.reponses);
      newReponses[questionId] = answer;
      final newScore = newReponses.values.fold(0, (s, a) => s + a.pointsObtenus);
      _submissions[subIndex] = HomeworkSubmission(
        id: sub.id,
        homeworkId: sub.homeworkId,
        eleveId: sub.eleveId,
        eleveNom: sub.eleveNom,
        elevePrenom: sub.elevePrenom,
        classe: sub.classe,
        dateDebut: sub.dateDebut,
        dateSoumission: sub.dateSoumission,
        enCours: true,
        termine: false,
        reponses: newReponses,
        score: newScore,
        tempsPasseSecondes: sub.tempsPasseSecondes,
      );
    }
    notifyListeners();
  }

  /// Termine la soumission : fige les réponses, calcule le score final,
  /// marque `termine=true` et `enCours=false`, enregistre la date.
  /// Retourne la soumission finale (avec score, note20, etc.).
  HomeworkSubmission? soumettreHomework({
    required String homeworkId,
    required int tempsPasseSecondes,
  }) {
    final subIndex = _submissions.indexWhere(
      (s) => s.homeworkId == homeworkId && s.eleveId == currentEleveId,
    );
    if (subIndex < 0) return null;

    final sub = _submissions[subIndex];
    final homework = _homeworks.firstWhere((h) => h.id == homeworkId);

    // Score final = somme des points obtenus (déjà calculés à chaque réponse)
    final score = sub.reponses.values.fold(0, (s, a) => s + a.pointsObtenus);

    final finalSub = HomeworkSubmission(
      id: sub.id,
      homeworkId: sub.homeworkId,
      eleveId: sub.eleveId,
      eleveNom: sub.eleveNom,
      elevePrenom: sub.elevePrenom,
      classe: sub.classe,
      dateDebut: sub.dateDebut,
      dateSoumission: DateTime.now(),
      enCours: false,
      termine: true,
      reponses: sub.reponses,
      score: score,
      tempsPasseSecondes: tempsPasseSecondes,
    );

    _submissions[subIndex] = finalSub;
    notifyListeners();

    // Log pour debug (peut servir au tableau de bord enseignant)
    debugPrint(
      'Devoir $homeworkId soumis par ${finalSub.nomComplet} : '
      '$score/${homework.pointsTotal} pts '
      '(${finalSub.note20.toStringAsFixed(1)}/20) '
      'en ${finalSub.tempsLabel}'
      '${finalSub.isEnRetard(homework) ? " (EN RETARD)" : ""}',
    );

    return finalSub;
  }

  // ─── ACCÈS ENSEIGNANT ──────────────────────────────────────────

  /// Tous les devoirs créés par l'enseignant courant.
  List<Homework> getHomeworksForCurrentEnseignant() {
    return _homeworks
        .where((h) => h.enseignantId == currentEnseignantId)
        .toList();
  }

  /// Toutes les soumissions pour un devoir donné (toutes classes confondues).
  List<HomeworkSubmission> getSubmissionsForHomework(String homeworkId) {
    return _submissions.where((s) => s.homeworkId == homeworkId).toList();
  }

  /// Effectif total ciblé par un devoir (somme des effectifs des classes
  /// ciblées — tous les élèves fictifs dont la classe est dans `classes`).
  int getEffectifForHomework(String homeworkId) {
    final homework = _homeworks.firstWhere((h) => h.id == homeworkId);
    return _eleves.where((e) => homework.classes.contains(e.classe)).length;
  }

  /// Calcule les stats agrégées pour un devoir (côté enseignant).
  HomeworkClassStats getStatsForHomework(String homeworkId) {
    final homework = _homeworks.firstWhere((h) => h.id == homeworkId);
    final effectif = getEffectifForHomework(homeworkId);
    final subs = getSubmissionsForHomework(homeworkId);

    final rendus = subs.where((s) => s.termine).toList();
    final enCours = subs.where((s) => s.enCours && !s.termine).length;
    final manques = effectif - rendus.length - enCours;

    // Moyenne des notes (sur 20) des élèves ayant rendu
    double moyenne = 0;
    int tempsTotal = 0;
    if (rendus.isNotEmpty) {
      double sum = 0;
      for (final s in rendus) {
        // Note sur 20 = (score / pointsTotal du devoir) * 20
        sum += (s.score / homework.pointsTotal) * 20;
        tempsTotal += s.tempsPasseSecondes;
      }
      moyenne = sum / rendus.length;
    }

    // Réussite par question
    final reussiteParQuestion = <String, double>{};
    for (final q in homework.questions) {
      int correct = 0;
      int total = 0;
      for (final s in rendus) {
        final ans = s.reponses[q.id];
        if (ans != null) {
          total++;
          if (ans.isCorrect) correct++;
        }
      }
      reussiteParQuestion[q.id] =
          total > 0 ? (correct / total) * 100 : 0;
    }

    return HomeworkClassStats(
      homeworkId: homeworkId,
      effectifClasse: effectif,
      nbRendus: rendus.length,
      nbEnCours: enCours,
      nbManques: manques < 0 ? 0 : manques,
      moyenne20: moyenne,
      tempsMoyenSecondes: rendus.isNotEmpty ? tempsTotal ~/ rendus.length : 0,
      reussiteParQuestion: reussiteParQuestion,
    );
  }

  /// Crée un nouveau devoir (côté enseignant).
  /// Retourne le devoir créé, ajouté à la liste interne.
  Homework creerDevoir({
    required String titre,
    required String description,
    required String matiere,
    required List<String> classes,
    required DateTime dateLimit,
    required List<HomeworkQuestion> questions,
    int dureeMinutes = 30,
  }) {
    final homework = Homework(
      id: 'hw_${DateTime.now().millisecondsSinceEpoch}',
      titre: titre,
      description: description,
      matiere: matiere,
      classes: classes,
      enseignantId: currentEnseignantId,
      enseignantNom: 'M. Kossi Mensah',
      dateCreation: DateTime.now(),
      dateLimit: dateLimit,
      questions: questions,
      lifecycle: HomeworkLifecycle.publie,
      dureeMinutes: dureeMinutes,
    );
    _homeworks.add(homework);
    notifyListeners();
    return homework;
  }

  /// Export CSV simple du rapport classe pour un devoir.
  /// Format : prenom,nom,classe,score,note20,temps_secondes,en_retard
  String exportCsv(String homeworkId) {
    final homework = _homeworks.firstWhere((h) => h.id == homeworkId);
    final subs = getSubmissionsForHomework(homeworkId);
    final rendus = subs.where((s) => s.termine).toList();

    final buf = StringBuffer();
    buf.writeln('prenom,nom,classe,score,note_20,temps_secondes,en_retard');
    for (final s in rendus) {
      final note = (s.score / homework.pointsTotal) * 20;
      buf.writeln(
        '${s.elevePrenom},${s.eleveNom},${s.classe},'
        '${s.score},${note.toStringAsFixed(2)},'
        '${s.tempsPasseSecondes},${s.isEnRetard(homework) ? 1 : 0}',
      );
    }
    return buf.toString();
  }

  // ─── MOCK DATA ─────────────────────────────────────────────────

  void _initMockData() {
    // ─── 5 devoirs ──────────────────────────────────────────────
    // Dates relatives à "maintenant" pour que les statuts soient
    // cohérents à l'exécution (deadline dans le passé ou le futur).
    final now = DateTime.now();

    // 1. Maths (rendu par l'élève courant — démo résultats)
    _homeworks.add(Homework(
      id: 'hw_math_01',
      titre: 'Devoir BEPC — Calcul littéral et équations',
      description: 'Révisions sur les équations du premier degré et le '
          'calcul littéral. 5 questions, 30 min conseillées. Lisez bien '
          'les énoncés avant de répondre.',
      matiere: 'Mathématiques',
      classes: const ['3e A', '3e B'],
      enseignantId: currentEnseignantId,
      enseignantNom: 'M. Kossi Mensah',
      dateCreation: now.subtract(const Duration(days: 7)),
      dateLimit: now.subtract(const Duration(days: 1)),
      dureeMinutes: 30,
      questions: const [
        HomeworkQuestion(
          id: 'hw_math_01_q1',
          enonce: 'Résoudre l\'équation : 2x + 5 = 17. Quelle est la valeur de x ?',
          choix: ['x = 4', 'x = 6', 'x = 8', 'x = 11'],
          bonIndex: 1,
          points: 2,
          explication: '2x = 17 - 5 = 12, donc x = 12 / 2 = 6.',
          competenceId: 'TG-MATHS-EQ1D',
        ),
        HomeworkQuestion(
          id: 'hw_math_01_q2',
          enonce: 'Développer puis réduire : (x + 3)(x - 2).',
          choix: ['x² + x - 6', 'x² - x - 6', 'x² + 5x - 6', 'x² + x + 6'],
          bonIndex: 0,
          points: 2,
          explication: 'x*x - 2x + 3x - 6 = x² + x - 6.',
          competenceId: 'TG-MATHS-CALC-LITT',
        ),
        HomeworkQuestion(
          id: 'hw_math_01_q3',
          enonce: 'Factoriser : 9x² - 25.',
          choix: ['(3x - 5)²', '(3x + 5)(3x - 5)', '(9x - 5)(x + 5)', '(3x + 5)²'],
          bonIndex: 1,
          points: 2,
          explication: 'a² - b² = (a-b)(a+b) avec a=3x et b=5.',
          competenceId: 'TG-MATHS-CALC-LITT',
        ),
        HomeworkQuestion(
          id: 'hw_math_01_q4',
          enonce: 'Si x = 4, calculer la valeur de 3x² - 2x + 1.',
          choix: ['33', '41', '49', '57'],
          bonIndex: 1,
          points: 2,
          explication: '3*16 - 2*4 + 1 = 48 - 8 + 1 = 41.',
          competenceId: 'TG-MATHS-CALC',
        ),
        HomeworkQuestion(
          id: 'hw_math_01_q5',
          enonce: 'Résoudre le système : x + y = 10 ET x - y = 4. Que vaut x ?',
          choix: ['x = 3', 'x = 5', 'x = 7', 'x = 14'],
          bonIndex: 2,
          points: 2,
          explication: '2x = 14 donc x = 7, puis y = 10 - 7 = 3.',
          competenceId: 'TG-MATHS-SYS',
        ),
      ],
    ));

    // 2. Français (en cours — l'élève a commencé mais pas fini)
    _homeworks.add(Homework(
      id: 'hw_fr_01',
      titre: 'Devoir BEPC — Figures de style et compréhension',
      description: 'Identifier les figures de style dans des extraits '
          'littéraires togolais. 4 questions, 25 min conseillées.',
      matiere: 'Français',
      classes: const ['3e A', '3e B'],
      enseignantId: currentEnseignantId,
      enseignantNom: 'Mme Afi Adjovi',
      dateCreation: now.subtract(const Duration(days: 5)),
      dateLimit: now.add(const Duration(days: 3)),
      dureeMinutes: 25,
      questions: const [
        HomeworkQuestion(
          id: 'hw_fr_01_q1',
          enonce: '"Le soleil sourit aux moissonneurs." Quelle figure de style ?',
          choix: ['Métaphore', 'Personnification', 'Comparaison', 'Hyperbole'],
          bonIndex: 1,
          points: 2,
          explication: 'On prête une action humaine (sourire) au soleil.',
        ),
        HomeworkQuestion(
          id: 'hw_fr_01_q2',
          enonce: '"Il est fort comme un lion." Quelle figure de style ?',
          choix: ['Métaphore', 'Personnification', 'Comparaison', 'Antithèse'],
          bonIndex: 2,
          points: 2,
          explication: 'Présence du tool "comme" : c\'est une comparaison.',
        ),
        HomeworkQuestion(
          id: 'hw_fr_01_q3',
          enonce: 'Identifier l\'antithèse dans : "Il vit dans la richesse et la misère."',
          choix: ['richesse / misère', 'vit / misère', 'richesse / dans', 'aucune'],
          bonIndex: 0,
          points: 2,
          explication: 'Deux mots de sens contraires rapprochés = antithèse.',
        ),
        HomeworkQuestion(
          id: 'hw_fr_01_q4',
          enonce: '"C\'est un océan de larmes." Quelle figure de style ?',
          choix: ['Hyperbole', 'Métonymie', 'Périphrase', 'Litote'],
          bonIndex: 0,
          points: 2,
          explication: 'Exagération volontaire pour marquer l\'émotion.',
        ),
      ],
    ));

    // 3. Sciences Physiques (à faire — pas encore commencé)
    _homeworks.add(Homework(
      id: 'hw_sci_01',
      titre: 'Devoir BEPC — Électricité et circuits',
      description: 'Loi d\'Ohm, montages en série et en parallèle. '
          '5 questions, 35 min conseillées.',
      matiere: 'Sciences Physiques',
      classes: const ['3e A', '3e B'],
      enseignantId: currentEnseignantId,
      enseignantNom: 'M. Edem Dosseh',
      dateCreation: now.subtract(const Duration(days: 2)),
      dateLimit: now.add(const Duration(days: 7)),
      dureeMinutes: 35,
      questions: const [
        HomeworkQuestion(
          id: 'hw_sci_01_q1',
          enonce: 'Énoncer la loi d\'Ohm aux bornes d\'un conducteur ohmique.',
          choix: ['U = R * I', 'U = R / I', 'U = R + I', 'U = I / R'],
          bonIndex: 0,
          points: 2,
          explication: 'La tension U (en V) = résistance R (en Ω) × intensité I (en A).',
        ),
        HomeworkQuestion(
          id: 'hw_sci_01_q2',
          enonce: 'Si U = 12 V et R = 4 Ω, calculer l\'intensité I.',
          choix: ['I = 3 A', 'I = 48 A', 'I = 8 A', 'I = 16 A'],
          bonIndex: 0,
          points: 2,
          explication: 'I = U / R = 12 / 4 = 3 A.',
        ),
        HomeworkQuestion(
          id: 'hw_sci_01_q3',
          enonce: 'Dans un montage en série, l\'intensité est :',
          choix: [
            'La même partout',
            'Plus grande près du générateur',
            'Différente en chaque point',
            'Nulle',
          ],
          bonIndex: 0,
          points: 2,
          explication: 'En série, l\'intensité est identique en tous points du circuit.',
        ),
        HomeworkQuestion(
          id: 'hw_sci_01_q4',
          enonce: 'Deux résistances R1=6 Ω et R2=3 Ω en parallèle. Résistance équivalente ?',
          choix: ['2 Ω', '9 Ω', '3 Ω', '18 Ω'],
          bonIndex: 0,
          points: 2,
          explication: '1/Req = 1/6 + 1/3 = 1/6 + 2/6 = 3/6 = 1/2, donc Req = 2 Ω.',
        ),
        HomeworkQuestion(
          id: 'hw_sci_01_q5',
          enonce: 'Quel appareil mesure la tension électrique ?',
          choix: ['Ampèremètre', 'Voltmètre', 'Ohmmètre', 'Wattmètre'],
          bonIndex: 1,
          points: 1,
          explication: 'Le voltmètre se branche en dérivation aux bornes du dipôle.',
        ),
      ],
    ));

    // 4. SVT (manqué — deadline passée, élève n'a pas rendu)
    _homeworks.add(Homework(
      id: 'hw_svt_01',
      titre: 'Devoir SVT — Digestion et absorption des nutriments',
      description: 'Compréhension de la digestion et du trajet des aliments. '
          '4 questions, 20 min conseillées.',
      matiere: 'SVT',
      classes: const ['3e A'],
      enseignantId: currentEnseignantId,
      enseignantNom: 'Mme Ama Komi',
      dateCreation: now.subtract(const Duration(days: 14)),
      dateLimit: now.subtract(const Duration(days: 3)),
      dureeMinutes: 20,
      questions: const [
        HomeworkQuestion(
          id: 'hw_svt_01_q1',
          enonce: 'Où commence la digestion chimique des glucides ?',
          choix: ['Bouche', 'Estomac', 'Intestin grêle', 'Gros intestin'],
          bonIndex: 0,
          points: 2,
          explication: 'La salive contient de l\'amylase qui démarre la digestion des sucres.',
        ),
        HomeworkQuestion(
          id: 'hw_svt_01_q2',
          enonce: 'Quel organe absorbe la majorité des nutriments ?',
          choix: ['Estomac', 'Intestin grêle', 'Côlon', 'Foie'],
          bonIndex: 1,
          points: 2,
          explication: 'L\'intestin grêle a une grande surface d\'absorption grâce aux villosités.',
        ),
        HomeworkQuestion(
          id: 'hw_svt_01_q3',
          enonce: 'L\'acide chlorhydrique est sécrété par :',
          choix: ['Le pancréas', 'L\'estomac', 'Le foie', 'L\'intestin'],
          bonIndex: 1,
          points: 2,
          explication: 'Les cellules de la paroi de l\'estomac sécrètent HCl.',
        ),
        HomeworkQuestion(
          id: 'hw_svt_01_q4',
          enonce: 'Les nutriments passent ensuite dans le sang par :',
          choix: ['Les villosités intestinales', 'Le pylore', 'L\'œsophage', 'La vésicule biliaire'],
          bonIndex: 0,
          points: 2,
          explication: 'Les villosités sont riches en capillaires sanguins pour absorber les nutriments.',
        ),
      ],
    ));

    // 5. Histoire-Géo (rendu — autre démo de résultats)
    _homeworks.add(Homework(
      id: 'hw_hist_01',
      titre: 'Devoir BEPC — Indépendance du Togo et décolonisation',
      description: 'Compréhension du processus d\'indépendance togolaise (1960) '
          'et de la décolonisation africaine. 5 questions, 30 min conseillées.',
      matiere: 'Histoire-Géographie',
      classes: const ['3e A', '3e B'],
      enseignantId: currentEnseignantId,
      enseignantNom: 'M. Komlan Mensah',
      dateCreation: now.subtract(const Duration(days: 10)),
      dateLimit: now.subtract(const Duration(days: 2)),
      dureeMinutes: 30,
      questions: const [
        HomeworkQuestion(
          id: 'hw_hist_01_q1',
          enonce: 'En quelle année le Togo a-t-il obtenu son indépendance ?',
          choix: ['1956', '1958', '1960', '1962'],
          bonIndex: 2,
          points: 2,
          explication: 'Le Togo est devenu indépendant le 27 avril 1960.',
        ),
        HomeworkQuestion(
          id: 'hw_hist_01_q2',
          enonce: 'Qui était le premier président du Togo indépendant ?',
          choix: [
            'Gnassingbé Eyadéma',
            'Sylvanus Olympio',
            'Nicolas Grunitzky',
            'Édouard Kodjo',
          ],
          bonIndex: 1,
          points: 2,
          explication: 'Sylvanus Olympio a dirigé le pays de 1960 à son assassinat en 1963.',
        ),
        HomeworkQuestion(
          id: 'hw_hist_01_q3',
          enonce: 'Le Togo était sous mandat de quel pays avant l\'indépendance ?',
          choix: ['Le Royaume-Uni', 'La France', 'L\'Allemagne', 'La Belgique'],
          bonIndex: 1,
          points: 2,
          explication: 'Après la 1re guerre mondiale, le Togo est placé sous mandat français (et britannique pour la partie ouest).',
        ),
        HomeworkQuestion(
          id: 'hw_hist_01_q4',
          enonce: 'Quelle est la capitale économique de la Communauté Économique des États de l\'Afrique de l\'Ouest (CEDEAO) ?',
          choix: ['Abuja', 'Accra', 'Lomé', 'Dakar'],
          bonIndex: 0,
          points: 1,
          explication: 'Abuja (Nigeria) héberge le siège de la CEDEAO. Lomé héberge le siège de l\'UEMOA bancataire.',
        ),
        HomeworkQuestion(
          id: 'hw_hist_01_q5',
          enonce: 'L\'année 1960 est souvent appelée :',
          choix: [
            'Année de la libération',
            'Année de l\'Afrique',
            'Année des indépendances africaines',
            'Réponses 2 et 3',
          ],
          bonIndex: 3,
          points: 2,
          explication: '17 pays africains ont obtenu leur indépendance en 1960.',
        ),
      ],
    ));

    // ─── 30 élèves répartis sur 3 classes ─────────────────────
    _eleves.addAll([
      // 3e A (12 élèves, dont l'élève courant)
      const MockEleve(id: currentEleveId, prenom: 'Moi', nom: 'Élève', classe: '3e A'),
      const MockEleve(id: 'el_001', prenom: 'Kossi', nom: 'Mensah', classe: '3e A'),
      const MockEleve(id: 'el_002', prenom: 'Aya', nom: 'Agbodjan', classe: '3e A'),
      const MockEleve(id: 'el_003', prenom: 'Komlan', nom: 'Kpedetor', classe: '3e A'),
      const MockEleve(id: 'el_004', prenom: 'Adjo', nom: 'Aziabou', classe: '3e A'),
      const MockEleve(id: 'el_005', prenom: 'Yao', nom: 'Ameganvi', classe: '3e A'),
      const MockEleve(id: 'el_006', prenom: 'Akossiwa', nom: 'Lawson', classe: '3e A'),
      const MockEleve(id: 'el_007', prenom: 'Kofi', nom: 'Agbo', classe: '3e A'),
      const MockEleve(id: 'el_008', prenom: 'Afi', nom: 'Adjovi', classe: '3e A'),
      const MockEleve(id: 'el_009', prenom: 'Mawunyo', nom: 'd\'Almeida', classe: '3e A'),
      const MockEleve(id: 'el_010', prenom: 'Edem', nom: 'Dosseh', classe: '3e A'),
      const MockEleve(id: 'el_011', prenom: 'Sena', nom: 'Akolly', classe: '3e A'),

      // 3e B (10 élèves)
      const MockEleve(id: 'el_012', prenom: 'Delali', nom: 'Sewa', classe: '3e B'),
      const MockEleve(id: 'el_013', prenom: 'Kossiwa', nom: 'Tetey', classe: '3e B'),
      const MockEleve(id: 'el_014', prenom: 'Mawuko', nom: 'Ayeva', classe: '3e B'),
      const MockEleve(id: 'el_015', prenom: 'Ama', nom: 'Komi', classe: '3e B'),
      const MockEleve(id: 'el_016', prenom: 'Aya', nom: 'Koffi', classe: '3e B'),
      const MockEleve(id: 'el_017', prenom: 'Kossi', nom: 'Agbodjan', classe: '3e B'),
      const MockEleve(id: 'el_018', prenom: 'Komlan', nom: 'Mensah', classe: '3e B'),
      const MockEleve(id: 'el_019', prenom: 'Adjo', nom: 'Lawson', classe: '3e B'),
      const MockEleve(id: 'el_020', prenom: 'Yao', nom: 'Kpedetor', classe: '3e B'),
      const MockEleve(id: 'el_021', prenom: 'Akossiwa', nom: 'Aziabou', classe: '3e B'),

      // Terminale C (8 élèves)
      const MockEleve(id: 'el_022', prenom: 'Kossi', nom: 'Agbodjan', classe: 'Terminale C'),
      const MockEleve(id: 'el_023', prenom: 'Komlan', nom: 'Mensah', classe: 'Terminale C'),
      const MockEleve(id: 'el_024', prenom: 'Adjo', nom: 'Lawson', classe: 'Terminale C'),
      const MockEleve(id: 'el_025', prenom: 'Yao', nom: 'Kpedetor', classe: 'Terminale C'),
      const MockEleve(id: 'el_026', prenom: 'Akossiwa', nom: 'Aziabou', classe: 'Terminale C'),
      const MockEleve(id: 'el_027', prenom: 'Kofi', nom: 'Ameganvi', classe: 'Terminale C'),
      const MockEleve(id: 'el_028', prenom: 'Afi', nom: 'd\'Almeida', classe: 'Terminale C'),
      const MockEleve(id: 'el_029', prenom: 'Mawunyo', nom: 'Dosseh', classe: 'Terminale C'),
    ]);

    // ─── Soumissions pré-remplies (mock) ──────────────────────
    // Pour chaque devoir, on simule que les élèves ont rendu (avec
    // scores variés) sauf quelques uns qui sont "en cours" ou "manqués".
    _generateMockSubmissions();
  }

  /// Génère les soumissions mock pour les 5 devoirs et 30 élèves.
  /// L'élève courant a un pattern spécifique :
  ///   - hw_math_01 : rendu (résultats disponibles)
  ///   - hw_fr_01 : en cours (l'élève a commencé mais pas fini)
  ///   - hw_sci_01 : à faire (pas commencé)
  ///   - hw_svt_01 : manqué (deadline passée, pas rendu)
  ///   - hw_hist_01 : rendu (autre démo résultats)
  void _generateMockSubmissions() {
    final now = DateTime.now();
    final rng = _DeterministicRng(seed: 42); // déterministe pour reproductibilité

    for (final hw in _homeworks) {
      // Élèves ciblés par ce devoir
      final elevesCibles =
          _eleves.where((e) => hw.classes.contains(e.classe)).toList();

      for (final eleve in elevesCibles) {
        // Cas spéciaux de l'élève courant
        if (eleve.id == currentEleveId) {
          if (hw.id == 'hw_math_01') {
            _submissions.add(_buildMockSubmission(
              homework: hw,
              eleve: eleve,
              termine: true,
              correctCount: 4, // 4/5 bonnes
              tempsSecondes: 18 * 60, // 18 min
              dateSoumission: now.subtract(const Duration(days: 2)),
            ));
          } else if (hw.id == 'hw_fr_01') {
            _submissions.add(_buildMockSubmission(
              homework: hw,
              eleve: eleve,
              termine: false,
              enCours: true,
              correctCount: 2, // 2/4 commencées, 2 correctes
              tempsSecondes: 7 * 60, // 7 min passées
              dateSoumission: null,
            ));
          } else if (hw.id == 'hw_hist_01') {
            _submissions.add(_buildMockSubmission(
              homework: hw,
              eleve: eleve,
              termine: true,
              correctCount: 3, // 3/5 bonnes
              tempsSecondes: 22 * 60, // 22 min
              dateSoumission: now.subtract(const Duration(days: 3)),
            ));
          }
          // hw_sci_01 : à faire (pas de soumission)
          // hw_svt_01 : manqué (pas de soumission)
          continue;
        }

        // Autres élèves : 70% rendus, 15% en cours, 15% manqués
        final roll = rng.nextDouble();
        if (roll < 0.70) {
          // Rendu avec score variable (40% à 100% de bonnes réponses)
          final pct = 0.40 + rng.nextDouble() * 0.55; // 0.40 à 0.95
          final correctCount = (hw.nbQuestions * pct).round();
          final temps = (hw.dureeMinutes * 0.4 +
                  rng.nextDouble() * hw.dureeMinutes * 0.6) *
              60; // 40% à 100% de la durée conseillée
          // Date de soumission : aléatoire avant la deadline
          final dateSoumission = hw.isDeadlineDepassee
              ? hw.dateLimit.subtract(Duration(
                  minutes: rng.nextInt(60 * 24 * 3))) // 0-3j avant deadline
              : now.subtract(Duration(
                  minutes: rng.nextInt(60 * 24))); // 0-24h avant maintenant

          // 10% des rendus sont en retard (après deadline)
          final enRetard = rng.nextDouble() < 0.10;
          final dateS = enRetard && hw.isDeadlineDepassee
              ? hw.dateLimit.add(Duration(hours: rng.nextInt(48)))
              : dateSoumission;

          _submissions.add(_buildMockSubmission(
            homework: hw,
            eleve: eleve,
            termine: true,
            correctCount: correctCount,
            tempsSecondes: temps.round(),
            dateSoumission: dateS,
          ));
        } else if (roll < 0.85) {
          // En cours (commencé mais pas fini)
          _submissions.add(_buildMockSubmission(
            homework: hw,
            eleve: eleve,
            termine: false,
            enCours: true,
            correctCount: (hw.nbQuestions * 0.3).round(),
            tempsSecondes: (hw.dureeMinutes * 0.3 * 60).round(),
            dateSoumission: null,
          ));
        }
        // else : manqué (pas de soumission)
      }
    }
  }

  /// Construit une soumission mock complète (avec réponses).
  HomeworkSubmission _buildMockSubmission({
    required Homework homework,
    required MockEleve eleve,
    required bool termine,
    bool enCours = false,
    required int correctCount,
    required int tempsSecondes,
    required DateTime? dateSoumission,
  }) {
    final reponses = <String, HomeworkAnswer>{};
    int score = 0;

    // Distribue les bonnes réponses sur les premières questions
    final correctIds = <String>{};
    for (var i = 0; i < correctCount && i < homework.questions.length; i++) {
      correctIds.add(homework.questions[i].id);
    }

    for (final q in homework.questions) {
      final isCorrect = correctIds.contains(q.id);
      final points = isCorrect ? q.points : 0;
      score += points;

      int? qcmIndex;
      String? texteOuvert;
      if (q.isQcm) {
        qcmIndex = isCorrect ? q.bonIndex! : ((q.bonIndex! + 1) % q.choix!.length);
      } else if (q.bonneReponseOuverte != null) {
        texteOuvert = isCorrect ? q.bonneReponseOuverte : 'réponse incorrecte';
      }

      reponses[q.id] = HomeworkAnswer(
        questionId: q.id,
        qcmIndex: qcmIndex,
        texteOuvert: texteOuvert,
        autoEvalueCorrect: isCorrect,
        isCorrect: isCorrect,
        pointsObtenus: points,
      );
    }

    return HomeworkSubmission(
      id: 'sub_${homework.id}_${eleve.id}',
      homeworkId: homework.id,
      eleveId: eleve.id,
      eleveNom: eleve.nom,
      elevePrenom: eleve.prenom,
      classe: eleve.classe,
      dateDebut: dateSoumission?.subtract(Duration(seconds: tempsSecondes)) ??
          DateTime.now().subtract(Duration(seconds: tempsSecondes)),
      dateSoumission: dateSoumission,
      enCours: enCours,
      termine: termine,
      reponses: reponses,
      score: score,
      tempsPasseSecondes: tempsSecondes,
    );
  }
}

/// Générateur de nombres pseudo-aléatoires déterministe (mock reproductible).
/// Évite l'usage de `dart:math` Random qui produirait des résultats
/// différents à chaque exécution (et compliquerait les démos).
class _DeterministicRng {
  int _state;
  _DeterministicRng({required int seed}) : _state = seed;

  double nextDouble() {
    // LCG simple (constantes Numerical Recipes)
    _state = (1664525 * _state + 1013904223) & 0xFFFFFFFF;
    return (_state & 0x7FFFFFFF) / 0x7FFFFFFF;
  }

  int nextInt(int max) {
    return (nextDouble() * max).floor();
  }
}
