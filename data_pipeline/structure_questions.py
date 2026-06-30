"""
Structuration du texte OCR en questions JSON via GPT-4o-mini.

Pour chaque fichier texte dans `data/extracted_text/`:
    1. Charge le texte OCR.
    2. Determine l'examen, la matiere, l'annee, la serie depuis le nom du
       fichier (construit par ocr_extract.py a partir du manifeste).
    3. Appelle GPT-4o-mini avec un prompt structure pour extraire toutes les
       questions au format JSON attendu par l'app Flutter.
    4. Sauvegarde le resultat dans
       `data/structured_questions/{source}_{annee}_{matiere}.json`.

Usage:
    python structure_questions.py
    python structure_questions.py --file data/extracted_text/foo.txt
    python structure_questions.py --limit 10
"""

from __future__ import annotations

import argparse
import logging
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from tqdm import tqdm

from config import PATHS
from utils.json_utils import (
    build_question_id,
    is_valid_id,
    save_questions,
    validate_question_dict,
)
from utils.openai_utils import (
    OpenAIConfigError,
    is_openai_configured,
    openai_structure_questions,
)

logger = logging.getLogger("structure_questions")


# ─── Parsing du nom de fichier OCR ────────────────────────────────────────

# Format attendu: {source}_{examen}_{matiere}_{annee}_{serie}.txt
# Ex: epreuvesetcorriges_BEPC_Mathematiques_2022_TOUTES.txt
# Ex: epreuvesetcorriges_BAC1_Mathematiques_2023_C.txt
_FILE_NAME_RE = re.compile(
    r"^(?P<source>[^_]+)_(?P<examen>BEPC|BAC1|BAC2|Probatoire)"
    r"_(?P<matiere>[A-Za-zÀ-ÿ ]+?)"
    r"_(?P<annee>\d{4})"
    r"(?:_(?P<serie>[A-F]|TOUTES))?\.txt$"
)


def parse_ocr_filename(filename: str) -> Optional[Dict[str, object]]:
    """Extract metadata from an OCR text filename.

    Args:
        filename: basename of the .txt file (no path).

    Returns:
        Dict with keys source/examen/matiere/annee/serie, or None if the
        filename does not follow the expected convention.
    """
    m = _FILE_NAME_RE.match(filename)
    if not m:
        return None
    serie = m.group("serie")
    if serie in (None, "TOUTES"):
        serie = None
    return {
        "source": m.group("source"),
        "examen": m.group("examen"),
        "matiere": m.group("matiere").replace("_", " "),
        "annee": int(m.group("annee")),
        "serie": serie,
    }


# ─── Renumerotation / normalization post-LLM ──────────────────────────────


def normalize_questions(
    raw_questions: List[Dict],
    examen: str,
    matiere: str,
    annee: int,
    serie: Optional[str],
) -> List[Dict]:
    """Normalize LLM output: rebuild ids, force coherence on serie/examen.

    Args:
        raw_questions: list of dicts as returned by GPT-4o-mini.
        examen/matiere/annee/serie: authoritative metadata from filename.

    Returns:
        List of normalized question dicts (still unvalidated).
    """
    normalized: List[Dict] = []
    for idx, q in enumerate(raw_questions, start=1):
        if not isinstance(q, dict):
            continue
        # Force coherence.
        q["examen"] = examen
        q["annee"] = annee
        q["matiere"] = matiere
        if examen == "BEPC":
            q["serie"] = None
        else:
            q["serie"] = serie or q.get("serie")
        # Rebuild canonical id.
        q["id"] = build_question_id(examen, matiere, annee, idx, serie)
        # Ensure irt dict is present.
        if not isinstance(q.get("irt"), dict):
            q["irt"] = {"a": None, "b": None, "c": None, "calibre": False}
        else:
            q["irt"].setdefault("a", None)
            q["irt"].setdefault("b", None)
            q["irt"].setdefault("c", None)
            q["irt"].setdefault("calibre", False)
        # Choix coerent.
        if q.get("type") not in ("qcm", "vraiFaux"):
            q["choix"] = None
        elif not q.get("choix"):
            q["choix"] = None
        normalized.append(q)
    return normalized


