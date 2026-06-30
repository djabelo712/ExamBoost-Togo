"""tests/test_irt.py — Tests des services IRT, BKT et SM-2."""

from __future__ import annotations

import math
from datetime import datetime, timedelta, timezone

import pytest

from services import bkt_service, irt_service, srs_service


# ────────────────────────────────────────────────────────────────────
# IRT 3PL
# ────────────────────────────────────────────────────────────────────
class TestIRTProbability:
    """Tests de la formule IRT 3PL (miroir de lib/services/srs_service.dart)."""

    def test_theta_equals_b_returns_p_05_when_c_zero(self):
        """Si theta = b et c = 0, P = 0.5 (peu importe a)."""
        p = irt_service.irt_probability(theta=0.0, a=1.0, b=0.0, c=0.0)
        assert math.isclose(p, 0.5, rel_tol=1e-6)

    def test_high_theta_high_p(self):
        """theta >> b -> P proche de 1."""
        p = irt_service.irt_probability(theta=3.0, a=1.0, b=0.0, c=0.0)
        assert p > 0.95

    def test_low_theta_low_p(self):
        """theta << b -> P proche de c."""
        p = irt_service.irt_probability(theta=-3.0, a=1.0, b=0.0, c=0.0)
        assert p < 0.05

    def test_c_is_floor_for_low_theta(self):
        """Quand theta -> -inf, P -> c."""
        p = irt_service.irt_probability(theta=-10.0, a=1.0, b=0.0, c=0.2)
        assert math.isclose(p, 0.2, abs_tol=1e-3)

    def test_p_always_in_unit_interval(self):
        """P in [0, 1] pour tous les parametres extremes."""
        for theta in [-5, -1, 0, 1, 5]:
            for a in [0.2, 1.0, 2.5]:
                for b in [-3, 0, 3]:
                    for c in [0.0, 0.1, 0.3]:
                        p = irt_service.irt_probability(theta, a, b, c)
                        assert 0.0 <= p <= 1.0

    def test_matches_dart_formula(self):
        """Verifie quelques valeurs calculees a la main.

        Formule : P = c + (1-c) * 1/(1 + exp(-1.7 * a * (theta - b)))

        Pour theta=1, a=1, b=0, c=0 :
            exponent = -1.7 * 1 * (1 - 0) = -1.7
            P = 1/(1 + exp(-1.7)) ≈ 0.8455
        """
        p = irt_service.irt_probability(theta=1.0, a=1.0, b=0.0, c=0.0)
        assert math.isclose(p, 1.0 / (1.0 + math.exp(-1.7)), rel_tol=1e-6)


class TestEstimateTheta:
    """Tests d'estimation du theta."""

    def test_empty_returns_zero(self):
        assert irt_service.estimate_theta([]) == 0.0

    def test_all_correct_high_theta(self):
        """100% de reussite -> theta eleve."""
        responses = [(1.0, 0.0, 0.0, 0, 1) for _ in range(10)]
        theta = irt_service.estimate_theta(responses)
        assert theta > 1.0

    def test_all_wrong_low_theta(self):
        """0% de reussite -> theta faible."""
        responses = [(1.0, 0.0, 0.0, 0, 0) for _ in range(10)]
        theta = irt_service.estimate_theta(responses)
        assert theta < -1.0


class TestCalibrateIRT:
    """Tests de la calibration (fallback probit)."""

    def test_empty_dataframe_returns_empty(self):
        import pandas as pd

        df = pd.DataFrame(columns=["question_id", "user_id", "correct"])
        result = irt_service.calibrate_irt(df, use_pyirt=False)
        assert result == []

    def test_probit_fallback(self):
        """Avec assez de donnees, on obtient un b < 0 pour un item facile."""
        import pandas as pd

        rows = []
        # 90% de reussite -> b fortement negatif
        for i in range(20):
            rows.append({"question_id": "Q1", "user_id": f"u{i}", "correct": 1 if i < 18 else 0})
        df = pd.DataFrame(rows)

        result = irt_service.calibrate_irt(df, use_pyirt=False)
        assert len(result) == 1
        item = result[0]
        assert item.question_id == "Q1"
        assert item.method == "probit_fallback"
        assert item.b < 0  # item facile -> b negatif


