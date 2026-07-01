"""
Verification de doublons vs questions existantes (SimHash).

Pour chaque question LLM, calcule un SimHash de l'enonce normalise et le
compare aux hashes des 64 questions existantes de questions.json. Si la
distance de Hamming est inferieure au seuil, la question est consideree
comme doublon.

Utilise le module `simhash` (deja utilise par deduplicate.py).

Usage:
    from validators.duplicate_checker import DuplicateChecker, check_duplicates
    checker = DuplicateChecker(existing_questions)
    if check_duplicates(new_question, checker):
        # doublon -> discard
        ...
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

try:
    from simhash import Simhash, SimhashIndex  # type: ignore
    _SIMHASH_AVAILABLE = True
except ImportError:  # pragma: no cover
    Simhash = None  # type: ignore
    SimhashIndex = None  # type: ignore
    _SIMHASH_AVAILABLE = False

logger = logging.getLogger(__name__)


# ─── Constantes ───────────────────────────────────────────────────────────

# Seuil de distance de Hamming en dessous duquel deux questions sont
# considerees comme doublons (0 = identique, 64 = totalement different).
# 5/64 ~= 8% => similarite > 92% (plus strict que le seuil general).
DUPLICATE_MAX_BIT_DISTANCE: int = 5

# Chemin par defaut vers questions.json (banque existante).
DEFAULT_QUESTIONS_PATH: Path = Path(__file__).resolve().parents[3] / \
    "assets" / "data" / "questions.json"


# ─── Helpers de normalisation ─────────────────────────────────────────────


def _normalize_enonce(enonce: str) -> str:
    """Normalise un enonce pour le hachage SimHash.

    Operations:
        - lowercase
        - suppression des accents (NFKD + filtre combining)
        - suppression de la ponctuation
        - collapse des espaces

    Args:
        enonce: texte brut de l'enonce.

    Returns:
        Texte normalise (sans accents ni ponctuation).
    """
    import re
    import unicodedata

    if not enonce:
        return ""
    text = enonce.lower()
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = re.sub(r"[^\w\s]", " ", text, flags=re.UNICODE)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _compute_simhash(enonce: str) -> Any:
    """Calcule le SimHash 64 bits d'un enonce normalise.

    Utilise des shingles de 3 mots (meilleure precision que mots uniques),
    comme dans deduplicate.py.

    Args:
        enonce: texte brut de l'enonce.

    Returns:
        Instance Simhash (ou None si simhash non disponible).
    """
    if not _SIMHASH_AVAILABLE:
        return None
    norm = _normalize_enonce(enonce)
    tokens = norm.split()
    if len(tokens) < 3:
        features = tokens
    else:
        features = [" ".join(tokens[i:i + 3]) for i in range(len(tokens) - 2)]
    return Simhash(features or ["empty"])


# ─── Checker ──────────────────────────────────────────────────────────────


class DuplicateChecker:
    """Verificateur de doublons contre une liste de questions existantes.

    Charge une fois les SimHash des questions existantes, puis offre une
    methode `is_duplicate(new_question)` rapide.

    Attributes:
        existing: liste des questions existantes (chargees une fois).
        index: SimhashIndex pour recherche rapide par voisins.
        hashes: liste de tuples (id, Simhash).
    """

    def __init__(
        self,
        existing: List[Dict[str, Any]],
        threshold: int = DUPLICATE_MAX_BIT_DISTANCE,
    ) -> None:
        self.existing: List[Dict[str, Any]] = existing
        self.threshold: int = threshold
        self.hashes: List[Tuple[str, Any]] = []
        self.index: Optional[Any] = None
        self._build_index()

    def _build_index(self) -> None:
        """Construit l'index SimHash des questions existantes."""
        if not _SIMHASH_AVAILABLE:
            logger.warning(
                "simhash non disponible -> DuplicateChecker desactive "
                "(aucun doublon ne sera detecte)"
            )
            return
        for q in self.existing:
            enonce = q.get("enonce", "")
            sh = _compute_simhash(enonce)
            if sh is not None:
                qid = q.get("id", f"q{len(self.hashes)}")
                self.hashes.append((qid, sh))
        # SimhashIndex permet la recherche rapide des voisins.
        self.index = SimhashIndex(self.hashes, k=self.threshold)
        logger.info(
            "DuplicateChecker: %d questions existantes indexees (seuil=%d bits)",
            len(self.hashes), self.threshold,
        )

    def is_duplicate(
        self,
        new_question: Dict[str, Any],
    ) -> bool:
        """Verifie si une nouvelle question est en doublon.

        Args:
            new_question: question candidate.

        Returns:
            True si la question est en doublon d'une existante, False sinon.
        """
        if not _SIMHASH_AVAILABLE or self.index is None:
            return False
        new_sh = _compute_simhash(new_question.get("enonce", ""))
        if new_sh is None:
            return False
        # get_near_dups retourne les ids des hashes proches.
        near_dups = self.index.get_near_dups(new_sh)
        if near_dups:
            logger.debug(
                "Doublon detecte pour %s -> %s",
                new_question.get("id", "?"), near_dups[:3],
            )
            return True
        return False

    def find_duplicates(
        self,
        new_questions: List[Dict[str, Any]],
    ) -> Tuple[List[Dict[str, Any]], List[Tuple[Dict[str, Any], List[str]]]]:
        """Separe une liste de nouvelles questions en uniques / doublons.

        Args:
            new_questions: liste de questions candidates.

        Returns:
            Tuple (uniques, doublons) ou doublons est une liste de
            (question, [ids_des_questions_existantes_similaires]).
        """
        uniques: List[Dict[str, Any]] = []
        doublons: List[Tuple[Dict[str, Any], List[str]]] = []
        for q in new_questions:
            if not _SIMHASH_AVAILABLE or self.index is None:
                uniques.append(q)
                continue
            new_sh = _compute_simhash(q.get("enonce", ""))
            if new_sh is None:
                uniques.append(q)
                continue
            near_dups = self.index.get_near_dups(new_sh)
            if near_dups:
                doublons.append((q, near_dups))
            else:
                uniques.append(q)
        return uniques, doublons


# ─── API fonctionnelle (alternative a la classe) ──────────────────────────


def check_duplicates(
    new_question: Dict[str, Any],
    checker: DuplicateChecker,
) -> bool:
    """Verifie si une question est en doublon (API fonctionnelle).

    Args:
        new_question: question candidate.
        checker: instance DuplicateChecker initialisee avec les existantes.

    Returns:
        True si doublon, False sinon.
    """
    return checker.is_duplicate(new_question)


def load_existing_questions(path: Optional[Path] = None) -> List[Dict[str, Any]]:
    """Charge les questions existantes depuis questions.json.

    Args:
        path: chemin vers questions.json (defaut: assets/data/questions.json).

    Returns:
        Liste de dicts de questions (vide si fichier absent ou invalide).
    """
    import json

    path = path or DEFAULT_QUESTIONS_PATH
    if not path.exists():
        logger.warning("Fichier de questions existantes introuvable: %s", path)
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


__all__ = [
    "DuplicateChecker",
    "check_duplicates",
    "load_existing_questions",
    "DUPLICATE_MAX_BIT_DISTANCE",
    "DEFAULT_QUESTIONS_PATH",
]
