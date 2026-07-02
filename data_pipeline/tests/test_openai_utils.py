"""
Tests unitaires pour utils/openai_utils.py.

Couvre:
    - get_client / is_openai_configured (cle presente / absente).
    - encode_image_b64 / image_to_data_url (round-trip b64).
    - openai_vision_ocr (mock du client OpenAI, GPT-4o Vision OCR).
    - openai_structure_questions (mock du client, GPT-4o-mini structure JSON).
    - _extract_json_array (parsing robuste des reponses LLM).
    - estimate_vision_cost (formule de cout).
    - Prompts (contenu, variables).
    - Mock HTTP via `responses` (au cas ou du code utiliserait requests
      directement; sert aussi de documentation des endpoints attendus).

Aucun appel reseau. Le client OpenAI est entierement remplace par un
MagicMock via monkeypatch sur `utils.openai_utils.get_client`.

Note: le SDK OpenAI (>=1.x) utilise httpx en interne, pas requests. La
librairie `responses` ne peut donc pas intercepter directement les appels
OpenAI. On mock donc `get_client()` pour renvoyer un faux client dont la
methode `chat.completions.create` retourne une reponse pre-construite.
On enregistre aussi les URL OpenAI via `responses` comme gardien (si du
code utilisait requests par erreur, le test echouerait proprement).
"""

from __future__ import annotations

import base64
import json
from pathlib import Path
from typing import Any, Dict, List
from unittest.mock import MagicMock, patch

import pytest
import responses

import utils.openai_utils as openai_mod
from utils.openai_utils import (
    OpenAIConfigError,
    STRUCTURE_SYSTEM_PROMPT,
    STRUCTURE_USER_PROMPT_TEMPLATE,
    VISION_OCR_PROMPT,
    _extract_json_array,
    encode_image_b64,
    estimate_vision_cost,
    get_client,
    image_to_data_url,
    is_openai_configured,
    openai_structure_questions,
    openai_vision_ocr,
)


# ─── Helpers ──────────────────────────────────────────────────────────────


def _make_chat_response(content: str) -> MagicMock:
    """Build a MagicMock mimicking OpenAI ChatCompletion response."""
    resp = MagicMock(name="ChatCompletion")
    resp.choices = [MagicMock(message=MagicMock(content=content))]
    resp.usage = MagicMock(total_tokens=42)
    return resp


@pytest.fixture
def mock_openai_client(monkeypatch):
    """Patch get_client to return a fresh MagicMock client.

    Returns the mock so tests can configure chat.completions.create.
    """
    client = MagicMock(name="OpenAIClient")
    client.chat.completions.create.return_value = _make_chat_response("")
    monkeypatch.setattr(openai_mod, "get_client", lambda: client)
    return client


# ─── 1) Configuration client ─────────────────────────────────────────────


class TestGetClient:
    """get_client lazily instantiates the OpenAI client."""

    def test_get_client_returns_same_instance_when_key_set(self, monkeypatch):
        """When the API key is set, get_client returns a singleton client."""
        # Reset the module-level _client cache.
        monkeypatch.setattr(openai_mod, "_client", None)
        monkeypatch.setattr(openai_mod, "OPENAI_API_KEY", "sk-test-fake-key")

        # Patch OpenAI constructor to avoid real init.
        with patch.object(openai_mod, "OpenAI") as mock_openai_cls:
            mock_instance = MagicMock(name="OpenAIInstance")
            mock_openai_cls.return_value = mock_instance

            c1 = get_client()
            c2 = get_client()
            assert c1 is c2  # singleton
            mock_openai_cls.assert_called_once_with(api_key="sk-test-fake-key")

        # Cleanup the cache for subsequent tests.
        monkeypatch.setattr(openai_mod, "_client", None)

    def test_get_client_raises_when_key_missing(self, monkeypatch):
        monkeypatch.setattr(openai_mod, "_client", None)
        monkeypatch.setattr(openai_mod, "OPENAI_API_KEY", None)
        with pytest.raises(OpenAIConfigError) as exc_info:
            get_client()
        assert "OPENAI_API_KEY" in str(exc_info.value)

    def test_is_openai_configured_true_when_key_set(self, monkeypatch):
        monkeypatch.setattr(openai_mod, "OPENAI_API_KEY", "sk-test")
        assert is_openai_configured() is True

    def test_is_openai_configured_false_when_key_missing(self, monkeypatch):
        monkeypatch.setattr(openai_mod, "OPENAI_API_KEY", None)
        assert is_openai_configured() is False

    def test_is_openai_configured_false_when_key_empty(self, monkeypatch):
        monkeypatch.setattr(openai_mod, "OPENAI_API_KEY", "")
        assert is_openai_configured() is False

    def test_openai_config_error_is_runtime_error(self):
        assert issubclass(OpenAIConfigError, RuntimeError)


