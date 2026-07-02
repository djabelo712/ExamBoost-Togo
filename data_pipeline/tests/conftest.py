"""
Configuration pytest commune.

Ajoute la racine du pipeline au sys.path afin que les imports
`from utils...`, `from config...` fonctionnent depuis le dossier tests/.

Definit aussi un ensemble de fixtures reutilisees par les differents
modules de tests :

    - tmp_cache_dir  : dossier de cache OCR isole (monkeypatch PATHS.cache)
    - sample_image   : PIL.Image 100x100 blanche
    - sample_pdf     : fichier binaire factice simulant un PDF
    - sample_pdf_path: chemin vers le PDF factice
    - valid_bepc_q   : dictionnaire question BEPC valide canonique
    - valid_bac_q    : dictionnaire question BAC serie C valide canonique
    - valid_qcm_q    : dictionnaire question QCM valide
    - sample_questions: liste de 3 questions diverses
    - openai_client_mock : MagicMock remplaceant le client OpenAI
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any, Dict, List
from unittest.mock import MagicMock

import pytest
from PIL import Image

# Remonte d'un niveau (tests/ -> data_pipeline/)
_PIPELINE_ROOT = Path(__file__).resolve().parent.parent
if str(_PIPELINE_ROOT) not in sys.path:
    sys.path.insert(0, str(_PIPELINE_ROOT))


# ─── Cache OCR isole ─────────────────────────────────────────────────────


@pytest.fixture
def tmp_cache_dir(tmp_path, monkeypatch):
    """Redirect PATHS.cache to a temp dir so OCR tests never pollute repo.

    Paths is a frozen dataclass => we replace the whole PATHS instance on
    the config module (and on every utils module that imported it at the
    top of the file) with a new Paths pointing at tmp_path subdirs.
    """
    import config as config_mod

    cache = tmp_path / "ocr_cache"
    cache.mkdir(parents=True, exist_ok=True)
    fake_paths = config_mod.Paths(
        root=tmp_path,
        raw_pdfs=tmp_path / "raw",
        extracted_text=tmp_path / "txt",
        structured_questions=tmp_path / "q",
        final=tmp_path / "final",
        cache=cache,
    )
    # Patch on the config module AND on every utils module that did
    # `from config import PATHS` at the top of the file.
    monkeypatch.setattr(config_mod, "PATHS", fake_paths)
    import utils.pdf_utils as pdf_utils_mod

    monkeypatch.setattr(pdf_utils_mod, "PATHS", fake_paths)
    import utils.tesseract_utils as tess_mod

    monkeypatch.setattr(tess_mod, "PATHS", fake_paths, raising=False)
    import utils.openai_utils as openai_mod

    monkeypatch.setattr(openai_mod, "PATHS", fake_paths, raising=False)
    import ocr_extract as ocr_mod

    monkeypatch.setattr(ocr_mod, "PATHS", fake_paths, raising=False)
    return cache


# ─── Images & PDF factices ────────────────────────────────────────────────


@pytest.fixture
def sample_image() -> Image.Image:
    """A 100x100 white RGB PIL image."""
    return Image.new("RGB", (100, 100), "white")


@pytest.fixture
def sample_pdf_bytes() -> bytes:
    """Minimal fake PDF bytes (header only) for size/path tests."""
    return b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n1 0 obj<</Pages 2 0 R>>endobj\n"


@pytest.fixture
def sample_pdf_path(tmp_path, sample_pdf_bytes) -> Path:
    """A fake .pdf file written on disk (header-only)."""
    p = tmp_path / "bepc_maths_2022.pdf"
    p.write_bytes(sample_pdf_bytes)
    return p


# ─── Questions canoniques ────────────────────────────────────────────────


@pytest.fixture
def valid_bepc_q() -> Dict[str, Any]:
    """A fully valid BEPC question dict (serie=None, calcul, points=4)."""
    return {
        "id": "TG-BEPC-MATHS-2022-Q01",
        "enonce": "Resoudre l'equation 3x + 7 = 22",
        "reponse": "x = 5",
        "explication": "On soustrait 7 puis on divise par 3.",
        "matiere": "Mathématiques",
        "chapitre": "Equations 1er degre",
        "competence_id": "TG-MATHS-EQ1D-001",
        "examen": "BEPC",
        "serie": None,
        "annee": 2022,
        "type": "calcul",
        "choix": None,
        "points": 4,
        "irt": {"a": None, "b": -0.5, "c": None, "calibre": False},
    }


@pytest.fixture
def valid_bac_q() -> Dict[str, Any]:
    """A fully valid BAC1 serie C question."""
    return {
        "id": "TG-BAC-MATHC-2023-Q01",
        "enonce": "Etudier la continuite de f(x) = (x^2 - 1)/(x - 1) en x=1",
        "reponse": "f est prolongeable par continuite en 1 avec f(1)=2",
        "explication": "On factorise le numerateur puis on simplifie.",
        "matiere": "Mathématiques",
        "chapitre": "Continuite",
        "competence_id": "TG-MATHS-CONT-001",
        "examen": "BAC1",
        "serie": "C",
        "annee": 2023,
        "type": "calcul",
        "choix": None,
        "points": 5,
        "irt": {"a": None, "b": 0.8, "c": None, "calibre": False},
    }


@pytest.fixture
def valid_qcm_q() -> Dict[str, Any]:
    """A fully valid QCM (4 choices) BEPC question."""
    return {
        "id": "TG-BEPC-SVT-2021-Q03",
        "enonce": "Quelle est la fonction principale des globules rouges ?",
        "reponse": "Transporter l'oxygene",
        "explication": "Les globules rouges contiennent de l'hemoglobine.",
        "matiere": "Sciences de la Vie et de la Terre",
        "chapitre": "Le sang",
        "competence_id": "TG-SVT-SANG-001",
        "examen": "BEPC",
        "serie": None,
        "annee": 2021,
        "type": "qcm",
        "choix": [
            "Transporter l'oxygene",
            "Defendre l'organisme",
            "Coaguler le sang",
            "Transporter les nutriments",
        ],
        "points": 2,
        "irt": {"a": None, "b": -0.3, "c": None, "calibre": False},
    }


@pytest.fixture
def sample_questions(valid_bepc_q, valid_bac_q, valid_qcm_q) -> List[Dict[str, Any]]:
    """A small list of 3 distinct valid questions."""
    return [valid_bepc_q, valid_bac_q, valid_qcm_q]


# ─── OpenAI client mock ──────────────────────────────────────────────────


@pytest.fixture
def openai_client_mock() -> MagicMock:
    """A MagicMock that mimics the OpenAI client surface used in openai_utils.

    Usage:
        monkeypatch.setattr("utils.openai_utils.get_client",
                            lambda: openai_client_mock)
    """
    client = MagicMock(name="OpenAIClientMock")
    # Configure a default chat.completions.create response.
    response = MagicMock(name="ChatCompletionMock")
    response.choices = [MagicMock(message=MagicMock(content=""))]
    response.usage = MagicMock(total_tokens=10)
    client.chat.completions.create.return_value = response
    return client
