"""
Extraction OCR des PDFs d'annales.

Pipeline par page:
    1. Conversion PDF -> image (pdf2image, 300 dpi).
    2. Tesseract OCR (langue fra) -> texte brut.
    3. Si la page contient des formules maths (heuristique) -> fallback GPT-4o
       Vision qui renvoie du Markdown avec LaTeX + descriptions de figures.
    4. Concatenation dans data/extracted_text/{id}.txt.

Le cache (images PNG + texte OCR) evite de retraiter un PDF deja vu.

Usage:
    python ocr_extract.py                          # tous les PDFs du manifeste
    python ocr_extract.py --pdf path/to/file.pdf
    python ocr_extract.py --use-vision-only        # bypass Tesseract (maths)
    python ocr_extract.py --limit 5
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

from tqdm import tqdm

from config import OCR_CONFIG, PATHS
from scrape_pdfs import load_manifest, pdf_local_path
from utils.openai_utils import (
    OpenAIConfigError,
    estimate_vision_cost,
    is_openai_configured,
    openai_vision_ocr,
)
from utils.pdf_utils import (
    convert_pdf_to_images,
    count_pdf_pages,
    save_page_image,
)
from utils.tesseract_utils import (
    detect_math_content,
    normalize_tesseract_text,
    run_tesseract,
)

logger = logging.getLogger("ocr_extract")


# ─── Modele de cache ──────────────────────────────────────────────────────


@dataclass
class OcrCacheEntry:
    """Cache entry for a single OCR'd PDF."""

    pdf_id: str
    pdf_path: str
    num_pages: int = 0
    pages_done: List[int] = field(default_factory=list)
    vision_pages: List[int] = field(default_factory=list)
    text_path: Optional[str] = None
    md5: Optional[str] = None
    done: bool = False


def pdf_id_from_path(pdf_path: Path) -> str:
    """Derive a stable pdf_id from a path (relative to raw_pdfs)."""
    try:
        rel = pdf_path.relative_to(PATHS.raw_pdfs)
    except ValueError:
        rel = Path(pdf_path.name)
    return str(rel).replace("/", "_").replace("\\", "_").removesuffix(".pdf")


def md5_of_file(path: Path, chunk: int = 65536) -> str:
    """Compute the MD5 hash of a file (for cache invalidation)."""
    h = hashlib.md5()
    with path.open("rb") as fh:
        while True:
            buf = fh.read(chunk)
            if not buf:
                break
            h.update(buf)
    return h.hexdigest()


# ─── Cache I/O ────────────────────────────────────────────────────────────


def cache_path(pdf_id: str) -> Path:
    return PATHS.cache / f"{pdf_id}.json"


def load_cache(pdf_id: str) -> Optional[OcrCacheEntry]:
    p = cache_path(pdf_id)
    if not p.exists():
        return None
    try:
        with p.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        return OcrCacheEntry(**data)
    except (json.JSONDecodeError, TypeError, OSError) as exc:
        logger.warning("Cache illisible pour %s: %s", pdf_id, exc)
        return None


def save_cache(entry: OcrCacheEntry) -> None:
    p = cache_path(entry.pdf_id)
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open("w", encoding="utf-8") as fh:
        json.dump(entry.__dict__, fh, ensure_ascii=False, indent=2)


# ─── Extraction ───────────────────────────────────────────────────────────