# ─── 2) Image encoding ──────────────────────────────────────────────────


class TestImageEncoding:
    """encode_image_b64 and image_to_data_url convert image files to b64."""

    def test_encode_image_b64_round_trip(self, tmp_path):
        # Write a small binary file.
        raw = b"\x89PNG\r\n\x1a\nfake-png-bytes"
        img_path = tmp_path / "page.png"
        img_path.write_bytes(raw)

        b64 = encode_image_b64(img_path)
        # Decode and verify the bytes match.
        decoded = base64.b64decode(b64)
        assert decoded == raw

    def test_encode_image_b64_returns_string(self, tmp_path):
        img_path = tmp_path / "img.png"
        img_path.write_bytes(b"hello")
        b64 = encode_image_b64(img_path)
        assert isinstance(b64, str)

    def test_image_to_data_url_png(self, tmp_path):
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        url = image_to_data_url(img_path)
        assert url.startswith("data:image/png;base64,")

    def test_image_to_data_url_jpeg(self, tmp_path):
        img_path = tmp_path / "page.jpg"
        img_path.write_bytes(b"fake-jpeg")
        url = image_to_data_url(img_path)
        assert url.startswith("data:image/jpeg;base64,")

    def test_image_to_data_url_jpeg_extension_uppercase(self, tmp_path):
        img_path = tmp_path / "page.JPG"
        img_path.write_bytes(b"fake-jpeg")
        url = image_to_data_url(img_path)
        assert url.startswith("data:image/jpeg;base64,")

    def test_image_to_data_url_unknown_extension_defaults_png(self, tmp_path):
        img_path = tmp_path / "page.xyz"
        img_path.write_bytes(b"fake")
        url = image_to_data_url(img_path)
        assert url.startswith("data:image/png;base64,")

    def test_image_to_data_url_no_extension_defaults_png(self, tmp_path):
        img_path = tmp_path / "page"
        img_path.write_bytes(b"fake")
        url = image_to_data_url(img_path)
        assert url.startswith("data:image/png;base64,")

    def test_data_url_decodes_back_to_original(self, tmp_path):
        raw = b"some-image-bytes-for-round-trip"
        img_path = tmp_path / "img.png"
        img_path.write_bytes(raw)
        url = image_to_data_url(img_path)
        # Strip prefix and decode.
        b64_part = url.split("base64,", 1)[1]
        assert base64.b64decode(b64_part) == raw


# ─── 3) openai_vision_ocr (GPT-4o Vision) ────────────────────────────────


