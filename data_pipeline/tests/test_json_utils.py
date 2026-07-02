"""
Tests unitaires pour utils/json_utils.py.

Couvre:
    - Schema JSON Schema (Draft 7) validation.
    - build_question_id / is_valid_id (canonical id format).
    - normalize_enonce (lowercase, accents, punctuation, whitespace).
    - validate_question_dict (schema + coherence + qualite).
    - validate_question_list (partition valid/invalid).
    - load_questions / save_questions (round-trip, formats acceptes).
    - merge_questions (concatenation).
    - QuestionSchemaError (exception type).

Aucun appel reseau. Les I/O utilisent tmp_path (pytest fixture).
"""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any, Dict

import pytest

from utils.json_utils import (
    QUESTION_JSON_SCHEMA,
    QuestionSchemaError,
    build_question_id,
    is_valid_id,
    load_questions,
    merge_questions,
    normalize_enonce,
    save_questions,
    validate_question_dict,
    validate_question_list,
)


# ─── build_question_id ───────────────────────────────────────────────────


class TestBuildQuestionId:
    """Canonical id builder for BEPC and BAC examens."""

    def test_bepc_maths_2022_q01(self):
        assert build_question_id(
            "BEPC", "Mathématiques", 2022, 1,
        ) == "TG-BEPC-MATHS-2022-Q01"

    def test_bepc_francais_2021_q10(self):
        assert build_question_id(
            "BEPC", "Français", 2021, 10,
        ) == "TG-BEPC-FR-2021-Q10"

    def test_bac1_maths_serie_c(self):
        assert build_question_id(
            "BAC1", "Mathématiques", 2023, 1, serie="C",
        ) == "TG-BAC-MATHC-2023-Q01"

    def test_bac2_maths_serie_d(self):
        assert build_question_id(
            "BAC2", "Mathématiques", 2022, 3, serie="D",
        ) == "TG-BAC-MATHD-2022-Q03"

    def test_bac_physics_no_serie_suffix(self):
        """Non-Maths BAC subjects do not get a serie suffix in the code."""
        assert build_question_id(
            "BAC1", "Sciences Physiques", 2023, 1, serie="C",
        ) == "TG-BAC-PHYS-2023-Q01"

    def test_bac_svt_no_serie_suffix(self):
        assert build_question_id(
            "BAC2", "Sciences de la Vie et de la Terre", 2022, 5, serie="D",
        ) == "TG-BAC-SVT-2022-Q05"

    def test_bac_without_serie(self):
        assert build_question_id(
            "BAC1", "Français", 2022, 5,
        ) == "TG-BAC-FR-2022-Q05"

    def test_q_number_zero_padded_to_two_digits(self):
        assert build_question_id(
            "BEPC", "Mathématiques", 2022, 1,
        ) == "TG-BEPC-MATHS-2022-Q01"
        assert build_question_id(
            "BEPC", "Mathématiques", 2022, 99,
        ) == "TG-BEPC-MATHS-2022-Q99"

    def test_q_number_three_digits_for_100_plus(self):
        # The format string is Q{q:02d} which produces 3 digits for q=100.
        qid = build_question_id("BEPC", "Mathématiques", 2022, 100)
        assert qid == "TG-BEPC-MATHS-2022-Q100"

    def test_unknown_matiere_uses_gen_code(self):
        """Unknown matieres fall back to the 'GEN' (generic) code."""
        qid = build_question_id("BEPC", "Astronomie", 2022, 1)
        assert qid == "TG-BEPC-GEN-2022-Q01"


# ─── is_valid_id ─────────────────────────────────────────────────────────


class TestIsValidId:
    """is_valid_id checks the canonical id regex."""

    @pytest.mark.parametrize(
        "qid",
        [
            "TG-BEPC-MATHS-2022-Q01",
            "TG-BEPC-FR-2021-Q10",
            "TG-BAC-MATHC-2023-Q01",
            "TG-BAC-MATHD-2022-Q03",
            "TG-BAC-PHYS-2023-Q01",
            "TG-BAC1-MATHC-2023-Q12",
            "TG-BAC2-MATHS-2022-Q99",
            "TG-Probatoire-MATHS-2020-Q01",
        ],
    )
    def test_accepts_valid_ids(self, qid):
        assert is_valid_id(qid) is True

    @pytest.mark.parametrize(
        "qid",
        [
            "",
            "question-1",
            "TG-BEPC-MATHS-2022-Q1",      # Q1 needs at least 2 digits
            "TG-BEPC-MATHS-22-Q01",        # year must be 4 digits
            "TG-BEPC-MATHS-2022-Q9999",    # too many digits
            "TG-BEPC-MATHS-2022-",         # missing Q part
            "TG-BEPC-MATHS-2022",          # missing Q part
            "TG-XXX-MATHS-2022-Q01",       # unknown examen
            "TG-BEPC-maths-2022-Q01",      # lowercase matiere code
            "tg-bepc-maths-2022-q01",      # lowercase prefix
        ],
    )
    def test_rejects_invalid_ids(self, qid):
        assert is_valid_id(qid) is False


