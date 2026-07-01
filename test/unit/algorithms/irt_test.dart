// test/unit/algorithms/irt_test.dart
// IRT 3-Parameter Logistic (3PL) model tests.
//
// The SrsService.irtProbability() implements:
//   P(correct) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))
//
// Where:
//   theta = student ability
//   a     = discrimination
//   b     = difficulty
//   c     = guessing (lower asymptote)
//
// Reference: Birnbaum (1968), Lord (1980).

import 'package:flutter_test/flutter_test.dart';
import 'package:examboost_togo/services/srs_service.dart';

void main() {
  late SrsService service;

  setUp(() {
    service = SrsService();
  });

  group('IRT 3PL', () {
    // ─── Basic shape ──────────────────────────────────────────────
    group('Basic shape', () {
      test('Probabilité = 0.5 quand θ = b (sans chance)', () {
        final p = service.irtProbability(theta: 0.0, a: 1.0, b: 0.0, c: 0.0);
        expect(p, closeTo(0.5, 0.01));
      });

      test('Probabilité = 0.5 quand θ = b (avec chance c > 0)', () {
        // P = c + (1-c) * 0.5 = 0.25 + 0.75*0.5 = 0.625
        final p = service.irtProbability(theta: 0.0, a: 1.0, b: 0.0, c: 0.25);
        expect(p, closeTo(0.625, 0.01));
      });

      test('Probabilité augmente avec θ', () {
        final p1 = service.irtProbability(theta: -1, a: 1, b: 0, c: 0);
        final p2 = service.irtProbability(theta: 0, a: 1, b: 0, c: 0);
        final p3 = service.irtProbability(theta: 1, a: 1, b: 0, c: 0);
        expect(p1, lessThan(p2));
        expect(p2, lessThan(p3));
      });

      test('Probabilité diminue quand b augmente (θ fixe)', () {
        final p1 = service.irtProbability(theta: 0, a: 1, b: -1, c: 0);
        final p2 = service.irtProbability(theta: 0, a: 1, b: 0, c: 0);
        final p3 = service.irtProbability(theta: 0, a: 1, b: 1, c: 0);
        expect(p1, greaterThan(p2));
        expect(p2, greaterThan(p3));
      });
    });

    // ─── Limites ──────────────────────────────────────────────────
    group('Limites asymptotiques', () {
      test('Avec chance (c=0.25), probabilité minimale tend vers 0.25', () {
        final p = service.irtProbability(theta: -10, a: 1, b: 0, c: 0.25);
        expect(p, greaterThanOrEqualTo(0.25));
        expect(p, lessThan(0.30));
      });

      test('Probabilité maximale tend vers 1.0 (θ très grand, c=0)', () {
        final p = service.irtProbability(theta: 10, a: 1, b: 0, c: 0.0);
        expect(p, closeTo(1.0, 0.01));
      });

      test('Probabilité maximale tend vers 1.0 (θ très grand, c=0.25)', () {
        final p = service.irtProbability(theta: 10, a: 1, b: 0, c: 0.25);
        expect(p, closeTo(1.0, 0.01));
      });

      test('Probabilité minimale tend vers 0 (θ très petit, c=0)', () {
        final p = service.irtProbability(theta: -10, a: 1, b: 0, c: 0.0);
        expect(p, lessThan(0.01));
      });

      test('Avec c=0.5, le plancher est 0.5', () {
        final p = service.irtProbability(theta: -10, a: 1, b: 0, c: 0.5);
        expect(p, greaterThanOrEqualTo(0.5));
        expect(p, lessThan(0.55));
      });
    });

    // ─── Discrimination ───────────────────────────────────────────
    group('Discrimination parameter (a)', () {
      test('a=0 donne probabilité = c + (1-c)*0.5 (pas de discrimination)', () {
        // a=0 means exp(0)=1, so P = c + (1-c)*0.5 = 0.5 (if c=0)
        final p = service.irtProbability(theta: 5, a: 0, b: 0, c: 0);
        expect(p, closeTo(0.5, 0.001));
      });

      test('a plus élevé rend la transition plus abrupte', () {
        // At theta=b, P=0.5 regardless of a. But at theta=b+0.5, a higher a
        // gives a higher P.
        final pLowA = service.irtProbability(theta: 0.5, a: 0.5, b: 0, c: 0);
        final pHighA = service.irtProbability(theta: 0.5, a: 2.0, b: 0, c: 0);
        expect(pHighA, greaterThan(pLowA));
      });
    });

    // ─── Overflow protection ──────────────────────────────────────
    group('Overflow protection', () {
      test('θ extrême positif ne crash pas', () {
        expect(
          () => service.irtProbability(theta: 1000, a: 1, b: 0, c: 0),
          returnsNormally,
        );
      });

      test('θ extrême négatif ne crash pas', () {
        expect(
          () => service.irtProbability(theta: -1000, a: 1, b: 0, c: 0),
          returnsNormally,
        );
      });

      test('a extrême ne crash pas', () {
        expect(
          () => service.irtProbability(theta: 1, a: 1000, b: 0, c: 0),
          returnsNormally,
        );
      });

      test('a négatif ne crash pas (anti-discriminating item)', () {
        // a < 0 is theoretically invalid but should not crash.
        final p = service.irtProbability(theta: 1, a: -1, b: 0, c: 0);
        expect(p, greaterThanOrEqualTo(0.0));
        expect(p, lessThanOrEqualTo(1.0));
      });
    });

    // ─── Bornes ───────────────────────────────────────────────────
    group('Output bounds', () {
      test('Toujours dans [0, 1] pour θ variés', () {
        for (double theta = -5; theta <= 5; theta += 0.5) {
          final p = service.irtProbability(theta: theta, a: 1.5, b: 0, c: 0.2);
          expect(p, greaterThanOrEqualTo(0.0));
          expect(p, lessThanOrEqualTo(1.0));
        }
      });

      test('Toujours dans [c, 1] pour θ variés (c > 0)', () {
        const c = 0.25;
        for (double theta = -5; theta <= 5; theta += 0.5) {
          final p = service.irtProbability(theta: theta, a: 1.5, b: 0, c: c);
          expect(p, greaterThanOrEqualTo(c));
          expect(p, lessThanOrEqualTo(1.0));
        }
      });
    });

    // ─── Symmetry ────────────────────────────────────────────────
    group('Symmetry', () {
      test('P(θ=b+x) = 1 - P(θ=b-x) when c=0', () {
        // Without guessing, the ICC is symmetric around θ=b in the logit space.
        const b = 0.5;
        final pPlus = service.irtProbability(theta: b + 1, a: 1.2, b: b, c: 0);
        final pMinus = service.irtProbability(theta: b - 1, a: 1.2, b: b, c: 0);
        expect(pPlus + pMinus, closeTo(1.0, 0.001));
      });
    });
  });
}
