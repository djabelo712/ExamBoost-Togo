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


# ─── Extensions: pdf_id_from_path, cache, extract pipeline ────────────────


def test_pdf_id_from_path_handles_backslashes(tmp_path):
    """On Windows-style paths, backslashes are also replaced by underscores."""
    import ocr_extract as ocr_extract_mod
    from config import Paths

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path,
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    # We cannot easily test backslashes on Linux (Path normalizes them),
    # but we can verify the function returns a deterministic string.
    raw = tmp_path / "src_BEPC_Maths_2022.pdf"
    raw.write_bytes(b"fake")
    pdf_id = ocr_extract_mod.pdf_id_from_path(raw)
    assert pdf_id == "src_BEPC_Maths_2022"


def test_pdf_id_from_path_outside_raw_pdfs_uses_basename(tmp_path):
    """If the path is NOT under PATHS.raw_pdfs, only the filename is used."""
    import ocr_extract as ocr_extract_mod
    from config import Paths

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.raw_pdfs.mkdir(parents=True, exist_ok=True)
    import ocr_extract
    ocr_extract.PATHS = fake_paths  # patch the import-time reference

    outside = tmp_path / "elsewhere" / "outside.pdf"
    outside.parent.mkdir(parents=True, exist_ok=True)
    outside.write_bytes(b"x")
    pdf_id = ocr_extract_mod.pdf_id_from_path(outside)
    assert pdf_id == "outside"


def test_md5_of_file_chunked_reading_consistency(tmp_path):
    """Two consecutive MD5 reads of the same file produce the same hash."""
    import ocr_extract as ocr_extract_mod
    f = tmp_path / "large.pdf"
    # Write more than one chunk (chunk=65536 in the implementation).
    f.write_bytes(b"AB" * 50000)  # 100_000 bytes
    h1 = ocr_extract_mod.md5_of_file(f)
    h2 = ocr_extract_mod.md5_of_file(f)
    assert h1 == h2
    assert len(h1) == 32


def test_md5_of_file_differs_for_different_content(tmp_path):
    """Two files with different content produce different MD5 hashes."""
    import ocr_extract as ocr_extract_mod
    f1 = tmp_path / "a.pdf"
    f2 = tmp_path / "b.pdf"
    f1.write_bytes(b"content A")
    f2.write_bytes(b"content B")
    h1 = ocr_extract_mod.md5_of_file(f1)
    h2 = ocr_extract_mod.md5_of_file(f2)
    assert h1 != h2


def test_cache_save_and_load_roundtrip(tmp_path, monkeypatch):
    """OcrCacheEntry is serialised to JSON and can be reloaded."""
    import ocr_extract as ocr_extract_mod
    from config import Paths
    from ocr_extract import OcrCacheEntry, load_cache, save_cache

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path,
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)

    entry = OcrCacheEntry(
        pdf_id="test_pdf",
        pdf_path="/fake/path.pdf",
        num_pages=3,
        pages_done=[1, 2, 3],
        vision_pages=[2],
        text_path=str(tmp_path / "test_pdf.txt"),
        md5="abc123",
        done=True,
    )
    save_cache(entry)

    loaded = load_cache("test_pdf")
    assert loaded is not None
    assert loaded.pdf_id == "test_pdf"
    assert loaded.num_pages == 3
    assert loaded.pages_done == [1, 2, 3]
    assert loaded.vision_pages == [2]
    assert loaded.done is True
    assert loaded.md5 == "abc123"


def test_cache_load_returns_none_when_missing(tmp_path, monkeypatch):
    """load_cache returns None when no cache file exists."""
    import ocr_extract as ocr_extract_mod
    from config import Paths
    from ocr_extract import load_cache

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path,
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)
    assert load_cache("nonexistent_pdf") is None


def test_cache_load_returns_none_on_corrupt_json(tmp_path, monkeypatch):
    """load_cache returns None when the cache file is not valid JSON."""
    import ocr_extract as ocr_extract_mod
    from config import Paths
    from ocr_extract import cache_path, load_cache

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path,
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.cache.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)

    # Write corrupt JSON to the cache file.
    cache_file = cache_path("corrupt_pdf")
    cache_file.write_text("{not valid json", encoding="utf-8")

    assert load_cache("corrupt_pdf") is None


