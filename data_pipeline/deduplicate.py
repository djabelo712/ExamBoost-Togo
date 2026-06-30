"""
Déduplication des questions par hachage SimHash.

Approche:
    - Normalise chaque enonce (lowercase, sans accents, sans ponctuation).
    - Calcule un SimHash 64 bits par question.
    - Compare les hashes par distance de Hamming.
    - Pour chaque cluster de questions similaires (distance <= seuil), on
      garde la version "la plus complete" (avec explication + points + IRT).
    - Les questions validees sont sauvegardees dans
      `data/final/questions_dedup.json` (etape intermediaire avant IRT).

Usage:
    python deduplicate.py
    python deduplicate.py --threshold 10   # distance max (0-64)
"""

from __future__ import annotations

import argparse
import logging
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

from simhash import Simhash, SimhashIndex

from config import (
    PATHS,
    SIMILARITY_MAX_BIT_DISTANCE,
    SIMILARITY_PERCENT_THRESHOLD,
)
from utils.json_utils import load_questions, normalize_enonce, save_questions

logger = logging.getLogger("deduplicate")


# ─── Score de completude ──────────────────────────────────────────────────


def completeness_score(q: Dict) -> int:
    """Score (0-5): how complete is the question?

    Higher score = keep this one when duplicates collide.
    """
    score = 0
    if (q.get("enonce") or "").strip():
        score += 1
    if (q.get("reponse") or "").strip():
        score += 1
    if (q.get("explication") or "").strip():
        score += 1
    if q.get("points") is not None:
        score += 1
    if isinstance(q.get("irt"), dict) and q["irt"].get("b") is not None:
        score += 1
    return score


# ─── SimHash ──────────────────────────────────────────────────────────────


def compute_simhash(question: Dict) -> Simhash:
    """Compute the SimHash of a question's normalized enonce."""
    norm = normalize_enonce(question.get("enonce", ""))
    # Decoupage en shingles de 3 mots (meilleure precision que mots uniques).
    tokens = norm.split()
    if len(tokens) < 3:
        features = tokens
    else:
        features = [" ".join(tokens[i:i + 3]) for i in range(len(tokens) - 2)]
    return Simhash(features or ["empty"])


@dataclass
class DedupResult:
    """Outcome of a dedup run."""

    input_count: int = 0
    output_count: int = 0
    duplicates_dropped: int = 0
    clusters: List[List[str]] = field(default_factory=list)


def deduplicate_questions(
    questions: List[Dict],
    threshold: int = SIMILARITY_MAX_BIT_DISTANCE,
) -> Tuple[List[Dict], DedupResult]:
    """Remove near-duplicate questions using SimHash.

    Args:
        questions: input list of question dicts.
        threshold: max Hamming distance to consider two questions duplicates.

    Returns:
        Tuple (kept_questions, DedupResult with stats).
    """
    result = DedupResult(input_count=len(questions))

    # Index Simhash pour recherche rapide des voisins.
    objs: List[Tuple[str, Simhash]] = []
    for idx, q in enumerate(questions):
        sh = compute_simhash(q)
        objs.append((f"q{idx}", sh))
    index = SimhashIndex(objs, k=threshold)

    seen: Set[int] = set()
    kept: List[Dict] = []
    clusters: List[List[str]] = []

    for idx, q in enumerate(questions):
        if idx in seen:
            continue
        sh = objs[idx][1]
        near_ids = index.get_near_dups(sh)
        # Recuperer les indices correspondants.
        cluster_idx = [int(nid[1:]) for nid in near_ids]
        cluster_idx = [i for i in cluster_idx if i not in seen]
        if not cluster_idx:
            cluster_idx = [idx]
        # Garder la question la plus complete.
        best_idx = max(cluster_idx, key=lambda i: (completeness_score(questions[i]), i))
        kept.append(questions[best_idx])
        for i in cluster_idx:
            seen.add(i)
        if len(cluster_idx) > 1:
            clusters.append([questions[i].get("id", f"q{i}") for i in cluster_idx])

    result.output_count = len(kept)
    result.duplicates_dropped = len(questions) - len(kept)
    result.clusters = clusters[:20]
    return kept, result


# ─── Driver ───────────────────────────────────────────────────────────────


def run_dedup(
    input_dir: Optional[Path] = None,
    output_path: Optional[Path] = None,
    threshold: int = SIMILARITY_MAX_BIT_DISTANCE,
) -> DedupResult:
    """Load all structured questions, dedup, save to data/final/.

    Args:
        input_dir: override source dir (defaults to PATHS.structured_questions).
        output_path: override output file (defaults to PATHS.final / questions_dedup.json).
        threshold: Hamming threshold.

    Returns:
        DedupResult stats.
    """
    input_dir = input_dir or PATHS.structured_questions
    output_path = output_path or (PATHS.final / "questions_dedup.json")

    all_questions: List[Dict] = []
    for f in sorted(input_dir.glob("*.json")):
        if f.name.endswith("_invalid.json") or f.name == ".gitkeep":
            continue
        all_questions.extend(load_questions(f))

    logger.info("Charge %d questions depuis %s", len(all_questions), input_dir)

    kept, result = deduplicate_questions(all_questions, threshold=threshold)
    save_questions(kept, output_path)

    logger.info(
        "Dedup: %d -> %d (-%d, seuil distance=%d bits, ~%.1f%% similarite)",
        result.input_count, result.output_count, result.duplicates_dropped,
        threshold, SIMILARITY_PERCENT_THRESHOLD,
    )
    return result


# ─── CLI ──────────────────────────────────────────────────────────────────


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Deduplication SimHash des questions.")
    parser.add_argument("--threshold", type=int,
                        default=SIMILARITY_MAX_BIT_DISTANCE,
                        help=f"Distance de Hamming max (defaut: {SIMILARITY_MAX_BIT_DISTANCE}, "
                             f"soit ~{SIMILARITY_PERCENT_THRESHOLD}% similarite).")
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    )
    run_dedup(threshold=args.threshold)
    return 0


if __name__ == "__main__":
    sys.exit(main())
