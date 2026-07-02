"""
Tests unitaires pour la phase de validation des questions.

Couvre trois axes:
    1. validate_schema      -- champs obligatoires, types, enums (JSON Schema).
    2. validate_pedagogy    -- longueurs minimales, presence de reponse/explication.
    3. validate_coherence   -- BEPC => serie null, BAC => serie non null,
                               QCM => >= 2 choix, vraiFaux => 2 choix.

Aucun appel reseau. Les fixtures (valid_bepc_q, valid_bac_q, ...) viennent
de conftest.py.
"""

from __future__ import annotations

from copy import deepcopy
from typing import Any, Dict

import pytest

from utils.json_utils import (
    QUESTION_JSON_SCHEMA,
    validate_question_dict,
    validate_question_list,
)


# ─── Helpers locaux ────────────────────────────────────────────────────────


def _make_invalid(q: Dict[str, Any], **overrides) -> Dict[str, Any]:
    """Clone a valid question and apply overrides (deep copy)."""
    clone = deepcopy(q)
    clone.update(overrides)
    return clone


# ─── 1) validate_schema : champs obligatoires ──────────────────────────────


class TestValidateSchemaRequired:
    """All required fields must be present (no missing field allowed)."""

    @pytest.mark.parametrize(
        "missing_field",
        [
            "id",
            "enonce",
            "reponse",
            "matiere",
            "chapitre",
            "competence_id",
            "examen",
            "annee",
            "type",
            "choix",
            "points",
            "irt",
        ],
    )
    def test_missing_required_field_is_invalid(self, valid_bepc_q, missing_field):
        q = deepcopy(valid_bepc_q)
        q.pop(missing_field)
        ok, errs = validate_question_dict(q)
        assert not ok
        assert any("schema" in e or "required" in e.lower() for e in errs)


# ─── 1b) validate_schema : types & contraintes ─────────────────────────────


class TestValidateSchemaTypes:
    """Schema enforces types, enums, and length bounds."""

    def test_annee_must_be_integer(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, annee="2022")
        ok, errs = validate_question_dict(q)
        assert not ok

    def test_annee_out_of_range_rejected(self, valid_bepc_q):
        # Too old.
        q = _make_invalid(valid_bepc_q, annee=1980, id="TG-BEPC-MATHS-1980-Q01")
        assert not validate_question_dict(q)[0]
        # Too far in the future.
        q = _make_invalid(valid_bepc_q, annee=2050, id="TG-BEPC-MATHS-2050-Q01")
        assert not validate_question_dict(q)[0]

    def test_points_out_of_range_rejected(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, points=25)
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_unknown_matiere_rejected(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, matiere="Astronomie")
        ok, errs = validate_question_dict(q)
        assert not ok

    def test_unknown_type_rejected(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, type="dragAndDrop")
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_unknown_examen_rejected(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, examen="CAP")
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_unknown_serie_rejected(self, valid_bepc_q):
        # BEPC cannot have a serie, but the schema enum also rejects 'Z'.
        q = _make_invalid(valid_bepc_q, serie="Z")
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_irt_object_must_have_all_keys(self, valid_bepc_q):
        q = deepcopy(valid_bepc_q)
        q["irt"] = {"a": None, "b": 0.5}  # missing c and calibre
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_irt_calibre_must_be_boolean(self, valid_bepc_q):
        q = deepcopy(valid_bepc_q)
        q["irt"]["calibre"] = "yes"
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_additional_property_rejected(self, valid_bepc_q):
        # additionalProperties: False at the top level.
        q = deepcopy(valid_bepc_q)
        q["extra_field"] = "surprise"
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_irt_b_can_be_null_or_number(self, valid_bepc_q):
        # Null is allowed (question not yet calibrated).
        q = deepcopy(valid_bepc_q)
        q["irt"]["b"] = None
        ok, _ = validate_question_dict(q)
        assert ok

    def test_choix_can_be_null(self, valid_bepc_q):
        ok, _ = validate_question_dict(valid_bepc_q)
        assert ok

    def test_choix_must_be_array_of_strings(self, valid_bepc_q):
        q = deepcopy(valid_bepc_q)
        q["type"] = "qcm"
        q["choix"] = [1, 2, 3, 4]  # integers, not strings
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_id_min_length_enforced(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, id="ab")
        ok, _ = validate_question_dict(q)
        assert not ok


