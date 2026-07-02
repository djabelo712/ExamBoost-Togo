"""
Tests unitaires pour la structuration JSON, la validation, la deduplication
et l'estimation IRT.

Aucun appel reseau : OpenAI est mocke. Les tests couvrent les regles metier
qui doivent rester stables (BEPC -> serie null, QCM -> choix, format d'id,
normalisation pour dedup, etc.).
"""

from __future__ import annotations

import json
import math
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


# ─── Extensions: structure_one_file, normalize edge cases ─────────────────


def test_parse_ocr_filename_bepc_toutes_series():
    """BEPC files use 'TOUTES' which is normalized to None."""
    meta = parse_ocr_filename("banquedesepreuves_BEPC_Histoire Geographie_2020_TOUTES.txt")
    assert meta["source"] == "banquedesepreuves"
    assert meta["examen"] == "BEPC"
    assert meta["matiere"] == "Histoire Geographie"
    assert meta["annee"] == 2020
    assert meta["serie"] is None


def test_parse_ocr_filename_bac2_serie_d():
    meta = parse_ocr_filename("epreuvesetcorriges_BAC2_Sciences Physiques_2022_D.txt")
    assert meta["examen"] == "BAC2"
    assert meta["serie"] == "D"
    assert meta["matiere"] == "Sciences Physiques"
    assert meta["annee"] == 2022


def test_parse_ocr_filename_probatoire():
    meta = parse_ocr_filename("epreuvesetcorriges_Probatoire_Mathematiques_2023_C.txt")
    assert meta["examen"] == "Probatoire"
    assert meta["serie"] == "C"


def test_parse_ocr_filename_no_serie_for_bepc():
    """BEPC filenames may omit the serie part entirely."""
    meta = parse_ocr_filename("epreuvesetcorriges_BEPC_Francais_2021.txt")
    assert meta is not None
    assert meta["examen"] == "BEPC"
    assert meta["serie"] is None


def test_parse_ocr_filename_rejects_bad_examen():
    """An unknown examen keyword returns None."""
    assert parse_ocr_filename("src_CONCOURS_Mathematiques_2022_C.txt") is None


def test_parse_ocr_filename_rejects_missing_year():
    assert parse_ocr_filename("src_BEPC_Mathematiques_C.txt") is None


def test_parse_ocr_filename_rejects_wrong_extension():
    assert parse_ocr_filename("src_BEPC_Mathematiques_2022_C.json") is None


def test_normalize_questions_assigns_sequential_ids():
    """normalize_questions rebuilds ids with sequential Q01, Q02, ..."""
    raw = [
        {"enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
         "chapitre": "C1", "examen": "BEPC", "annee": 2022, "type": "calcul",
         "choix": None, "points": 4, "irt": {}},
        {"enonce": "Q2 enonce", "reponse": "r2", "matiere": "Mathématiques",
         "chapitre": "C2", "examen": "BEPC", "annee": 2022, "type": "calcul",
         "choix": None, "points": 4, "irt": {}},
        {"enonce": "Q3 enonce", "reponse": "r3", "matiere": "Mathématiques",
         "chapitre": "C3", "examen": "BEPC", "annee": 2022, "type": "calcul",
         "choix": None, "points": 4, "irt": {}},
    ]
    out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
    ids = [q["id"] for q in out]
    assert ids == [
        "TG-BEPC-MATHS-2022-Q01",
        "TG-BEPC-MATHS-2022-Q02",
        "TG-BEPC-MATHS-2022-Q03",
    ]


def test_normalize_questions_filters_non_dict_entries():
    """Non-dict entries (strings, None) in raw_questions are skipped."""
    raw = [
        {"enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
         "chapitre": "C1", "examen": "BEPC", "annee": 2022, "type": "calcul",
         "choix": None, "points": 4, "irt": {}},
        "not a dict",
        None,
        42,
    ]
    out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
    assert len(out) == 1


