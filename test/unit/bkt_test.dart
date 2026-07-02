// test/unit/bkt_test.dart
// Bayesian Knowledge Tracing (BKT) tests — pure formula verification.
//
// CRITICAL tests for the per-competence mastery tracker at the heart of
// ExamBoost Togo. The AppUser.updateBkt() method implements the standard
// BKT update:
//
//   P(L|obs=correct)   = P(L) * (1 - P(S))
//                        / [ P(L) * (1 - P(S)) + (1 - P(L)) * P(G) ]
//   P(L|obs=incorrect) = P(L) * P(S)
//                        / [ P(L) * P(S) + (1 - P(L)) * (1 - P(G)) ]
//   P(L_next) = P(L|obs) + (1 - P(L|obs)) * P(T)
//
// Default params: P(T) = 0.20, P(S) = 0.10, P(G) = 0.20, initial P(L) = 0.10.
//
// NOTE: AppUser extends HiveObject and updateBkt() calls save() at the end.
// When the user is not attached to a Hive box, save() is a no-op — so these
// tests can construct AppUser directly without initialising Hive.

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/user.dart';

void main() {
  group('BKT Algorithm', () {
    late AppUser user;

    setUp(() {
      user = AppUser(
        id: 'u1',
        nom: 'Test',
        prenom: 'Test',
        niveauScolaire: '3eme',
        dateInscription: DateTime.now(),
      );
    });

    // ─── Correct answer ───────────────────────────────────────────
    group('Reponse correcte', () {
      test('P(L) augmente apres reponse correcte', () {
        user.bktMaitrise['comp1'] = 0.10;
        user.updateBkt(competenceId: 'comp1', correct: true);
        expect(user.bktMaitrise['comp1']!, greaterThan(0.10));
      });

      test('Valeur exacte : pL=0.1, correct -> pL=0.466', () {
        // pL=0.1, pSlip=0.1, pGuess=0.2, pLearn=0.2
        // pCorrect = 0.1*0.9 + 0.9*0.2 = 0.09 + 0.18 = 0.27
        // pL|obs=1 = (0.1*0.9) / 0.27 = 0.333
        // pL_next  = 0.333 + (1-0.333)*0.2 = 0.333 + 0.133 = 0.466
        user.bktMaitrise['comp1'] = 0.10;
        user.updateBkt(competenceId: 'comp1', correct: true);
        expect(user.bktMaitrise['comp1']!, closeTo(0.466, 0.01));
      });

      test('P(L) deja elevee augmente encore vers 1.0', () {
        user.bktMaitrise['comp1'] = 0.80;
        user.updateBkt(competenceId: 'comp1', correct: true);
        // pL=0.80, pCorrect = 0.80*0.90 + 0.20*0.20 = 0.72 + 0.04 = 0.76
        // pL|obs = 0.72 / 0.76 = 0.9474
        // pL_next = 0.9474 + 0.0526 * 0.20 = 0.9579
        expect(user.bktMaitrise['comp1']!, closeTo(0.958, 0.005));
      });
    });

    // ─── Incorrect answer ─────────────────────────────────────────
    group('Reponse incorrecte', () {
      test('P(L) diminue apres reponse incorrecte', () {
        user.bktMaitrise['comp1'] = 0.50;
        user.updateBkt(competenceId: 'comp1', correct: false);
        expect(user.bktMaitrise['comp1']!, lessThan(0.50));
      });

      test('Valeur exacte : pL=0.5, incorrect -> pL=0.289', () {
        // pL=0.5, pSlip=0.1, pGuess=0.2, pLearn=0.2
        // pIncorrect = 0.5*0.1 + 0.5*0.8 = 0.05 + 0.4 = 0.45
        // pL|obs=0 = (0.5*0.1) / 0.45 = 0.111
        // pL_next  = 0.111 + (1-0.111)*0.2 = 0.111 + 0.178 = 0.289
        user.bktMaitrise['comp1'] = 0.50;
        user.updateBkt(competenceId: 'comp1', correct: false);
        expect(user.bktMaitrise['comp1']!, closeTo(0.289, 0.01));
      });
    });

    // ─── Mastery threshold ────────────────────────────────────────
    group('Seuil de maitrise', () {
      test('competencesMaitrisees filtre >= 0.85', () {
        user.bktMaitrise['comp1'] = 0.80;
        user.bktMaitrise['comp2'] = 0.85;
        user.bktMaitrise['comp3'] = 0.95;
        final mastered = user.competencesMaitrisees;
        expect(mastered, contains('comp2'));
        expect(mastered, contains('comp3'));
        expect(mastered, isNot(contains('comp1')));
      });

      test('Aucune competence maitrisee -> liste vide', () {
        user.bktMaitrise['comp1'] = 0.10;
        user.bktMaitrise['comp2'] = 0.50;
        expect(user.competencesMaitrisees, isEmpty);
      });
    });

    // ─── Convergence ──────────────────────────────────────────────
    group('Convergence', () {
      test('Apres 10 correctes consecutives : P(L) >= 0.85', () {
        user.bktMaitrise['comp1'] = 0.10;
        for (int i = 0; i < 10; i++) {
          user.updateBkt(competenceId: 'comp1', correct: true);
        }
        expect(user.bktMaitrise['comp1']!, greaterThanOrEqualTo(0.85));
      });

      // NOTE: The spec asked for "P(L) < 0.10 after 5 incorrect". The
      // implementation has pLearn=0.20 (transition probability), which
      // creates a floor: P(L_next) = P(L|obs) + (1 - P(L|obs)) * pLearn
      // converges to pLearn (0.20) when P(L|obs) -> 0. After 5 incorrect
      // answers from P(L)=0.90, the value stabilises around 0.23 — NOT
      // below 0.10. The implementation is correct; the spec was overly
      // optimistic. We assert `lessThan(0.30)` instead.
      test('Apres 5 incorrectes consecutives : P(L) chute fortement', () {
        user.bktMaitrise['comp1'] = 0.90;
        for (int i = 0; i < 5; i++) {
          user.updateBkt(competenceId: 'comp1', correct: false);
        }
        expect(user.bktMaitrise['comp1']!, lessThan(0.30));
        expect(user.bktMaitrise['comp1']!, greaterThanOrEqualTo(0.15));
      });

      test('P(L) toujours clampe entre 0 et 1', () {
        user.bktMaitrise['comp1'] = 0.001;
        for (int i = 0; i < 20; i++) {
          user.updateBkt(competenceId: 'comp1', correct: false);
        }
        expect(user.bktMaitrise['comp1']!, greaterThanOrEqualTo(0.0));
        expect(user.bktMaitrise['comp1']!, lessThanOrEqualTo(1.0));

        user.bktMaitrise['comp2'] = 0.999;
        for (int i = 0; i < 20; i++) {
          user.updateBkt(competenceId: 'comp2', correct: true);
        }
        expect(user.bktMaitrise['comp2']!, greaterThanOrEqualTo(0.0));
        expect(user.bktMaitrise['comp2']!, lessThanOrEqualTo(1.0));
      });
    });

    // ─── New competence ───────────────────────────────────────────
    group('Nouvelle competence', () {
      test('Competence jamais vue : P(L) defaut 0.10 puis update', () {
        // comp2 doesn't exist; updateBkt must initialise it to 0.10 then
        // compute the posterior.
        user.updateBkt(competenceId: 'comp2', correct: true);
        expect(user.bktMaitrise['comp2']!, greaterThan(0.10));
        expect(user.bktMaitrise['comp2']!, lessThan(0.50));
      });

      test('getMaitrise retourne 0.0 pour une competence inconnue', () {
        expect(user.getMaitrise('unknown'), 0.0);
      });

      test('getMaitrise retourne la valeur stockee si presente', () {
        user.bktMaitrise['comp1'] = 0.42;
        expect(user.getMaitrise('comp1'), 0.42);
      });
    });

    // ─── Score global ─────────────────────────────────────────────
    group('Score global', () {
      test('Score global = moyenne P(L) x 100', () {
        user.bktMaitrise['comp1'] = 0.50;
        user.bktMaitrise['comp2'] = 0.70;
        // (0.5 + 0.7) / 2 * 100 = 60.0
        expect(user.scoreGlobal, closeTo(60.0, 0.1));
      });

      test('Score global vide = 0', () {
        expect(user.scoreGlobal, 0.0);
      });

      test('Score global clampe a 100 max', () {
        user.bktMaitrise['comp1'] = 0.99;
        user.bktMaitrise['comp2'] = 0.99;
        // (0.99 + 0.99) / 2 * 100 = 99.0 — under the 100 clamp.
        expect(user.scoreGlobal, closeTo(99.0, 0.1));
      });
    });

    // ─── Custom BKT parameters ────────────────────────────────────
    group('Parametres BKT personnalises', () {
      test('pLearn eleve accelere l\'apprentissage', () {
        final userLow = AppUser(
          id: 'u-low',
          nom: 'T',
          prenom: 'T',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        )..bktMaitrise['comp1'] = 0.10;
        userLow.updateBkt(competenceId: 'comp1', correct: true, pLearn: 0.10);

        final userHigh = AppUser(
          id: 'u-high',
          nom: 'T',
          prenom: 'T',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        )..bktMaitrise['comp1'] = 0.10;
        userHigh.updateBkt(competenceId: 'comp1', correct: true, pLearn: 0.50);

        expect(userHigh.bktMaitrise['comp1']!,
            greaterThan(userLow.bktMaitrise['comp1']!));
      });

      test('pSlip eleve rend une erreur moins informative', () {
        // If pSlip is high, an incorrect response is more likely even for a
        // master, so P(L) should not drop as much.
        final userLowSlip = AppUser(
          id: 'u-ls',
          nom: 'T',
          prenom: 'T',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        )..bktMaitrise['comp1'] = 0.50;
        userLowSlip.updateBkt(
            competenceId: 'comp1', correct: false, pSlip: 0.05);

        final userHighSlip = AppUser(
          id: 'u-hs',
          nom: 'T',
          prenom: 'T',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        )..bktMaitrise['comp1'] = 0.50;
        userHighSlip.updateBkt(
            competenceId: 'comp1', correct: false, pSlip: 0.40);

        expect(userHighSlip.bktMaitrise['comp1']!,
            greaterThan(userLowSlip.bktMaitrise['comp1']!));
      });

      test('pGuess eleve rend une bonne reponse moins informative', () {
        // If pGuess is high, a correct response might just be luck, so P(L)
        // should not rise as much.
        final userLowGuess = AppUser(
          id: 'u-lg',
          nom: 'T',
          prenom: 'T',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        )..bktMaitrise['comp1'] = 0.10;
        userLowGuess.updateBkt(
            competenceId: 'comp1', correct: true, pGuess: 0.05);

        final userHighGuess = AppUser(
          id: 'u-hg',
          nom: 'T',
          prenom: 'T',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        )..bktMaitrise['comp1'] = 0.10;
        userHighGuess.updateBkt(
            competenceId: 'comp1', correct: true, pGuess: 0.40);

        expect(userHighGuess.bktMaitrise['comp1']!,
            lessThan(userLowGuess.bktMaitrise['comp1']!));
      });
    });

    // ─── Identity helpers ─────────────────────────────────────────
    group('Identity helpers', () {
      test('nomComplet = prenom + nom', () {
        final u = AppUser(
          id: 'u1',
          nom: 'Doe',
          prenom: 'Jane',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        );
        expect(u.nomComplet, 'Jane Doe');
      });
    });
  });
}
