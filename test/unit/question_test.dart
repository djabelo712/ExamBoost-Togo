// test/unit/question_test.dart
// Tests for the Question model (HiveType 0).
//
// Verifies JSON (de)serialisation, the derived `difficulte` getter, and the
// QuestionType / DifficulteNiveau enums. The Question model is shared by
// every layer of the app (Hive box, JSON catalog, backend API) so a
// round-trip regression here would break everything downstream.

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/question.dart';

void main() {
  group('Question model', () {
    // ─── fromJson ─────────────────────────────────────────────────
    group('fromJson', () {
      test('parse correctement une question complete', () {
        final json = <String, dynamic>{
          'id': 'TG-BEPC-MATHS-2022-Q01',
          'enonce': 'Resoudre : 3x + 7 = 22',
          'reponse': 'x = 5',
          'explication': '...',
          'matiere': 'Mathematiques',
          'chapitre': 'Equations',
          'competence_id': 'TG-MATHS-EQ1D-001',
          'examen': 'BEPC',
          'serie': null,
          'annee': 2022,
          'type': 'calcul',
          'choix': null,
          'points': 4,
          'irt': {'a': null, 'b': -0.5, 'c': null, 'calibre': false},
        };

        final q = Question.fromJson(json);
        expect(q.id, 'TG-BEPC-MATHS-2022-Q01');
        expect(q.matiere, 'Mathematiques');
        expect(q.examen, 'BEPC');
        expect(q.type, QuestionType.calcul);
        expect(q.irtB, -0.5);
        expect(q.irtA, isNull);
        expect(q.irtC, isNull);
        expect(q.irtCalibrated, isFalse);
      });

      test('parse un QCM avec choix', () {
        final json = <String, dynamic>{
          'id': 'Q-QCM-1',
          'enonce': 'Quel est le PGCD de 24 et 36 ?',
          'reponse': '12',
          'matiere': 'Mathematiques',
          'chapitre': 'PGCD',
          'examen': 'BEPC',
          'type': 'qcm',
          'choix': ['6', '8', '12', '24'],
          'points': 2,
          'irt': {'a': 1.2, 'b': 0.9, 'c': 0.25, 'calibre': true},
        };
        final q = Question.fromJson(json);
        expect(q.type, QuestionType.qcm);
        expect(q.choix, isNotNull);
        expect(q.choix!.length, 4);
        expect(q.choix!.contains('12'), isTrue);
        expect(q.irtA, 1.2);
        expect(q.irtB, 0.9);
        expect(q.irtC, 0.25);
        expect(q.irtCalibrated, isTrue);
      });

      test('competence_id manquant -> chaene vide', () {
        final json = <String, dynamic>{
          'id': 'X',
          'enonce': 'e',
          'reponse': 'r',
          'matiere': 'm',
          'chapitre': 'c',
          'examen': 'BEPC',
          'type': 'ouvert',
        };
        final q = Question.fromJson(json);
        expect(q.competenceId, '');
      });

      test('examen manquant -> "BEPC" par defaut', () {
        final json = <String, dynamic>{
          'id': 'X',
          'enonce': 'e',
          'reponse': 'r',
          'matiere': 'm',
          'chapitre': 'c',
          'type': 'ouvert',
        };
        final q = Question.fromJson(json);
        expect(q.examen, 'BEPC');
      });

      test('type manquant -> "ouvert" par defaut', () {
        final json = <String, dynamic>{
          'id': 'X',
          'enonce': 'e',
          'reponse': 'r',
          'matiere': 'm',
          'chapitre': 'c',
          'examen': 'BEPC',
        };
        final q = Question.fromJson(json);
        expect(q.type, QuestionType.ouvert);
      });

      test('irt manquant -> tous les params null + calibre false', () {
        final json = <String, dynamic>{
          'id': 'X',
          'enonce': 'e',
          'reponse': 'r',
          'matiere': 'm',
          'chapitre': 'c',
          'examen': 'BEPC',
          'type': 'ouvert',
        };
        final q = Question.fromJson(json);
        expect(q.irtA, isNull);
        expect(q.irtB, isNull);
        expect(q.irtC, isNull);
        expect(q.irtCalibrated, isFalse);
      });
    });

    // ─── toJson round-trip ────────────────────────────────────────
    group('toJson round-trip', () {
      test('Round-trip preserve les donnees de base', () {
        final q = Question(
          id: 'test',
          enonce: 'test enonce',
          reponse: 'test reponse',
          matiere: 'Mathematiques',
          chapitre: 'test chapitre',
          competenceId: 'test-comp',
          examen: 'BEPC',
          type: QuestionType.calcul,
          irtB: 0.5,
        );

        final json = q.toJson();
        final q2 = Question.fromJson(json);
        expect(q2.id, q.id);
        expect(q2.enonce, q.enonce);
        expect(q2.reponse, q.reponse);
        expect(q2.matiere, q.matiere);
        expect(q2.chapitre, q.chapitre);
        expect(q2.competenceId, q.competenceId);
        expect(q2.examen, q.examen);
        expect(q2.type, q.type);
        expect(q2.irtB, q.irtB);
      });

      test('Round-trip preserve IRT complet + QCM', () {
        final q = Question(
          id: 'Q-1',
          enonce: 'e',
          reponse: 'r',
          explication: 'exp',
          matiere: 'Physique',
          chapitre: 'Chap',
          competenceId: 'COMP',
          examen: 'BAC1',
          serie: 'C',
          annee: 2023,
          type: QuestionType.qcm,
          choix: const ['A', 'B', 'C', 'D'],
          points: 5,
          irtA: 1.2,
          irtB: 0.3,
          irtC: 0.2,
          irtCalibrated: true,
        );
        final json = q.toJson();
        final restored = Question.fromJson(json);

        expect(restored.id, q.id);
        expect(restored.explication, q.explication);
        expect(restored.serie, q.serie);
        expect(restored.annee, q.annee);
        expect(restored.choix, q.choix);
        expect(restored.points, q.points);
        expect(restored.irtA, q.irtA);
        expect(restored.irtB, q.irtB);
        expect(restored.irtC, q.irtC);
        expect(restored.irtCalibrated, q.irtCalibrated);
      });

      test('toJson structure IRT correcte', () {
        final q = Question(
          id: 'Q',
          enonce: 'e',
          reponse: 'r',
          matiere: 'm',
          chapitre: 'c',
          competenceId: 'comp',
          examen: 'BEPC',
          type: QuestionType.ouvert,
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

    // ─── difficulte (derived from irtB) ───────────────────────────
    group('difficulte (derivee de irtB)', () {
      Question makeQuestion({double? irtB}) => Question(
            id: 'q',
            enonce: '',
            reponse: '',
            matiere: '',
            chapitre: '',
            competenceId: '',
            examen: 'BEPC',
            type: QuestionType.calcul,
            irtB: irtB,
          );

      test('irtB < -0.5 -> facile', () {
        expect(makeQuestion(irtB: -1.0).difficulte, DifficulteNiveau.facile);
        expect(makeQuestion(irtB: -0.6).difficulte, DifficulteNiveau.facile);
      });

      test('irtB = -0.5 -> moyen (borne exclue)', () {
        expect(makeQuestion(irtB: -0.5).difficulte, DifficulteNiveau.moyen);
      });

      test('irtB = 0 -> moyen', () {
        expect(makeQuestion(irtB: 0.0).difficulte, DifficulteNiveau.moyen);
      });

      test('irtB = 0.79 -> moyen', () {
        expect(makeQuestion(irtB: 0.79).difficulte, DifficulteNiveau.moyen);
      });

      test('irtB = 0.8 -> difficile (borne incluse)', () {
        expect(makeQuestion(irtB: 0.8).difficulte, DifficulteNiveau.difficile);
      });

      test('irtB = 1.5 -> difficile', () {
        expect(makeQuestion(irtB: 1.5).difficulte, DifficulteNiveau.difficile);
      });

      test('irtB null -> moyen (defaut 0.0)', () {
        expect(makeQuestion(irtB: null).difficulte, DifficulteNiveau.moyen);
      });
    });

    // ─── QuestionType enum ────────────────────────────────────────
    group('QuestionType enum', () {
      test('5 types definis', () {
        expect(QuestionType.values.length, 5);
      });

      test('Ordre: ouvert, qcm, redaction, calcul, vraiFaux', () {
        expect(QuestionType.values, [
          QuestionType.ouvert,
          QuestionType.qcm,
          QuestionType.redaction,
          QuestionType.calcul,
          QuestionType.vraiFaux,
        ]);
      });

      test('byName resout correctement les chanes', () {
        expect(QuestionType.values.byName('ouvert'), QuestionType.ouvert);
        expect(QuestionType.values.byName('qcm'), QuestionType.qcm);
        expect(QuestionType.values.byName('redaction'), QuestionType.redaction);
        expect(QuestionType.values.byName('calcul'), QuestionType.calcul);
        expect(QuestionType.values.byName('vraiFaux'), QuestionType.vraiFaux);
      });
    });

    // ─── DifficulteNiveau enum ────────────────────────────────────
    group('DifficulteNiveau enum', () {
      test('3 niveaux definis', () {
        expect(DifficulteNiveau.values.length, 3);
      });

      test('Ordre: facile, moyen, difficile', () {
        expect(DifficulteNiveau.values, [
          DifficulteNiveau.facile,
          DifficulteNiveau.moyen,
          DifficulteNiveau.difficile,
        ]);
      });
    });
  });
}
