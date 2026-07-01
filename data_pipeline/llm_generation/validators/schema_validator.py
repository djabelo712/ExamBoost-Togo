"""
Validation du schema JSON des questions generees par les LLM.

Cette validation est distincte de celle de utils/json_utils.py car elle
s'applique aux questions issues de la generation LLM (qui peuvent avoir
des champs supplementaires temporaires comme `_source`, `_hash`). Elle
verifie en plus :
    - presence de tous les champs obligatoires
    - types conformes (string, int, list, etc.)
    - coherence examen/serie (BEPC -> serie null ; BAC -> serie non null)
    - QCM a exactement 4 choix dont la reponse
    - irt.b dans [-2, 2]
    - points dans [1, 5]

Usage:
    from validators.schema_validator import validate_schema
    ok, errors = validate_schema(question_dict)
    if ok:
        ...
"""

from __future__ import annotations

import logging
import re
from typing import Any, Dict, List, Tuple

logger = logging.getLogger(__name__)


# ─── Constantes ───────────────────────────────────────────────────────────

# Champs obligatoires (alignes sur lib/models/question.dart).
REQUIRED_FIELDS: Tuple[str, ...] = (
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
)

# Types de questions valides (alignes sur l'enum Dart QuestionType).
VALID_TYPES: Tuple[str, ...] = (
    "calcul", "ouvert", "qcm", "vraiFaux", "redaction",
)

# Examens valides.
VALID_EXAMENS: Tuple[str, ...] = ("BEPC", "BAC1", "BAC2", "Probatoire")

# Series valides pour BAC (None pour BEPC).
VALID_SERIES: Tuple[str | None, ...] = (None, "A", "B", "C", "D", "F")

# Matieres valides (alignees sur config.py).
VALID_MATIERES: Tuple[str, ...] = (
    "Mathématiques",
    "Français",
    "Sciences Physiques",
    "Sciences de la Vie et de la Terre",
    "Histoire-Géographie",
    "Anglais",
    "Philosophie",
    "EPS",
)

# Variantes acceptees (sans accents) -> matiere canonique.
# Les LLM renvoient parfois "Mathematiques" sans accent ; on normalise.
_MATIERE_ALIASES: Dict[str, str] = {
    "Mathematiques": "Mathématiques",
    "Mathématique": "Mathématiques",
    "Mathematique": "Mathématiques",
    "Francais": "Français",
    "Sciences Physiques": "Sciences Physiques",
    "Sciences physiques": "Sciences Physiques",
    "Physique-Chimie": "Sciences Physiques",
    "Physique Chimie": "Sciences Physiques",
    "SVT": "Sciences de la Vie et de la Terre",
    "Sciences de la Vie et de la Terre": "Sciences de la Vie et de la Terre",
    "Sciences de la vie et de la terre": "Sciences de la Vie et de la Terre",
    "Sciences de la Vie et de la Terre (SVT)": "Sciences de la Vie et de la Terre",
    "Histoire-Géographie": "Histoire-Géographie",
    "Histoire-Geographie": "Histoire-Géographie",
    "Histoire Geo": "Histoire-Géographie",
    "HG": "Histoire-Géographie",
}

# Variantes acceptees pour examen (LLM peut retourner "BAC" au lieu de "BAC1").
_EXAMEN_ALIASES: Dict[str, str] = {
    "BAC": "BAC1",
    "BAC Général": "BAC1",
    "BAC General": "BAC1",
    "Probatoire": "Probatoire",
}


def _normalize_examen(value: str) -> str:
    """Normalise un libelle d'examen vers sa forme canonique.

    Args:
        value: libelle brute retourne par le LLM.

    Returns:
        Forme canonique ("BEPC", "BAC1", "BAC2", "Probatoire") ou la valeur
        originale si aucune normalisation n'est trouvee.
    """
    if value in VALID_EXAMENS:
        return value
    return _EXAMEN_ALIASES.get(value or "", value or "")


