"""
Wrappers pour les appels OpenAI (GPT-4o Vision OCR + GPT-4o-mini structuration).

Le client OpenAI est instancie paresseusement et son existence est testable via
`is_openai_configured()`. En cas de cle absente, les fonctions levent une
`OpenAIConfigError` explicite plutot que d'echouer silencieusement.
"""

from __future__ import annotations

import base64
import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from openai import OpenAI
from PIL import Image

from config import OCR_CONFIG, OPENAI_API_KEY

logger = logging.getLogger(__name__)


class OpenAIConfigError(RuntimeError):
    """Raised when the OpenAI API key is missing or invalid."""


_client: Optional[OpenAI] = None


def get_client() -> OpenAI:
    """Return a lazily-instantiated OpenAI client.

    Raises:
        OpenAIConfigError: if OPENAI_API_KEY is not set.
    """
    global _client
    if _client is not None:
        return _client
    if not OPENAI_API_KEY:
        raise OpenAIConfigError(
            "OPENAI_API_KEY manquant. Copiez .env.example en .env et "
            "remplissez la cle."
        )
    _client = OpenAI(api_key=OPENAI_API_KEY)
    return _client


def is_openai_configured() -> bool:
    """Return True if an API key is available (without raising)."""
    return bool(OPENAI_API_KEY)


# ─── Encodage image ───────────────────────────────────────────────────────


def encode_image_b64(image_path: Path | str) -> str:
    """Encode an image file to base64 (data URL payload).

    Args:
        image_path: path to the PNG/JPG on disk.

    Returns:
        Base64 string suitable for the OpenAI Vision API.
    """
    with open(image_path, "rb") as fh:
        return base64.b64encode(fh.read()).decode("utf-8")


def image_to_data_url(image_path: Path | str) -> str:
    """Build a `data:image/png;base64,...` URL from an image file."""
    b64 = encode_image_b64(image_path)
    ext = Path(image_path).suffix.lstrip(".").lower() or "png"
    mime = "jpeg" if ext in ("jpg", "jpeg") else "png"
    return f"data:image/{mime};base64,{b64}"


# ─── OCR Vision (GPT-4o) ──────────────────────────────────────────────────


VISION_OCR_PROMPT: str = (
    "Tu es un expert en reconnaissance de texte pour des annales d'examens "
    "togolais (BEPC, BAC series A/B/C/D/F). Analyse l'image fournie et "
    "renvoie UNIQUEMENT le texte integral de la page, structuré en Markdown.\n"
    "Contraintes:\n"
    "- Conserve les formules mathematiques en LaTeX inline ($...$) ou display "
    "($$...$$). Ex: $\\sqrt{2}$, $\\frac{a}{b}$, $\\int_0^1 x^2 dx$.\n"
    "- Conserve les tableaux en Markdown.\n"
    "- Decris brievement entre <figure>...</figure> toute figure geometrique "
    "ou graphique (sans inventer de donnees).\n"
    "- Numerote les questions Q1, Q2, ... si elles sont visibles.\n"
    "- Ne commente pas, n'ajoute aucune note hors du texte de la page.\n"
)


def openai_vision_ocr(
    image: Image.Image | Path | str,
    prompt: Optional[str] = None,
    model: Optional[str] = None,
) -> str:
    """Run GPT-4o Vision to extract text from a page image.

    Args:
        image: PIL image OR path to a saved PNG/JPG.
        prompt: optional prompt override.
        model: optional model override (default: config.OCR_CONFIG.vision_model).

    Returns:
        Markdown text extracted by the model. Empty string on failure.
    """
    client = get_client()
    model = model or OCR_CONFIG.vision_model
    prompt = prompt or VISION_OCR_PROMPT

    if isinstance(image, (str, Path)):
        data_url = image_to_data_url(image)
    else:
        # PIL Image -> sauvegarde temporaire en memoire.
        import io
        buf = io.BytesIO()
        if image.mode != "RGB":
            image = image.convert("RGB")
        image.save(buf, format="PNG")
        b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
        data_url = f"data:image/png;base64,{b64}"

    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {"url": data_url, "detail": "high"},
                        },
                    ],
                }
            ],
            max_tokens=4000,
            temperature=0.0,
        )
        text = response.choices[0].message.content or ""
        usage = getattr(response, "usage", None)
        logger.info(
            "Vision OCR OK (model=%s, tokens=%s, chars=%d)",
            model,
            usage,
            len(text),
        )
        return text.strip()
    except Exception as exc:  # noqa: BLE001
        logger.error("Erreur OpenAI Vision OCR: %s", exc)
        return ""


# ─── Structuration (GPT-4o-mini) ──────────────────────────────────────────


STRUCTURE_SYSTEM_PROMPT: str = (
    "Tu es un assistant qui structure des questions d'examens togolais."
)


