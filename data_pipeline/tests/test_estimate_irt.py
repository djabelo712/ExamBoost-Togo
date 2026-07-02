"""
Tests unitaires pour l'estimation IRT (parametre b = difficulte).

Couvre:
    - Heuristique b par type (calcul=0.5, qcm=0.0, ouvert=0.3, vraiFaux=-0.2,
      redaction=0.8).
    - Ajustements (points==5 -> +0.3 ; BAC -> +0.4 ; serie C/D -> +0.2 ;
      explication absente -> -0.1).
    - Validation range b [-3, +3] (clamp applique par la fonction).
    - Estimation depuis taux de reussite (inv_norm).
    - Consommation d'historique CSV.
    - Integration estimate_irt_for_questions (skip si b deja set).

Aucun appel reseau. Aucune dependance filesystem pour les tests unitaires.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Any, Dict

import pytest

from estimate_irt import (
    BASE_B_BY_TYPE,
    BAC_BONUS,
    NO_EXPLANATION_PENALTY,
    POINTS_BONUS_5,
    SCIENTIFIC_SERIES,
    SCIENTIFIC_SERIE_BONUS,
    estimate_b_from_success_rate,
    estimate_b_heuristic,
    estimate_irt_for_questions,
    inv_norm,
    load_history,
)


# ─── Helpers ───────────────────────────────────────────────────────────────


def _q(
    qtype: str = "calcul",
    examen: str = "BEPC",
    points: int | None = 4,
    serie: str | None = None,
    explication: str = "explication",
) -> Dict[str, Any]:
    """Build a minimal question dict for IRT heuristics."""
    return {
        "id": "TG-BEPC-MATHS-2022-Q01",
        "type": qtype,
        "examen": examen,
        "points": points,
        "serie": serie,
        "explication": explication,
        "irt": {"a": None, "b": None, "c": None, "calibre": False},
    }


# ─── 1) BASE_B_BY_TYPE ───────────────────────────────────────────────────


class TestBaseBByType:
    """The base difficulty per question type is fixed by spec."""

    def test_calcul_base_is_05(self):
        assert BASE_B_BY_TYPE["calcul"] == 0.5

    def test_qcm_base_is_0(self):
        assert BASE_B_BY_TYPE["qcm"] == 0.0

    def test_ouvert_base_is_03(self):
        assert BASE_B_BY_TYPE["ouvert"] == 0.3

    def test_vraiFaux_base_is_neg_02(self):
        assert BASE_B_BY_TYPE["vraiFaux"] == -0.2

    def test_redaction_base_is_08(self):
        assert BASE_B_BY_TYPE["redaction"] == 0.8

    def test_all_question_types_covered(self):
        from config import QUESTION_TYPES

        for qtype in QUESTION_TYPES:
            assert qtype in BASE_B_BY_TYPE, f"missing base b for type: {qtype}"

    def test_constants_match_spec(self):
        assert POINTS_BONUS_5 == 0.3
        assert BAC_BONUS == 0.4
        assert SCIENTIFIC_SERIE_BONUS == 0.2
        assert NO_EXPLANATION_PENALTY == -0.1
        assert SCIENTIFIC_SERIES == {"C", "D"}


# ─── 2) estimate_b_heuristic : base par type ─────────────────────────────


class TestEstimateBHeuristicBase:
    """Heuristic returns the base b for each type (no bonus applied)."""

    def test_calcul_bepc_no_bonus(self):
        q = _q(qtype="calcul", examen="BEPC", points=4, explication="ok")
        # base 0.5, no points bonus (4 != 5), no BAC bonus, no serie bonus.
        assert estimate_b_heuristic(q) == 0.5

    def test_qcm_bepc_no_bonus(self):
        q = _q(qtype="qcm", examen="BEPC", points=2, explication="ok")
        assert estimate_b_heuristic(q) == 0.0

    def test_ouvert_bepc_no_bonus(self):
        q = _q(qtype="ouvert", examen="BEPC", points=3, explication="ok")
        assert estimate_b_heuristic(q) == 0.3

    def test_vraiFaux_bepc_no_bonus(self):
        q = _q(qtype="vraiFaux", examen="BEPC", points=1, explication="ok")
        assert estimate_b_heuristic(q) == -0.2

    def test_redaction_bepc_no_bonus(self):
        q = _q(qtype="redaction", examen="BEPC", points=6, explication="ok")
        assert estimate_b_heuristic(q) == 0.8

    def test_unknown_type_falls_back_to_default_03(self):
        """An unknown question type defaults to 0.3 (the 'ouvert' value)."""
        q = _q(qtype="unknownType", examen="BEPC", points=4, explication="ok")
        assert estimate_b_heuristic(q) == 0.3


# ─── 3) estimate_b_heuristic : ajustements ───────────────────────────────


class TestEstimateBHeuristicAdjustments:
    """All bonus/penalty adjustments combine linearly."""

    def test_points_5_adds_03(self):
        """points==5 -> +0.3 bonus."""
        q = _q(qtype="calcul", examen="BEPC", points=5, explication="ok")
        # 0.5 + 0.3 = 0.8
        assert estimate_b_heuristic(q) == 0.8

    def test_points_4_does_not_add_bonus(self):
        q = _q(qtype="calcul", examen="BEPC", points=4, explication="ok")
        assert estimate_b_heuristic(q) == 0.5

    def test_points_none_does_not_add_bonus(self):
        q = _q(qtype="calcul", examen="BEPC", points=None, explication="ok")
        assert estimate_b_heuristic(q) == 0.5

    def test_bac_adds_04(self):
        """BAC examen -> +0.4 bonus."""
        q = _q(qtype="calcul", examen="BAC1", points=4,
               serie="A", explication="ok")
        # 0.5 + 0.4 (BAC) = 0.9 (serie A is not scientific)
        assert estimate_b_heuristic(q) == 0.9

    def test_bac2_also_adds_04(self):
        """BAC2 should also receive the +0.4 bonus (starts with 'BAC')."""
        q = _q(qtype="calcul", examen="BAC2", points=4,
               serie="A", explication="ok")
        assert estimate_b_heuristic(q) == 0.9

    def test_bepc_does_not_add_bac_bonus(self):
        q = _q(qtype="calcul", examen="BEPC", points=4, explication="ok")
        assert estimate_b_heuristic(q) == 0.5  # no BAC bonus

    def test_serie_c_adds_02(self):
        """Serie C is scientific -> +0.2."""
        q = _q(qtype="calcul", examen="BAC1", points=4,
               serie="C", explication="ok")
        # 0.5 + 0.4 (BAC) + 0.2 (C) = 1.1
        assert estimate_b_heuristic(q) == 1.1

    def test_serie_d_adds_02(self):
        q = _q(qtype="calcul", examen="BAC1", points=4,
               serie="D", explication="ok")
        assert estimate_b_heuristic(q) == 1.1

    def test_serie_a_does_not_add_scientific_bonus(self):
        q = _q(qtype="calcul", examen="BAC1", points=4,
               serie="A", explication="ok")
        # 0.5 + 0.4 (BAC) = 0.9 (no scientific bonus for A)
        assert estimate_b_heuristic(q) == 0.9

    def test_serie_b_does_not_add_scientific_bonus(self):
        q = _q(qtype="calcul", examen="BAC1", points=4,
               serie="B", explication="ok")
        assert estimate_b_heuristic(q) == 0.9

    def test_no_explication_adds_penalty(self):
        """Empty explication -> -0.1 penalty."""
        q = _q(qtype="calcul", examen="BEPC", points=4, explication="")
        # 0.5 + (-0.1) = 0.4
        assert estimate_b_heuristic(q) == 0.4

    def test_whitespace_explication_treated_as_empty(self):
        q = _q(qtype="calcul", examen="BEPC", points=4, explication="   ")
        # 0.5 + (-0.1) = 0.4
        assert estimate_b_heuristic(q) == 0.4

    def test_none_explication_treated_as_empty(self):
        q = _q(qtype="calcul", examen="BEPC", points=4, explication=None)
        # 0.5 + (-0.1) = 0.4
        assert estimate_b_heuristic(q) == 0.4

    def test_full_stack_bac_calcul_5_points_serie_c_no_explication(self):
        """All bonuses/penalties combined:
        0.5 (calcul) + 0.3 (points=5) + 0.4 (BAC) + 0.2 (C) - 0.1 (no expl) = 1.3
        """
        q = _q(qtype="calcul", examen="BAC1", points=5,
               serie="C", explication="")
        assert estimate_b_heuristic(q) == 1.3

    def test_full_stack_bac_calcul_5_points_serie_c_with_explication(self):
        """Same as above but WITH explication:
        0.5 + 0.3 + 0.4 + 0.2 = 1.4
        """
        q = _q(qtype="calcul", examen="BAC1", points=5,
               serie="C", explication="ok")
        assert estimate_b_heuristic(q) == 1.4


# ─── 4) Validation range [-3, +3] (clamp) ────────────────────────────────


class TestEstimateBRange:
    """estimate_b_heuristic clamps the final b to [-3, +3]."""

    def test_normal_values_within_range(self):
        q = _q(qtype="calcul", examen="BEPC", points=4, explication="ok")
        b = estimate_b_heuristic(q)
        assert -3.0 <= b <= 3.0

    def test_extreme_positive_still_clamped(self):
        """Even with all bonuses applied, b stays within [-3, +3]."""
        q = _q(qtype="redaction", examen="BAC2", points=5,
               serie="D", explication="ok")
        b = estimate_b_heuristic(q)
        # 0.8 + 0.3 + 0.4 + 0.2 = 1.7 (within range)
        assert b == 1.7
        assert -3.0 <= b <= 3.0

    def test_extreme_negative_still_clamped(self):
        """All penalties combined (impossible in practice but tests clamp)."""
        # vraiFaux=-0.2, no points (None), no BAC, no serie, no explication
        q = _q(qtype="vraiFaux", examen="BEPC", points=None,
               serie=None, explication="")
        b = estimate_b_heuristic(q)
        # -0.2 + (-0.1) = -0.3
        assert b == -0.3
        assert -3.0 <= b <= 3.0

    def test_b_is_rounded_to_3_decimals(self):
        """The function rounds b to 3 decimal places."""
        q = _q(qtype="calcul", examen="BAC1", points=5,
               serie="C", explication="ok")
        b = estimate_b_heuristic(q)
        # 1.4 has at most 3 decimal places.
        assert round(b, 3) == b


# ─── 5) inv_norm ──────────────────────────────────────────────────────────


class TestInvNorm:
    """Inverse standard normal CDF (Beasley-Springer-Moro)."""

    def test_inv_norm_median_is_zero(self):
        assert abs(inv_norm(0.5)) < 0.01

    def test_inv_norm_84_percentile_is_plus_one(self):
        """inv_norm(0.8413) ~ 1.0 (84th percentile)."""
        assert abs(inv_norm(0.8413) - 1.0) < 0.05

    def test_inv_norm_16_percentile_is_minus_one(self):
        """inv_norm(0.1587) ~ -1.0 (16th percentile)."""
        assert abs(inv_norm(0.1587) - (-1.0)) < 0.05

    def test_inv_norm_monotonic_increasing(self):
        """inv_norm is monotonically increasing."""
        p1, p2, p3 = 0.1, 0.5, 0.9
        assert inv_norm(p1) < inv_norm(p2) < inv_norm(p3)

    def test_inv_norm_extremes_clamped(self):
        """p=0 and p=1 are clamped to avoid infinities."""
        assert math.isfinite(inv_norm(0.0))
        assert math.isfinite(inv_norm(1.0))

    def test_inv_norm_symmetric(self):
        """inv_norm(1 - p) = -inv_norm(p)."""
        for p in (0.1, 0.2, 0.3, 0.4):
            assert abs(inv_norm(1 - p) - (-inv_norm(p))) < 0.01


# ─── 6) estimate_b_from_success_rate ────────────────────────────────────


class TestEstimateBFromSuccessRate:
    """b = inv_norm(1 - success_rate)."""

    def test_high_success_rate_gives_easy_question(self):
        """80% success => b negative (facile)."""
        b = estimate_b_from_success_rate(0.8)
        assert b < 0

    def test_low_success_rate_gives_hard_question(self):
        """20% success => b positive (difficile)."""
        b = estimate_b_from_success_rate(0.2)
        assert b > 0

    def test_50_percent_success_gives_zero_b(self):
        """50% success => b ~ 0."""
        b = estimate_b_from_success_rate(0.5)
        assert abs(b) < 0.05

    def test_extreme_success_rates_are_finite(self):
        """Clamping via inv_norm ensures finite b."""
        assert math.isfinite(estimate_b_from_success_rate(0.0))
        assert math.isfinite(estimate_b_from_success_rate(1.0))

    def test_b_is_rounded_to_3_decimals(self):
        b = estimate_b_from_success_rate(0.8)
        assert round(b, 3) == b


# ─── 7) estimate_irt_for_questions ──────────────────────────────────────


class TestEstimateIrtForQuestions:
    """The driver fills irt.b on every question lacking it."""

    def test_sets_b_on_question_without_b(self):
        qs = [_q(qtype="calcul", examen="BEPC", points=4)]
        estimate_irt_for_questions(qs)
        assert qs[0]["irt"]["b"] is not None
        assert qs[0]["irt"]["b"] == 0.5

    def test_skips_question_with_b_already_set(self):
        qs = [_q(qtype="calcul", examen="BEPC", points=4)]
        qs[0]["irt"]["b"] = 0.99
        estimate_irt_for_questions(qs)
        assert qs[0]["irt"]["b"] == 0.99  # unchanged

    def test_creates_irt_dict_if_missing(self):
        qs = [{"id": "Q1", "type": "calcul", "examen": "BEPC",
               "points": 4, "serie": None, "explication": "ok"}]
        estimate_irt_for_questions(qs)
        assert isinstance(qs[0]["irt"], dict)
        assert qs[0]["irt"]["b"] is not None
        assert qs[0]["irt"]["calibre"] is False

    def test_uses_history_when_available(self):
        """When history has a success_rate for the question, b is derived
        from inv_norm(1 - rate)."""
        qs = [_q(qtype="calcul", examen="BEPC", points=4)]
        history = {qs[0]["id"]: 0.8}  # 80% success
        estimate_irt_for_questions(qs, history=history)
        # b should be ~ inv_norm(0.2) ~ -0.84
        assert qs[0]["irt"]["b"] < 0
        assert abs(qs[0]["irt"]["b"] - (-0.842)) < 0.05

    def test_history_takes_precedence_over_heuristic(self):
        qs = [_q(qtype="calcul", examen="BAC1", points=5,
                 serie="C", explication="ok")]
        # Heuristic would give 1.4 (hard).
        # History says 90% success => b ~ -1.28 (easy).
        history = {qs[0]["id"]: 0.9}
        estimate_irt_for_questions(qs, history=history)
        assert qs[0]["irt"]["b"] < 0

    def test_calibre_stays_false_after_estimation(self):
        """Estimation does NOT mark the question as 'calibre' (real calibration
        happens later via py-irt in the backend)."""
        qs = [_q(qtype="calcul", examen="BEPC", points=4)]
        estimate_irt_for_questions(qs)
        assert qs[0]["irt"]["calibre"] is False

    def test_a_and_c_stay_none_after_estimation(self):
        """Only b is estimated; a (discrimination) and c (chance) stay None
        until py-irt calibration runs."""
        qs = [_q(qtype="calcul", examen="BEPC", points=4)]
        estimate_irt_for_questions(qs)
        assert qs[0]["irt"]["a"] is None
        assert qs[0]["irt"]["c"] is None

    def test_empty_list_is_noop(self):
        qs: list = []
        estimate_irt_for_questions(qs)
        assert qs == []

    def test_returns_same_list_reference(self):
        """The function returns the mutated list (in-place + return)."""
        qs = [_q(qtype="calcul", examen="BEPC", points=4)]
        out = estimate_irt_for_questions(qs)
        assert out is qs

    def test_all_b_within_valid_range(self):
        """All estimated b values fall in [-3, +3]."""
        qs = [
            _q(qtype="calcul", examen="BAC1", points=5,
               serie="C", explication="ok"),
            _q(qtype="vraiFaux", examen="BEPC", points=1, explication=""),
            _q(qtype="redaction", examen="BAC2", points=5,
               serie="D", explication="ok"),
        ]
        estimate_irt_for_questions(qs)
        for q in qs:
            assert -3.0 <= q["irt"]["b"] <= 3.0


# ─── 8) load_history (CSV parsing) ───────────────────────────────────────


class TestLoadHistory:
    """load_history parses a CSV of question_id,n_attempts,n_correct."""

    def test_loads_valid_csv(self, tmp_path):
        csv_path = tmp_path / "history.csv"
        csv_path.write_text(
            "question_id,n_attempts,n_correct\n"
            "TG-BEPC-MATHS-2022-Q01,100,72\n"
            "TG-BEPC-MATHS-2022-Q02,50,10\n",
            encoding="utf-8",
        )
        history = load_history(csv_path)
        assert "TG-BEPC-MATHS-2022-Q01" in history
        assert history["TG-BEPC-MATHS-2022-Q01"] == 0.72
        assert history["TG-BEPC-MATHS-2022-Q02"] == 0.2

    def test_missing_file_returns_empty_dict(self, tmp_path):
        history = load_history(tmp_path / "nonexistent.csv")
        assert history == {}

    def test_zero_attempts_skipped(self, tmp_path):
        """Rows with n_attempts=0 are skipped (division by zero avoided)."""
        csv_path = tmp_path / "history.csv"
        csv_path.write_text(
            "question_id,n_attempts,n_correct\n"
            "TG-BEPC-MATHS-2022-Q01,0,0\n"
            "TG-BEPC-MATHS-2022-Q02,100,50\n",
            encoding="utf-8",
        )
        history = load_history(csv_path)
        assert "TG-BEPC-MATHS-2022-Q01" not in history
        assert "TG-BEPC-MATHS-2022-Q02" in history

    def test_invalid_rows_skipped(self, tmp_path):
        """Malformed rows (non-integer values) are silently skipped."""
        csv_path = tmp_path / "history.csv"
        csv_path.write_text(
            "question_id,n_attempts,n_correct\n"
            "TG-BEPC-MATHS-2022-Q01,not_a_number,50\n"
            "TG-BEPC-MATHS-2022-Q02,100,50\n",
            encoding="utf-8",
        )
        history = load_history(csv_path)
        assert "TG-BEPC-MATHS-2022-Q01" not in history
        assert "TG-BEPC-MATHS-2022-Q02" in history
