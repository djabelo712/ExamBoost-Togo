"""
Helpers pour la validation et la manipulation du schema JSON des questions.

Le schema cible est celui defini par `lib/models/question.dart` dans l'app
Flutter. Ce module centralise les regles de validation afin d'eviter toute
divergence entre le pipeline et le client mobile.
"""

from __future__ import annotations

import json
import logging
import re
import unicodedata
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

from jsonschema import validate as jsonschema_validate
from jsonschema.exceptions import ValidationError as JsonSchemaValidationError

from config import MATIERE_CODE, MATIERES, QUESTION_TYPES

logger = logging.getLogger(__name__)


class QuestionSchemaError(ValueError):
    """Raised when a question dict does not conform to the expected schema."""


# ─── Schema JSON Schema ( Draft 7 ) ───────────────────────────────────────

QUESTION_JSON_SCHEMA: Dict[str, Any] = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "additionalProperties": False,
    "required": [
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
    "properties": {
        "id": {"type": "string", "minLength": 5, "maxLength": 80},
        "enonce": {"type": "string", "minLength": 5},
        "reponse": {"type": "string"},
        "explication": {"type": ["string", "null"]},
        "matiere": {"type": "string", "enum": list(MATIERES)},
        "chapitre": {"type": "string", "minLength": 2},
        "competence_id": {"type": "string", "minLength": 5},
        "examen": {"type": "string", "enum": ["BEPC", "BAC1", "BAC2", "Probatoire"]},
        "serie": {"type": ["string", "null"], "enum": [None, "A", "B", "C", "D", "F"]},
        "annee": {"type": "integer", "minimum": 1990, "maximum": 2030},
        "type": {"type": "string", "enum": list(QUESTION_TYPES)},
        "choix": {"type": ["array", "null"], "items": {"type": "string"}},
        "points": {"type": ["integer", "null"], "minimum": 0, "maximum": 20},
        "irt": {
            "type": "object",
            "additionalProperties": False,
            "required": ["a", "b", "c", "calibre"],
            "properties": {
                "a": {"type": ["number", "null"]},
                "b": {"type": ["number", "null"]},
                "c": {"type": ["number", "null"]},
                "calibre": {"type": "boolean"},
            },
        },
    },
}


# ─── Identifiants ─────────────────────────────────────────────────────────

_ID_RE = re.compile(
    r"^TG-(BEPC|BAC1|BAC2|BAC|Probatoire)-([A-Z]+)-(\d{4})-Q\d{2,3}$"
)


def build_question_id(
    examen: str,
    matiere: str,
    annee: int,
    q_number: int,
    serie: Optional[str] = None,
) -> str:
    """Build a canonical question id (e.g. TG-BEPC-MATHS-2022-Q01).

    Conventions (alignees sur assets/data/questions.json existant):
        - BEPC: id prefix = "BEPC", matiere code as-is (MATHS, FR, PHYS...).
          Ex: TG-BEPC-MATHS-2022-Q01
        - BAC1 / BAC2: id prefix = "BAC" (pas "BAC1"). Pour les
          Mathematiques, le code devient "MATH" + serie (MATHC, MATHD).
          Pour les autres matieres, on garde le code nu (PHYS, FR...).
          Ex: TG-BAC-MATHC-2023-Q01, TG-BAC-PHYS-2023-Q01

    Args:
        examen: "BEPC" | "BAC1" | "BAC2" | "Probatoire".
        matiere: full matiere label (e.g. "Mathématiques").
        annee: 4-digit year.
        q_number: 1-based question index in the source PDF.
        serie: optional letter (BAC only).

    Returns:
        Canonical id string.
    """
    code = MATIERE_CODE.get(matiere, "GEN")

    if examen.startswith("BAC"):
        id_examen = "BAC"
        # Cas special: Mathematiques en BAC avec serie -> "MATH" + serie.
        if matiere == "Mathématiques" and serie:
            code = f"MATH{serie}"
        # Les autres matieres gardent leur code tel quel.
    else:
        id_examen = examen

    return f"TG-{id_examen}-{code}-{annee}-Q{q_number:02d}"


def is_valid_id(qid: str) -> bool:
    """Return True if the question id matches the canonical pattern."""
    return bool(_ID_RE.match(qid))


# ─── Normalisation (pour deduplication) ───────────────────────────────────

_PUNCT_RE = re.compile(r"[^\w\s]", flags=re.UNICODE)
_WS_RE = re.compile(r"\s+")