# Pattern d'id canonique : TG-{EXAMEN}-{CODE}-{ANNEE}-Q{NN}
# Note: on accepte aussi bien "BAC" que "BAC1" / "BAC2" dans l'id car
# les conventions d'ID utilisees dans questions.json utilisent "BAC" nu
# pour les BAC (voir utils/json_utils.build_question_id).
_ID_RE = re.compile(
    r"^TG-(BEPC|BAC1|BAC2|BAC|Probatoire)-([A-Z]+)-(\d{4})-Q\d{2,3}$"
)

# Pattern d'id de competence : TG-{MATIERE}-{CHAP}-NNN
_COMPETENCE_RE = re.compile(
    r"^TG-([A-Z]+)-([A-Z0-9]+)-\d{3}$"
)


# ─── Validation ───────────────────────────────────────────────────────────


def validate_schema(question: Dict[str, Any]) -> bool:
    """Valide une question contre le schema ExamBoost.

    Verifie:
        1. Presence de tous les champs obligatoires.
        2. Types conformes.
        3. Coherence examen/serie.
        4. QCM a 4 choix dont la reponse.
        5. irt.b dans [-2, 2].
        6. points dans [1, 5].
        7. id canonique.
        8. competence_id au format TG-{MAT}-{CHAP}-NNN.

    Args:
        question: dict de question (typiquement sortie de LLM).

    Returns:
        True si la question est valide, False sinon. Les erreurs sont loggees.
    """
    errors: List[str] = _collect_errors(question)
    if errors:
        logger.debug(
            "Schema invalide [%s]: %s",
            question.get("id", "?"),
            " | ".join(errors),
        )
        return False
    return True


def validate_schema_with_errors(
    question: Dict[str, Any],
) -> Tuple[bool, List[str]]:
    """Idem que validate_schema mais retourne aussi les erreurs.

    Args:
        question: dict de question.

    Returns:
        Tuple (is_valid, list_of_errors).
    """
    errors = _collect_errors(question)
    return (len(errors) == 0, errors)


# ─── Implementation interne ───────────────────────────────────────────────


