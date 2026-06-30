"""
Validation du schéma JSON et de la qualité des questions structurées.

Parcourt tous les fichiers JSON dans `data/structured_questions/` et:
    1. Valide chaque question contre le schema (utils.json_utils).
    2. Verifie la coherence (BEPC -> serie null, BAC -> serie non null, etc.).
    3. Detecte les doublons d'enonce normalises.
    4. Marque les questions suspectes (enonce court, reponse vide, etc.).

Genere un rapport Markdown dans `data/final/validation_report.md`.

Usage:
    python validate_questions.py
    python validate_questions.py --strict   # exit non-zero si invalides
"""

from __future__ import annotations

import argparse
import logging
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

from config import PATHS
from utils.json_utils import (
    is_valid_id,
    load_questions,
    normalize_enonce,
    validate_question_dict,
)

logger = logging.getLogger("validate_questions")


# ─── Modele de rapport ────────────────────────────────────────────────────


@dataclass
class ValidationReport:
    """Aggregate validation statistics and suspicious entries."""

    files_scanned: int = 0
    total_questions: int = 0
    valid_questions: int = 0
    invalid_questions: int = 0
    duplicates: int = 0
    suspects: int = 0
    errors_by_reason: Dict[str, int] = field(default_factory=Counter)
    invalid_examples: List[Tuple[str, List[str]]] = field(default_factory=list)
    duplicate_groups: List[List[str]] = field(default_factory=list)
    by_examen: Dict[str, int] = field(default_factory=Counter)
    by_matiere: Dict[str, int] = field(default_factory=Counter)
    by_annee: Dict[int, int] = field(default_factory=Counter)


# ─── Doublons ─────────────────────────────────────────────────────────────


def find_duplicates(questions: List[Dict]) -> Tuple[List[List[Dict]], int]:
    """Find questions whose normalized enonce collide.

    Args:
        questions: list of question dicts.

    Returns:
        Tuple (duplicate_groups, total_duplicates_count).
        duplicate_groups is a list of groups (each group is a list of
        questions sharing the same normalized enonce, with len >= 2).
    """
    by_norm: Dict[str, List[Dict]] = defaultdict(list)
    for q in questions:
        norm = normalize_enonce(q.get("enonce", ""))
        if norm:
            by_norm[norm].append(q)

    groups: List[List[Dict]] = []
    total_dup = 0
    for norm, qs in by_norm.items():
        if len(qs) >= 2:
            groups.append(qs)
            total_dup += len(qs) - 1  # on garde 1 par groupe
    return groups, total_dup


# ─── Suspects ─────────────────────────────────────────────────────────────

_SUSPECT_MIN_ENONCE_LEN = 10
_SUSPECT_MIN_REPONSE_LEN = 1


def is_suspect(question: Dict) -> List[str]:
    """Return a list of suspicion reasons for a question (empty if OK)."""
    reasons: List[str] = []
    enonce = (question.get("enonce") or "").strip()
    reponse = (question.get("reponse") or "").strip()
    if len(enonce) < _SUSPECT_MIN_ENONCE_LEN:
        reasons.append(f"enonce_court({len(enonce)})")
    if len(reponse) < _SUSPECT_MIN_REPONSE_LEN:
        reasons.append("reponse_vide")
    if not question.get("chapitre"):
        reasons.append("chapitre_manquant")
    if not question.get("explication"):
        reasons.append("explication_manquante")
    if question.get("points") is None:
        reasons.append("points_manquant")
    irt = question.get("irt") or {}
    if irt.get("b") is None:
        reasons.append("irt_b_manquant")
    return reasons


# ─── Validation principale ────────────────────────────────────────────────


