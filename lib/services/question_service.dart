// lib/services/question_service.dart
// Service de chargement et filtrage des questions depuis assets/data/questions.json

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../utils/app_logger.dart';

class QuestionService {
  List<Question> _allQuestions = [];
  bool _loaded = false;

  Future<void> loadQuestions() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/questions.json');
      final List<dynamic> jsonList = json.decode(jsonStr);
      _allQuestions = jsonList.map((j) => Question.fromJson(j)).toList();
      _loaded = true;
      AppLogger.info('${_allQuestions.length} questions chargées depuis assets');
    } catch (e) {
      AppLogger.error('Erreur chargement questions: $e');
      _allQuestions = _getSampleQuestions(); // fallback données d'exemple
      _loaded = true;
    }
  }

  // ─── Filtres ──────────────────────────────────────────────────

  List<Question> getByMatiere(String matiere) =>
      _allQuestions.where((q) => q.matiere == matiere).toList();

  List<Question> getByExamen(String examen, {String? serie}) {
    return _allQuestions.where((q) {
      final matchExamen = q.examen == examen;
      final matchSerie = serie == null || q.serie == serie;
      return matchExamen && matchSerie;
    }).toList();
  }

  List<Question> getByCompetence(String competenceId) =>
      _allQuestions.where((q) => q.competenceId == competenceId).toList();

  List<Question> getByIds(List<String> ids) =>
      _allQuestions.where((q) => ids.contains(q.id)).toList();

  Question? getById(String id) {
    try {
      return _allQuestions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Questions disponibles pour révision adaptative
  /// Filtre par matière + exclut celles déjà très bien maîtrisées
  List<Question> getForAdaptiveRevision({
    required String matiere,
    required List<String> excludeIds,
    int limit = 50,
  }) {
    return _allQuestions
        .where((q) => q.matiere == matiere && !excludeIds.contains(q.id))
        .take(limit)
        .toList();
  }

  /// Générer un examen blanc complet
  List<Question> generateSimulation({
    required String examen,
    required String? serie,
    int nombreQuestions = 20,
  }) {
    final pool = getByExamen(examen, serie: serie);
    pool.shuffle();
    return pool.take(nombreQuestions).toList();
  }

  /// Liste des matières disponibles
  List<String> get matieres =>
      _allQuestions.map((q) => q.matiere).toSet().toList()..sort();

  int get totalQuestions => _allQuestions.length;

  // ─── Données de démo (fallback si JSON absent) ─────────────────
  List<Question> _getSampleQuestions() {
    return [
      Question(
        id: 'TG-BEPC-MATHS-2022-Q01',
        enonce: 'Résoudre l\'équation : 3x + 7 = 22',
        reponse: 'x = 5',
        explication: 'On soustrait 7 des deux membres : 3x = 15, puis on divise par 3 : x = 5.',
        matiere: 'Mathématiques',
        chapitre: 'Équations du premier degré',
        competenceId: 'TG-MATHS-EQ1D-001',
        examen: 'BEPC',
        annee: 2022,
        type: QuestionType.calcul,
        points: 4,
        irtB: -0.5,
      ),
      Question(
        id: 'TG-BEPC-MATHS-2021-Q02',
        enonce: 'Calculer l\'aire d\'un triangle rectangle de côtés 6 cm et 8 cm.',
        reponse: '24 cm²',
        explication: 'Aire = (base × hauteur) / 2 = (6 × 8) / 2 = 24 cm².',
        matiere: 'Mathématiques',
        chapitre: 'Géométrie plane — Triangles',
        competenceId: 'TG-MATHS-GEO-001',
        examen: 'BEPC',
        annee: 2021,
        type: QuestionType.calcul,
        points: 3,
        irtB: -0.3,
      ),
      Question(
        id: 'TG-BEPC-MATHS-2020-Q03',
        enonce: 'Dans un repère orthonormé, soit A(1 ; 2) et B(5 ; 6). Calculer la longueur AB.',
        reponse: 'AB = 4√2 ≈ 5,66 cm',
        explication: 'AB = √[(5-1)² + (6-2)²] = √[16 + 16] = √32 = 4√2.',
        matiere: 'Mathématiques',
        chapitre: 'Géométrie analytique',
        competenceId: 'TG-MATHS-GEO-002',
        examen: 'BEPC',
        annee: 2020,
        type: QuestionType.calcul,
        points: 4,
        irtB: 0.2,
      ),
      Question(
        id: 'TG-BEPC-FR-2022-Q01',
        enonce: 'Identifiez la figure de style dans la phrase : "Ses yeux sont deux étoiles brillantes."',
        reponse: 'Comparaison (ou métaphore selon le contexte)',
        explication: 'La comparaison rapproche deux éléments à l\'aide d\'un comparatif. Si on dit "ses yeux sont des étoiles" sans "comme", c\'est une métaphore.',
        matiere: 'Français',
        chapitre: 'Figures de style',
        competenceId: 'TG-FR-STYLE-001',
        examen: 'BEPC',
        annee: 2022,
        type: QuestionType.ouvert,
        points: 3,
        irtB: 0.1,
      ),
      Question(
        id: 'TG-BEPC-FR-2021-Q02',
        enonce: 'Conjuguez le verbe "finir" au conditionnel présent, première personne du singulier.',
        reponse: 'Je finirais',
        explication: 'Le conditionnel présent de "finir" : je finirais, tu finirais, il finirait, nous finirions, vous finiriez, ils finiraient.',
        matiere: 'Français',
        chapitre: 'Conjugaison — Le conditionnel',
        competenceId: 'TG-FR-CONJ-001',
        examen: 'BEPC',
        annee: 2021,
        type: QuestionType.ouvert,
        points: 2,
        irtB: -0.4,
      ),
    ];
  }
}
