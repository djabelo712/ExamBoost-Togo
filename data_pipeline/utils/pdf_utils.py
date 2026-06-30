"""
Utilitaires pour la conversion PDF -> images.

Wrapper autour de pdf2image (qui s'appuie sur poppler-utils). Toutes les
fonctions sont pures et ne realisent aucun appel reseau.
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import List, Optional

from pdf2image import convert_from_path, pdfinfo_from_path
from PIL import Image

from config import OCR_CONFIG, PATHS

logger = logging.getLogger(__name__)


def count_pdf_pages(pdf_path: Path | str) -> int:
    """Return the total number of pages in a PDF file.

    Args:
        pdf_path: path to the PDF on disk.

    Returns:
        Number of pages (>=1). Returns 0 if the file cannot be parsed.
    """
    pdf_path = Path(pdf_path)
    if not pdf_path.exists():
        logger.warning("PDF introuvable: %s", pdf_path)
        return 0
    try:
        info = pdfinfo_from_path(str(pdf_path))
        return int(info.get("Pages", 0))
    except Exception as exc:  # noqa: BLE001
        logger.error("Impossible de lire le nombre de pages de %s: %s", pdf_path, exc)
        return 0


def convert_pdf_to_images(
    pdf_path: Path | str,
    dpi: Optional[int] = None,
    first_page: int = 1,
    last_page: Optional[int] = None,
) -> List[Image.Image]:
    """Convert a PDF document into a list of PIL images (one per page).

    Args:
        pdf_path: path to the PDF file.
        dpi: resolution for rasterisation (default: config.OCR_CONFIG.dpi).
        first_page: 1-based index of the first page to convert.
        last_page: 1-based index of the last page to convert (None = all).

    Returns:
        List of PIL.Image in RGB mode. Empty list if the conversion fails.
    """
    pdf_path = Path(pdf_path)
    dpi = dpi or OCR_CONFIG.dpi
    try:
        images = convert_from_path(
            str(pdf_path),
            dpi=dpi,
            first_page=first_page,
            last_page=last_page or 0,
            fmt="png",
        )
        logger.info(
            "PDF converti: %s -> %d page(s) @ %d dpi",
            pdf_path.name,
            len(images),
            dpi,
        )
        return images
    except Exception as exc:  # noqa: BLE001
        logger.error("Erreur conversion PDF %s: %s", pdf_path, exc)
        return []


def save_page_image(
    image: Image.Image,
    pdf_id: str,
    page_num: int,
    out_dir: Optional[Path] = None,
) -> Path:
    """Persist a single page image to the OCR cache directory.

    Args:
        image: PIL image (one PDF page).
        pdf_id: stable identifier (e.g. "epreuvesetcorriges_BEPC_Mathematiques_2022").
        page_num: 1-based page number.
        out_dir: override directory (defaults to PATHS.cache).

    Returns:
        Path to the saved PNG.
    """
    out_dir = out_dir or PATHS.cache
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{pdf_id}_p{page_num:03d}.png"
    if image.mode != "RGB":
        image = image.convert("RGB")
    image.save(out_path, format="PNG")
    return out_path


def cleanup_page_images(pdf_id: str, out_dir: Optional[Path] = None) -> int:
    """Delete cached page images for a given PDF id.

    Args:
        pdf_id: identifier used when saving.
        out_dir: directory containing the PNGs.

    Returns:
        Number of files deleted.
    """
    out_dir = out_dir or PATHS.cache
    if not out_dir.exists():
        return 0
    count = 0
    for f in out_dir.glob(f"{pdf_id}_p*.png"):
        try:
            f.unlink()
            count += 1
        except OSError as exc:  # noqa: BLE001
            logger.warning("Suppression impossible %s: %s", f, exc)
    return count


__all__ = [
    "count_pdf_pages",
    "convert_pdf_to_images",
    "save_page_image",
    "cleanup_page_images",
]
