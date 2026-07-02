"""
Fusion des sorties des 3 LLM + validation croisee 2/3.

Methode :
    1. Pour chaque question, on normalise l'enonce (lowercase, sans accents,
       sans ponctuation).
    2. On calcule un SimHash 64 bits de l'enonce normalise (shingles 3 mots).
    3. On regroupe les questions similaires (distance de Hamming < seuil).
    4. Pour chaque groupe, si au moins 2 LLM sur 3 ont genere une question
       similaire -> on garde la meilleure version (explication la plus longue,
       puis reponse la plus complete).
    5. Sinon -> discard (question potentiellement hallucinee ou trop unique).

Usage:
    from merge_questions import merge_and_cross_validate
    merged = merge_and_cross_validate({
        "claude": [...],
        "openai": [...],
        "mistral": [...],
    })
"""

from __future__ import annotations

import logging
from collections import defaultdict
from typing import Any, Dict, List, Optional, Set, Tuple

try:
    from simhash import Simhash, SimhashIndex  # type: ignore
    _SIMHASH_AVAILABLE = True
except ImportError:  # pragma: no cover
    Simhash = None  # type: ignore
    SimhashIndex = None  # type: ignore
    _SIMHASH_AVAILABLE = False

logger = logging.getLogger(__name__)


# ─── Constantes ───────────────────────────────────────────────────────────

# Seuil de distance de Hamming pour considerer 2 enonces comme "similaires".
# 9/64 ~= 14% de difference => similarite > 86% (aligne sur config.py).
CROSS_VALIDATE_MAX_BIT_DISTANCE: int = 9

# Nombre minimum de LLM sources pour valider une question.
MIN_SOURCES_FOR_VALIDATION: int = 2


# ─── Normalisation ────────────────────────────────────────────────────────


def _normalize_enonce(enonce: str) -> str:
    """Normalise un enonce pour le hachage SimHash.

    Args:
        enonce: texte brut de l'enonce.

    Returns:
        Texte normalise (sans accents, sans ponctuation, lowercase).
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


def _compute_simhash(enonce: str) -> Optional[Any]:
    """Calcule le SimHash d'un enonce normalise (shingles 3 mots).

    Args:
        enonce: texte brut.

    Returns:
        Instance Simhash, ou None si simhash indisponible.
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


def _hamming_distance(sh1: Any, sh2: Any) -> int:
    """Calcule la distance de Hamming entre 2 SimHash.

    Args:
        sh1, sh2: instances Simhash.

    Returns:
        Nombre de bits differents (0 a 64).
    """
    if sh1 is None or sh2 is None:
        return 64
    return sh1.distance(sh2)


# ─── Score de qualite ─────────────────────────────────────────────────────


def _quality_score(q: Dict[str, Any]) -> int:
    """Score de qualite d'une question (plus haut = meilleure).

    Critères (cumulatifs) :
        +1 si enonce non vide
        +1 si reponse non vide
        +1 si explication non vide
        +1 si explication >= 50 caracteres (detaillee)
        +1 si points present
        +1 si irt.b present
        +1 si chapitre present

    Args:
        q: dict de question.

    Returns:
        Score entier 0-7.
    """
    score = 0
    if (q.get("enonce") or "").strip():
        score += 1
    if (q.get("reponse") or "").strip():
        score += 1
    expl = (q.get("explication") or "").strip()
    if expl:
        score += 1
        if len(expl) >= 50:
            score += 1
    if q.get("points") is not None:
        score += 1
    if isinstance(q.get("irt"), dict) and q["irt"].get("b") is not None:
        score += 1
    if (q.get("chapitre") or "").strip():
        score += 1
    return score


# ─── Groupage par similarite ──────────────────────────────────────────────


def _group_similar(
    questions: List[Dict[str, Any]],
    threshold: int = CROSS_VALIDATE_MAX_BIT_DISTANCE,
) -> List[List[Dict[str, Any]]]:
    """Groupe les questions similaires (distance de Hamming < threshold).

    Algorithme:
        - Calcule le SimHash de chaque question.
        - Construit un SimhashIndex pour recherche rapide de voisins.
        - Parcourt les questions et regroupe les voisins non encore vus.

    Args:
        questions: liste de dicts avec cle `_source` et `_hash` eventuelle.
        threshold: distance de Hamming max pour etre "similaire".

    Returns:
        Liste de groupes (chaque groupe est une liste de questions).
    """
    if not _SIMHASH_AVAILABLE:
        logger.warning(
            "simhash indisponible -> 1 groupe par question (pas de cross-val)"
        )
        return [[q] for q in questions]

    # Pre-calcule des SimHash + index.
    objs: List[Tuple[str, Any]] = []
    simhashes: List[Any] = []
    for idx, q in enumerate(questions):
        sh = q.get("_hash")
        if sh is None:
            sh = _compute_simhash(q.get("enonce", ""))
            q["_hash"] = sh
        simhashes.append(sh)
        objs.append((f"q{idx}", sh))
    index = SimhashIndex(objs, k=threshold)

    seen: Set[int] = set()
    groups: List[List[Dict[str, Any]]] = []

    for idx, q in enumerate(questions):
        if idx in seen:
            continue
        sh = simhashes[idx]
        near_ids = index.get_near_dups(sh)
        cluster_idx = [int(nid[1:]) for nid in near_ids]
        cluster_idx = [i for i in cluster_idx if i not in seen]
        if not cluster_idx:
            cluster_idx = [idx]
        groups.append([questions[i] for i in cluster_idx])
        for i in cluster_idx:
            seen.add(i)

    return groups


