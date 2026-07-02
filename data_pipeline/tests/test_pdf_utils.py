"""
Tests unitaires pour utils/pdf_utils.py.

Couvre:
    - count_pdf_pages       (mock pdfinfo, fichier manquant, exception)
    - convert_pdf_to_images (mock pdf2image.convert_from_path, exception)
    - save_page_image        (extension PNG, nommage, conversion RGB)
    - cleanup_page_images    (suppression, compte, dossier manquant)
    - Cache images           (sauvegarde + relecture, isolation tmp_path)

Aucun appel reseau. pdf2image et poppler sont entierement moques via
monkeypatch sur les symboles importes dans utils.pdf_utils.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest
from PIL import Image

import utils.pdf_utils as pdf_utils_mod
from utils.pdf_utils import (
    cleanup_page_images,
    convert_pdf_to_images,
    count_pdf_pages,
    save_page_image,
)


# ─── count_pdf_pages ──────────────────────────────────────────────────────


class TestCountPdfPages:
    """count_pdf_pages returns the number of pages (0 on failure)."""

    def test_missing_file_returns_zero(self, tmp_path):
        assert count_pdf_pages(tmp_path / "nonexistent.pdf") == 0

    def test_mocked_pdfinfo_returns_page_count(
        self, sample_pdf_path, monkeypatch,
    ):
        monkeypatch.setattr(
            pdf_utils_mod,
            "pdfinfo_from_path",
            lambda path: {"Pages": "5"},
        )
        assert count_pdf_pages(sample_pdf_path) == 5

    def test_mocked_pdfinfo_zero_pages(self, sample_pdf_path, monkeypatch):
        monkeypatch.setattr(
            pdf_utils_mod,
            "pdfinfo_from_path",
            lambda path: {"Pages": "0"},
        )
        assert count_pdf_pages(sample_pdf_path) == 0

    def test_pdfinfo_missing_pages_key_returns_zero(
        self, sample_pdf_path, monkeypatch,
    ):
        monkeypatch.setattr(
            pdf_utils_mod,
            "pdfinfo_from_path",
            lambda path: {},  # no Pages key
        )
        assert count_pdf_pages(sample_pdf_path) == 0

    def test_pdfinfo_raises_exception_returns_zero(
        self, sample_pdf_path, monkeypatch,
    ):
        def boom(_path):
            raise RuntimeError("poppler missing")

        monkeypatch.setattr(pdf_utils_mod, "pdfinfo_from_path", boom)
        assert count_pdf_pages(sample_pdf_path) == 0

    def test_accepts_string_path(self, sample_pdf_path, monkeypatch):
        monkeypatch.setattr(
            pdf_utils_mod,
            "pdfinfo_from_path",
            lambda path: {"Pages": "3"},
        )
        assert count_pdf_pages(str(sample_pdf_path)) == 3


# ─── convert_pdf_to_images ────────────────────────────────────────────────


class TestConvertPdfToImages:
    """convert_pdf_to_images mocks pdf2image.convert_from_path."""

    def test_returns_list_of_pil_images(self, sample_pdf_path, monkeypatch):
        fake_images = [
            Image.new("RGB", (100, 100), "white"),
            Image.new("RGB", (100, 100), "white"),
        ]
        monkeypatch.setattr(
            pdf_utils_mod,
            "convert_from_path",
            lambda *a, **kw: fake_images,
        )
        out = convert_pdf_to_images(sample_pdf_path)
        assert len(out) == 2
        assert all(isinstance(img, Image.Image) for img in out)

    def test_returns_empty_list_on_exception(
        self, sample_pdf_path, monkeypatch,
    ):
        def boom(*a, **kw):
            raise RuntimeError("poppler-utils not installed")

        monkeypatch.setattr(pdf_utils_mod, "convert_from_path", boom)
        assert convert_pdf_to_images(sample_pdf_path) == []

    def test_passes_dpi_kwarg(self, sample_pdf_path, monkeypatch):
        captured = {}

        def fake_convert(path, **kwargs):
            captured.update(kwargs)
            return [Image.new("RGB", (10, 10), "white")]

        monkeypatch.setattr(pdf_utils_mod, "convert_from_path", fake_convert)
        convert_pdf_to_images(sample_pdf_path, dpi=150)
        assert captured["dpi"] == 150

    def test_default_dpi_from_config(self, sample_pdf_path, monkeypatch):
        captured = {}

        def fake_convert(path, **kwargs):
            captured.update(kwargs)
            return []

        monkeypatch.setattr(pdf_utils_mod, "convert_from_path", fake_convert)
        from config import OCR_CONFIG

        convert_pdf_to_images(sample_pdf_path)
        assert captured["dpi"] == OCR_CONFIG.dpi

    def test_passes_first_and_last_page(self, sample_pdf_path, monkeypatch):
        captured = {}

        def fake_convert(path, **kwargs):
            captured.update(kwargs)
            return []

        monkeypatch.setattr(pdf_utils_mod, "convert_from_path", fake_convert)
        convert_pdf_to_images(
            sample_pdf_path,
            first_page=2,
            last_page=4,
        )
        assert captured["first_page"] == 2
        assert captured["last_page"] == 4

    def test_last_page_none_becomes_zero(self, sample_pdf_path, monkeypatch):
        """When last_page is None, the wrapper passes 0 (meaning 'all pages')."""
        captured = {}

        def fake_convert(path, **kwargs):
            captured.update(kwargs)
            return []

        monkeypatch.setattr(pdf_utils_mod, "convert_from_path", fake_convert)
        convert_pdf_to_images(sample_pdf_path, last_page=None)
        assert captured["last_page"] == 0

    def test_format_always_png(self, sample_pdf_path, monkeypatch):
        captured = {}

        def fake_convert(path, **kwargs):
            captured.update(kwargs)
            return []

        monkeypatch.setattr(pdf_utils_mod, "convert_from_path", fake_convert)
        convert_pdf_to_images(sample_pdf_path)
        assert captured["fmt"] == "png"

    def test_accepts_string_path(self, sample_pdf_path, monkeypatch):
        monkeypatch.setattr(
            pdf_utils_mod,
            "convert_from_path",
            lambda *a, **kw: [],
        )
        # Should not raise.
        convert_pdf_to_images(str(sample_pdf_path))


# ─── save_page_image ──────────────────────────────────────────────────────


class TestSavePageImage:
    """save_page_image persists a PIL image as a PNG with a canonical name."""

    def test_writes_png_with_canonical_name(self, tmp_path, sample_image):
        out = save_page_image(
            sample_image,
            pdf_id="test_pdf",
            page_num=1,
            out_dir=tmp_path,
        )
        assert out.exists()
        assert out.suffix == ".png"
        assert out.name == "test_pdf_p001.png"

    def test_zero_pads_page_number_to_three_digits(
        self, tmp_path, sample_image,
    ):
        out = save_page_image(
            sample_image, pdf_id="pdf", page_num=42, out_dir=tmp_path,
        )
        assert out.name == "pdf_p042.png"

    def test_creates_out_dir_if_missing(self, tmp_path, sample_image):
        out_dir = tmp_path / "nested" / "cache"
        out = save_page_image(
            sample_image, pdf_id="pdf", page_num=1, out_dir=out_dir,
        )
        assert out_dir.exists()
        assert out.exists()

    def test_converts_non_rgb_image_to_rgb(self, tmp_path):
        """A grayscale (L) image is converted to RGB before saving."""
        gray = Image.new("L", (10, 10), 128)
        out = save_page_image(
            gray, pdf_id="pdf", page_num=1, out_dir=tmp_path,
        )
        # Reload and verify mode.
        reloaded = Image.open(out)
        reloaded.load()
        assert reloaded.mode == "RGB"

    def test_default_out_dir_uses_paths_cache(
        self, tmp_path, sample_image, monkeypatch,
    ):
        """When out_dir is None, files go to PATHS.cache.

        Paths is a frozen dataclass, so we replace the whole instance
        on both `config` and `utils.pdf_utils` modules.
        """
        import config as config_mod

        fake_cache = tmp_path / "default_cache"
        fake_cache.mkdir(parents=True, exist_ok=True)
        fake_paths = config_mod.Paths(
            root=tmp_path,
            raw_pdfs=tmp_path / "raw",
            extracted_text=tmp_path / "txt",
            structured_questions=tmp_path / "q",
            final=tmp_path / "final",
            cache=fake_cache,
        )
        monkeypatch.setattr(config_mod, "PATHS", fake_paths)
        monkeypatch.setattr(pdf_utils_mod, "PATHS", fake_paths)
        out = save_page_image(sample_image, pdf_id="pdf", page_num=1)
        assert out.parent == fake_cache
        assert out.exists()


# ─── cleanup_page_images ──────────────────────────────────────────────────


class TestCleanupPageImages:
    """cleanup_page_images removes all {pdf_id}_p*.png from a directory."""

    def test_deletes_matching_files(self, tmp_path, sample_image):
        for n in (1, 2, 3):
            save_page_image(
                sample_image,
                pdf_id="pdf",
                page_num=n,
                out_dir=tmp_path,
            )
        # Sanity: 3 files present.
        assert len(list(tmp_path.glob("pdf_p*.png"))) == 3
        count = cleanup_page_images("pdf", out_dir=tmp_path)
        assert count == 3
        assert len(list(tmp_path.glob("pdf_p*.png"))) == 0

    def test_only_deletes_matching_pdf_id(self, tmp_path, sample_image):
        save_page_image(sample_image, pdf_id="pdf_a", page_num=1, out_dir=tmp_path)
        save_page_image(sample_image, pdf_id="pdf_b", page_num=1, out_dir=tmp_path)
        count = cleanup_page_images("pdf_a", out_dir=tmp_path)
        assert count == 1
        # pdf_b file remains.
        remaining = list(tmp_path.glob("*.png"))
        assert len(remaining) == 1
        assert remaining[0].name == "pdf_b_p001.png"

    def test_missing_dir_returns_zero(self, tmp_path):
        missing = tmp_path / "does_not_exist"
        assert cleanup_page_images("pdf", out_dir=missing) == 0

    def test_no_matching_files_returns_zero(self, tmp_path):
        # Empty dir.
        assert cleanup_page_images("pdf", out_dir=tmp_path) == 0

    def test_default_dir_uses_paths_cache(self, tmp_path, sample_image, monkeypatch):
        import config as config_mod

        fake_cache = tmp_path / "default_cache"
        fake_cache.mkdir(parents=True, exist_ok=True)
        save_page_image(
            sample_image, pdf_id="pdf", page_num=1, out_dir=fake_cache,
        )
        fake_paths = config_mod.Paths(
            root=tmp_path,
            raw_pdfs=tmp_path / "raw",
            extracted_text=tmp_path / "txt",
            structured_questions=tmp_path / "q",
            final=tmp_path / "final",
            cache=fake_cache,
        )
        monkeypatch.setattr(config_mod, "PATHS", fake_paths)
        monkeypatch.setattr(pdf_utils_mod, "PATHS", fake_paths)
        count = cleanup_page_images("pdf")
        assert count == 1


# ─── Cache integration ───────────────────────────────────────────────────


class TestCacheIntegration:
    """Save then reload a page image: PNG round-trip is lossless for RGB."""

    def test_save_and_reload_preserves_dimensions(self, tmp_path, sample_image):
        out = save_page_image(
            sample_image, pdf_id="pdf", page_num=1, out_dir=tmp_path,
        )
        reloaded = Image.open(out)
        reloaded.load()
        assert reloaded.size == (100, 100)

    def test_save_and_reload_preserves_pixel_data(self, tmp_path):
        img = Image.new("RGB", (50, 50), (255, 0, 0))  # red
        out = save_page_image(img, pdf_id="pdf", page_num=1, out_dir=tmp_path)
        reloaded = Image.open(out)
        reloaded.load()
        # Top-left pixel should be red.
        assert reloaded.getpixel((0, 0)) == (255, 0, 0)

    def test_multiple_pages_no_collision(self, tmp_path, sample_image):
        for n in (1, 10, 100):
            save_page_image(
                sample_image, pdf_id="pdf", page_num=n, out_dir=tmp_path,
            )
        files = sorted(tmp_path.glob("pdf_p*.png"))
        names = [f.name for f in files]
        assert names == ["pdf_p001.png", "pdf_p010.png", "pdf_p100.png"]


# ─── Public API ───────────────────────────────────────────────────────────


class TestPublicApi:
    """Sanity check: __all__ matches the exported names."""

    def test_all_exports_present(self):
        exports = set(pdf_utils_mod.__all__)
        expected = {
            "count_pdf_pages",
            "convert_pdf_to_images",
            "save_page_image",
            "cleanup_page_images",
        }
        assert expected.issubset(exports)
