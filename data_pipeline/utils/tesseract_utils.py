"""
Configuration et helpers pour Tesseract OCR (langue francaise).

Toutes les fonctions sont pures et s'appuient sur pytesseract. Aucune
connexion reseau n'est necessaire.
"""

from __future__ import annotations

import logging
import re
import unicodedata
from pathlib import Path
from typing import List, Optional

import pytesseract
from PIL import Image

from config import OCR_CONFIG

logger = logging.getLogger(__name__)


# Configuration Tesseract optimisee pour les documents francais scannes.
# -oem 3 : reseaux de neurones LSTM (defaut, le plus precis)
# -psm 6 : page unique, bloc de texte (bon pour annales)
TESSERACT_CONFIG: str = "--oem 3 --psm 6 -l fra"


def run_tesseract(
    image: Image.Image,
    lang: Optional[str] = None,
    custom_config: Optional[str] = None,
) -> str:
    """Run Tesseract OCR on a single PIL image.

    Args:
        image: PIL image (page rasterisee).
        lang: code langue Tesseract (defaut: config).
        custom_config: surcharge de la config Tesseract.

    Returns:
        Texte reconnu, brut (peut contenir du bruit OCR).
    """
    lang = lang or OCR_CONFIG.tesseract_lang
    config = custom_config or TESSERACT_CONFIG
    try:
        text = pytesseract.image_to_string(image, lang=lang, config=config)
        logger.debug("Tesseract OK (%d caracteres)", len(text))
        return text
    except Exception as exc:  # noqa: BLE001
        logger.error("Erreur Tesseract: %s", exc)
        return ""


def detect_math_content(text: str) -> bool:
    """Heuristique: detecte si une page contient des formules mathematiques.

    Args:
        text: texte OCR (Tesseract) d'une page.

    Returns:
        True si au moins un symbole mathematique est present, sinon False.
        Declenche le fallback GPT-4o Vision dans ocr_extract.py.
    """
    if not text:
        return False
    for symbol in OCR_CONFIG.math_symbols:
        if symbol in text:
            return True
    # Motifs additionnels (fractions "a/b", puissances "x^2", etc.)
    if re.search(r"\b\d+\s*/\s*\d+\b", text):
        return True
    if re.search(r"[a-zA-Z]\^\{?[0-9]+\}?", text):
        return True
    if re.search(r"\\(frac|sqrt|sum|int|lim)", text):
        return True
    return False


def normalize_tesseract_text(text: str) -> str:
    """Clean raw Tesseract output: trim, collapse whitespace, fix hyphens.

    Args:
        text: texte OCR brut.

    Returns:
        Texte normalise, lisible par le LLM de structuration.
    """
    if not text:
        return ""
    # Recoller les mots coupes en fin de ligne (tiret + newline).
    text = re.sub(r"-\s*\n\s*", "", text)
    # Remplacer les newlines isoles par des espaces, garder les paragraphes.
    text = re.sub(r"[ \t]*\n[ \t]*", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    # Supprimer les caracteres de controle non imprimables.
    text = "".join(ch for ch in text if unicodedata.category(ch)[0] != "C" or ch in "\n\t")
    return text.strip()


def available_languages() -> List[str]:
    """List Tesseract languages installed on the system.

    Returns:
        Sorted list of language codes (e.g. ['eng', 'fra']).
    """
    try:
        langs = pytesseract.get_languages(config="")
        return sorted(langs or [])
    except Exception as exc:  # noqa: BLE001
        logger.warning("Impossible de lister les langues Tesseract: %s", exc)
        return []


def ensure_french_available() -> bool:
    """Verify that the French language pack is installed.

    Returns:
        True if 'fra' is available, else False.
    """
    return "fra" in available_languages()


__all__ = [
    "TESSERACT_CONFIG",
    "run_tesseract",
    "detect_math_content",
    "normalize_tesseract_text",
    "available_languages",
    "ensure_french_available",
]