def normalize_enonce(enonce: str) -> str:
    """Normalize an enonce for hashing / deduplication.

    - lowercase
    - strip accents
    - remove punctuation
    - collapse whitespace

    Args:
        enonce: raw enonce string.

    Returns:
        Normalized string.
    """
    if not enonce:
        return ""
    text = enonce.lower()
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = _PUNCT_RE.sub(" ", text)
    text = _WS_RE.sub(" ", text).strip()
    return text


# ─── Validation ───────────────────────────────────────────────────────────


def validate_question_dict(question: Dict[str, Any]) -> Tuple[bool, List[str]]:
    """Validate a single question dict against the schema + business rules.

    Args:
        question: question dict to validate.

    Returns:
        Tuple (is_valid, list_of_errors).
    """
    errors: List[str] = []

    # 1) Schema JSON strict.
    try:
        jsonschema_validate(instance=question, schema=QUESTION_JSON_SCHEMA)
    except JsonSchemaValidationError as exc:
        errors.append(f"schema: {exc.message} (path: {'/'.join(map(str, exc.path))})")

    # 2) Regles metier.
    examen = question.get("examen")
    serie = question.get("serie")
    if examen == "BEPC" and serie is not None:
        errors.append("coherence: BEPC ne doit pas avoir de serie")
    if examen and examen.startswith("BAC") and serie is None:
        errors.append("coherence: BAC doit avoir une serie non null")

    # 3) QCM doit avoir des choix non vides.
    qtype = question.get("type")
    choix = question.get("choix")
    if qtype == "qcm":
        if not choix or not isinstance(choix, list) or len(choix) < 2:
            errors.append("coherence: QCM doit avoir >= 2 choix")
    elif qtype in {"vraiFaux"} and not choix:
        errors.append("coherence: vraiFaux doit avoir 2 choix ['Vrai','Faux']")

    # 4) Longueur minimale de l'enonce.
    enonce = question.get("enonce") or ""
    if len(enonce.strip()) < 10:
        errors.append("qualite: enonce trop court (<10 caracteres)")

    # 5) Reponse non vide pour calcul/ouvert/qcm.
    reponse = question.get("reponse") or ""
    if qtype in {"calcul", "ouvert", "qcm", "vraiFaux"} and not reponse.strip():
        errors.append("qualite: reponse vide")

    # 6) Identifiant canonique.
    qid = question.get("id", "")
    if not is_valid_id(qid):
        errors.append(f"format: id non canonique '{qid}'")

    return (len(errors) == 0, errors)


def validate_question_list(questions: Iterable[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], List[Tuple[Dict[str, Any], List[str]]]]:
    """Split a list of questions into (valid, invalid_with_errors).

    Args:
        questions: iterable of question dicts.

    Returns:
        Tuple (valid_questions, invalid_pairs) where each invalid_pair is
        (question_dict, list_of_error_messages).
    """
    valid: List[Dict[str, Any]] = []
    invalid: List[Tuple[Dict[str, Any], List[str]]] = []
    for q in questions:
        ok, errs = validate_question_dict(q)
        if ok:
            valid.append(q)
        else:
            invalid.append((q, errs))
    return valid, invalid


# ─── I/O ──────────────────────────────────────────────────────────────────


def load_questions(path: Path | str) -> List[Dict[str, Any]]:
    """Load a JSON file containing a list of questions.

    Args:
        path: path to the JSON file.

    Returns:
        List of question dicts (empty if file missing or invalid).
    """
    path = Path(path)
    if not path.exists():
        return []
    try:
        with path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        if isinstance(data, list):
            return data
        if isinstance(data, dict) and isinstance(data.get("questions"), list):
            return data["questions"]
        logger.warning("Format JSON inattendu dans %s", path)
        return []
    except (json.JSONDecodeError, OSError) as exc:
        logger.error("Lecture %s impossible: %s", path, exc)
        return []


def save_questions(questions: List[Dict[str, Any]], path: Path | str) -> None:
    """Persist a list of questions as a pretty-printed JSON file.

    Args:
        questions: list of question dicts.
        path: destination file path.
    """
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        json.dump(questions, fh, ensure_ascii=False, indent=2)
    logger.info("Sauvegarde: %s (%d questions)", path, len(questions))


def merge_questions(*sources: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Concatenate several lists of questions into one.

    Args:
        *sources: any number of question lists.

    Returns:
        Flat list of all questions (no deduplication here).
    """
    merged: List[Dict[str, Any]] = []
    for src in sources:
        merged.extend(src)
    return merged


__all__ = [
    "QuestionSchemaError",
    "QUESTION_JSON_SCHEMA",
    "build_question_id",
    "is_valid_id",
    "normalize_enonce",
    "validate_question_dict",
    "validate_question_list",
    "load_questions",
    "save_questions",
    "merge_questions",
]
