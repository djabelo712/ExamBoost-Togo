"""
Orchestrateur principal du pipeline OCR ExamBoost Togo.

Enchaîne les etapes dans l'ordre:
    1. scrape     — telechargement des PDFs d'annales.
    2. ocr        — extraction de texte (Tesseract + GPT-4o Vision fallback).
    3. structure  — structuration LLM en questions JSON.
    4. validate   — validation du schema + detection doublons.
    5. dedup      — deduplication SimHash.
    6. irt        — estimation initiale du parametre IRT b.

Le pipeline est reprenable: chaque etape persiste son etat (manifeste OCR,
fichiers intermediaires JSON), ce qui permet de relancer apres une
interruption sans tout retraiter.

Usage:
    python run_pipeline.py --full
    python run_pipeline.py --source epreuvesetcorriges --year 2022 --matiere Mathematiques
    python run_pipeline.py --from-ocr            # skip scrape, demarrer a l'OCR
    python run_pipeline.py --from-structure      # skip scrape + ocr
    python run_pipeline.py --only dedup,irt
"""

from __future__ import annotations

import argparse
import logging
import logging.config
import sys
import time
from dataclasses import dataclass, field
from typing import Callable, Dict, List, Optional

from config import LOG_DATE_FORMAT, LOG_FORMAT, LOG_LEVEL, SOURCES
from deduplicate import run_dedup
from estimate_irt import run as run_irt
from ocr_extract import extract_all_manifest_pdfs, extract_text_from_pdf
from scrape_pdfs import load_manifest, scrape_source
from structure_questions import structure_all
from validate_questions import validate_all

logger = logging.getLogger("run_pipeline")


# ─── Etapes ───────────────────────────────────────────────────────────────


@dataclass
class StepResult:
    """Outcome of one pipeline step."""

    name: str
    success: bool
    duration_s: float
    details: Dict = field(default_factory=dict)


def step_scrape(
    source: Optional[str] = None,
    year: Optional[int] = None,
    examen: Optional[str] = None,
    matiere: Optional[str] = None,
    limit: Optional[int] = None,
) -> StepResult:
    """Run the scraping step."""
    start = time.time()
    sources = [source] if source else list(SOURCES.keys())
    total = 0
    for src in sources:
        entries = scrape_source(
            src, year=year, examen=examen, matiere=matiere, limit=limit,
        )
        total += len(entries)
    return StepResult(
        name="scrape",
        success=True,
        duration_s=round(time.time() - start, 2),
        details={"entries": total, "sources": sources},
    )


def step_ocr(use_vision_only: bool = False, limit: Optional[int] = None) -> StepResult:
    """Run the OCR extraction step."""
    start = time.time()
    results = extract_all_manifest_pdfs(
        use_vision_only=use_vision_only, limit=limit,
    )
    return StepResult(
        name="ocr",
        success=True,
        duration_s=round(time.time() - start, 2),
        details={"pdfs_processed": len(results)},
    )


def step_structure(limit: Optional[int] = None) -> StepResult:
    """Run the LLM structuration step."""
    start = time.time()
    stats = structure_all(limit=limit)
    return StepResult(
        name="structure",
        success=True,
        duration_s=round(time.time() - start, 2),
        details=stats,
    )


def step_validate() -> StepResult:
    """Run the schema + duplicate validation step."""
    start = time.time()
    report = validate_all()
    return StepResult(
        name="validate",
        success=True,
        duration_s=round(time.time() - start, 2),
        details={
            "total": report.total_questions,
            "valid": report.valid_questions,
            "invalid": report.invalid_questions,
            "duplicates": report.duplicates,
        },
    )


def step_dedup() -> StepResult:
    """Run the SimHash deduplication step."""
    start = time.time()
    result = run_dedup()
    return StepResult(
        name="dedup",
        success=True,
        duration_s=round(time.time() - start, 2),
        details={
            "input": result.input_count,
            "output": result.output_count,
            "dropped": result.duplicates_dropped,
        },
    )


def step_irt(history_csv: Optional[str] = None) -> StepResult:
    """Run the IRT estimation step."""
    start = time.time()
    from pathlib import Path
    count = run_irt(history_csv=Path(history_csv) if history_csv else None)
    return StepResult(
        name="irt",
        success=True,
        duration_s=round(time.time() - start, 2),
        details={"final_count": count},
    )


# ─── Orchestration ────────────────────────────────────────────────────────


