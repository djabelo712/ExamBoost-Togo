"""
Tests unitaires pour la structuration JSON, la validation, la deduplication
et l'estimation IRT.

Aucun appel reseau : OpenAI est mocke. Les tests couvrent les regles metier
qui doivent rester stables (BEPC -> serie null, QCM -> choix, format d'id,
normalisation pour dedup, etc.).
"""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from deduplicate import (
    completeness_score,
    deduplicate_questions,
)
from estimate_irt import (
    BASE_B_BY_TYPE,
    estimate_b_from_success_rate,
    estimate_b_heuristic,
    estimate_irt_for_questions,
    inv_norm,
)
from structure_questions import (
    normalize_questions,
    parse_ocr_filename,
)
from utils.json_utils import (
    build_question_id,
    is_valid_id,
    normalize_enonce,
    validate_question_dict,
    validate_question_list,
)
from validate_questions import find_duplicates, is_suspect


# ─── build_question_id ────────────────────────────────────────────────────


def test_build_question_id_bepc():
    qid = build_question_id("BEPC", "Mathématiques", 2022, 1)
    assert qid == "TG-BEPC-MATHS-2022-Q01"


def test_build_question_id_bac_with_serie():
    """BAC1/BAC2 -> prefix "BAC" dans l'id; Maths serie C -> MATHC."""
    qid = build_question_id("BAC1", "Mathématiques", 2023, 1, serie="C")
    assert qid == "TG-BAC-MATHC-2023-Q01"


def test_build_question_id_bac2_mathd():
    qid = build_question_id("BAC2", "Mathématiques", 2022, 3, serie="D")
    assert qid == "TG-BAC-MATHD-2022-Q03"


def test_build_question_id_bac_physics_no_serie_suffix():
    """Pour les matieres non-Maths en BAC, on ne suffixe pas par la serie."""
    qid = build_question_id("BAC1", "Sciences Physiques", 2023, 1, serie="C")
    assert qid == "TG-BAC-PHYS-2023-Q01"


def test_is_valid_id_accepts_bac_prefix():
    assert is_valid_id("TG-BAC-MATHC-2023-Q01") is True
    assert is_valid_id("TG-BAC-PHYS-2023-Q01") is True


def test_build_question_id_bac_without_serie():
    """Sans serie, on n'ajoute pas de suffixe."""
    qid = build_question_id("BAC1", "Français", 2022, 5)
    assert qid == "TG-BAC-FR-2022-Q05"


def test_is_valid_id_canonical():
    assert is_valid_id("TG-BEPC-MATHS-2022-Q01") is True
    assert is_valid_id("TG-BAC1-MATHC-2023-Q12") is True


def test_is_valid_id_rejects_bad_format():
    assert is_valid_id("question-1") is False
    assert is_valid_id("TG-BEPC-MATHS-2022-Q1") is False  # Q01 minimum
    assert is_valid_id("") is False


# ─── normalize_enonce ─────────────────────────────────────────────────────


def test_normalize_enonce_strips_accents_and_punct():
    raw = "Calcule l'aire du triangle ABC !"
    out = normalize_enonce(raw)
    assert "'" not in out
    assert "!" not in out
    assert "calcule" in out and "aire" in out
    assert "e" not in out.split()  # pas d'accent residuel


def test_normalize_enonce_handles_empty():
    assert normalize_enonce("") == ""


def test_normalize_enonce_is_case_insensitive():
    assert normalize_enonce("ABC") == normalize_enonce("abc")


# ─── validate_question_dict ───────────────────────────────────────────────


VALID_BEPC_Q = {
    "id": "TG-BEPC-MATHS-2022-Q01",
    "enonce": "Resoudre l'equation 3x + 7 = 22",
    "reponse": "x = 5",
    "explication": "On soustrait 7 puis on divise par 3.",
    "matiere": "Mathématiques",
    "chapitre": "Equations 1er degre",
    "competence_id": "TG-MATHS-EQ1D-001",
    "examen": "BEPC",
    "serie": None,
    "annee": 2022,
    "type": "calcul",
    "choix": None,
    "points": 4,
    "irt": {"a": None, "b": -0.5, "c": None, "calibre": False},
}


def test_validate_question_valid():
    ok, errs = validate_question_dict(VALID_BEPC_Q.copy())
    assert ok, errs


def test_validate_question_bepc_with_serie_is_invalid():
    q = VALID_BEPC_Q.copy()
    q["serie"] = "C"
    ok, errs = validate_question_dict(q)
    assert not ok
    assert any("BEPC ne doit pas avoir de serie" in e for e in errs)


