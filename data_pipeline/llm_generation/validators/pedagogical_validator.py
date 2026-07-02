"""
Validation pedagogique des questions generees par LLM.

Verifie la qualite pedagogique d'une question (au-dela du schema) :
    - enonce assez long (>= 10 caracteres)
    - reponse non vide (>= 1 caractere)
    - explication assez fournie (>= 30 caracteres)
    - pas de question "piege" (mot "pas" dans l'enonce + reponse negative)
    - coherence niveau (BAC C plus difficile que BEPC)
    - format de competence_id respecte

Usage:
    from validators.pedagogical_validator import validate_pedagogy
    ok, errors = validate_pedagogy(question_dict)
"""

from __future__ import annotations

import logging
import re
from typing import Any, Dict, List, Tuple

logger = logging.getLogger(__name__)


# ─── Seuils ───────────────────────────────────────────────────────────────

MIN_ENONCE_LEN: int = 10
MIN_REPONSE_LEN: int = 1
MIN_EXPLICATION_LEN: int = 30
MAX_EXPLICATION_LEN: int = 600  # Evite les murs de texte.

# Mots negatifs dans une reponse (indique potentiel piege).
_NEGATIVE_WORDS: Tuple[str, ...] = (
    "non", "ne pas", "n'est pas", "n'a pas", "faux",
    "incorrect", "impossible", "aucun", "aucune",
)

# Pattern competence_id (re-utilise depuis schema_validator).
_COMPETENCE_RE = re.compile(
    r"^TG-([A-Z]+)-([A-Z0-9]+)-\d{3}$"
)

# Seuils de difficulte IRT par niveau (alignes sur question.dart).
# irtB < -0.5 : facile ; -0.5 a 0.8 : moyen ; > 0.8 : difficile.
_BAC_DIFFICILE_MIN_BIRT: float = -0.2  # BAC devrait etre >= moyen
_BEPC_FACILE_MAX_BIRT: float = 1.2    # BEPC devrait etre <= moyen difficile


# ─── API publique ─────────────────────────────────────────────────────────


def validate_pedagogy(question: Dict[str, Any]) -> bool:
    """Valide la qualite pedagogique d'une question.

    Args:
        question: dict de question.

    Returns:
        True si la question est pedagogiquement valide, False sinon.
    """
    errors = _collect_pedagogy_errors(question)
    if errors:
        logger.debug(
            "Pedago invalide [%s]: %s",
            question.get("id", "?"),
            " | ".join(errors),
        )
        return False
    return True


def validate_pedagogy_with_errors(
    question: Dict[str, Any],
) -> Tuple[bool, List[str]]:
    """Idem validate_pedagogy mais retourne aussi les erreurs.

    Args:
        question: dict de question.

    Returns:
        Tuple (is_valid, list_of_errors).
    """
    errors = _collect_pedagogy_errors(question)
    return (len(errors) == 0, errors)


# ─── Implementation interne ───────────────────────────────────────────────


