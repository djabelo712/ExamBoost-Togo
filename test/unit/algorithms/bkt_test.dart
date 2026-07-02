// test/unit/algorithms/bkt_test.dart
// Bayesian Knowledge Tracing (BKT) tests — pure formula verification.
//
// The AppUser.updateBkt() method implements the standard BKT update:
//
//   P(L|obs=correct) = P(L) * (1 - P(S)) / [P(L) * (1 - P(S)) + (1 - P(L)) * P(G)]
//   P(L|obs=incorrect) = P(L) * P(S) / [P(L) * P(S) + (1 - P(L)) * (1 - P(G))]
//   P(L_next) = P(L|obs) + (1 - P(L|obs)) * P(T)
//
// Default params: P(T) = 0.20, P(S) = 0.10, P(G) = 0.20, initial P(L) = 0.10.

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/models/user.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BKT Algorithm', () {
    group('Default parameters', () {
      test('Default pL when competence not in map = 0.10', () {
        final user = createTestUser();
        expect(user.getMaitrise('unknown-comp'), 0.10);
      });

      test('getMaitrise returns the stored value if present', () {
        final user = createTestUser(bktMaitrise: {'comp1': 0.42});
        expect(user.getMaitrise('comp1'), 0.42);
      });
    });

    // ─── updateBkt - réponse correcte ─────────────────────────────
    group('updateBkt - réponse correcte', () {
      test('P(L) augmente après réponse correcte', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.10;
        user.updateBkt(competenceId: 'comp1', correct: true);
        expect(user.bktMaitrise['comp1']!, greaterThan(0.10));
        // Vérifier valeur exacte (default params):
        //   pL=0.10, pSlip=0.10, pGuess=0.20, pLearn=0.20
        //   pCorrect = 0.10*0.90 + 0.90*0.20 = 0.09 + 0.18 = 0.27
        //   pL|obs=1 = 0.09 / 0.27 = 0.3333
        //   pL_next = 0.3333 + (1 - 0.3333) * 0.20 = 0.3333 + 0.1333 = 0.4667
        expect(user.bktMaitrise['comp1']!, closeTo(0.4667, 0.01));
      });

      test('P(L) déjà élevée augmente encore vers 1.0', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.80;
        user.updateBkt(competenceId: 'comp1', correct: true);
        // pL=0.80, pCorrect = 0.80*0.90 + 0.20*0.20 = 0.72 + 0.04 = 0.76
        // pL|obs = 0.72 / 0.76 = 0.9474
        // pL_next = 0.9474 + 0.0526 * 0.20 = 0.9474 + 0.0105 = 0.9579
        expect(user.bktMaitrise['comp1']!, closeTo(0.958, 0.005));
      });

      test('Crée une nouvelle entrée si compétence inconnue', () {
        final user = createTestUser();
        expect(user.bktMaitrise.containsKey('new-comp'), isFalse);
        user.updateBkt(competenceId: 'new-comp', correct: true);
        expect(user.bktMaitrise.containsKey('new-comp'), isTrue);
        expect(user.bktMaitrise['new-comp']!, greaterThan(0.10));
      });
    });

    // ─── updateBkt - réponse incorrecte ───────────────────────────
    group('updateBkt - réponse incorrecte', () {
      test('P(L) diminue après réponse incorrecte', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.50;
        user.updateBkt(competenceId: 'comp1', correct: false);
        expect(user.bktMaitrise['comp1']!, lessThan(0.50));
        // pL=0.50, pIncorrect = 0.50*0.10 + 0.50*0.80 = 0.05 + 0.40 = 0.45
        // pL|obs = 0.05 / 0.45 = 0.1111
        // pL_next = 0.1111 + 0.8889 * 0.20 = 0.1111 + 0.1778 = 0.2889
        expect(user.bktMaitrise['comp1']!, closeTo(0.289, 0.005));
      });

      test('P(L) très faible reste faible après erreur', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.10;
        user.updateBkt(competenceId: 'comp1', correct: false);
        // pL=0.10, pIncorrect = 0.10*0.10 + 0.90*0.80 = 0.01 + 0.72 = 0.73
        // pL|obs = 0.01 / 0.73 = 0.0137
        // pL_next = 0.0137 + 0.9863 * 0.20 = 0.0137 + 0.1973 = 0.2110
        // Note: P(T) creates a floor — even after an error, P(L) cannot go below ~pLearn.
        expect(user.bktMaitrise['comp1']!, closeTo(0.211, 0.005));
      });
    });

    // ─── Custom parameters ────────────────────────────────────────
    group('Custom BKT parameters', () {
      test('pLearn élevé accélère l\'apprentissage', () {
        final userLow = createTestUser();
        userLow.bktMaitrise['comp1'] = 0.10;
        userLow.updateBkt(competenceId: 'comp1', correct: true, pLearn: 0.10);

        final userHigh = createTestUser();
        userHigh.bktMaitrise['comp1'] = 0.10;
        userHigh.updateBkt(competenceId: 'comp1', correct: true, pLearn: 0.50);

        expect(userHigh.bktMaitrise['comp1']!,
            greaterThan(userLow.bktMaitrise['comp1']!));
      });

      test('pSlip élevé rend une erreur moins informative', () {
        // If pSlip is high, an incorrect response is more likely even for a
        // master, so P(L) should not drop as much.
        final userLowSlip = createTestUser();
        userLowSlip.bktMaitrise['comp1'] = 0.50;
        userLowSlip.updateBkt(
            competenceId: 'comp1', correct: false, pSlip: 0.05);

        final userHighSlip = createTestUser();
        userHighSlip.bktMaitrise['comp1'] = 0.50;
        userHighSlip.updateBkt(
            competenceId: 'comp1', correct: false, pSlip: 0.40);

        expect(userHighSlip.bktMaitrise['comp1']!,
            greaterThan(userLowSlip.bktMaitrise['comp1']!));
      });

      test('pGuess élevé rend une bonne réponse moins informative', () {
        // If pGuess is high, a correct response might just be luck, so P(L)
        // should not rise as much.
        final userLowGuess = createTestUser();
        userLowGuess.bktMaitrise['comp1'] = 0.10;
        userLowGuess.updateBkt(
            competenceId: 'comp1', correct: true, pGuess: 0.05);

        final userHighGuess = createTestUser();
        userHighGuess.bktMaitrise['comp1'] = 0.10;
        userHighGuess.updateBkt(
            competenceId: 'comp1', correct: true, pGuess: 0.40);

        expect(userHighGuess.bktMaitrise['comp1']!,
            lessThan(userLowGuess.bktMaitrise['comp1']!));
      });
    });

    // ─── Convergence ──────────────────────────────────────────────
    group('Convergence', () {
      test('Après 10 bonnes réponses consécutives, P(L) >= 0.85', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.10;
        for (int i = 0; i < 10; i++) {
          user.updateBkt(competenceId: 'comp1', correct: true);
        }
        expect(user.bktMaitrise['comp1']!, greaterThanOrEqualTo(0.85));
      });

      test('Après 5 mauvaises réponses, P(L) diminue fortement', () {
        // Note: with default pLearn=0.20, P(L) has a floor around 0.20
        // (because P(L_next) = P(L|obs) + (1 - P(L|obs)) * pLearn converges
        // to pLearn when P(L|obs) -> 0). So we cannot assert < 0.10.
        // Instead we verify P(L) drops substantially from 0.90.
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.90;
        for (int i = 0; i < 5; i++) {
          user.updateBkt(competenceId: 'comp1', correct: false);
        }
        // P(L) should drop below 0.30 (close to the pLearn floor).
        expect(user.bktMaitrise['comp1']!, lessThan(0.30));
        expect(user.bktMaitrise['comp1']!, greaterThanOrEqualTo(0.15));
      });

      test('Alternance correct/incorrect maintient P(L) médian', () {
        final user = createTestUser();
        user.bktMaitrise['comp1'] = 0.50;
        for (int i = 0; i < 20; i++) {
          user.updateBkt(competenceId: 'comp1', correct: i.isEven);
        }
        // After alternating, P(L) should be somewhere in the middle range.
        expect(user.bktMaitrise['comp1']!, greaterThan(0.20));
        expect(user.bktMaitrise['comp1']!, lessThan(0.90));
      });

      test('P(L) toujours clampé entre 0 et 1', () {
        final user = createTestUser();
        // Extreme low start + many incorrect.
        user.bktMaitrise['comp1'] = 0.001;
        for (int i = 0; i < 20; i++) {
          user.updateBkt(competenceId: 'comp1', correct: false);
        }
        expect(user.bktMaitrise['comp1']!, greaterThanOrEqualTo(0.0));
        expect(user.bktMaitrise['comp1']!, lessThanOrEqualTo(1.0));

        // Extreme high start + many correct.
        user.bktMaitrise['comp2'] = 0.999;
        for (int i = 0; i < 20; i++) {
          user.updateBkt(competenceId: 'comp2', correct: true);
        }
        expect(user.bktMaitrise['comp2']!, greaterThanOrEqualTo(0.0));
        expect(user.bktMaitrise['comp2']!, lessThanOrEqualTo(1.0));
      });
    });
  });
}