def test_validate_question_bac_without_serie_is_invalid():
    q = VALID_BEPC_Q.copy()
    q["examen"] = "BAC1"
    q["id"] = "TG-BAC1-MATHS-2022-Q01"
    ok, errs = validate_question_dict(q)
    assert not ok
    assert any("BAC doit avoir une serie" in e for e in errs)


def test_validate_question_qcm_without_choix_is_invalid():
    q = VALID_BEPC_Q.copy()
    q["type"] = "qcm"
    q["choix"] = None
    ok, errs = validate_question_dict(q)
    assert not ok
    assert any("QCM doit avoir" in e for e in errs)


def test_validate_question_qcm_with_2_choix_ok():
    q = VALID_BEPC_Q.copy()
    q["type"] = "qcm"
    q["choix"] = ["A", "B"]
    ok, errs = validate_question_dict(q)
    assert ok, errs


def test_validate_question_short_enonce_invalid():
    q = VALID_BEPC_Q.copy()
    q["enonce"] = "ok"
    ok, errs = validate_question_dict(q)
    assert not ok
    assert any("enonce trop court" in e for e in errs)


def test_validate_question_unknown_matiere_invalid():
    q = VALID_BEPC_Q.copy()
    q["matiere"] = "Astronomie"
    ok, errs = validate_question_dict(q)
    assert not ok


def test_validate_question_list_splits():
    invalid_q = VALID_BEPC_Q.copy()
    invalid_q["id"] = "bad-id"
    valid, invalid = validate_question_list([VALID_BEPC_Q.copy(), invalid_q])
    assert len(valid) == 1
    assert len(invalid) == 1


# ─── parse_ocr_filename ───────────────────────────────────────────────────


def test_parse_ocr_filename_bepc():
    meta = parse_ocr_filename("epreuvesetcorriges_BEPC_Mathematiques_2022_TOUTES.txt")
    assert meta == {
        "source": "epreuvesetcorriges",
        "examen": "BEPC",
        "matiere": "Mathematiques",
        "annee": 2022,
        "serie": None,
    }


def test_parse_ocr_filename_bac_with_serie():
    meta = parse_ocr_filename("epreuvesetcorriges_BAC1_Mathematiques_2023_C.txt")
    assert meta["examen"] == "BAC1"
    assert meta["serie"] == "C"
    assert meta["annee"] == 2023


def test_parse_ocr_filename_bad_returns_none():
    assert parse_ocr_filename("random_file.txt") is None


# ─── normalize_questions ──────────────────────────────────────────────────


def test_normalize_questions_forces_canonical_id():
    raw = [{
        "enonce": "Calcule 2+2",
        "reponse": "4",
        "matiere": "Mathématiques",
        "chapitre": "Additions",
        "examen": "BEPC",
        "annee": 2022,
        "type": "calcul",
        "choix": None,
        "points": 2,
        "irt": {},
    }]
    out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
    assert out[0]["id"] == "TG-BEPC-MATHS-2022-Q01"
    assert out[0]["serie"] is None
    assert out[0]["irt"]["calibre"] is False


def test_normalize_questions_bac_with_serie():
    raw = [{
        "enonce": "Soit f continue...",
        "reponse": "...",
        "matiere": "Mathématiques",
        "chapitre": "Continuite",
        "examen": "BAC1",
        "annee": 2023,
        "type": "ouvert",
        "choix": None,
        "points": 4,
    }]
    out = normalize_questions(raw, "BAC1", "Mathématiques", 2023, "C")
    assert out[0]["id"] == "TG-BAC-MATHC-2023-Q01"
    assert out[0]["serie"] == "C"


# ─── Deduplication ────────────────────────────────────────────────────────


def _make_q(qid, enonce, points=4, explication=""):
    return {
        "id": qid,
        "enonce": enonce,
        "reponse": "reponse",
        "explication": explication,
        "matiere": "Mathématiques",
        "chapitre": "Test",
        "competence_id": "TG-MATHS-TEST-001",
        "examen": "BEPC",
        "serie": None,
        "annee": 2022,
        "type": "calcul",
        "choix": None,
        "points": points,
        "irt": {"a": None, "b": None, "c": None, "calibre": False},
    }


def test_completeness_score_max_5():
    q = _make_q("TG-BEPC-MATHS-2022-Q01", "Calculer 2+2", points=4,
                explication="explication")
    q["irt"]["b"] = 0.5
    assert completeness_score(q) == 5


def test_completeness_score_min_1():
    q = {"enonce": "x"}
    assert completeness_score(q) == 1


def test_deduplicate_drops_near_duplicates():
    qs = [
        _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4."),
        _make_q("Q2", "Calculer la somme 1+2+3+4."),  # quasi identique
        _make_q("Q3", "Quelle est la capitale du Togo ?"),
    ]
    kept, result = deduplicate_questions(qs)
    assert result.input_count == 3
    assert result.output_count == 2  # Q1 ou Q2 + Q3
    assert result.duplicates_dropped == 1