def run_pipeline(
    skip_scrape: bool = False,
    skip_ocr: bool = False,
    skip_structure: bool = False,
    only: Optional[List[str]] = None,
    source: Optional[str] = None,
    year: Optional[int] = None,
    examen: Optional[str] = None,
    matiere: Optional[str] = None,
    limit: Optional[int] = None,
    use_vision_only: bool = False,
    history_csv: Optional[str] = None,
) -> List[StepResult]:
    """Run the full pipeline (or a subset).

    Args:
        skip_scrape / skip_ocr / skip_structure: convenience flags.
        only: explicit list of step names to run (overrides skips).
        source / year / examen / matiere / limit: scrape filters.
        use_vision_only: OCR Vision-only mode (skip Tesseract).
        history_csv: optional CSV of observed success rates for IRT.

    Returns:
        List of StepResult for each executed step.
    """
    all_steps: Dict[str, Callable[[], StepResult]] = {}

    if not (skip_scrape or (only and "scrape" not in only)):
        all_steps["scrape"] = lambda: step_scrape(
            source=source, year=year, examen=examen, matiere=matiere, limit=limit,
        )
    if not (skip_ocr or (only and "ocr" not in only)):
        all_steps["ocr"] = lambda: step_ocr(use_vision_only=use_vision_only, limit=limit)
    if not (skip_structure or (only and "structure" not in only)):
        all_steps["structure"] = lambda: step_structure(limit=limit)
    if not (only and "validate" not in only):
        all_steps["validate"] = step_validate
    if not (only and "dedup" not in only):
        all_steps["dedup"] = step_dedup
    if not (only and "irt" not in only):
        all_steps["irt"] = lambda: step_irt(history_csv=history_csv)

    if only:
        # Restrict to the requested subset, in canonical order.
        canonical = ["scrape", "ocr", "structure", "validate", "dedup", "irt"]
        ordered = [s for s in canonical if s in only]
        all_steps = {s: all_steps[s] for s in ordered if s in all_steps}

    results: List[StepResult] = []
    for name, fn in all_steps.items():
        logger.info("==> Etape: %s", name)
        try:
            res = fn()
            results.append(res)
            logger.info(
                "<== %s OK (%.2fs) %s",
                name, res.duration_s, res.details,
            )
        except Exception as exc:  # noqa: BLE001
            logger.exception("Etape %s en echec: %s", name, exc)
            results.append(StepResult(
                name=name, success=False, duration_s=0.0,
                details={"error": str(exc)},
            ))
            # On continue sur les etapes suivantes si possible.

    _print_summary(results)
    return results


def _print_summary(results: List[StepResult]) -> None:
    """Print a final summary table."""
    print()
    print("=" * 60)
    print("RESUME DU PIPELINE")
    print("=" * 60)
    print(f"{'Etape':<12} {'Statut':<8} {'Duree (s)':<10} {'Details'}")
    print("-" * 60)
    for r in results:
        status = "OK" if r.success else "ECHEC"
        print(f"{r.name:<12} {status:<8} {r.duration_s:<10} {r.details}")
    print("=" * 60)


# ─── CLI ──────────────────────────────────────────────────────────────────


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Pipeline OCR complet: scrape -> OCR -> structure -> validate -> dedup -> IRT."
    )
    parser.add_argument("--full", action="store_true", help="Executer toutes les etapes.")
    parser.add_argument("--from-ocr", action="store_true", help="Skip scrape, demarrer a l'OCR.")
    parser.add_argument("--from-structure", action="store_true",
                        help="Skip scrape + OCR, demarrer a la structuration.")
    parser.add_argument("--only", help="Etapes a executer (separees par virgule).")
    parser.add_argument("--source", help="Source specifique a scraper.")
    parser.add_argument("--year", type=int, help="Filtre annee.")
    parser.add_argument("--examen", choices=["BEPC", "BAC1", "BAC2"],
                        help="Filtre examen.")
    parser.add_argument("--matiere", help="Filtre matiere (label exact).")
    parser.add_argument("--limit", type=int, help="Nombre max de PDFs/fichiers.")
    parser.add_argument("--use-vision-only", action="store_true",
                        help="OCR: bypass Tesseract, GPT-4o Vision sur chaque page.")
    parser.add_argument("--history-csv", help="CSV de taux de reussite pour IRT.")
    args = parser.parse_args(argv)

    # Logging.
    logging.basicConfig(
        level=getattr(logging, LOG_LEVEL.upper(), logging.INFO),
        format=LOG_FORMAT,
        datefmt=LOG_DATE_FORMAT,
    )

    if not any([args.full, args.from_ocr, args.from_structure, args.only,
                args.source, args.year, args.examen, args.matiere]):
        parser.print_help()
        return 1

    only_list = [s.strip() for s in args.only.split(",")] if args.only else None

    results = run_pipeline(
        skip_scrape=args.from_ocr or args.from_structure,
        skip_ocr=args.from_structure,
        only=only_list,
        source=args.source,
        year=args.year,
        examen=args.examen,
        matiere=args.matiere,
        limit=args.limit,
        use_vision_only=args.use_vision_only,
        history_csv=args.history_csv,
    )

    # Exit non-zero if any step failed.
    return 0 if all(r.success for r in results) else 2


if __name__ == "__main__":
    sys.exit(main())
