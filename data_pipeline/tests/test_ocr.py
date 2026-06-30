"""
Tests unitaires pour la phase OCR (Tesseract + heuristiques maths + cache).

Aucun appel reseau : tous les composants externes (Tesseract, OpenAI, pdf2image)
sont remplaces par des mocks.
"""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from PIL import Image

import utils.tesseract_utils as tesseract_utils
from utils.pdf_utils import count_pdf_pages, save_page_image
from utils.tesseract_utils import (
    detect_math_content,
    normalize_tesseract_text,
    run_tesseract,
)


# ─── detect_math_content ──────────────────────────────────────────────────


def test_detect_math_content_true_with_sqrt():
    """La presence d'un symbole maths declenche le fallback Vision."""
    assert detect_math_content("Calculer √(16)") is True


def test_detect_math_content_true_with_latex():
    """Une fraction en LaTeX est aussi un signal maths."""
    assert detect_math_content("Soit $\\frac{a}{b}$ un rationnel") is True


def test_detect_math_content_true_with_caret():
    """Puissance style x^2 reconnue."""
    assert detect_math_content("Derivee de x^2 + 3x") is True


def test_detect_math_content_false_pure_text():
    """Texte litteraire pur => pas de fallback."""
    assert detect_math_content("Qui est l'auteur de 'Les Fleurs du Mal' ?") is False


def test_detect_math_content_empty():
    assert detect_math_content("") is False


# ─── normalize_tesseract_text ─────────────────────────────────────────────


def test_normalize_rejoins_hyphenated_words():
    """Les mots coupes par un tiret en fin de ligne sont recolles."""
    raw = "calcul\nmath-\nemati-\nque"
    out = normalize_tesseract_text(raw)
    assert "mathematique" in out
    assert "-" not in out


def test_normalize_collapses_excessive_newlines():
    raw = "para1\n\n\n\n\npara2"
    out = normalize_tesseract_text(raw)
    assert out.count("\n\n") == 1


def test_normalize_strips_control_chars():
    raw = "text\x00\x01avec\x02control"
    out = normalize_tesseract_text(raw)
    assert "\x00" not in out and "\x01" not in out and "\x02" not in out


# ─── run_tesseract (mocke) ────────────────────────────────────────────────


def test_run_tesseract_returns_text_on_success(monkeypatch):
    """Tesseract retourne le texte reconnu (mock pytesseract)."""
    fake_image = Image.new("RGB", (10, 10), "white")
    monkeypatch.setattr(
        tesseract_utils.pytesseract,
        "image_to_string",
        lambda *a, **kw: "Bonjour Togo",
    )
    out = run_tesseract(fake_image)
    assert out == "Bonjour Togo"


def test_run_tesseract_returns_empty_on_error(monkeypatch):
    """En cas d'exception, on retourne une chaine vide (pas de crash)."""
    fake_image = Image.new("RGB", (10, 10), "white")

    def boom(*a, **kw):
        raise RuntimeError("tesseract missing")

    monkeypatch.setattr(tesseract_utils.pytesseract, "image_to_string", boom)
    assert run_tesseract(fake_image) == ""


# ─── count_pdf_pages (mocke) ──────────────────────────────────────────────


def test_count_pdf_pages_missing_file(tmp_path):
    """Fichier inexistant -> 0."""
    assert count_pdf_pages(tmp_path / "nope.pdf") == 0


def test_count_pdf_pages_with_mocked_pdfinfo(monkeypatch, tmp_path):
    """Mock pdfinfo_from_path pour renvoyer 5 pages."""
    fake_pdf = tmp_path / "fake.pdf"
    fake_pdf.write_bytes(b"%PDF-1.4 fake")
    monkeypatch.setattr(
        "utils.pdf_utils.pdfinfo_from_path",
        lambda path: {"Pages": "5"},
    )
    assert count_pdf_pages(fake_pdf) == 5


# ─── save_page_image ──────────────────────────────────────────────────────


def test_save_page_image_writes_png(tmp_path):
    img = Image.new("RGB", (100, 100), "white")
    out = save_page_image(img, pdf_id="test_pdf", page_num=1, out_dir=tmp_path)
    assert out.exists()
    assert out.suffix == ".png"
    assert out.name == "test_pdf_p001.png"


# ─── Cache OCR (md5, pdf_id) ──────────────────────────────────────────────


def test_pdf_id_is_stable(tmp_path, monkeypatch):
    """Le pdf_id derive du chemin relatif a PATHS.raw_pdfs."""
    import ocr_extract as ocr_extract_mod
    from config import Paths

    # On construit un Paths fictif pointant vers tmp_path pour la relativisation.
    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path,
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)

    raw = tmp_path / "epreuvesetcorriges" / "BEPC" / "Mathematiques" / "2022_C.pdf"
    raw.parent.mkdir(parents=True)
    raw.write_bytes(b"fake")

    pdf_id = ocr_extract_mod.pdf_id_from_path(raw)
    assert pdf_id == "epreuvesetcorriges_BEPC_Mathematiques_2022_C"


def test_md5_of_file_is_deterministic(tmp_path):
    import ocr_extract as ocr_extract_mod
    f = tmp_path / "a.pdf"
    f.write_bytes(b"hello world")
    h1 = ocr_extract_mod.md5_of_file(f)
    h2 = ocr_extract_mod.md5_of_file(f)
    assert h1 == h2
    assert len(h1) == 32  # md5 hex


# ─── estimate_vision_cost ─────────────────────────────────────────────────


def test_estimate_vision_cost_1500_pages():
    """Le cout estime pour 1500 pages doit etre ~15 USD."""
    from utils.openai_utils import estimate_vision_cost
    assert estimate_vision_cost(1500) == 15.0


def test_estimate_vision_cost_zero():
    from utils.openai_utils import estimate_vision_cost
    assert estimate_vision_cost(0) == 0.0