# ─── Traitement d'un fichier OCR ──────────────────────────────────────────


def structure_one_file(text_path: Path) -> Tuple[List[Dict], List[Dict]]:
    """Structure questions from a single OCR text file.

    Args:
        text_path: path to a .txt produced by ocr_extract.py.

    Returns:
        Tuple (valid_questions, invalid_questions).
    """
    meta = parse_ocr_filename(text_path.name)
    if not meta:
        logger.warning("Nom de fichier non parsable: %s", text_path.name)
        return [], []

    if not is_openai_configured():
        raise OpenAIConfigError(
            "OPENAI_API_KEY manquant. Configurez .env avant de lancer la phase structure."
        )

    ocr_text = text_path.read_text(encoding="utf-8")
    if not ocr_text.strip():
        logger.warning("Fichier OCR vide: %s", text_path)
        return [], []

    raw_questions = openai_structure_questions(
        ocr_text=ocr_text,
        examen=meta["examen"],
        matiere=meta["matiere"],
        annee=meta["annee"],
        serie=meta["serie"],
    )
    logger.info("LLM a retourne %d question(s) brute(s) pour %s",
                len(raw_questions), text_path.name)

    normalized = normalize_questions(
        raw_questions,
        examen=meta["examen"],
        matiere=meta["matiere"],
        annee=meta["annee"],
        serie=meta["serie"],
    )

    valid: List[Dict] = []
    invalid: List[Dict] = []
    for q in normalized:
        ok, errs = validate_question_dict(q)
        if ok:
            valid.append(q)
        else:
            q["_validation_errors"] = errs
            invalid.append(q)

    # Persistance.
    out_path = PATHS.structured_questions / f"{meta['source']}_{meta['annee']}_{meta['matiere'].replace(' ', '_')}.json"
    save_questions(valid, out_path)
    if invalid:
        invalid_path = PATHS.structured_questions / f"{meta['source']}_{meta['annee']}_{meta['matiere'].replace(' ', '_')}_invalid.json"
        save_questions(invalid, invalid_path)
    logger.info(
        "Structure complete: %d valides, %d invalides -> %s",
        len(valid), len(invalid), out_path.name,
    )
    return valid, invalid


def structure_all(limit: Optional[int] = None) -> Dict[str, int]:
    """Run structuration on every OCR text file in data/extracted_text/.

    Args:
        limit: max number of files to process.

    Returns:
        Dict {"files": N, "valid": N, "invalid": N}.
    """
    files = sorted(p for p in PATHS.extracted_text.glob("*.txt") if p.name != ".gitkeep")
    if limit:
        files = files[:limit]
    logger.info("Fichiers OCR a structurer: %d", len(files))

    total_valid = 0
    total_invalid = 0
    for f in tqdm(files, desc="Structure", unit="file"):
        try:
            valid, invalid = structure_one_file(f)
            total_valid += len(valid)
            total_invalid += len(invalid)
        except OpenAIConfigError as exc:
            logger.error("Arret: %s", exc)
            break
        except Exception as exc:  # noqa: BLE001
            logger.error("Echec structuration %s: %s", f.name, exc)

    return {"files": len(files), "valid": total_valid, "invalid": total_invalid}


# ─── CLI ──────────────────────────────────────────────────────────────────


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Structuration LLM des OCR en questions JSON."
    )
    parser.add_argument("--file", type=Path, help="Fichier OCR specifique.")
    parser.add_argument("--limit", type=int, help="Nombre max de fichiers.")
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    )

    if args.file:
        structure_one_file(args.file)
    else:
        stats = structure_all(limit=args.limit)
        logger.info(
            "Stats finales: %d fichiers, %d valides, %d invalides",
            stats["files"], stats["valid"], stats["invalid"],
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
