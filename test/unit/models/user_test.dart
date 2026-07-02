// test/unit/models/user_test.dart
// Tests for the AppUser model (HiveType 3) — BKT, scoring, helpers.
//
// Note: the BKT algorithm itself is exhaustively tested in
// test/unit/algorithms/bkt_test.dart. This file focuses on the model's
// non-algorithm behavior.

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/user.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('AppUser model', () {
    // ─── Construction ─────────────────────────────────────────────
    group('Construction', () {
      test('Tous les champs sont correctement assignés', () {
        final user = AppUser(
          id: 'u1',
          nom: 'Komla',
          prenom: 'Kofi',
          email: 'kofi@example.com',
          niveauScolaire: 'Terminale',
          serie: 'C',
          etablissement: 'Lycée de Tokoin',
          ville: 'Lomé',
          dateInscription: DateTime(2026, 1, 15),
          thetaIrt: 0.5,
        );
        expect(user.id, 'u1');
        expect(user.nom, 'Komla');
        expect(user.prenom, 'Kofi');
        expect(user.email, 'kofi@example.com');
        expect(user.niveauScolaire, 'Terminale');
        expect(user.serie, 'C');
        expect(user.etablissement, 'Lycée de Tokoin');
        expect(user.ville, 'Lomé');
        expect(user.dateInscription, DateTime(2026, 1, 15));
        expect(user.thetaIrt, 0.5);
      });

      test('Valeurs par défaut correctes', () {
        final user = AppUser(
          id: 'u1',
          nom: 'X',
          prenom: 'Y',
          niveauScolaire: '3eme',
          dateInscription: DateTime(2026),
        );
        expect(user.email, isNull);
        expect(user.serie, isNull);
        expect(user.etablissement, isNull);
        expect(user.ville, isNull);
        expect(user.bktMaitrise, isEmpty);
        expect(user.totalSessionsCount, 0);
        expect(user.totalQuestionsAnswered, 0);
        expect(user.thetaIrt, isNull);
        expect(user.lastActiveDate, isNull);
      });

      test('bktMaitrise est mutable (Map<String, double>)', () {
        final user = createTestUser();
        expect(user.bktMaitrise, isEmpty);
        user.bktMaitrise['comp1'] = 0.5;
        expect(user.bktMaitrise['comp1'], 0.5);
      });
    });

    // ─── Helpers ──────────────────────────────────────────────────
    group('Helpers', () {
      test('nomComplet combine prenom + nom', () {
        final user = createTestUser(prenom: 'Kofi', nom: 'Komla');
        expect(user.nomComplet, 'Kofi Komla');
      });

      test('getMaitrise retourne 0.0 si compétence inconnue', () {
        final user = createTestUser();
        expect(user.getMaitrise('unknown'), 0.0);
      });

      test('getMaitrise retourne la valeur stockée', () {
        final user = createTestUser(bktMaitrise: {'c1': 0.42});
        expect(user.getMaitrise('c1'), 0.42);
      });
    });

    // ─── BKT update ──────────────────────────────────────────────
    group('BKT update', () {
      test('updateBkt correct augmente P(L)', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.10;
        user.updateBkt(competenceId: 'comp1', correct: true);
        expect(user.bktMaitrise['comp1']!, greaterThan(0.10));
      });

      test('updateBkt incorrect diminue P(L)', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.50;
        user.updateBkt(competenceId: 'comp1', correct: false);
        expect(user.bktMaitrise['comp1']!, lessThan(0.50));
      });

      test('updateBkt crée l\'entrée si compétence absente', () {
        final user = createTestUser();
        expect(user.bktMaitrise.containsKey('new'), isFalse);
        user.updateBkt(competenceId: 'new', correct: true);
        expect(user.bktMaitrise.containsKey('new'), isTrue);
      });
    });

    // ─── Seuil de maîtrise ───────────────────────────────────────
    group('Seuil de maîtrise', () {
      test('competencesMaitrisees filtre >= 0.85', () {
        final user = createTestUser(bktMaitrise: {
          'comp1': 0.80, // pas maîtrisée
          'comp2': 0.85, // maîtrisée (juste)
          'comp3': 0.95, // maîtrisée
        });
        expect(user.competencesMaitrisees, contains('comp2'));
        expect(user.competencesMaitrisees, contains('comp3'));
        expect(user.competencesMaitrisees, isNot(contains('comp1')));
      });

      test('competencesMaitrisees vide si rien au-dessus du seuil', () {
        final user = createTestUser(bktMaitrise: {
          'comp1': 0.10,
          'comp2': 0.50,
          'comp3': 0.84,
        });
        expect(user.competencesMaitrisees, isEmpty);
      });

      test('competencesMaitrisees vide si map vide', () {
        final user = createTestUser();
        expect(user.competencesMaitrisees, isEmpty);
      });
    });

    // ─── scoreGlobal ─────────────────────────────────────────────
    group('scoreGlobal', () {
      test('0 si bktMaitrise vide', () {
        final user = createTestUser();
        expect(user.scoreGlobal, 0.0);
      });

      test('Moyenne des P(L) × 100', () {
        final user = createTestUser(bktMaitrise: {
          'c1': 0.5,
          'c2': 0.8,
          'c3': 1.0,
        });
        // (0.5 + 0.8 + 1.0) / 3 * 100 = 76.67
        expect(user.scoreGlobal, closeTo(76.67, 0.5));
      });

      test('Bornes [0, 100]', () {
        final userLow = createTestUser(bktMaitrise: {'c1': 0.0});
        expect(userLow.scoreGlobal, 0.0);

        final userHigh = createTestUser(bktMaitrise: {'c1': 1.0});
        expect(userHigh.scoreGlobal, 100.0);
      });
    });

    // ─── Convergence ─────────────────────────────────────────────
    group('Convergence BKT', () {
      test('Après 10 bonnes réponses consécutives, P(L) >= 0.85', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.10;
        for (int i = 0; i < 10; i++) {
          user.updateBkt(competenceId: 'comp1', correct: true);
        }
        expect(user.bktMaitrise['comp1']!, greaterThanOrEqualTo(0.85));
        expect(user.competencesMaitrisees, contains('comp1'));
      });

      test('Après 5 mauvaises réponses, P(L) a baissé fortement', () {
        // Note: pLearn=0.20 creates a floor ~0.20.
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.90;
        for (int i = 0; i < 5; i++) {
          user.updateBkt(competenceId: 'comp1', correct: false);
        }
        expect(user.bktMaitrise['comp1']!, lessThan(0.30));
      });
    });
  });
}