def _collect_pedagogy_errors(question: Dict[str, Any]) -> List[str]:
    """Collecte les erreurs pedagogiques d'une question.

    Args:
        question: dict de question.

    Returns:
        Liste de messages d'erreur (vide si valide).
    """
    errors: List[str] = []

    enonce = question.get("enonce") or ""
    reponse = question.get("reponse") or ""
    explication = question.get("explication") or ""

    # 1. Longueur de l'enonce.
    if len(enonce.strip()) < MIN_ENONCE_LEN:
        errors.append(
            f"enonce trop court (<{MIN_ENONCE_LEN} caracteres): "
            f"{len(enonce.strip())} caracteres"
        )

    # 2. Reponse non vide.
    if len(reponse.strip()) < MIN_REPONSE_LEN:
        errors.append("reponse vide")

    # 3. Explication assez fournie.
    if not explication.strip():
        errors.append("explication manquante")
    elif len(explication.strip()) < MIN_EXPLICATION_LEN:
        errors.append(
            f"explication trop courte (<{MIN_EXPLICATION_LEN} caracteres)"
        )
    elif len(explication.strip()) > MAX_EXPLICATION_LEN:
        # Avertissement non bloquant : on ne rejette pas, on log.
        logger.debug(
            "Explication tres longue (%d chars) pour %s",
            len(explication), question.get("id", "?"),
        )

    # 4. Detection de question piege.
    piege = _detect_piege(enonce, reponse)
    if piege:
        errors.append(f"question piege potentielle: {piege}")

    # 5. Coherence niveau / difficulte.
    niveau_err = _check_niveau_difficulty(question)
    if niveau_err:
        errors.append(niveau_err)

    # 6. Format competence_id.
    comp = question.get("competence_id", "")
    if comp and not _COMPETENCE_RE.match(comp):
        errors.append(
            f"competence_id ne suit pas le format TG-MAT-CHAP-NNN: {comp!r}"
        )

    # 7. Variete des choix QCM (pas de doublons).
    if question.get("type") == "qcm":
        choix = question.get("choix") or []
        if isinstance(choix, list) and len(choix) != len(set(choix)):
            errors.append("QCM: choix en doublon")

    # 8. Verifie que l'enonce se termine par un point ou ? (presentation).
    if enonce.strip() and not enonce.strip()[-1] in (".", "?", "!", ":"):
        # Avertissement non bloquant : juste un log.
        logger.debug(
            "Enonce ne se termine pas par un point/?/%s pour %s",
            "!", question.get("id", "?"),
        )

    return errors


def _detect_piege(enonce: str, reponse: str) -> str:
    """Detecte les questions piege classiques.

    Args:
        enonce: texte de l'enonce.
        reponse: texte de la reponse.

    Returns:
        Chaine vide si OK, sinon description du piege detecte.
    """
    enonce_lower = enonce.lower()
    reponse_lower = reponse.lower().strip()

    # Piege : "pas" dans l'enonce + reponse negative.
    if " pas " in f" {enonce_lower} " and any(
        neg in reponse_lower for neg in _NEGATIVE_WORDS
    ):
        return "enonce contient 'pas' ET reponse negative"

    # Piege : double negation dans l'enonce.
    neg_count = sum(
        1 for neg in ("pas", "non", "ni", "n'est pas", "n'a pas")
        if neg in enonce_lower
    )
    if neg_count >= 2:
        return f"double negation dans l'enonce ({neg_count} occurrences)"

    return ""


def _check_niveau_difficulty(question: Dict[str, Any]) -> str:
    """Verifie la coherence entre niveau (BEPC/BAC) et difficulte IRT.

    Args:
        question: dict de question.

    Returns:
        Chaine vide si OK, sinon message d'erreur.
    """
    examen = question.get("examen")
    irt = question.get("irt") or {}
    irt_b = irt.get("b") if isinstance(irt, dict) else None
    if irt_b is None or not isinstance(irt_b, (int, float)):
        # Pas de b IRT -> on ne peut pas juger, on accepte.
        return ""

    # BAC devrait etre >= moyen (pas trop facile).
    if examen and examen.startswith("BAC") and irt_b < _BAC_DIFFICILE_MIN_BIRT:
        return (
            f"coherence niveau: BAC mais irt.b={irt_b} trop facile "
            f"(devrait etre >= {_BAC_DIFFICILE_MIN_BIRT})"
        )

    # BEPC ne devrait pas etre excessivement difficile.
    if examen == "BEPC" and irt_b > _BEPC_FACILE_MAX_BIRT:
        return (
            f"coherence niveau: BEPC mais irt.b={irt_b} trop difficile "
            f"(devrait etre <= {_BEPC_FACILE_MAX_BIRT})"
        )

    return ""


__all__ = [
    "validate_pedagogy",
    "validate_pedagogy_with_errors",
    "MIN_ENONCE_LEN",
    "MIN_REPONSE_LEN",
    "MIN_EXPLICATION_LEN",
    "MAX_EXPLICATION_LEN",
]