# ─── normalize_enonce ────────────────────────────────────────────────────


class TestNormalizeEnonce:
    """normalize_enonce prepares the enonce for hashing/dedup."""

    def test_lowercases(self):
        assert normalize_enonce("ABCDEF") == "abcdef"

    def test_strips_accents(self):
        out = normalize_enonce("Calculer l'aire d'un triangle équilatéral")
        # No combining diacritics remain.
        assert "é" not in out
        assert "è" not in out
        assert "ê" not in out
        assert "à" not in out

    def test_removes_punctuation(self):
        out = normalize_enonce("Calcule ! L'aire, du triangle ?")
        assert "!" not in out
        assert "?" not in out
        assert "," not in out
        # Apostrophe is punctuation too.
        assert "'" not in out

    def test_collapses_whitespace(self):
        out = normalize_enonce("a    b\t\tc\n\nd")
        assert "  " not in out
        assert "\t" not in out
        assert "\n" not in out

    def test_empty_returns_empty(self):
        assert normalize_enonce("") == ""

    def test_whitespace_only_returns_empty(self):
        assert normalize_enonce("   \t\n  ") == ""

    def test_case_insensitive(self):
        assert normalize_enonce("ABC") == normalize_enonce("abc")

    def test_normalization_idempotent(self):
        """Normalizing twice gives the same result."""
        raw = "Calculer l'aire du triangle ABC !"
        once = normalize_enonce(raw)
        twice = normalize_enonce(once)
        assert once == twice

    def test_strips_digits_safe(self):
        r"""Digits are preserved (the regex `[^\w\s]` keeps word chars)."""
        out = normalize_enonce("Calculer 2+2")
        assert "2" in out


# ─── validate_question_dict ──────────────────────────────────────────────


class TestValidateQuestionDict:
    """validate_question_dict combines schema + coherence + qualite rules."""

    def test_valid_bepc_question(self, valid_bepc_q):
        ok, errs = validate_question_dict(valid_bepc_q)
        assert ok, errs

    def test_valid_bac_question(self, valid_bac_q):
        ok, errs = validate_question_dict(valid_bac_q)
        assert ok, errs

    def test_valid_qcm_question(self, valid_qcm_q):
        ok, errs = validate_question_dict(valid_qcm_q)
        assert ok, errs

    def test_returns_errors_list(self, valid_bepc_q):
        q = deepcopy(valid_bepc_q)
        q["enonce"] = "x"
        ok, errs = validate_question_dict(q)
        assert not ok
        assert isinstance(errs, list)
        assert len(errs) >= 1

    def test_valid_returns_empty_errors_list(self, valid_bepc_q):
        ok, errs = validate_question_dict(valid_bepc_q)
        assert ok
        assert errs == []


# ─── validate_question_list ──────────────────────────────────────────────


class TestValidateQuestionList:
    """validate_question_list partitions questions into valid/invalid."""

    def test_empty_list(self):
        valid, invalid = validate_question_list([])
        assert valid == []
        assert invalid == []

    def test_all_valid(self, sample_questions):
        valid, invalid = validate_question_list(sample_questions)
        assert len(valid) == 3
        assert invalid == []

    def test_mixed_list(self, valid_bepc_q):
        bad = deepcopy(valid_bepc_q)
        bad["id"] = "invalid"
        valid, invalid = validate_question_list([valid_bepc_q, bad])
        assert len(valid) == 1
        assert len(invalid) == 1
        # invalid entry is a (question, errors) tuple.
        assert invalid[0][0] is bad
        assert isinstance(invalid[0][1], list)


# ─── load_questions / save_questions ─────────────────────────────────────


class TestLoadSaveQuestions:
    """JSON I/O round-trip tests."""

    def test_save_and_reload_roundtrip(self, tmp_path, sample_questions):
        out_path = tmp_path / "questions.json"
        save_questions(sample_questions, out_path)
        assert out_path.exists()
        loaded = load_questions(out_path)
        assert loaded == sample_questions

    def test_save_creates_parent_dir(self, tmp_path, sample_questions):
        out_path = tmp_path / "nested" / "subdir" / "questions.json"
        save_questions(sample_questions, out_path)
        assert out_path.exists()

    def test_save_is_pretty_printed(self, tmp_path, sample_questions):
        out_path = tmp_path / "questions.json"
        save_questions(sample_questions, out_path)
        content = out_path.read_text(encoding="utf-8")
        # Pretty-printed JSON has newlines and indentation.
        assert "\n" in content
        assert "  " in content  # 2-space indent

    def test_save_preserves_unicode(self, tmp_path, valid_bepc_q):
        out_path = tmp_path / "q.json"
        save_questions([valid_bepc_q], out_path)
        content = out_path.read_text(encoding="utf-8")
        # ensure_ascii=False => accents preserved as UTF-8.
        assert "Mathématiques" in content

    def test_load_missing_file_returns_empty(self, tmp_path):
        assert load_questions(tmp_path / "nonexistent.json") == []

    def test_load_invalid_json_returns_empty(self, tmp_path):
        p = tmp_path / "bad.json"
        p.write_text("{not valid json", encoding="utf-8")
        assert load_questions(p) == []

    def test_load_list_format(self, tmp_path, sample_questions):
        """load_questions accepts a top-level JSON array."""
        p = tmp_path / "q.json"
        p.write_text(
            json.dumps(sample_questions, ensure_ascii=False),
            encoding="utf-8",
        )
        assert load_questions(p) == sample_questions

    def test_load_object_format_with_questions_key(self, tmp_path, sample_questions):
        """load_questions accepts {"questions": [...]} format."""
        p = tmp_path / "q.json"
        p.write_text(
            json.dumps({"questions": sample_questions}, ensure_ascii=False),
            encoding="utf-8",
        )
        assert load_questions(p) == sample_questions

    def test_load_unexpected_format_returns_empty(self, tmp_path):
        """A JSON object without 'questions' key returns empty list."""
        p = tmp_path / "q.json"
        p.write_text(
            json.dumps({"foo": "bar"}, ensure_ascii=False),
            encoding="utf-8",
        )
        assert load_questions(p) == []

    def test_load_accepts_string_path(self, tmp_path, sample_questions):
        out_path = tmp_path / "q.json"
        save_questions(sample_questions, out_path)
        loaded = load_questions(str(out_path))
        assert loaded == sample_questions