def _collect_errors(question: Dict[str, Any]) -> List[str]:
    """Collecte toutes les erreurs de schema d'une question.

    Args:
        question: dict de question.

    Returns:
        Liste de messages d'erreur (vide si valide).
    """
    errors: List[str] = []

    # 1. Presence des champs obligatoires.
    for field in REQUIRED_FIELDS:
        if field not in question:
            errors.append(f"champ manquant: {field}")

    # Si pas de champs minimaux, inutile d'aller plus loin.
    if not question.get("enonce") or not question.get("type"):
        return errors

    # 2. Types conformes.
    if not isinstance(question.get("id"), str):
        errors.append("id doit etre une string")
    if not isinstance(question.get("enonce"), str):
        errors.append("enonce doit etre une string")
    if not isinstance(question.get("reponse"), str):
        errors.append("reponse doit etre une string")
    if not isinstance(question.get("matiere"), str):
        errors.append("matiere doit etre une string")
    if not isinstance(question.get("chapitre"), str):
        errors.append("chapitre doit etre une string")
    if not isinstance(question.get("competence_id"), str):
        errors.append("competence_id doit etre une string")
    if not isinstance(question.get("examen"), str):
        errors.append("examen doit etre une string")
    if not isinstance(question.get("annee"), int):
        errors.append("annee doit etre un entier")
    if not isinstance(question.get("type"), str):
        errors.append("type doit etre une string")
    if not isinstance(question.get("irt"), dict):
        errors.append("irt doit etre un dict")
        # On ne peut pas valider irt si pas un dict.
        irt = None
    else:
        irt = question["irt"]

    # 3. Valeurs autorisees.
    examen = question.get("examen")
    if examen not in VALID_EXAMENS:
        # Tenter une normalisation (BAC -> BAC1, etc.).
        normalized = _normalize_examen(examen or "")
        if normalized in VALID_EXAMENS:
            question["examen"] = normalized
        else:
            errors.append(f"examen invalide: {examen!r} (attendu: {VALID_EXAMENS})")

    matiere = question.get("matiere")
    if matiere not in VALID_MATIERES:
        # Tenter une normalisation via les alias (sans accents, etc.).
        normalized = _MATIERE_ALIASES.get(matiere or "")
        if normalized:
            # Remplace in-place par la forme canonique.
            question["matiere"] = normalized
        else:
            errors.append(f"matiere invalide: {matiere!r}")

    qtype = question.get("type")
    if qtype not in VALID_TYPES:
        errors.append(f"type invalide: {qtype!r} (attendu: {VALID_TYPES})")

    serie = question.get("serie")
    if serie not in VALID_SERIES:
        errors.append(f"serie invalide: {serie!r} (attendu: {VALID_SERIES})")

    # 4. Coherence examen / serie (re-fetch apres normalisation potentielle).
    examen = question.get("examen")
    serie = question.get("serie")
    if examen == "BEPC" and serie is not None:
        errors.append("coherence: BEPC ne doit pas avoir de serie")
    if examen and examen.startswith("BAC") and serie is None:
        errors.append("coherence: BAC doit avoir une serie (A/B/C/D/F)")

    # 5. QCM / vraiFaux : coherence des choix.
    choix = question.get("choix")
    if qtype == "qcm":
        if not isinstance(choix, list):
            errors.append("QCM: choix doit etre une liste")
        elif len(choix) != 4:
            errors.append(f"QCM: doit avoir exactement 4 choix ({len(choix)} trouves)")
        else:
            # La reponse doit etre un des choix.
            reponse = question.get("reponse", "")
            if reponse and reponse not in choix:
                errors.append(
                    f"QCM: la reponse '{reponse}' n'est pas dans les choix {choix}"
                )
    elif qtype == "vraiFaux":
        if not isinstance(choix, list) or len(choix) != 2:
            errors.append("vraiFaux: doit avoir 2 choix ['Vrai', 'Faux']")
    else:
        # Pour calcul/ouvert/redaction, choix doit etre null.
        if choix is not None:
            errors.append(f"{qtype}: choix devrait etre null (pas {type(choix).__name__})")

    # 6. Points dans [1, 5].
    points = question.get("points")
    if points is not None:
        if not isinstance(points, int):
            errors.append(f"points doit etre un entier (pas {type(points).__name__})")
        elif points < 1 or points > 5:
            errors.append(f"points hors plage [1, 5]: {points}")

    # 7. irt.b dans [-2, 2].
    if isinstance(irt, dict):
        irt_b = irt.get("b")
        if irt_b is not None:
            if not isinstance(irt_b, (int, float)):
                errors.append("irt.b doit etre un nombre")
            elif irt_b < -2.0 or irt_b > 2.0:
                errors.append(f"irt.b hors plage [-2, 2]: {irt_b}")
        # Calibre doit etre bool.
        if "calibre" in irt and not isinstance(irt["calibre"], bool):
            errors.append("irt.calibre doit etre un booleen")

    # 8. id canonique.
    qid = question.get("id", "")
    if qid and not _ID_RE.match(qid):
        errors.append(f"id non canonique: {qid!r}")

    # 9. competence_id au format TG-{MAT}-{CHAP}-NNN.
    comp = question.get("competence_id", "")
    if comp and not _COMPETENCE_RE.match(comp):
        errors.append(f"competence_id non canonique: {comp!r}")

    # 10. annee raisonnable.
    annee = question.get("annee")
    if isinstance(annee, int) and (annee < 1990 or annee > 2030):
        errors.append(f"annee hors plage [1990, 2030]: {annee}")

    return errors


__all__ = [
    "validate_schema",
    "validate_schema_with_errors",
    "REQUIRED_FIELDS",
    "VALID_TYPES",
    "VALID_EXAMENS",
    "VALID_SERIES",
    "VALID_MATIERES",
]