# ─── 2) validate_pedagogy : qualite du contenu ────────────────────────────


class TestValidatePedagogy:
    """Pedagogical quality rules: lengths, presence of explanation."""

    def test_short_enonce_rejected(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, enonce="ok")
        ok, errs = validate_question_dict(q)
        assert not ok
        assert any("enonce trop court" in e for e in errs)

    def test_enonce_with_only_whitespace_rejected(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, enonce="          ")
        ok, errs = validate_question_dict(q)
        assert not ok
        assert any("enonce trop court" in e for e in errs)

    def test_enonce_exactly_10_chars_accepted(self, valid_bepc_q):
        # Boundary: 10 chars (the threshold).
        q = _make_invalid(
            valid_bepc_q,
            enonce="1234567890",
            id="TG-BEPC-MATHS-2022-Q02",
        )
        ok, errs = validate_question_dict(q)
        assert ok, errs

    def test_empty_reponse_rejected_for_calcul(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, reponse="   ")
        ok, errs = validate_question_dict(q)
        assert not ok
        assert any("reponse vide" in e for e in errs)

    def test_empty_reponse_rejected_for_qcm(self, valid_qcm_q):
        q = _make_invalid(valid_qcm_q, reponse="")
        ok, errs = validate_question_dict(q)
        assert not ok

    def test_empty_reponse_rejected_for_vraiFaux(self, valid_bepc_q):
        q = _make_invalid(
            valid_bepc_q,
            type="vraiFaux",
            choix=["Vrai", "Faux"],
            reponse="",
        )
        ok, errs = validate_question_dict(q)
        assert not ok

    def test_chapitre_min_length_enforced(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, chapitre="x")
        ok, _ = validate_question_dict(q)
        assert not ok

    def test_competence_id_min_length_enforced(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, competence_id="x")
        ok, _ = validate_question_dict(q)
        assert not ok


# ─── 3) validate_coherence : regles metier examen/serie/type ──────────────


class TestValidateCoherence:
    """Business rules: BEPC/BAC series, QCM/vraiFaux choices."""

    def test_bepc_with_serie_is_invalid(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, serie="C")
        ok, errs = validate_question_dict(q)
        assert not ok
        assert any("BEPC ne doit pas avoir de serie" in e for e in errs)

    def test_bepc_with_serie_null_is_valid(self, valid_bepc_q):
        ok, _ = validate_question_dict(valid_bepc_q)
        assert ok

    def test_bac_without_serie_is_invalid(self, valid_bepc_q):
        q = _make_invalid(
            valid_bepc_q,
            examen="BAC1",
            id="TG-BAC1-MATHS-2022-Q01",
        )
        # serie still None from valid_bepc_q
        ok, errs = validate_question_dict(q)
        assert not ok
        assert any("BAC doit avoir une serie" in e for e in errs)

    def test_bac_with_serie_is_valid(self, valid_bac_q):
        ok, _ = validate_question_dict(valid_bac_q)
        assert ok

    def test_bac2_with_serie_d_is_valid(self, valid_bac_q):
        q = _make_invalid(
            valid_bac_q,
            examen="BAC2",
            id="TG-BAC-MATHD-2022-Q01",
            serie="D",
            annee=2022,
        )
        ok, _ = validate_question_dict(q)
        assert ok, _

    def test_qcm_without_choix_is_invalid(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, type="qcm", choix=None)
        ok, errs = validate_question_dict(q)
        assert not ok
        assert any("QCM doit avoir" in e for e in errs)

    def test_qcm_with_single_choix_is_invalid(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, type="qcm", choix=["A"])
        ok, errs = validate_question_dict(q)
        assert not ok

    def test_qcm_with_two_choix_is_valid(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, type="qcm", choix=["A", "B"])
        ok, _ = validate_question_dict(q)
        assert ok

    def test_qcm_with_four_choix_is_valid(self, valid_qcm_q):
        ok, _ = validate_question_dict(valid_qcm_q)
        assert ok

    def test_vraiFaux_without_choix_is_invalid(self, valid_bepc_q):
        q = _make_invalid(valid_bepc_q, type="vraiFaux", choix=None)
        ok, errs = validate_question_dict(q)
        assert not ok
        assert any("vraiFaux" in e for e in errs)

    def test_vraiFaux_with_two_choices_is_valid(self, valid_bepc_q):
        q = _make_invalid(
            valid_bepc_q,
            type="vraiFaux",
            choix=["Vrai", "Faux"],
        )
        ok, _ = validate_question_dict(q)
        assert ok

    def test_calcul_with_choix_array_is_forced_to_none_by_normalizer(self):
        """The schema permits choix=None or array; the coherence rule for
        'calcul' type does NOT reject a non-null choix, but the normalizer
        in structure_questions forces choix=None for non-QCM types."""
        # Here we only test schema-level validation.
        from structure_questions import normalize_questions

        raw = [{
            "enonce": "Calculer 2+2",
            "reponse": "4",
            "matiere": "Mathématiques",
            "chapitre": "Additions",
            "examen": "BEPC",
            "annee": 2022,
            "type": "calcul",
            "choix": ["A", "B"],  # should be cleared by normalizer
            "points": 2,
            "irt": {},
        }]
        out = normalize_questions(raw, "BEPC", "Mathématiques", 2022, None)
        assert out[0]["choix"] is None