class TestOpenaiVisionOcr:
    """openai_vision_ocr calls the OpenAI Vision API (mocked)."""

    def test_returns_text_on_success(self, mock_openai_client, tmp_path):
        """The function returns the content from the mock response."""
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "# Markdown avec $\\sqrt{2}$"
        )
        out = openai_vision_ocr(img_path)
        assert "\\sqrt{2}" in out

    def test_returns_empty_string_on_exception(self, mock_openai_client, tmp_path):
        """If the API call raises, the function returns '' (no crash)."""
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        mock_openai_client.chat.completions.create.side_effect = RuntimeError(
            "OpenAI API timeout"
        )
        assert openai_vision_ocr(img_path) == ""

    def test_uses_default_vision_model(self, mock_openai_client, tmp_path):
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        openai_vision_ocr(img_path)
        # Verify the model kwarg passed to create().
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        from config import OCR_CONFIG

        assert call_kwargs["model"] == OCR_CONFIG.vision_model

    def test_uses_custom_model_when_provided(self, mock_openai_client, tmp_path):
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        openai_vision_ocr(img_path, model="gpt-4o-2024-08-06")
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        assert call_kwargs["model"] == "gpt-4o-2024-08-06"

    def test_uses_default_prompt_when_none(self, mock_openai_client, tmp_path):
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        openai_vision_ocr(img_path)
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        messages = call_kwargs["messages"]
        assert messages[0]["content"][0]["text"] == VISION_OCR_PROMPT

    def test_uses_custom_prompt_when_provided(self, mock_openai_client, tmp_path):
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        custom_prompt = "Custom OCR prompt for testing purposes."
        openai_vision_ocr(img_path, prompt=custom_prompt)
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        messages = call_kwargs["messages"]
        assert messages[0]["content"][0]["text"] == custom_prompt

    def test_message_content_contains_image_url(self, mock_openai_client, tmp_path):
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        openai_vision_ocr(img_path)
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        messages = call_kwargs["messages"]
        content_parts = messages[0]["content"]
        # 2 parts: text + image_url.
        assert len(content_parts) == 2
        image_part = next(p for p in content_parts if p["type"] == "image_url")
        assert "url" in image_part["image_url"]
        assert image_part["image_url"]["url"].startswith("data:image/png;base64,")

    def test_accepts_pil_image(self, mock_openai_client, sample_image):
        """A PIL.Image is accepted (encoded to b64 PNG in-memory)."""
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "text from PIL"
        )
        out = openai_vision_ocr(sample_image)
        assert out == "text from PIL"

    def test_temperature_is_zero(self, mock_openai_client, tmp_path):
        """OCR is deterministic: temperature=0."""
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        openai_vision_ocr(img_path)
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        assert call_kwargs["temperature"] == 0.0

    def test_strips_whitespace_from_response(self, mock_openai_client, tmp_path):
        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "  \n  stripped text  \n"
        )
        assert openai_vision_ocr(img_path) == "stripped text"


# ─── 4) openai_structure_questions (GPT-4o-mini) ────────────────────────


class TestOpenaiStructureQuestions:
    """openai_structure_questions asks GPT-4o-mini for a JSON list."""

    def test_returns_list_on_success(self, mock_openai_client):
        questions = [
            {"id": "Q1", "enonce": "Calculer 2+2", "reponse": "4"},
            {"id": "Q2", "enonce": "Capitale du Togo ?", "reponse": "Lomé"},
        ]
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            json.dumps(questions)
        )
        out = openai_structure_questions(
            ocr_text="texte ocr",
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
        )
        assert len(out) == 2
        assert out[0]["enonce"] == "Calculer 2+2"

    def test_returns_empty_list_on_exception(self, mock_openai_client):
        mock_openai_client.chat.completions.create.side_effect = RuntimeError(
            "API error"
        )
        out = openai_structure_questions(
            ocr_text="texte",
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
        )
        assert out == []

    def test_uses_default_structure_model(self, mock_openai_client):
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "[]"
        )
        openai_structure_questions(
            ocr_text="texte",
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
        )
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        from config import OCR_CONFIG

        assert call_kwargs["model"] == OCR_CONFIG.structure_model

    def test_uses_custom_model_when_provided(self, mock_openai_client):
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "[]"
        )
        openai_structure_questions(
            ocr_text="texte",
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
            model="gpt-4o-mini-2024-07-18",
        )
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        assert call_kwargs["model"] == "gpt-4o-mini-2024-07-18"

    def test_response_format_is_json_object(self, mock_openai_client):
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "[]"
        )
        openai_structure_questions(
            ocr_text="texte",
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
        )
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        assert call_kwargs["response_format"] == {"type": "json_object"}

    def test_messages_contain_system_and_user(self, mock_openai_client):
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "[]"
        )
        openai_structure_questions(
            ocr_text="texte OCR de test",
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
        )
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        messages = call_kwargs["messages"]
        assert len(messages) == 2
        assert messages[0]["role"] == "system"
        assert messages[0]["content"] == STRUCTURE_SYSTEM_PROMPT
        assert messages[1]["role"] == "user"
        # The user prompt should include the OCR text.
        assert "texte OCR de test" in messages[1]["content"]

    def test_serie_null_renders_in_prompt_for_bepc(self, mock_openai_client):
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "[]"
        )
        openai_structure_questions(
            ocr_text="texte",
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
            serie=None,
        )
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        user_msg = call_kwargs["messages"][1]["content"]
        assert "Serie: null" in user_msg

    def test_serie_letter_renders_in_prompt_for_bac(self, mock_openai_client):
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "[]"
        )
        openai_structure_questions(
            ocr_text="texte",
            examen="BAC1",
            matiere="Mathématiques",
            annee=2023,
            serie="C",
        )
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        user_msg = call_kwargs["messages"][1]["content"]
        assert "Serie: C" in user_msg

    def test_temperature_is_low_for_structure(self, mock_openai_client):
        """Structure uses low (but not zero) temperature for slight diversity."""
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "[]"
        )
        openai_structure_questions(
            ocr_text="texte",
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
        )
        call_kwargs = mock_openai_client.chat.completions.create.call_args.kwargs
        assert call_kwargs["temperature"] == 0.1