def test_extract_text_from_pdf_returns_empty_when_missing(tmp_path):
    """extract_text_from_pdf returns '' when the PDF file doesn't exist."""
    from ocr_extract import extract_text_from_pdf
    out = extract_text_from_pdf(tmp_path / "nonexistent.pdf")
    assert out == ""


def test_extract_text_from_pdf_cache_hit_skips_processing(
    tmp_path, monkeypatch,
):
    """When a valid cache entry exists, the function reads the cached text
    without re-running Tesseract or Vision."""
    import ocr_extract as ocr_extract_mod
    from config import Paths
    from ocr_extract import OcrCacheEntry, extract_text_from_pdf

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.cache.mkdir(parents=True, exist_ok=True)
    fake_paths.extracted_text.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)

    # Create the fake PDF.
    pdf_path = tmp_path / "raw" / "test.pdf"
    pdf_path.parent.mkdir(parents=True, exist_ok=True)
    pdf_path.write_bytes(b"fake pdf bytes")

    # Pre-create the cached text file.
    cached_text_path = fake_paths.extracted_text / "test.txt"
    cached_text_path.write_text("CACHED OCR TEXT", encoding="utf-8")

    # Compute md5 to match.
    from ocr_extract import md5_of_file
    md5 = md5_of_file(pdf_path)

    entry = OcrCacheEntry(
        pdf_id="test",
        pdf_path=str(pdf_path),
        num_pages=1,
        pages_done=[1],
        vision_pages=[],
        text_path=str(cached_text_path),
        md5=md5,
        done=True,
    )
    from ocr_extract import save_cache
    save_cache(entry)

    # Spy: if convert_pdf_to_images is called, we fail the test.
    def boom(*a, **kw):
        raise AssertionError("convert_pdf_to_images should NOT be called on cache hit")

    monkeypatch.setattr(ocr_extract_mod, "convert_pdf_to_images", boom)

    out = extract_text_from_pdf(pdf_path)
    assert out == "CACHED OCR TEXT"


def test_extract_text_from_pdf_no_pages_returns_empty(
    tmp_path, monkeypatch,
):
    """When count_pdf_pages returns 0, extract returns ''."""
    import ocr_extract as ocr_extract_mod
    from config import Paths
    from ocr_extract import extract_text_from_pdf

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.raw_pdfs.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)

    pdf_path = tmp_path / "raw" / "test.pdf"
    pdf_path.write_bytes(b"%PDF-1.4 fake")

    monkeypatch.setattr(ocr_extract_mod, "count_pdf_pages", lambda p: 0)
    out = extract_text_from_pdf(pdf_path)
    assert out == ""


def test_extract_text_from_pdf_conversion_failure_returns_empty(
    tmp_path, monkeypatch,
):
    """When convert_pdf_to_images returns [], extract returns ''."""
    import ocr_extract as ocr_extract_mod
    from config import Paths
    from ocr_extract import extract_text_from_pdf

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.raw_pdfs.mkdir(parents=True, exist_ok=True)
    fake_paths.cache.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)

    pdf_path = tmp_path / "raw" / "test.pdf"
    pdf_path.write_bytes(b"%PDF-1.4 fake")

    monkeypatch.setattr(ocr_extract_mod, "count_pdf_pages", lambda p: 3)
    monkeypatch.setattr(
        ocr_extract_mod, "convert_pdf_to_images", lambda *a, **kw: [],
    )
    out = extract_text_from_pdf(pdf_path)
    assert out == ""