def test_normalize_questions_forces_bepc_serie_null():
    """Even if the LLM returns a serie for BEPC, normalize_questions
    forces it to None (authoritative metadata wins)."""
    raw = [{
        "enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
        "chapitre": "C1", "examen": "BEPC", "annee": 2022, "type": "calcul",
        "choix": None, "points": 4, "serie": "C",  # LLM hallucinated serie
        "irt": {},
    }]
    out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
    assert out[0]["serie"] is None


def test_normalize_questions_bac_keeps_provided_serie():
    """For BAC, normalize_questions uses the serie from the filename."""
    raw = [{
        "enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
        "chapitre": "C1", "examen": "BAC1", "annee": 2023, "type": "calcul",
        "choix": None, "points": 4,
        "irt": {},
    }]
    out = normalize_questions(raw, "BAC1", "Mathématiques", 2023, "D")
    assert out[0]["serie"] == "D"


def test_normalize_questions_bac_falls_back_to_llm_serie():
    """If the filename has no serie but the LLM provided one, use it."""
    raw = [{
        "enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
        "chapitre": "C1", "examen": "BAC1", "annee": 2023, "type": "calcul",
        "choix": None, "points": 4, "serie": "C",
        "irt": {},
    }]
    out = normalize_questions(raw, "BAC1", "Mathématiques", 2023, None)
    assert out[0]["serie"] == "C"


def test_normalize_questions_clears_choix_for_non_qcm_types():
    """For 'calcul' / 'ouvert' / 'redaction' types, choix is forced to None."""
    for qtype in ("calcul", "ouvert", "redaction"):
        raw = [{
            "enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
            "chapitre": "C1", "examen": "BEPC", "annee": 2022, "type": qtype,
            "choix": ["A", "B", "C", "D"],  # should be cleared
            "points": 4, "irt": {},
        }]
        out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
        assert out[0]["choix"] is None


def test_normalize_questions_keeps_choix_for_qcm():
    raw = [{
        "enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
        "chapitre": "C1", "examen": "BEPC", "annee": 2022, "type": "qcm",
        "choix": ["A", "B", "C", "D"],
        "points": 4, "irt": {},
    }]
    out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
    assert out[0]["choix"] == ["A", "B", "C", "D"]


def test_normalize_questions_clears_choix_when_qcm_has_empty_list():
    """QCM with empty choix => set to None (avoids validation failure)."""
    raw = [{
        "enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
        "chapitre": "C1", "examen": "BEPC", "annee": 2022, "type": "qcm",
        "choix": [],
        "points": 4, "irt": {},
    }]
    out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
    assert out[0]["choix"] is None


def test_normalize_questions_ensures_irt_dict_keys():
    """If irt is partially filled, normalize_questions ensures all 4 keys
    are present (a, b, c, calibre)."""
    raw = [{
        "enonce": "Q1 enonce", "reponse": "r1", "matiere": "Mathématiques",
        "chapitre": "C1", "examen": "BEPC", "annee": 2022, "type": "calcul",
        "choix": None, "points": 4,
        "irt": {"b": 0.5},  # missing a, c, calibre
    }]
    out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
    irt = out[0]["irt"]
    assert set(irt.keys()) == {"a", "b", "c", "calibre"}
    assert irt["b"] == 0.5  # preserved
    assert irt["a"] is None
    assert irt["c"] is None
    assert irt["calibre"] is False


def test_structure_one_file_unparsable_filename_returns_empty(tmp_path):
    """structure_one_file returns ([], []) when the filename is not parsable."""
    from structure_questions import structure_one_file

    bad = tmp_path / "random_file.txt"
    bad.write_text("some OCR text", encoding="utf-8")
    valid, invalid = structure_one_file(bad)
    assert valid == []
    assert invalid == []