# ─── merge_questions ─────────────────────────────────────────────────────


class TestMergeQuestions:
    """merge_questions concatenates multiple lists."""

    def test_concatenates_two_lists(self, valid_bepc_q, valid_bac_q):
        merged = merge_questions([valid_bepc_q], [valid_bac_q])
        assert len(merged) == 2
        assert merged[0] is valid_bepc_q
        assert merged[1] is valid_bac_q

    def test_concatenates_three_lists(
        self, valid_bepc_q, valid_bac_q, valid_qcm_q,
    ):
        merged = merge_questions(
            [valid_bepc_q], [valid_bac_q], [valid_qcm_q],
        )
        assert len(merged) == 3

    def test_no_dedup_performed(self, valid_bepc_q):
        """merge_questions does NOT dedup (caller is responsible)."""
        merged = merge_questions([valid_bepc_q], [valid_bepc_q])
        assert len(merged) == 2

    def test_empty_lists(self):
        assert merge_questions([], []) == []

    def test_no_arguments(self):
        assert merge_questions() == []


# ─── QUESTION_JSON_SCHEMA ────────────────────────────────────────────────


class TestQuestionJsonSchema:
    """Sanity checks on the JSON Schema definition itself."""

    def test_schema_has_draft_7(self):
        assert QUESTION_JSON_SCHEMA["$schema"].endswith("draft-07/schema#")

    def test_schema_type_is_object(self):
        assert QUESTION_JSON_SCHEMA["type"] == "object"

    def test_additional_properties_false(self):
        assert QUESTION_JSON_SCHEMA["additionalProperties"] is False

    def test_required_fields_complete(self):
        required = set(QUESTION_JSON_SCHEMA["required"])
        expected = {
            "id", "enonce", "reponse", "matiere", "chapitre",
            "competence_id", "examen", "annee", "type", "choix",
            "points", "irt",
        }
        assert required == expected

    def test_irt_schema_has_4_required_keys(self):
        irt = QUESTION_JSON_SCHEMA["properties"]["irt"]
        assert set(irt["required"]) == {"a", "b", "c", "calibre"}
        assert irt["additionalProperties"] is False

    def test_matiere_enum_matches_config(self):
        from config import MATIERES

        schema_enum = set(
            QUESTION_JSON_SCHEMA["properties"]["matiere"]["enum"]
        )
        assert schema_enum == set(MATIERES)

    def test_type_enum_matches_config(self):
        from config import QUESTION_TYPES

        schema_enum = set(
            QUESTION_JSON_SCHEMA["properties"]["type"]["enum"]
        )
        assert schema_enum == set(QUESTION_TYPES)

    def test_examen_enum(self):
        examen_enum = set(
            QUESTION_JSON_SCHEMA["properties"]["examen"]["enum"]
        )
        assert examen_enum == {"BEPC", "BAC1", "BAC2", "Probatoire"}

    def test_serie_enum_allows_null_and_letters(self):
        serie_enum = set(
            QUESTION_JSON_SCHEMA["properties"]["serie"]["enum"]
        )
        assert None in serie_enum
        for letter in ("A", "B", "C", "D", "F"):
            assert letter in serie_enum


# ─── QuestionSchemaError ─────────────────────────────────────────────────


class TestQuestionSchemaError:
    """The custom exception type is exported and usable."""

    def test_is_subclass_of_value_error(self):
        assert issubclass(QuestionSchemaError, ValueError)

    def test_can_be_raised_and_caught(self):
        with pytest.raises(QuestionSchemaError):
            raise QuestionSchemaError("test error")

    def test_message_preserved(self):
        try:
            raise QuestionSchemaError("custom message")
        except QuestionSchemaError as exc:
            assert "custom message" in str(exc)