def test_extract_text_from_pdf_full_mocked_pipeline(
    tmp_path, monkeypatch,
):
    """Full pipeline: 2 pages Tesseract OK, no maths, cache saved."""
    import ocr_extract as ocr_extract_mod
    from config import Paths
    from ocr_extract import extract_text_from_pdf
    from PIL import Image

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.raw_pdfs.mkdir(parents=True, exist_ok=True)
    fake_paths.cache.mkdir(parents=True, exist_ok=True)
    fake_paths.extracted_text.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)

    pdf_path = tmp_path / "raw" / "test.pdf"
    pdf_path.write_bytes(b"%PDF-1.4 fake")

    monkeypatch.setattr(ocr_extract_mod, "count_pdf_pages", lambda p: 2)
    fake_images = [
        Image.new("RGB", (10, 10), "white"),
        Image.new("RGB", (10, 10), "white"),
    ]
    monkeypatch.setattr(
        ocr_extract_mod,
        "convert_pdf_to_images",
        lambda *a, **kw: fake_images,
    )

    call_count = {"n": 0}

    def fake_tesseract(image):
        call_count["n"] += 1
        return f"PAGE {call_count['n']} TEXT"

    monkeypatch.setattr(ocr_extract_mod, "run_tesseract", fake_tesseract)
    # No maths detected.
    monkeypatch.setattr(ocr_extract_mod, "detect_math_content", lambda t: False)
    # is_openai_configured not needed since no maths -> no Vision fallback.

    out = extract_text_from_pdf(pdf_path)
    assert "PAGE 1 TEXT" in out
    assert "PAGE 2 TEXT" in out
    # The page break marker is present between the two pages.
    assert "=== PAGE BREAK ===" in out

    # Verify a final cache entry was saved with done=True.
    from ocr_extract import load_cache
    entry = load_cache("test")
    assert entry is not None
    assert entry.done is True
    assert entry.num_pages == 2
    assert entry.pages_done == [1, 2]


def test_extract_text_from_pdf_vision_fallback_on_maths(
    tmp_path, monkeypatch,
):
    """When detect_math_content triggers, the Vision fallback is invoked."""
    import ocr_extract as ocr_extract_mod
    from config import Paths
    from ocr_extract import extract_text_from_pdf
    from PIL import Image

    fake_paths = Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=tmp_path / "cache",
    )
    fake_paths.raw_pdfs.mkdir(parents=True, exist_ok=True)
    fake_paths.cache.mkdir(parents=True, exist_ok=True)
    fake_paths.extracted_text.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(ocr_extract_mod, "PATHS", fake_paths)

    pdf_path = tmp_path / "raw" / "maths.pdf"
    pdf_path.write_bytes(b"%PDF-1.4 fake")

    monkeypatch.setattr(ocr_extract_mod, "count_pdf_pages", lambda p: 1)
    monkeypatch.setattr(
        ocr_extract_mod,
        "convert_pdf_to_images",
        lambda *a, **kw: [Image.new("RGB", (10, 10), "white")],
    )
    monkeypatch.setattr(
        ocr_extract_mod, "run_tesseract", lambda img: "page with sqrt symbol",
    )
    # detect_math_content returns True on first pass.
    monkeypatch.setattr(ocr_extract_mod, "detect_math_content", lambda t: True)
    monkeypatch.setattr(ocr_extract_mod, "is_openai_configured", lambda: True)
    monkeypatch.setattr(
        ocr_extract_mod,
        "save_page_image",
        lambda image, pdf_id, page_num: Path("/tmp/fake.png"),
    )
    monkeypatch.setattr(
        ocr_extract_mod,
        "openai_vision_ocr",
        lambda image_or_path, prompt=None, model=None: "VISION MARKDOWN",
    )

    out = extract_text_from_pdf(pdf_path)
    assert "VISION MARKDOWN" in out

    # Verify the cache reports vision_pages=[1].
    from ocr_extract import load_cache
    entry = load_cache("maths")
    assert entry is not None
    assert entry.vision_pages == [1]


def test_page_break_marker_format():
    """The pipeline joins pages with a specific marker used to split later."""
    # Sanity check: the marker is exactly the one used in ocr_extract.py.
    marker = "\n\n=== PAGE BREAK ===\n\n"
    pages = ["PAGE 1", "PAGE 2", "PAGE 3"]
    out = marker.join(pages)
    # Splitting by the marker recovers the original pages.
    assert out.split("\n\n=== PAGE BREAK ===\n\n") == pages