# ─── 4) validate_question_list : partitionnement valid/invalid ────────────


class TestValidateQuestionList:
    """validate_question_list must split a mixed list correctly."""

    def test_splits_valid_and_invalid(self, valid_bepc_q, valid_bac_q):
        invalid = _make_invalid(valid_bepc_q, id="bad")
        valid, inv = validate_question_list([valid_bepc_q, valid_bac_q, invalid])
        assert len(valid) == 2
        assert len(inv) == 1
        # The invalid pair is (question, errors_list).
        assert inv[0][0]["id"] == "bad"
        assert isinstance(inv[0][1], list) and len(inv[0][1]) > 0

    def test_empty_list_returns_empty(self):
        valid, inv = validate_question_list([])
        assert valid == []
        assert inv == []

    def test_all_valid_returns_no_invalid(self, sample_questions):
        valid, inv = validate_question_list(sample_questions)
        assert len(valid) == 3
        assert inv == []

    def test_all_invalid_returns_no_valid(self, valid_bepc_q):
        bad1 = _make_invalid(valid_bepc_q, id="bad1")
        bad2 = _make_invalid(valid_bepc_q, id="bad2", enonce="x")
        valid, inv = validate_question_list([bad1, bad2])
        assert valid == []
        assert len(inv) == 2


# ─── 5) QuestionSchemaError / Schema metadata ────────────────────────────


class TestSchemaMetadata:
    """Sanity checks on QUESTION_JSON_SCHEMA itself."""

    def test_schema_is_draft_7(self):
        assert QUESTION_JSON_SCHEMA["$schema"].endswith("draft-07/schema#")

    def test_schema_rejects_additional_properties(self):
        assert QUESTION_JSON_SCHEMA["additionalProperties"] is False

    def test_schema_required_fields_complete(self):
        required = set(QUESTION_JSON_SCHEMA["required"])
        expected = {
            "id", "enonce", "reponse", "matiere", "chapitre",
            "competence_id", "examen", "annee", "type", "choix",
            "points", "irt",
        }
        assert required == expected

    def test_schema_irt_has_four_required_keys(self):
        irt_schema = QUESTION_JSON_SCHEMA["properties"]["irt"]
        assert set(irt_schema["required"]) == {"a", "b", "c", "calibre"}
        assert irt_schema["additionalProperties"] is False

    def test_schema_examen_enum(self):
        examen_schema = QUESTION_JSON_SCHEMA["properties"]["examen"]
        assert set(examen_schema["enum"]) == {"BEPC", "BAC1", "BAC2", "Probatoire"}

    def test_schema_serie_enum_allows_null(self):
        serie_schema = QUESTION_JSON_SCHEMA["properties"]["serie"]
        # None is allowed.
        assert None in serie_schema["enum"]
        # All official Togo BAC series are allowed.
        for letter in ("A", "B", "C", "D", "F"):
            assert letter in serie_schema["enum"]