def test_structure_one_file_empty_text_returns_empty(tmp_path, monkeypatch):
    """When the OCR text file is empty, structure_one_file returns ([], [])."""
    from structure_questions import structure_one_file

    # Patch is_openai_configured so we don't raise OpenAIConfigError early.
    import structure_questions as struct_mod
    monkeypatch.setattr(struct_mod, "is_openai_configured", lambda: True)

    f = tmp_path / "src_BEPC_Mathematiques_2022.txt"
    f.write_text("   \n  \n   ", encoding="utf-8")
    valid, invalid = structure_one_file(f)
    assert valid == []
    assert invalid == []


def test_structure_one_file_raises_when_openai_not_configured(
    tmp_path, monkeypatch,
):
    """When OpenAI is not configured, structure_one_file raises
    OpenAIConfigError (instead of silently producing nothing)."""
    from structure_questions import structure_one_file
    import structure_questions as struct_mod
    from utils.openai_utils import OpenAIConfigError

    monkeypatch.setattr(struct_mod, "is_openai_configured", lambda: False)

    f = tmp_path / "src_BEPC_Mathematiques_2022.txt"
    f.write_text("OCR text content", encoding="utf-8")

    with pytest.raises(OpenAIConfigError):
        structure_one_file(f)


def test_structure_one_file_with_mocked_openai(tmp_path, monkeypatch):
    """Full structure_one_file flow with a mocked OpenAI client."""
    from structure_questions import structure_one_file
    import structure_questions as struct_mod

    monkeypatch.setattr(struct_mod, "is_openai_configured", lambda: True)

    # Mock openai_structure_questions to return raw questions.
    # NOTE: matiere must match an entry in MATIERES (with accents), and
    # competence_id is required by the schema.
    raw_questions = [{
        "enonce": "Calculer 2+2 (enonce de test suffisamment long)",
        "reponse": "4",
        "explication": "car 2+2=4",
        "matiere": "Mathématiques",
        "chapitre": "Additions",
        "competence_id": "TG-MATHS-ADD-001",
        "examen": "BEPC",
        "annee": 2022,
        "type": "calcul",
        "choix": None,
        "points": 4,
        "irt": {},
    }]
    monkeypatch.setattr(
        struct_mod,
        "openai_structure_questions",
        lambda **kw: raw_questions,
    )

    # Patch PATHS.structured_questions so save_questions writes to tmp.
    from config import Paths
    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.structured_questions.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(struct_mod, "PATHS", fake_paths)
    # json_utils also imported PATHS at top-level? No, it imports from config.
    # save_questions uses the path arg directly, so we're fine.

    f = tmp_path / "src_BEPC_Mathématiques_2022.txt"
    f.write_text("OCR text content for the structure phase", encoding="utf-8")

    valid, invalid = structure_one_file(f)
    assert len(valid) == 1
    assert valid[0]["id"] == "TG-BEPC-MATHS-2022-Q01"
    assert valid[0]["serie"] is None
    assert invalid == []

    # Verify the output JSON file was saved.
    out_files = list(fake_paths.structured_questions.glob("*.json"))
    assert len(out_files) == 1
    assert "2022_Mathématiques" in out_files[0].name


def test_structure_one_file_separates_invalid(tmp_path, monkeypatch):
    """When the LLM returns a question with a short enonce (invalid), it
    goes to the invalid list and is saved in a separate _invalid.json file."""
    from structure_questions import structure_one_file
    import structure_questions as struct_mod

    monkeypatch.setattr(struct_mod, "is_openai_configured", lambda: True)

    raw_questions = [
        # Valid question.
        {
            "enonce": "Calculer 2+2 (enonce de test suffisamment long)",
            "reponse": "4", "explication": "ok",
            "matiere": "Mathématiques", "chapitre": "Additions",
            "competence_id": "TG-MATHS-ADD-001",
            "examen": "BEPC", "annee": 2022, "type": "calcul",
            "choix": None, "points": 4, "irt": {},
        },
        # Invalid: short enonce (< 10 chars).
        {
            "enonce": "ok",  # too short
            "reponse": "6", "explication": "ok",
            "matiere": "Mathématiques", "chapitre": "Additions",
            "competence_id": "TG-MATHS-ADD-002",
            "examen": "BEPC", "annee": 2022, "type": "calcul",
            "choix": None, "points": 4, "irt": {},
        },
    ]
    monkeypatch.setattr(
        struct_mod,
        "openai_structure_questions",
        lambda **kw: raw_questions,
    )

    from config import Paths
    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.structured_questions.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(struct_mod, "PATHS", fake_paths)

    f = tmp_path / "src_BEPC_Mathématiques_2022.txt"
    f.write_text("OCR text", encoding="utf-8")

    valid, invalid = structure_one_file(f)
    assert len(valid) == 1
    assert len(invalid) == 1
    assert invalid[0]["enonce"] == "ok"
    assert "_validation_errors" in invalid[0]

    # Both valid and invalid output files should exist.
    out_files = sorted(
        fake_paths.structured_questions.glob("*.json"),
        key=lambda p: p.name,
    )
    # 1 valid + 1 _invalid.
    assert len(out_files) == 2
    invalid_files = [f for f in out_files if "_invalid" in f.name]
    assert len(invalid_files) == 1