# ─── 5) _extract_json_array (parsing robuste) ───────────────────────────


class TestExtractJsonArray:
    """_extract_json_array handles noisy LLM responses."""

    def test_direct_json_array(self):
        raw = '[{"id": "Q1"}, {"id": "Q2"}]'
        out = _extract_json_array(raw)
        assert len(out) == 2
        assert out[0]["id"] == "Q1"

    def test_object_with_questions_key(self):
        raw = '{"questions": [{"id": "Q1"}]}'
        out = _extract_json_array(raw)
        assert len(out) == 1
        assert out[0]["id"] == "Q1"

    def test_object_with_items_key(self):
        raw = '{"items": [{"id": "Q1"}]}'
        out = _extract_json_array(raw)
        assert len(out) == 1

    def test_object_with_data_key(self):
        raw = '{"data": [{"id": "Q1"}]}'
        out = _extract_json_array(raw)
        assert len(out) == 1

    def test_single_question_object(self):
        raw = '{"enonce": "Calculer 2+2", "reponse": "4"}'
        out = _extract_json_array(raw)
        assert len(out) == 1
        assert out[0]["enonce"] == "Calculer 2+2"

    def test_json_array_inside_markdown_code_block(self):
        """Regex fallback finds the first [...] block."""
        raw = 'Voici les questions:\n```json\n[{"id": "Q1"}]\n```\nFin.'
        out = _extract_json_array(raw)
        assert len(out) == 1
        assert out[0]["id"] == "Q1"

    def test_empty_string_returns_empty(self):
        assert _extract_json_array("") == []

    def test_none_returns_empty(self):
        assert _extract_json_array(None) == []  # type: ignore[arg-type]

    def test_invalid_json_returns_empty(self):
        assert _extract_json_array("not json at all") == []

    def test_filters_out_non_dict_items_in_array(self):
        """Non-dict entries (strings, ints) are filtered out."""
        raw = '[{"id": "Q1"}, "not a dict", 42, {"id": "Q2"}]'
        out = _extract_json_array(raw)
        assert len(out) == 2
        assert all(isinstance(q, dict) for q in out)

    def test_invalid_json_array_inside_text_returns_empty(self):
        """If regex finds a [...] block but it's invalid JSON, return []."""
        raw = "Some text [{not valid}] more text"
        out = _extract_json_array(raw)
        assert out == []

    def test_whitespace_only_string_returns_empty(self):
        assert _extract_json_array("   \n\t  ") == []


# ─── 6) estimate_vision_cost ────────────────────────────────────────────


class TestEstimateVisionCost:
    """estimate_vision_cost = num_pages * cost_per_page (rounded to 2 dp)."""

    def test_zero_pages_zero_cost(self):
        assert estimate_vision_cost(0) == 0.0

    def test_1500_pages_default_cost(self):
        """Default cost_per_page = 0.01 USD => 1500 pages = 15 USD."""
        assert estimate_vision_cost(1500) == 15.0

    def test_custom_cost_per_page(self):
        assert estimate_vision_cost(100, cost_per_page=0.05) == 5.0

    def test_rounding_to_two_decimals(self):
        # 33 * 0.01 = 0.33
        assert estimate_vision_cost(33) == 0.33

    def test_negative_pages_returns_negative_cost(self):
        """The function does not guard against negative inputs (caller's
        responsibility). Verify the math is consistent."""
        assert estimate_vision_cost(-10) == -0.1

    def test_uses_config_default_when_no_override(self, monkeypatch):
        """When cost_per_page is None, the function uses OCR_CONFIG."""
        from config import OCR_CONFIG

        # 100 pages * OCR_CONFIG.cost_per_vision_page.
        expected = round(100 * OCR_CONFIG.cost_per_vision_page, 2)
        assert estimate_vision_cost(100) == expected


# ─── 7) Prompts ──────────────────────────────────────────────────────────


