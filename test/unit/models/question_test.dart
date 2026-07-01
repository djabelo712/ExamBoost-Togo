// test/unit/models/question_test.dart
// Tests for the Question model (HiveType 0).

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/question.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Question model', () {
    // ─── Construction ─────────────────────────────────────────────
    group('Construction', () {
      test('Tous les champs sont correctement assignés', () {
        final q = createTestQuestion(
          id: 'TG-BEPC-MATHS-2022-Q01',
          enonce: 'Énoncé test',
          reponse: 'Réponse test',
          matiere: 'Mathématiques',
          chapitre: 'Chapitre test',
          competenceId: 'COMP-001',
          examen: 'BEPC',
          annee: 2022,
          type: QuestionType.calcul,
          points: 4,
          irtB: -0.5,
        );
        expect(q.id, 'TG-BEPC-MATHS-2022-Q01');
        expect(q.enonce, 'Énoncé test');
        expect(q.reponse, 'Réponse test');
        expect(q.matiere, 'Mathématiques');
        expect(q.chapitre, 'Chapitre test');
        expect(q.competenceId, 'COMP-001');
        expect(q.examen, 'BEPC');
        expect(q.annee, 2022);
        expect(q.type, QuestionType.calcul);
        expect(q.points, 4);
        expect(q.irtB, -0.5);
      });

      test('irtCalibrated defaults to false', () {
        final q = createTestQuestion();
        expect(q.irtCalibrated, isFalse);
      });

      test('Série et choix sont nullables', () {
        final q = createTestQuestion();
        expect(q.serie, isNull);
        expect(q.choix, isNull);
      });

      test('QCM peut avoir des choix', () {
        final q = createTestQuestion(
          type: QuestionType.qcm,
          choix: const ['A', 'B', 'C', 'D'],
        );
        expect(q.choix, isNotNull);
        expect(q.choix!.length, 4);
      });
    });

    // ─── Difficulté ───────────────────────────────────────────────
    group('Difficulté (basée sur irtB)', () {
      test('irtB < -0.5 → facile', () {
        final q = createTestQuestion(irtB: -1.0);
        expect(q.difficulte, DifficulteNiveau.facile);
      });

      test('irtB = -0.5 → moyen (borne exclue)', () {
        final q = createTestQuestion(irtB: -0.5);
        expect(q.difficulte, DifficulteNiveau.moyen);
      });

      test('irtB = 0 → moyen', () {
        final q = createTestQuestion(irtB: 0.0);
        expect(q.difficulte, DifficulteNiveau.moyen);
      });

      test('irtB = 0.79 → moyen', () {
        final q = createTestQuestion(irtB: 0.79);
        expect(q.difficulte, DifficulteNiveau.moyen);
      });

      test('irtB = 0.8 → difficile (borne incluse)', () {
        final q = createTestQuestion(irtB: 0.8);
        expect(q.difficulte, DifficulteNiveau.difficile);
      });

      test('irtB = 2.0 → difficile', () {
        final q = createTestQuestion(irtB: 2.0);
        expect(q.difficulte, DifficulteNiveau.difficile);
      });

      test('irtB null → moyen (défaut 0.0)', () {
        final q = createTestQuestion(irtB: null);
        expect(q.difficulte, DifficulteNiveau.moyen);
      });
    });

    // ─── JSON serialization ───────────────────────────────────────
    group('JSON serialization', () {
      test('toJson puis fromJson round-trip préserve les champs', () {
        final original = createTestQuestion(
          id: 'X-1',
          enonce: 'Énoncé',
          reponse: 'Réponse',
          explication: 'Explication',
          matiere: 'Physique',
          chapitre: 'Chapitre',
          competenceId: 'COMP',
          examen: 'BAC1',
          serie: 'C',
          annee: 2023,
          type: QuestionType.qcm,
          choix: const ['A', 'B'],
          points: 5,
          irtA: 1.2,
          irtB: 0.3,
          irtC: 0.2,
          irtCalibrated: true,
        );
        final json = original.toJson();
        final restored = Question.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.enonce, original.enonce);
        expect(restored.reponse, original.reponse);
        expect(restored.explication, original.explication);
        expect(restored.matiere, original.matiere);
        expect(restored.chapitre, original.chapitre);
        expect(restored.competenceId, original.competenceId);
        expect(restored.examen, original.examen);
        expect(restored.serie, original.serie);
        expect(restored.annee, original.annee);
        expect(restored.type, original.type);
        expect(restored.choix, original.choix);
        expect(restored.points, original.points);
        expect(restored.irtA, original.irtA);
        expect(restored.irtB, original.irtB);
        expect(restored.irtC, original.irtC);
        expect(restored.irtCalibrated, original.irtCalibrated);
      });

      test('fromJson gère les valeurs null', () {
        final json = {
          'id': 'X-2',
          'enonce': 'É',
          'reponse': 'R',
          'explication': null,
          'matiere': 'M',
          'chapitre': 'C',
          'examen': 'BEPC',
          'type': 'ouvert',
          'choix': null,
          'points': null,
        };
        final q = Question.fromJson(json);
        expect(q.explication, isNull);
        expect(q.choix, isNull);
        expect(q.points, isNull);
        expect(q.irtCalibrated, isFalse);
      });

      test('fromJson avec competence_id manquant → chaîne vide', () {
        final json = {
          'id': 'X-3',
          'enonce': 'É',
          'reponse': 'R',
          'matiere': 'M',
          'chapitre': 'C',
          'examen': 'BEPC',
          'type': 'ouvert',
        };
        final q = Question.fromJson(json);
        expect(q.competenceId, '');
      });

      test('fromJson avec examen manquant → "BEPC" par défaut', () {
        final json = {
          'id': 'X-4',
          'enonce': 'É',
          'reponse': 'R',
          'matiere': 'M',
          'chapitre': 'C',
          'type': 'ouvert',
        };
        final q = Question.fromJson(json);
        expect(q.examen, 'BEPC');
      });

      test('toJson structure IRT correcte', () {
        final q = createTestQuestion(
          irtA: 1.0,
          irtB: 0.5,
          irtC: 0.2,
          irtCalibrated: true,
        );
        final json = q.toJson();
        expect(json['irt'], isA<Map>());
        expect(json['irt']['a'], 1.0);
        expect(json['irt']['b'], 0.5);
        expect(json['irt']['c'], 0.2);
        expect(json['irt']['calibre'], isTrue);
      });
    });

    // ─── QuestionType enum ────────────────────────────────────────
    group('QuestionType enum', () {
      test('5 types définis', () {
        expect(QuestionType.values.length, 5);
      });

      test('Types ordonnés: ouvert, qcm, redaction, calcul, vraiFaux', () {
        expect(QuestionType.values, [
          QuestionType.ouvert,
          QuestionType.qcm,
          QuestionType.redaction,
          QuestionType.calcul,
          QuestionType.vraiFaux,
        ]);
      });

      test('byName résout correctement les chaînes', () {
        expect(QuestionType.values.byName('ouvert'), QuestionType.ouvert);
        expect(QuestionType.values.byName('qcm'), QuestionType.qcm);
        expect(QuestionType.values.byName('calcul'), QuestionType.calcul);
        expect(QuestionType.values.byName('vraiFaux'), QuestionType.vraiFaux);
      });
    });

    // ─── DifficulteNiveau enum ────────────────────────────────────
    group('DifficulteNiveau enum', () {
      test('3 niveaux définis', () {
        expect(DifficulteNiveau.values.length, 3);
      });
    });
  });
}