# ─── Extensions: completeness_score edge cases ────────────────────────────


def test_completeness_score_with_partial_irt():
    """irt dict present but b=None => irt score NOT awarded."""
    q = {
        "enonce": "x", "reponse": "4", "explication": "ok",
        "points": 4, "irt": {"b": None},
    }
    assert completeness_score(q) == 4


def test_completeness_score_with_none_values():
    """points=None => points score NOT awarded."""
    q = {
        "enonce": "x", "reponse": "4", "explication": "ok",
        "points": None,
    }
    assert completeness_score(q) == 3


# ─── Extensions: deduplicate cluster edge cases ───────────────────────────


def test_deduplicate_three_distinct_topics_no_clusters():
    qs = [
        _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4."),
        _make_q("Q2", "Quelle est la capitale du Togo en Afrique ?"),
        _make_q("Q3", "Definir la photosynthese chez les vegetaux verts."),
    ]
    kept, result = deduplicate_questions(qs)
    assert len(kept) == 3
    assert result.clusters == []
    assert result.duplicates_dropped == 0


def test_deduplicate_preserves_question_dict_reference():
    """The kept question is the SAME dict object as the input (not a copy)."""
    q = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
    kept, _ = deduplicate_questions([q])
    assert kept[0] is q


# ─── Extensions: inv_norm extreme values ─────────────────────────────────


def test_inv_norm_extreme_values_are_finite():
    """inv_norm(0.001) and inv_norm(0.999) should both be finite (clamped)."""
    assert math.isfinite(inv_norm(0.001))
    assert math.isfinite(inv_norm(0.999))
    # inv_norm(0.001) is very negative; inv_norm(0.999) very positive.
    assert inv_norm(0.001) < -2.0
    assert inv_norm(0.999) > 2.0


def test_inv_norm_extreme_clamping_does_not_return_inf():
    """p=0 and p=1 would normally return -inf and +inf; the function clamps."""
    assert inv_norm(0.0) == inv_norm(0.001)  # both clamped
    assert inv_norm(1.0) == inv_norm(0.999)


# ─── Extensions: estimate_irt_for_questions with mixed states ────────────


def test_estimate_irt_for_questions_mixed_states():
    """A list with one already-set b and one missing b: only the latter is
    modified."""
    qs = [
        {"id": "Q1", "type": "calcul", "examen": "BEPC", "points": 4,
         "serie": None, "explication": "ok",
         "irt": {"a": None, "b": 0.99, "c": None, "calibre": False}},
        {"id": "Q2", "type": "calcul", "examen": "BEPC", "points": 4,
         "serie": None, "explication": "ok",
         "irt": {"a": None, "b": None, "c": None, "calibre": False}},
    ]
    estimate_irt_for_questions(qs)
    assert qs[0]["irt"]["b"] == 0.99  # unchanged
    assert qs[1]["irt"]["b"] is not None  # newly estimated
    assert qs[1]["irt"]["b"] == 0.5  # heuristic for BEPC calcul no bonus