# ─── Selection de la meilleure version ────────────────────────────────────


def _pick_best(group: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Selectionne la meilleure question d'un groupe.

    Criteres (par ordre de priorite) :
        1. Score de qualite le plus eleve.
        2. Explication la plus longue (en cas d'egalite).
        3. Reponse la plus longue (en cas d'egalite).
        4. Index le plus bas (stable en cas d'egalite parfaite).

    Args:
        group: liste de questions similaires.

    Returns:
        La meilleure question.
    """
    if len(group) == 1:
        return group[0]
    return max(
        group,
        key=lambda q: (
            _quality_score(q),
            len((q.get("explication") or "")),
            len((q.get("reponse") or "")),
        ),
    )


# ─── API publique ─────────────────────────────────────────────────────────


def merge_and_cross_validate(
    raw_questions: Dict[str, List[Dict[str, Any]]],
    threshold: int = CROSS_VALIDATE_MAX_BIT_DISTANCE,
    min_sources: int = MIN_SOURCES_FOR_VALIDATION,
) -> List[Dict[str, Any]]:
    """Fusionne les 3 sources et valide croisee (>=2 LLM sur 3).

    Args:
        raw_questions: dict {source_name: liste_de_questions}.
            Sources attendues: "claude", "openai", "mistral".
        threshold: distance de Hamming max pour considerer 2 questions
            similaires (default: 9/64).
        min_sources: nombre minimum de LLM sources pour valider une question
            (default: 2 sur 3).

    Returns:
        Liste de questions validees (champs `_source` et `_hash` laisses pour
        trace ; a nettoyer avant integration finale).
    """
    # 1. Aplatir + taguer source + pre-calculer SimHash.
    all_questions: List[Dict[str, Any]] = []
    for source, questions in raw_questions.items():
        for q in questions:
            if not isinstance(q, dict):
                continue
            q["_source"] = source
            q["_hash"] = _compute_simhash(q.get("enonce", ""))
            all_questions.append(q)

    logger.info(
        "Cross-validation: %d questions brutes depuis %d sources",
        len(all_questions),
        len(raw_questions),
    )

    if not all_questions:
        return []

    # 2. Grouper par similarite.
    groups = _group_similar(all_questions, threshold=threshold)
    logger.info(
        "Cross-validation: %d groupes formes (seuil=%d bits)",
        len(groups), threshold,
    )

    # 3. Pour chaque groupe, verifier qu'au moins min_sources LLM y ont contribue.
    validated: List[Dict[str, Any]] = []
    discarded_single_source: int = 0
    for group in groups:
        sources_in_group: Set[str] = set(q.get("_source", "?") for q in group)
        if len(sources_in_group) >= min_sources:
            best = _pick_best(group)
            # Conserve la liste des sources qui ont valide cette question.
            best["_validated_by"] = sorted(sources_in_group)
            best["_group_size"] = len(group)
            validated.append(best)
        else:
            discarded_single_source += 1

    logger.info(
        "Cross-validation: %d validees (>= %d sources), %d ecartees (source unique)",
        len(validated), min_sources, discarded_single_source,
    )
    return validated


def clean_metadata(questions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Retire les champs internes (_source, _hash, _validated_by, _group_size).

    A appeler avant sauvegarde finale pour ne pas polluer questions.json.

    Args:
        questions: liste de questions avec metadonnees internes.

    Returns:
        Liste de questions nettoyees (sans les champs prefixés par _).
    """
    internal_keys = ("_source", "_hash", "_validated_by", "_group_size")
    cleaned: List[Dict[str, Any]] = []
    for q in questions:
        clean_q = {k: v for k, v in q.items() if k not in internal_keys}
        cleaned.append(clean_q)
    return cleaned


def stats(
    raw_questions: Dict[str, List[Dict[str, Any]]],
    merged: List[Dict[str, Any]],
) -> Dict[str, int]:
    """Calcule des statistiques sur la cross-validation.

    Args:
        raw_questions: dict {source: liste}.
        merged: liste validee apres cross-validation.

    Returns:
        Dict avec cles: claude_count, openai_count, mistral_count,
        total_raw, total_merged, validation_rate.
    """
    raw_total = sum(len(v) for v in raw_questions.values())
    return {
        "claude_count": len(raw_questions.get("claude", [])),
        "openai_count": len(raw_questions.get("openai", [])),
        "mistral_count": len(raw_questions.get("mistral", [])),
        "total_raw": raw_total,
        "total_merged": len(merged),
        "validation_rate": (
            round(len(merged) / raw_total * 100, 1) if raw_total else 0.0
        ),
    }


__all__ = [
    "merge_and_cross_validate",
    "clean_metadata",
    "stats",
    "CROSS_VALIDATE_MAX_BIT_DISTANCE",
    "MIN_SOURCES_FOR_VALIDATION",
]
