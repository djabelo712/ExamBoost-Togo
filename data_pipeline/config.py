"""
Configuration centrale du pipeline OCR ExamBoost Togo.

Centralise les chemins, sources d'annales, modeles LLM et parametres de
qualite. Toutes les valeurs sensibles sont lues depuis l'environnement
(fichier .env charge via python-dotenv).
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List

from dotenv import load_dotenv

# Chargement du .env situe a la racine du pipeline
_PIPELINE_ROOT = Path(__file__).resolve().parent
load_dotenv(_PIPELINE_ROOT / ".env")


# ─── Chemins ──────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Paths:
    """Regroupe tous les chemins utilises par le pipeline."""

    root: Path = _PIPELINE_ROOT
    raw_pdfs: Path = _PIPELINE_ROOT / "data" / "raw_pdfs"
    extracted_text: Path = _PIPELINE_ROOT / "data" / "extracted_text"
    structured_questions: Path = _PIPELINE_ROOT / "data" / "structured_questions"
    final: Path = _PIPELINE_ROOT / "data" / "final"
    cache: Path = _PIPELINE_ROOT / "data" / ".ocr_cache"
    manifest: Path = _PIPELINE_ROOT / "data" / "raw_pdfs" / "manifest.json"
    validation_report: Path = _PIPELINE_ROOT / "data" / "final" / "validation_report.md"

    def ensure(self) -> None:
        """Cree les dossiers cibles s'ils n'existent pas."""
        for p in (
            self.raw_pdfs,
            self.extracted_text,
            self.structured_questions,
            self.final,
            self.cache,
        ):
            p.mkdir(parents=True, exist_ok=True)


PATHS = Paths()
PATHS.ensure()


# ─── Sources d'annales ────────────────────────────────────────────────────

@dataclass(frozen=True)
class SourceConfig:
    """Decrit une source d'annales a scraper.

    Attributes:
        name: identifiant court, utilise dans les chemins de fichiers.
        base_url: racine du site.
        listing_url: page listant les PDFs (peut etre un template {annee}).
        examens: liste des examens concernes ("BEPC", "BAC1", "BAC2").
        series: series disponibles (None pour BEPC).
        year_range: bornes [min, max] d'annees couvertes.
        pdf_url_pattern: regex pour detecter un lien PDF dans la page.
        rate_limit: delai minimal entre deux requetes (secondes).
    """

    name: str
    base_url: str
    listing_url: str
    examens: tuple[str, ...]
    series: tuple[str | None, ...]
    year_range: tuple[int, int]
    pdf_url_pattern: str
    rate_limit: float = 1.0


SOURCES: Dict[str, SourceConfig] = {
    "epreuvesetcorriges": SourceConfig(
        name="epreuvesetcorriges",
        base_url="https://www.epreuvesetcorriges.com",
        listing_url="https://www.epreuvesetcorriges.com/togo/",
        examens=("BEPC", "BAC1", "BAC2"),
        series=(None, "A", "B", "C", "D", "F"),
        year_range=(2010, 2025),
        pdf_url_pattern=r"\.(?:pdf|PDF)$",
        rate_limit=1.0,
    ),
    "banquedesepreuves": SourceConfig(
        name="banquedesepreuves",
        base_url="https://www.banquedesepreuves.com",
        listing_url="https://www.banquedesepreuves.com/pays/togo/",
        examens=("BEPC", "BAC1", "BAC2"),
        series=(None, "A", "B", "C", "D"),
        year_range=(2015, 2024),
        pdf_url_pattern=r"\.(?:pdf|PDF)$",
        rate_limit=1.0,
    ),
    "examensconcours": SourceConfig(
        name="examensconcours",
        base_url="https://www.examens-concours.net",
        listing_url="https://www.examens-concours.net/togo/bac/maths-serie-c",
        examens=("BAC1", "BAC2"),
        series=("C",),
        year_range=(2012, 2024),
        pdf_url_pattern=r"\.(?:pdf|PDF)$",
        rate_limit=1.0,
    ),
    "fomesoutra": SourceConfig(
        name="fomesoutra",
        base_url="https://www.fomesoutra.com",
        listing_url="https://www.fomesoutra.com/bepc-togo/",
        examens=("BEPC",),
        series=(None,),
        year_range=(2015, 2024),
        pdf_url_pattern=r"\.(?:pdf|PDF)$",
        rate_limit=1.5,
    ),
    "digischool": SourceConfig(
        name="digischool",
        base_url="https://afrique.digischool.fr",
        listing_url="https://afrique.digischool.fr/bac-afrique-ouest/",
        examens=("BAC1", "BAC2"),
        series=("A", "B", "C", "D"),
        year_range=(2014, 2024),
        pdf_url_pattern=r"\.(?:pdf|PDF)$",
        rate_limit=1.0,
    ),
}


# ─── Parametres OCR / LLM ─────────────────────────────────────────────────

@dataclass(frozen=True)
class OcrConfig:
    """Parametres pour la phase d'extraction OCR."""

    tesseract_lang: str = os.getenv("TESSERACT_LANG", "fra")
    dpi: int = int(os.getenv("OCR_DPI", "300"))
    # Symboles declenchant le fallback Vision (maths / physique)
    math_symbols: tuple[str, ...] = (
        "√", "∫", "∑", "∏", "∂", "∞", "α", "β", "γ", "θ", "π",
        "≤", "≥", "≠", "≈", "∈", "∩", "∪", "→", "⇒", "⇔",
        "²", "³", "⁴", "ₓ", "ₐ", "ₙ",
    )
    vision_model: str = os.getenv("OPENAI_VISION_MODEL", "gpt-4o")
    structure_model: str = os.getenv("OPENAI_STRUCTURE_MODEL", "gpt-4o-mini")
    cost_per_vision_page: float = float(os.getenv("COST_PER_VISION_PAGE", "0.01"))