# ────────────────────────────────────────────────────────────────────
# BKT
# ────────────────────────────────────────────────────────────────────
class TestBKTUpdate:
    """Tests de update_bkt (miroir de lib/models/user.dart)."""

    def test_correct_increases_pL(self):
        """Une reponse correcte augmente P(L)."""
        result = bkt_service.update_bkt(pL=0.3, correct=True)
        assert result.pL_after > 0.3
        assert 0.0 <= result.pL_after <= 1.0

    def test_incorrect_decreases_pL(self):
        """Une reponse incorrecte diminue P(L)."""
        result = bkt_service.update_bkt(pL=0.7, correct=False)
        assert result.pL_after < 0.7
        assert result.pL_after >= 0.0

    def test_mastered_threshold(self):
        """Au-dessus du seuil, mastered = True."""
        result = bkt_service.update_bkt(pL=0.95, correct=True)
        assert result.mastered is True

    def test_low_pL_not_mastered(self):
        result = bkt_service.update_bkt(pL=0.1, correct=False)
        assert result.mastered is False

    def test_correct_formula_matches_dart(self):
        """Verifie que le calcul correspond exactement au code Dart.

        Avec P(L)=0.5, P(S)=0.1, P(G)=0.2, correct :
            P(correct) = 0.5 * 0.9 + 0.5 * 0.2 = 0.55
            P(L|1) = (0.5 * 0.9) / 0.55 = 0.8181...
            P(L_next) = 0.8181 + (1 - 0.8181) * 0.2 = 0.8545...
        """
        result = bkt_service.update_bkt(
            pL=0.5,
            correct=True,
            p_learn=0.2,
            p_slip=0.1,
            p_guess=0.2,
        )
        expected = (0.5 * 0.9) / 0.55  # 0.8181...
        expected_next = expected + (1 - expected) * 0.2  # 0.8545...
        assert math.isclose(result.pL_after, expected_next, rel_tol=1e-4)

    def test_incorrect_formula_matches_dart(self):
        """Avec P(L)=0.5, P(S)=0.1, P(G)=0.2, incorrect :
            P(incorrect) = 0.5 * 0.1 + 0.5 * 0.8 = 0.45
            P(L|0) = (0.5 * 0.1) / 0.45 = 0.1111...
            P(L_next) = 0.1111 + (1 - 0.1111) * 0.2 = 0.2888...
        """
        result = bkt_service.update_bkt(
            pL=0.5,
            correct=False,
            p_learn=0.2,
            p_slip=0.1,
            p_guess=0.2,
        )
        expected = (0.5 * 0.1) / 0.45
        expected_next = expected + (1 - expected) * 0.2
        assert math.isclose(result.pL_after, expected_next, rel_tol=1e-4)

    def test_pL_bounded(self):
        """P(L) reste dans [0, 1] meme avec des valeurs extremes."""
        for pL in [0.0, 0.001, 0.5, 0.999, 1.0]:
            r1 = bkt_service.update_bkt(pL=pL, correct=True)
            r2 = bkt_service.update_bkt(pL=pL, correct=False)
            assert 0.0 <= r1.pL_after <= 1.0
            assert 0.0 <= r2.pL_after <= 1.0


# ────────────────────────────────────────────────────────────────────
# SM-2
# ────────────────────────────────────────────────────────────────────
class TestSM2:
    """Tests de apply_sm2 (miroir de lib/models/review_card.dart)."""

    def test_quality_out_of_range_raises(self):
        state = srs_service.Sm2State()
        with pytest.raises(ValueError):
            srs_service.apply_sm2(state, quality=6)
        with pytest.raises(ValueError):
            srs_service.apply_sm2(state, quality=-1)

    def test_first_correct_sets_interval_one(self):
        """Premiere reponse correcte : interval = 1, repetitions = 1."""
        state = srs_service.Sm2State(repetitions=0, easiness_factor=2.5)
        result = srs_service.apply_sm2(state, quality=5)
        assert result.interval_days == 1
        assert result.repetitions == 1
        assert result.is_learning is False
        assert result.correct_attempts == 1
        assert result.total_attempts == 1

    def test_second_correct_sets_interval_six(self):
        """Deuxieme reponse correcte : interval = 6."""
        state = srs_service.Sm2State(
            repetitions=1, easiness_factor=2.5, interval_days=1
        )
        result = srs_service.apply_sm2(state, quality=5)
        assert result.interval_days == 6
        assert result.repetitions == 2

    def test_third_correct_uses_ef(self):
        """Troisieme reponse correcte : interval = floor(interval * EF_OLD).

        Important : en SM-2 (et dans le code Dart), l'intervalle est calcule
        avec l'ANCIEN EF (avant mise a jour). Donc :
            repetitions=2, EF=2.5, interval=6
            -> new_interval = floor(6 * 2.5) = 15
            PUIS EF est mis a jour (2.5 -> 2.6 pour q=5).
        """
        state = srs_service.Sm2State(
            repetitions=2, easiness_factor=2.5, interval_days=6
        )
        result = srs_service.apply_sm2(state, quality=5)
        assert result.interval_days == 15
        assert result.repetitions == 3
        # EF mis a jour APRES calcul de l'intervalle
        assert math.isclose(result.easiness_factor, 2.6, rel_tol=1e-6)

    def test_incorrect_resets(self):
        """Reponse incorrecte (q < 3) : reset a 0, interval = 1."""
        state = srs_service.Sm2State(
            repetitions=5, easiness_factor=2.5, interval_days=30
        )
        result = srs_service.apply_sm2(state, quality=2)
        assert result.repetitions == 0
        assert result.interval_days == 1
        assert result.is_learning is True
        assert result.correct_attempts == 0

    def test_ef_floor_1_3(self):
        """EF ne descend jamais sous 1.3."""
        state = srs_service.Sm2State(repetitions=0, easiness_factor=1.3)
        # q=0 devrait baisser EF mais le plancher est 1.3
        result = srs_service.apply_sm2(state, quality=0)
        assert result.easiness_factor >= 1.3

    def test_ef_increases_with_high_quality(self):
        """q=5 augmente l'EF de +0.1."""
        state = srs_service.Sm2State(repetitions=0, easiness_factor=2.5)
        result = srs_service.apply_sm2(state, quality=5)
        # EF' = 2.5 + (0.1 - 0*(...)) = 2.6
        assert math.isclose(result.easiness_factor, 2.6, rel_tol=1e-6)

    def test_next_review_date_in_future(self):
        """next_review_date > now."""
        state = srs_service.Sm2State()
        now = datetime.now(timezone.utc)
        result = srs_service.apply_sm2(state, quality=5, now=now)
        assert result.next_review_date > now

    def test_days_overdue_zero_when_future(self):
        future = datetime.now(timezone.utc) + timedelta(days=3)
        assert srs_service.days_overdue(future) == 0

    def test_days_overdue_positive_when_past(self):
        past = datetime.now(timezone.utc) - timedelta(days=5)
        assert srs_service.days_overdue(past) == 5
