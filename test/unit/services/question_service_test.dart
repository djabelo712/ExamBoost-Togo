// test/unit/services/question_service_test.dart
// Tests for QuestionService (loadQuestions, filters, generateSimulation).
//
// These tests load the bundled assets/data/questions.json via rootBundle.
// They require TestWidgetsFlutterBinding to be initialized.

import 'package:flutter_test/flutter_test.dart';

import 'package:examboost_togo/models/question.dart';
import 'package:examboost_togo/services/question_service.dart';

void main() {
  // The rootBundle needs the test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuestionService service;

  setUp(() {
    service = QuestionService();
  });

  group('QuestionService - loadQuestions', () {
    test('charge au moins 60 questions depuis assets', () async {
      await service.loadQuestions();
      expect(service.totalQuestions, greaterThanOrEqualTo(60));
    });

    test('est idempotent (double load ne recharge pas)', () async {
      await service.loadQuestions();
      final count1 = service.totalQuestions;
      await service.loadQuestions(); // Should be no-op
      final count2 = service.totalQuestions;
      expect(count2, count1);
    });

    test('charge réellement des questions valides', () async {
      await service.loadQuestions();
      // Sample the first question.
      final all = service.getByExamen('BEPC');
      expect(all, isNotEmpty);
      final q = all.first;
      expect(q.id, isNotEmpty);
      expect(q.enonce, isNotEmpty);
      expect(q.reponse, isNotEmpty);
      expect(q.matiere, isNotEmpty);
    });
  });

  group('QuestionService - filters', () {
    setUp(() async {
      await service.loadQuestions();
    });

    test('getByMatiere filtre correctement', () {
      final maths = service.getByMatiere('Mathématiques');
      expect(maths, isNotEmpty);
      expect(maths.every((q) => q.matiere == 'Mathématiques'), isTrue);
    });

    test('getByMatiere avec matière inconnue retourne vide', () {
      final unknown = service.getByMatiere('Philosophie');
      expect(unknown, isEmpty);
    });

    test('getByExamen filtre par BEPC', () {
      final bepc = service.getByExamen('BEPC');
      expect(bepc, isNotEmpty);
      expect(bepc.every((q) => q.examen == 'BEPC'), isTrue);
    });

    test('getByExamen filtre par BAC1', () {
      final bac1 = service.getByExamen('BAC1');
      expect(bac1, isNotEmpty);
      expect(bac1.every((q) => q.examen == 'BAC1'), isTrue);
    });

    test('getByExamen avec série filtre correctement', () {
      final bacC = service.getByExamen('BAC1', serie: 'C');
      expect(bacC, isNotEmpty);
      expect(bacC.every((q) => q.examen == 'BAC1' && q.serie == 'C'), isTrue);
    });

    test('getByExamen avec série D filtre correctement', () {
      final bacD = service.getByExamen('BAC1', serie: 'D');
      expect(bacD, isNotEmpty);
      expect(bacD.every((q) => q.examen == 'BAC1' && q.serie == 'D'), isTrue);
    });

    test('getByExamen avec série null retourne toutes les questions de l\'examen', () {
      final allBac1 = service.getByExamen('BAC1');
      final bac1NoSerie = service.getByExamen('BAC1', serie: null);
      expect(bac1NoSerie.length, allBac1.length);
    });

    test('getByCompetence filtre par compétence', () {
      // Pick a competence from the loaded data.
      final anyQuestion = service.getByExamen('BEPC').first;
      final byComp = service.getByCompetence(anyQuestion.competenceId);
      expect(byComp, isNotEmpty);
      expect(byComp.every((q) => q.competenceId == anyQuestion.competenceId), isTrue);
    });

    test('getByIds retourne les questions correspondantes', () {
      final all = service.getByExamen('BEPC');
      final ids = all.take(3).map((q) => q.id).toList();
      final selected = service.getByIds(ids);
      expect(selected.length, 3);
      expect(selected.every((q) => ids.contains(q.id)), isTrue);
    });

    test('getById retourne la question si présente', () {
      final any = service.getByExamen('BEPC').first;
      final found = service.getById(any.id);
      expect(found, isNotNull);
      expect(found!.id, any.id);
    });

    test('getById retourne null si absente', () {
      expect(service.getById('does-not-exist'), isNull);
    });
  });

  group('QuestionService - matieres', () {
    setUp(() async {
      await service.loadQuestions();
    });

    test('matieres retourne liste unique sans doublons', () {
      final matieres = service.matieres;
      // No duplicates.
      expect(matieres.toSet().length, matieres.length);
    });

    test('matieres est triée alphabétiquement', () {
      final matieres = service.matieres;
      final sorted = List<String>.from(matieres)..sort();
      expect(matieres, sorted);
    });

    test('matieres contient au moins Mathématiques et Français', () {
      final matieres = service.matieres;
      expect(matieres, contains('Mathématiques'));
      expect(matieres, contains('Français'));
    });
  });

  group('QuestionService - getForAdaptiveRevision', () {
    setUp(() async {
      await service.loadQuestions();
    });

    test('Retourne des questions de la matière demandée', () {
      final result = service.getForAdaptiveRevision(
        matiere: 'Mathématiques',
        excludeIds: const [],
      );
      expect(result, isNotEmpty);
      expect(result.every((q) => q.matiere == 'Mathématiques'), isTrue);
    });

    test('Exclut les questions dont l\'id est dans excludeIds', () {
      final all = service.getByMatiere('Mathématiques');
      final excluded = all.take(2).map((q) => q.id).toList();
      final result = service.getForAdaptiveRevision(
        matiere: 'Mathématiques',
        excludeIds: excluded,
      );
      expect(result.every((q) => !excluded.contains(q.id)), isTrue);
    });

    test('Respecte la limite', () {
      final result = service.getForAdaptiveRevision(
        matiere: 'Mathématiques',
        excludeIds: const [],
        limit: 2,
      );
      expect(result.length, lessThanOrEqualTo(2));
    });
  });

  group('QuestionService - generateSimulation', () {
    setUp(() async {
      await service.loadQuestions();
    });

    test('Retourne au plus nombreQuestions questions', () {
      final sim = service.generateSimulation(
        examen: 'BEPC',
        serie: null,
        nombreQuestions: 5,
      );
      expect(sim.length, lessThanOrEqualTo(5));
    });

    test('Toutes les questions viennent de l\'examen demandé', () {
      final sim = service.generateSimulation(
        examen: 'BEPC',
        serie: null,
        nombreQuestions: 10,
      );
      expect(sim.every((q) => q.examen == 'BEPC'), isTrue);
    });

    test('Avec série, filtre correctement', () {
      final sim = service.generateSimulation(
        examen: 'BAC1',
        serie: 'C',
        nombreQuestions: 10,
      );
      expect(sim.every((q) => q.examen == 'BAC1' && q.serie == 'C'), isTrue);
    });

    test('Si nombreQuestions > pool, retourne tout le pool', () {
      final pool = service.getByExamen('BEPC');
      final sim = service.generateSimulation(
        examen: 'BEPC',
        serie: null,
        nombreQuestions: 1000,
      );
      expect(sim.length, pool.length);
    });
  });
}