def validate_all() -> ValidationReport:
    """Run validation on every JSON file in data/structured_questions/.

    Returns:
        A ValidationReport with all stats.
    """
    report = ValidationReport()
    files = sorted(
        p for p in PATHS.structured_questions.glob("*.json")
        if not p.name.endswith("_invalid.json") and p.name != ".gitkeep"
    )
    report.files_scanned = len(files)
    logger.info("Fichiers a valider: %d", len(files))

    all_questions: List[Dict] = []
    for f in files:
        questions = load_questions(f)
        all_questions.extend(questions)
        for q in questions:
            report.by_examen[q.get("examen", "?")] += 1
            report.by_matiere[q.get("matiere", "?")] += 1
            report.by_annee[q.get("annee", 0)] += 1

    report.total_questions = len(all_questions)

    valid: List[Dict] = []
    invalid: List[Tuple[Dict, List[str]]] = []
    for q in all_questions:
        ok, errs = validate_question_dict(q)
        if ok:
            valid.append(q)
        else:
            invalid.append((q, errs))
            for e in errs:
                report.errors_by_reason[e] += 1
        suspects = is_suspect(q)
        if suspects:
            report.suspects += 1
            if not errs:
                # On n'ajoute que si non deja compte comme invalide.
                pass

    report.valid_questions = len(valid)
    report.invalid_questions = len(invalid)
    if invalid:
        # Limite a 20 exemples pour le rapport.
        for q, errs in invalid[:20]:
            qid = q.get("id", "<no-id>")
            report.invalid_examples.append((qid, errs))

    # Doublons (sur les valides uniquement).
    groups, total_dup = find_duplicates(valid)
    report.duplicates = total_dup
    report.duplicate_groups = [[q.get("id", "?") for q in g] for g in groups[:20]]

    _write_report(report)
    return report


def _write_report(report: ValidationReport) -> None:
    """Write the Markdown validation report to disk."""
    PATHS.final.mkdir(parents=True, exist_ok=True)
    lines: List[str] = [
        "# Rapport de validation des questions",
        "",
        f"- Fichiers scannees : **{report.files_scanned}**",
        f"- Questions totales : **{report.total_questions}**",
        f"- Questions valides : **{report.valid_questions}**",
        f"- Questions invalides : **{report.invalid_questions}**",
        f"- Doublons detectes : **{report.duplicates}**",
        f"- Questions suspectes : **{report.suspects}**",
        "",
        "## Repartition",
        "",
        "### Par examen",
        "",
        "| Examen | Nombre |",
        "|---|---:|",
    ]
    for k, v in sorted(report.by_examen.items()):
        lines.append(f"| {k} | {v} |")
    lines += ["", "### Par matiere", "", "| Matiere | Nombre |", "|---|---:|"]
    for k, v in sorted(report.by_matiere.items(), key=lambda x: -x[1]):
        lines.append(f"| {k} | {v} |")
    lines += ["", "### Par annee", "", "| Annee | Nombre |", "|---|---:|"]
    for k, v in sorted(report.by_annee.items()):
        lines.append(f"| {k} | {v} |")

    if report.errors_by_reason:
        lines += ["", "## Raisons d'invalidite", "",
                  "| Raison | Occurrences |", "|---|---:|"]
        for reason, count in sorted(report.errors_by_reason.items(), key=lambda x: -x[1]):
            lines.append(f"| {reason} | {count} |")

    if report.invalid_examples:
        lines += ["", "## Exemples d'invalides (max 20)", ""]
        for qid, errs in report.invalid_examples:
            lines.append(f"- `{qid}`: {', '.join(errs)}")

    if report.duplicate_groups:
        lines += ["", "## Groupes de doublons (max 20)", ""]
        for group in report.duplicate_groups:
            lines.append("- " + ", ".join(f"`{qid}`" for qid in group))

    PATHS.validation_report.write_text("\n".join(lines), encoding="utf-8")
    logger.info("Rapport ecrit: %s", PATHS.validation_report)


# ─── CLI ──────────────────────────────────────────────────────────────────


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Validation des questions JSON.")
    parser.add_argument("--strict", action="store_true",
                        help="Code de retour non-zero si questions invalides.")
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    )

    report = validate_all()
    print(
        f"Validation: {report.valid_questions} valides / "
        f"{report.total_questions} total ({report.invalid_questions} invalides, "
        f"{report.duplicates} doublons, {report.suspects} suspects)."
    )
    if args.strict and (report.invalid_questions > 0 or report.duplicates > 0):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