STRUCTURE_USER_PROMPT_TEMPLATE: str = """\
À partir du texte OCR suivant, extrais TOUTES les questions au format JSON.

Schéma attendu par question:
{{
  "id": "TG-{{EXAMEN}}-{{MATIERE}}-{{ANNEE}}-Q{{NN}}",
  "enonce": "...",
  "reponse": "...",
  "explication": "...",
  "matiere": "Mathématiques|Français|Sciences Physiques|Sciences de la Vie et de la Terre|Histoire-Géographie|Anglais|Philosophie",
  "chapitre": "...",
  "competence_id": "TG-{{MATIERE}}-{{CHAP}}-NNN",
  "examen": "BEPC|BAC1|BAC2",
  "serie": "A|B|C|D|F|null",
  "annee": 2022,
  "type": "calcul|ouvert|qcm|vraiFaux|redaction",
  "choix": ["A", "B", "C", "D"] ou null,
  "points": 4,
  "irt": {{"a": null, "b": null, "c": null, "calibre": false}}
}}

Règles:
- L'énoncé doit être complet (inclus les contextes, données).
- La réponse doit être exacte et concise.
- L'explication doit être pédagogique.
- Si la question a des sous-questions (a, b, c), sépare-les en questions distinctes.
- Pour BEPC, "serie" doit être null.
- Pour BAC, "serie" doit être une lettre (A, B, C, D ou F).
- Renvoie UNIQUEMENT un tableau JSON valide, sans texte autour.

Contexte du document:
- Examen: {examen}
- Matiere probable: {matiere}
- Annee: {annee}
- Serie: {serie}

Texte OCR:
---
{texte_ocr}
---
"""


def openai_structure_questions(
    ocr_text: str,
    examen: str,
    matiere: str,
    annee: int,
    serie: Optional[str] = None,
    model: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Ask GPT-4o-mini to convert OCR text into a list of question dicts.

    Args:
        ocr_text: full OCR text of a PDF (may span multiple pages).
        examen: "BEPC" | "BAC1" | "BAC2".
        matiere: matiere probable ("Mathématiques", ...).
        annee: year of the exam.
        serie: series letter (only for BAC, None for BEPC).
        model: optional model override.

    Returns:
        List of question dicts. Empty list on JSON parse failure.
    """
    client = get_client()
    model = model or OCR_CONFIG.structure_model
    serie_str = serie if serie else "null"
    prompt = STRUCTURE_USER_PROMPT_TEMPLATE.format(
        examen=examen,
        matiere=matiere,
        annee=annee,
        serie=serie_str,
        texte_ocr=ocr_text,
    )

    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": STRUCTURE_SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            temperature=0.1,
            max_tokens=6000,
            response_format={"type": "json_object"},
        )
        raw = response.choices[0].message.content or ""
        questions = _extract_json_array(raw)
        usage = getattr(response, "usage", None)
        logger.info(
            "Structure OK (model=%s, questions=%d, tokens=%s)",
            model,
            len(questions),
            usage,
        )
        return questions
    except Exception as exc:  # noqa: BLE001
        logger.error("Erreur OpenAI structure: %s", exc)
        return []


def _extract_json_array(raw: str) -> List[Dict[str, Any]]:
    """Parse a possibly-noisy LLM response into a list of dicts.

    The model is asked to return a JSON array, but with `response_format:
    json_object` OpenAI wraps arrays inside an object. We try several
    strategies: direct array, top-level object with a `questions` key,
    or regex extraction of the first JSON array found.
    """
    if not raw:
        return []
    raw = raw.strip()
    # 1) Direct array.
    if raw.startswith("["):
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, list):
                return [q for q in parsed if isinstance(q, dict)]
        except json.JSONDecodeError:
            pass
    # 2) Object containing a questions list.
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, dict):
            for key in ("questions", "items", "data"):
                if isinstance(parsed.get(key), list):
                    return [q for q in parsed[key] if isinstance(q, dict)]
            # Single question object?
            if "enonce" in parsed:
                return [parsed]
    except json.JSONDecodeError:
        pass
    # 3) Regex fallback: first [...] block.
    match = re.search(r"\[\s*\{.*\}\s*\]", raw, flags=re.DOTALL)
    if match:
        try:
            parsed = json.loads(match.group(0))
            if isinstance(parsed, list):
                return [q for q in parsed if isinstance(q, dict)]
        except json.JSONDecodeError:
            pass
    return []


# ─── Estimation couts ─────────────────────────────────────────────────────


def estimate_vision_cost(num_pages: int, cost_per_page: Optional[float] = None) -> float:
    """Estimate the total USD cost for OCR Vision on N pages.

    Args:
        num_pages: total number of pages to process.
        cost_per_page: override (default: config.OCR_CONFIG.cost_per_vision_page).

    Returns:
        Estimated cost in USD.
    """
    cost = cost_per_page if cost_per_page is not None else OCR_CONFIG.cost_per_vision_page
    return round(num_pages * cost, 2)


__all__ = [
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
]