def test_deduplicate_keeps_most_complete():
    """Sur deux doublons, on garde la version avec explication."""
    qs = [
        _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.", points=None, explication=""),
        _make_q("Q2", "Calculer la somme 1 + 2 + 3 + 4.", points=4, explication="explication"),
    ]
    kept, _ = deduplicate_questions(qs)
    assert len(kept) == 1
    assert kept[0]["id"] == "Q2"


# ─── Validation extras (suspects, find_duplicates) ────────────────────────


def test_find_duplicates_groups_normalized_enonce():
    qs = [
        _make_q("Q1", "Calcule 2+2."),
        _make_q("Q2", "Calcule 2 + 2."),  # meme normalise
        _make_q("Q3", "Quelle est la capitale du Togo ?"),
    ]
    groups, total = find_duplicates(qs)
    assert total == 1
    assert len(groups) == 1
    assert len(groups[0]) == 2


def test_is_suspect_flags_short_enonce():
    q = _make_q("Q1", "ok")
    reasons = is_suspect(q)
    assert any("enonce_court" in r for r in reasons)


def test_is_suspect_flags_missing_explication():
    q = _make_q("Q1", "Calculer 2+2", explication="")
    reasons = is_suspect(q)
    assert "explication_manquante" in reasons


def test_is_suspect_clean_question():
    q = _make_q("Q1", "Calculer 2+2", points=4, explication="explication")
    q["irt"]["b"] = 0.5
    reasons = is_suspect(q)
    assert reasons == []


# ─── Estimation IRT ───────────────────────────────────────────────────────


def test_inv_norm_basic_values():
    """inv_norm(0.5) ~ 0, inv_norm(0.84) ~ 1, inv_norm(0.16) ~ -1."""
    assert abs(inv_norm(0.5)) < 0.01
    assert abs(inv_norm(0.8413) - 1.0) < 0.05
    assert abs(inv_norm(0.1587) - (-1.0)) < 0.05


def test_estimate_b_from_success_rate_easy_question():
    """Taux de reussite eleve => b negatif (question facile)."""
    b = estimate_b_from_success_rate(0.9)
    assert b < 0


def test_estimate_b_from_success_rate_hard_question():
    """Taux de reussite faible => b positif (question difficile)."""
    b = estimate_b_from_success_rate(0.1)
    assert b > 0


def test_estimate_b_heuristic_bepc_calcul():
    q = {"type": "calcul", "examen": "BEPC", "points": 4, "serie": None, "explication": "ok"}
    b = estimate_b_heuristic(q)
    # base 0.5 (calcul), pas de bonus points (4 != 5), pas de bonus BAC.
    assert b == 0.5


def test_estimate_b_heuristic_bac_serie_c_high_points():
    q = {"type": "calcul", "examen": "BAC1", "points": 5, "serie": "C", "explication": "ok"}
    b = estimate_b_heuristic(q)
    # 0.5 (calcul) + 0.3 (points 5) + 0.4 (BAC) + 0.2 (serie C) = 1.4
    assert b == 1.4


def test_estimate_irt_for_questions_sets_b():
    qs = [
        {"id": "TG-BEPC-MATHS-2022-Q01", "type": "calcul",
         "examen": "BEPC", "points": 4, "serie": None, "explication": "ok",
         "irt": {"a": None, "b": None, "c": None, "calibre": False}},
    ]
    estimate_irt_for_questions(qs)
    assert qs[0]["irt"]["b"] is not None
    assert qs[0]["irt"]["calibre"] is False  # estimation, pas calibration reelle


def test_estimate_irt_skips_already_set_b():
    qs = [{
        "id": "TG-BEPC-MATHS-2022-Q01",
        "type": "calcul", "examen": "BEPC", "points": 4, "serie": None,
        "explication": "ok",
        "irt": {"a": None, "b": 0.99, "c": None, "calibre": False},
    }]
    estimate_irt_for_questions(qs)
    assert qs[0]["irt"]["b"] == 0.99  # non ecrase


def test_estimate_irt_uses_history_when_available():
    qs = [{
        "id": "TG-BEPC-MATHS-2022-Q01",
        "type": "calcul", "examen": "BEPC", "points": 4, "serie": None,
        "explication": "ok",
        "irt": {"a": None, "b": None, "c": None, "calibre": False},
    }]
    history = {"TG-BEPC-MATHS-2022-Q01": 0.8}  # 80% de reussite
    estimate_irt_for_questions(qs, history=history)
    # b doit etre ~ inv_norm(0.2) ~ -0.84
    assert qs[0]["irt"]["b"] < 0
    assert abs(qs[0]["irt"]["b"] - (-0.842)) < 0.05