OCR_CONFIG = OcrConfig()


# ─── API OpenAI ───────────────────────────────────────────────────────────

OPENAI_API_KEY: str | None = os.getenv("OPENAI_API_KEY")


# ─── Domaines metier ─────────────────────────────────────────────────────

# Liste des matieres officielles reconnues par l'app Flutter.
MATIERES: tuple[str, ...] = (
    "Mathématiques",
    "Français",
    "Sciences Physiques",
    "Sciences de la Vie et de la Terre",
    "Histoire-Géographie",
    "Anglais",
    "Philosophie",
    "EPS",
)

# Mapping matiere -> code court utilise dans les identifiants (TG-...-Q01).
MATIERE_CODE: Dict[str, str] = {
    "Mathématiques": "MATHS",
    "Français": "FR",
    "Sciences Physiques": "PHYS",
    "Sciences de la Vie et de la Terre": "SVT",
    "Histoire-Géographie": "HG",
    "Anglais": "ANG",
    "Philosophie": "PHILO",
    "EPS": "EPS",
}

# Types de questions alignes sur l'enum Dart `QuestionType`.
QUESTION_TYPES: tuple[str, ...] = (
    "calcul",
    "ouvert",
    "qcm",
    "vraiFaux",
    "redaction",
)

# Seuil de similarite SimHash au-dela duquel deux questions sont considerees
# comme doublons (0 a 64 bits; ici ~15% de difference max).
SIMILARITY_MAX_BIT_DISTANCE: int = 9  # 9/64 ~= 14% => similarite > 85%

# Seuil explicite demande par le cahier des charges (pour validation report).
SIMILARITY_PERCENT_THRESHOLD: float = 85.0


# ─── Logging ──────────────────────────────────────────────────────────────

LOG_FORMAT: str = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"
LOG_DATE_FORMAT: str = "%Y-%m-%d %H:%M:%S"
LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")


__all__ = [
    "PATHS",
    "Paths",
    "SOURCES",
    "SourceConfig",
    "OCR_CONFIG",
    "OcrConfig",
    "OPENAI_API_KEY",
    "MATIERES",
    "MATIERE_CODE",
    "QUESTION_TYPES",
    "SIMILARITY_MAX_BIT_DISTANCE",
    "SIMILARITY_PERCENT_THRESHOLD",
    "LOG_FORMAT",
    "LOG_DATE_FORMAT",
    "LOG_LEVEL",
]