class TestPrompts:
    """Sanity checks on the LLM prompt strings."""

    def test_vision_ocr_prompt_mentions_latex(self):
        assert "LaTeX" in VISION_OCR_PROMPT

    def test_vision_ocr_prompt_mentions_markdown(self):
        assert "Markdown" in VISION_OCR_PROMPT

    def test_vision_ocr_prompt_mentions_togo_exams(self):
        assert "togolais" in VISION_OCR_PROMPT.lower() or "togo" in VISION_OCR_PROMPT.lower()

    def test_vision_ocr_prompt_mentions_sqrt_example(self):
        assert "\\sqrt" in VISION_OCR_PROMPT

    def test_structure_system_prompt_non_empty(self):
        assert len(STRUCTURE_SYSTEM_PROMPT) > 10

    def test_structure_user_prompt_has_placeholders(self):
        """The user prompt template accepts the expected format variables."""
        formatted = STRUCTURE_USER_PROMPT_TEMPLATE.format(
            examen="BEPC",
            matiere="Mathématiques",
            annee=2022,
            serie="null",
            texte_ocr="texte de test",
        )
        assert "BEPC" in formatted
        assert "Mathématiques" in formatted
        assert "2022" in formatted
        assert "texte de test" in formatted

    def test_structure_user_prompt_mentions_serie_rules(self):
        formatted = STRUCTURE_USER_PROMPT_TEMPLATE.format(
            examen="BAC1",
            matiere="Mathématiques",
            annee=2023,
            serie="C",
            texte_ocr="x",
        )
        assert "BEPC" in formatted  # rule mentions BEPC
        assert "BAC" in formatted  # rule mentions BAC
        assert "serie" in formatted.lower()

    def test_structure_user_prompt_mentions_json_schema(self):
        formatted = STRUCTURE_USER_PROMPT_TEMPLATE.format(
            examen="BEPC", matiere="x", annee=2022, serie="null", texte_ocr="y",
        )
        assert "enonce" in formatted
        assert "reponse" in formatted
        assert "explication" in formatted
        assert "matiere" in formatted
        assert "irt" in formatted


# ─── 8) Mock HTTP via `responses` (gardien) ─────────────────────────────


class TestResponsesGuard:
    """These tests use `responses` as a guard against accidental real HTTP.

    They also document the OpenAI endpoint URLs that the pipeline would
    call in production. Since the OpenAI SDK uses httpx (not requests),
    `responses` does NOT intercept the actual OpenAI calls here -- those
    are mocked via `get_client`. But if any code path slipped through and
    used `requests` directly, the test would fail with ConnectionError.
    """

    @responses.activate
    def test_no_real_http_call_to_openai_when_client_mocked(
        self, mock_openai_client, tmp_path,
    ):
        """Even with responses activated (no URL registered), the mocked
        client means no real HTTP is attempted."""
        # Register a 404 for the OpenAI endpoint to prove it's NOT called.
        responses.add(
            responses.POST,
            "https://api.openai.com/v1/chat/completions",
            status=404,
        )

        img_path = tmp_path / "page.png"
        img_path.write_bytes(b"fake-png")
        mock_openai_client.chat.completions.create.return_value = _make_chat_response(
            "mocked response"
        )
        out = openai_vision_ocr(img_path)
        assert out == "mocked response"
        # The mocked client was called, not the real HTTP endpoint.
        assert len(responses.calls) == 0

    @responses.activate
    def test_responses_intercepts_requests_call(self):
        """Sanity: responses correctly intercepts a plain requests call.

        This proves the `responses` setup is functional (in case future
        code uses requests for HTTP).
        """
        import requests

        responses.add(
            responses.GET,
            "https://api.example.com/test",
            json={"ok": True},
            status=200,
        )
        resp = requests.get("https://api.example.com/test")
        assert resp.status_code == 200
        assert resp.json() == {"ok": True}
        assert len(responses.calls) == 1


# ─── 9) Public API ───────────────────────────────────────────────────────


class TestPublicApi:
    """Sanity check on __all__ exports."""

    def test_all_exports_present(self):
        exports = set(openai_mod.__all__)
        expected = {
            "OpenAIConfigError",
            "get_client",
            "is_openai_configured",
            "encode_image_b64",
            "image_to_data_url",
            "VISION_OCR_PROMPT",
            "openai_vision_ocr",
            "STRUCTURE_SYSTEM_PROMPT",
            "STRUCTURE_USER_PROMPT_TEMPLATE",
            "openai_structure_questions",
            "estimate_vision_cost",
        }
        assert expected.issubset(exports)
