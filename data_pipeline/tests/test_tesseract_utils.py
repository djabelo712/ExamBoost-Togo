"""
Tests unitaires pour utils/tesseract_utils.py.

Couvre:
    - Config Tesseract francais (TESSERACT_CONFIG: --oem 3 --psm 6 -l fra).
    - run_tesseract (mock pytesseract, success + exception fallback).
    - detect_math_content (heuristic: symboles, LaTeX, fractions, puissances).
    - normalize_tesseract_text (mots coupes, whitespace, control chars).
    - available_languages / ensure_french_available (mock).
    - Fallback GPT-4o Vision (test d'integration avec ocr_extract._ocr_one_page
      quand detect_math_content declenche).

Aucun appel reseau. pytesseract est entierement moque via monkeypatch.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest
from PIL import Image

import utils.tesseract_utils as tess_mod
from utils.tesseract_utils import (
    TESSERACT_CONFIG,
    available_languages,
    detect_math_content,
    ensure_french_available,
    normalize_tesseract_text,
    run_tesseract,
)


# ─── TESSERACT_CONFIG ────────────────────────────────────────────────────


class TestTesseractConfig:
    """The Tesseract config string targets French scanned documents."""

    def test_config_uses_lstm_oem(self):
        # --oem 3 = LSTM neural net (most accurate).
        assert "--oem 3" in TESSERACT_CONFIG

    def test_config_uses_psm_6(self):
        # --psm 6 = single block of text (good for exam papers).
        assert "--psm 6" in TESSERACT_CONFIG

    def test_config_uses_french_language(self):
        # -l fra = French language pack.
        assert "-l fra" in TESSERACT_CONFIG

    def test_config_is_string(self):
        assert isinstance(TESSERACT_CONFIG, str)


# ─── run_tesseract ────────────────────────────────────────────────────────


class TestRunTesseract:
    """run_tesseract wraps pytesseract.image_to_string safely."""

    def test_returns_text_on_success(self, sample_image, monkeypatch):
        monkeypatch.setattr(
            tess_mod.pytesseract,
            "image_to_string",
            lambda *a, **kw: "Bonjour Togo",
        )
        assert run_tesseract(sample_image) == "Bonjour Togo"

    def test_returns_empty_string_on_exception(self, sample_image, monkeypatch):
        def boom(*a, **kw):
            raise RuntimeError("tesseract binary not found")

        monkeypatch.setattr(tess_mod.pytesseract, "image_to_string", boom)
        assert run_tesseract(sample_image) == ""

    def test_passes_lang_kwarg(self, sample_image, monkeypatch):
        captured = {}

        def fake(image, lang=None, config=None, **kw):
            captured["lang"] = lang
            captured["config"] = config
            return "ok"

        monkeypatch.setattr(tess_mod.pytesseract, "image_to_string", fake)
        run_tesseract(sample_image, lang="eng")
        assert captured["lang"] == "eng"

    def test_passes_custom_config(self, sample_image, monkeypatch):
        captured = {}

        def fake(image, lang=None, config=None, **kw):
            captured["config"] = config
            return "ok"

        monkeypatch.setattr(tess_mod.pytesseract, "image_to_string", fake)
        run_tesseract(sample_image, custom_config="--oem 1 --psm 3 -l fra")
        assert captured["config"] == "--oem 1 --psm 3 -l fra"

    def test_default_lang_from_config(self, sample_image, monkeypatch):
        captured = {}

        def fake(image, lang=None, config=None, **kw):
            captured["lang"] = lang
            return "ok"

        monkeypatch.setattr(tess_mod.pytesseract, "image_to_string", fake)
        run_tesseract(sample_image)
        from config import OCR_CONFIG

        assert captured["lang"] == OCR_CONFIG.tesseract_lang

    def test_default_config_from_module(self, sample_image, monkeypatch):
        captured = {}

        def fake(image, lang=None, config=None, **kw):
            captured["config"] = config
            return "ok"

        monkeypatch.setattr(tess_mod.pytesseract, "image_to_string", fake)
        run_tesseract(sample_image)
        assert captured["config"] == TESSERACT_CONFIG


# ─── detect_math_content ─────────────────────────────────────────────────


class TestDetectMathContent:
    """detect_math_content returns True when math symbols / patterns appear."""

    # ── Symboles declares dans OCR_CONFIG.math_symbols ──

    @pytest.mark.parametrize(
        "symbol",
        ["√", "∫", "∑", "≤", "≥", "≠", "≈", "²", "³", "α", "β", "π", "θ"],
    )
    def test_math_symbol_triggers_true(self, symbol):
        text = f"Calculer {symbol} pour x = 2"
        assert detect_math_content(text) is True

    # ── Motifs additionnels (regex) ──

    def test_fraction_pattern_triggers_true(self):
        assert detect_math_content("Simplifier 3/4 puis 5/6") is True

    def test_power_caret_pattern_triggers_true(self):
        assert detect_math_content("Derivee de x^2 + 3x") is True

    def test_power_caret_with_braces_triggers_true(self):
        # The regex `[a-zA-Z]\^\{?[0-9]+\}?` requires digits inside braces.
        assert detect_math_content("On considere x^{2} + 1") is True

    def test_latex_frac_command_triggers_true(self):
        assert detect_math_content("Soit $\\frac{a}{b}$ un rationnel") is True

    def test_latex_sqrt_command_triggers_true(self):
        assert detect_math_content("Calculer $\\sqrt{16}$") is True

    def test_latex_sum_command_triggers_true(self):
        assert detect_math_content("La suite $\\sum_{i=1}^{n} i$") is True

    def test_latex_int_command_triggers_true(self):
        assert detect_math_content("L'integrale $\\int_0^1 x^2 dx$") is True

    def test_latex_lim_command_triggers_true(self):
        assert detect_math_content("Calculer $\\lim_{x \\to 0} f(x)$") is True

    # ── Cas negatifs ──

    def test_pure_literary_text_returns_false(self):
        assert detect_math_content(
            "Qui est l'auteur de 'Les Fleurs du Mal' ?"
        ) is False

    def test_empty_string_returns_false(self):
        assert detect_math_content("") is False

    def test_none_safe(self):
        # The function checks `if not text` => None is also falsy.
        assert detect_math_content(None) is False  # type: ignore[arg-type]

    def test_simple_addition_without_math_symbol_returns_false(self):
        """A simple "2 + 2" without math symbols/fractions/powers does NOT
        trigger the fallback Vision. This is intentional: Tesseract handles
        simple arithmetic well."""
        assert detect_math_content("Calculer 2 + 2") is False

    def test_long_historical_text_returns_false(self):
        text = (
            "En quelle annee le Togo a-t-il obtenu son independance ? "
            "Citez trois personnages cles de cette periode."
        )
        assert detect_math_content(text) is False


# ─── normalize_tesseract_text ────────────────────────────────────────────


class TestNormalizeTesseractText:
    """normalize_tesseract_text cleans raw OCR output for the LLM."""

    def test_rejoins_hyphenated_words(self):
        raw = "calcul\nmath-\nemati-\nque"
        out = normalize_tesseract_text(raw)
        assert "mathematique" in out
        assert "-" not in out

    def test_collapses_excessive_newlines(self):
        raw = "para1\n\n\n\n\npara2"
        out = normalize_tesseract_text(raw)
        # At most 2 consecutive newlines.
        assert "\n\n\n" not in out

    def test_strips_control_chars(self):
        raw = "text\x00\x01avec\x02control"
        out = normalize_tesseract_text(raw)
        assert "\x00" not in out
        assert "\x01" not in out
        assert "\x02" not in out

    def test_preserves_newlines_and_tabs(self):
        """Tab and newline are explicitly kept (they are printable whitespace)."""
        raw = "line1\nline2\tindented"
        out = normalize_tesseract_text(raw)
        assert "\n" in out
        assert "\t" in out

    def test_empty_string_returns_empty(self):
        assert normalize_tesseract_text("") == ""

    def test_strips_leading_trailing_whitespace(self):
        raw = "   \n  Bonjour  \n  "
        out = normalize_tesseract_text(raw)
        assert out == "Bonjour" or out.startswith("Bonjour")
        assert not out.startswith(" ")

    def test_cleans_isolated_newlines_to_single(self):
        """Single newlines remain newlines (paragraph markers)."""
        raw = "para1\npara2"
        out = normalize_tesseract_text(raw)
        assert "para1\npara2" in out

    def test_handles_none_input_safely(self):
        # The function checks `if not text` => None returns "".
        assert normalize_tesseract_text(None) == ""  # type: ignore[arg-type]


# ─── available_languages & ensure_french_available ──────────────────────


class TestAvailableLanguages:
    """available_languages wraps pytesseract.get_languages safely."""

    def test_returns_sorted_list(self, monkeypatch):
        monkeypatch.setattr(
            tess_mod.pytesseract,
            "get_languages",
            lambda config="": ["eng", "fra", "deu"],
        )
        langs = available_languages()
        assert langs == ["deu", "eng", "fra"]  # sorted

    def test_returns_empty_list_on_exception(self, monkeypatch):
        def boom(*a, **kw):
            raise RuntimeError("tesseract not installed")

        monkeypatch.setattr(tess_mod.pytesseract, "get_languages", boom)
        assert available_languages() == []

    def test_returns_empty_list_on_none(self, monkeypatch):
        monkeypatch.setattr(
            tess_mod.pytesseract,
            "get_languages",
            lambda config="": None,
        )
        assert available_languages() == []

    def test_ensure_french_available_true_when_fra_present(self, monkeypatch):
        monkeypatch.setattr(
            tess_mod.pytesseract,
            "get_languages",
            lambda config="": ["eng", "fra"],
        )
        assert ensure_french_available() is True

    def test_ensure_french_available_false_when_missing(self, monkeypatch):
        monkeypatch.setattr(
            tess_mod.pytesseract,
            "get_languages",
            lambda config="": ["eng", "deu"],
        )
        assert ensure_french_available() is False


# ─── Fallback GPT-4o Vision (integration avec ocr_extract) ───────────────


class TestVisionFallbackIntegration:
    """When detect_math_content triggers, ocr_extract._ocr_one_page calls
    the GPT-4o Vision path. We verify the wiring without making real
    network calls.
    """

    def test_vision_only_path_calls_openai_vision_ocr(
        self, sample_image, monkeypatch,
    ):
        """When use_vision_only=True and OpenAI is configured, the function
        should call openai_vision_ocr with the saved image path."""
        import ocr_extract

        # Patch OpenAI as configured + save_page_image + openai_vision_ocr.
        monkeypatch.setattr(ocr_extract, "is_openai_configured", lambda: True)

        saved_path = Path("/tmp/fake_page.png")
        monkeypatch.setattr(
            ocr_extract,
            "save_page_image",
            lambda image, pdf_id, page_num: saved_path,
        )

        called_with = {}

        def fake_vision(image_or_path, prompt=None, model=None):
            called_with["path"] = image_or_path
            return "# Markdown with $\\sqrt{2}$"

        monkeypatch.setattr(ocr_extract, "openai_vision_ocr", fake_vision)

        out = ocr_extract._ocr_one_page(
            sample_image, page_num=1, pdf_id="test_pdf",
            use_vision_only=True,
        )
        assert called_with["path"] == saved_path
        assert "\\sqrt{2}" in out

    def test_vision_only_falls_back_to_tesseract_when_not_configured(
        self, sample_image, monkeypatch,
    ):
        """When use_vision_only=True but OPENAI_API_KEY is absent, we
        fall back to Tesseract (and avoid crashing)."""
        import ocr_extract

        monkeypatch.setattr(ocr_extract, "is_openai_configured", lambda: False)

        def fake_tesseract(image):
            return "Tesseract fallback output"

        monkeypatch.setattr(ocr_extract, "run_tesseract", fake_tesseract)

        out = ocr_extract._ocr_one_page(
            sample_image, page_num=1, pdf_id="test_pdf",
            use_vision_only=True,
        )
        assert "Tesseract fallback" in out

    def test_tesseract_path_returns_normalized_text(
        self, sample_image, monkeypatch,
    ):
        """The default path: Tesseract then normalize."""
        import ocr_extract

        monkeypatch.setattr(
            ocr_extract, "run_tesseract", lambda image: "raw\n\ntext",
        )
        out = ocr_extract._ocr_one_page(
            sample_image, page_num=1, pdf_id="test_pdf",
            use_vision_only=False,
        )
        # normalize_tesseract_text keeps paragraphs.
        assert "raw" in out and "text" in out


# ─── Public API ───────────────────────────────────────────────────────────


class TestPublicApi:
    """Sanity check on __all__ exports."""

    def test_all_exports_present(self):
        exports = set(tess_mod.__all__)
        expected = {
            "TESSERACT_CONFIG",
            "run_tesseract",
            "detect_math_content",
            "normalize_tesseract_text",
            "available_languages",
            "ensure_french_available",
        }
        assert expected.issubset(exports)