def extract_text_from_pdf(
    pdf_path: Path,
    use_vision_only: bool = False,
    force: bool = False,
) -> str:
    """Run the full OCR pipeline on a single PDF.

    Args:
        pdf_path: path to the PDF on disk.
        use_vision_only: skip Tesseract, call GPT-4o Vision on every page
            (more expensive but more accurate for math-heavy pages).
        force: ignore cache and re-process.

    Returns:
        Concatenated OCR text for the whole PDF.
    """
    pdf_path = Path(pdf_path)
    if not pdf_path.exists():
        logger.error("PDF introuvable: %s", pdf_path)
        return ""

    pdf_id = pdf_id_from_path(pdf_path)
    md5 = md5_of_file(pdf_path)
    cache = load_cache(pdf_id) if not force else None

    if cache and cache.done and cache.md5 == md5:
        # Cache hit: read previously saved text.
        text_path = Path(cache.text_path) if cache.text_path else None
        if text_path and text_path.exists():
            logger.info("Cache hit pour %s", pdf_id)
            return text_path.read_text(encoding="utf-8")

    num_pages = count_pdf_pages(pdf_path)
    if num_pages == 0:
        logger.warning("Aucune page detectee dans %s", pdf_path)
        return ""

    # Reprise partielle: on garde les pages deja traitees.
    pages_done = set(cache.pages_done) if cache else set()
    vision_pages = set(cache.vision_pages) if cache else set()
    accumulated_text: List[str] = []

    # Precharger le texte existant si on reprend.
    if cache and cache.text_path and Path(cache.text_path).exists():
        existing = Path(cache.text_path).read_text(encoding="utf-8").split("\n\n=== PAGE BREAK ===\n\n")
        accumulated_text = existing

    images = convert_pdf_to_images(pdf_path)
    if not images:
        logger.error("Conversion PDF->images echouee pour %s", pdf_path)
        return ""

    out_text_path = PATHS.extracted_text / f"{pdf_id}.txt"
    out_text_path.parent.mkdir(parents=True, exist_ok=True)

    for idx, image in enumerate(tqdm(images, desc=f"OCR {pdf_id}", unit="pg"), start=1):
        if idx in pages_done and not force:
            continue

        page_text = _ocr_one_page(image, idx, pdf_id, use_vision_only)

        # Detect maths and fallback to Vision if needed.
        if not use_vision_only and detect_math_content(page_text):
            logger.info("Page %d: maths detectees -> fallback Vision", idx)
            page_text = _ocr_one_page(image, idx, pdf_id, use_vision_only=True)
            vision_pages.add(idx)

        if idx <= len(accumulated_text):
            accumulated_text[idx - 1] = page_text
        else:
            accumulated_text.append(page_text)
        pages_done.add(idx)

        # Persist partial state (resumable).
        cache_entry = OcrCacheEntry(
            pdf_id=pdf_id,
            pdf_path=str(pdf_path),
            num_pages=num_pages,
            pages_done=sorted(pages_done),
            vision_pages=sorted(vision_pages),
            text_path=str(out_text_path),
            md5=md5,
            done=False,
        )
        save_cache(cache_entry)

    # Final write.
    final_text = "\n\n=== PAGE BREAK ===\n\n".join(accumulated_text)
    out_text_path.write_text(final_text, encoding="utf-8")
    logger.info("Texte OCR sauvegarde: %s (%d caracteres)", out_text_path, len(final_text))

    cache_entry = OcrCacheEntry(
        pdf_id=pdf_id,
        pdf_path=str(pdf_path),
        num_pages=num_pages,
        pages_done=sorted(pages_done),
        vision_pages=sorted(vision_pages),
        text_path=str(out_text_path),
        md5=md5,
        done=True,
    )
    save_cache(cache_entry)

    return final_text


def _ocr_one_page(image, page_num: int, pdf_id: str, use_vision_only: bool) -> str:
    """Run Tesseract or GPT-4o Vision on a single page image."""
    if use_vision_only:
        if not is_openai_configured():
            logger.warning(
                "Vision demandee mais OPENAI_API_KEY absent. Fallback Tesseract."
            )
            return normalize_tesseract_text(run_tesseract(image))
        try:
            saved = save_page_image(image, pdf_id, page_num)
            return openai_vision_ocr(saved)
        except OpenAIConfigError as exc:
            logger.error("Vision OCR impossible: %s", exc)
            return normalize_tesseract_text(run_tesseract(image))
    # Tesseract path.
    text = run_tesseract(image)
    return normalize_tesseract_text(text)


# ─── Driver: tous les PDFs du manifeste ───────────────────────────────────


def extract_all_manifest_pdfs(
    use_vision_only: bool = False,
    limit: Optional[int] = None,
    force: bool = False,
) -> Dict[str, str]:
    """Run OCR on every PDF referenced in the manifest.

    Args:
        use_vision_only: see extract_text_from_pdf.
        limit: max number of PDFs to process.
        force: ignore cache.

    Returns:
        Dict {pdf_id: text_path}.
    """
    manifest = load_manifest()
    pending = [e for e in manifest.entries if e.status == "downloaded" and e.local_path]
    if limit:
        pending = pending[:limit]
    logger.info("PDFs a traiter: %d", len(pending))

    total_pages = 0
    for entry in pending:
        total_pages += count_pdf_pages(Path(entry.local_path))
    estimated_cost = estimate_vision_cost(total_pages) if use_vision_only else estimate_vision_cost(int(total_pages * 0.3))
    logger.info(
        "Cout estime OCR Vision: ~%.2f USD pour ~%d pages",
        estimated_cost, total_pages,
    )

    results: Dict[str, str] = {}
    for entry in tqdm(pending, desc="PDFs", unit="pdf"):
        pdf_path = Path(entry.local_path)
        text = extract_text_from_pdf(pdf_path, use_vision_only=use_vision_only, force=force)
        results[pdf_id_from_path(pdf_path)] = text
    return results


# ─── CLI ──────────────────────────────────────────────────────────────────


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="OCR extraction des PDFs d'annales.")
    parser.add_argument("--pdf", type=Path, help="Chemin d'un PDF specifique.")
    parser.add_argument("--use-vision-only", action="store_true",
                        help="Bypass Tesseract, utiliser GPT-4o Vision sur chaque page.")
    parser.add_argument("--limit", type=int, help="Nombre max de PDFs (manifeste).")
    parser.add_argument("--force", action="store_true",
                        help="Ignorer le cache OCR et retraiter.")
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    )

    if args.pdf:
        text = extract_text_from_pdf(
            args.pdf,
            use_vision_only=args.use_vision_only,
            force=args.force,
        )
        print(f"OCR termine: {len(text)} caracteres.")
    else:
        extract_all_manifest_pdfs(
            use_vision_only=args.use_vision_only,
            limit=args.limit,
            force=args.force,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
