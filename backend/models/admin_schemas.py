"""models/admin_schemas.py — Pydantic schemas dedies au module admin.

Ces schemas sont independants de ``models/schemas.py`` pour ne pas
introduire de breaking change sur l'API publique. Ils definissent le
contrat d'entree/sortie des endpoints ``/admin/*`` (CRUD questions,
import/export batch, stats contenu, logs actions).

Conventions :
    - Tous les schemas utilisent Pydantic v2 (ConfigDict(from_attributes=True)
      quand la conversion ORM est necessaire).
    - Les champs IRT sont aplatis (irt_a / irt_b / irt_c) pour coller au
      modele ORM ``Question`` (et non imbriques comme dans schemas.QuestionCreate).
    - Les datetimes sont serialisees en ISO 8601 (defaut Pydantic).
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


# ─── CRUD Questions ──────────────────────────────────────────────────
class QuestionCreate(BaseModel):
    """Payload de creation d'une question (admin).

    Le champ ``id`` est obligatoire et doit respecter la convention
    ``TG-<EXAMEN>-<MATIERE>-<ANNEE>-Q<NN>`` (ex: TG-BEPC-MATHS-2024-Q01).
    """

    id: str = Field(
        ...,
        min_length=3,
        max_length=64,
        description="ID unique ex: TG-BEPC-MATHS-2024-Q01",
    )
    enonce: str = Field(..., min_length=10, max_length=2000)
    reponse: str = Field(..., min_length=1)
    explication: Optional[str] = Field(None, max_length=4000)
    matiere: str = Field(..., min_length=1, max_length=80)
    chapitre: str = Field(..., min_length=1, max_length=150)
    competence_id: str = Field(..., min_length=1, max_length=80)
    examen: str = Field(..., description="BEPC, BAC1, BAC2, Probatoire")
    serie: Optional[str] = Field(
        None,
        description="A, B, C, D, F — null pour BEPC",
        max_length=5,
    )
    annee: Optional[int] = Field(None, ge=1990, le=2100)
    type: str = Field(
        ...,
        description="calcul, ouvert, qcm, vraiFaux, redaction",
    )
    choix: Optional[List[str]] = Field(
        None, description="Obligatoire et 4 items pour le type 'qcm'"
    )
    points: Optional[int] = Field(None, ge=1, le=5)

    # Parametres IRT (aplatis comme dans l'ORM Question)
    irt_a: Optional[float] = Field(None, description="Discrimination IRT 3PL")
    irt_b: Optional[float] = Field(None, description="Difficulte IRT 3PL")
    irt_c: Optional[float] = Field(None, description="Pseudo-chance IRT 3PL")


class QuestionUpdate(BaseModel):
    """Payload de mise a jour (tous les champs optionnels).

    Seuls les champs explicitement fournis seront ecrases (exclude_unset
    cote service). Le ``id`` et la ``matiere`` ne sont pas modifiables
    ici (un renommage d'ID necessite un delete + create).
    """

    enonce: Optional[str] = Field(None, min_length=10, max_length=2000)
    reponse: Optional[str] = Field(None, min_length=1)
    explication: Optional[str] = Field(None, max_length=4000)
    chapitre: Optional[str] = None
    competence_id: Optional[str] = None
    type: Optional[str] = None
    choix: Optional[List[str]] = None
    points: Optional[int] = Field(None, ge=1, le=5)

    # IRT : on peut mettre a jour les parametres et le flag de calibration
    irt_a: Optional[float] = None
    irt_b: Optional[float] = None
    irt_c: Optional[float] = None
    irt_calibrated: Optional[bool] = None


class QuestionOut(BaseModel):
    """Question serialisee pour les reponses admin.

    Inclut le flag ``irt_calibrated`` (contrairement au schema public
    ``schemas.QuestionOut`` qui embarque un objet IrtParams imbrique).
    """

    model_config = ConfigDict(from_attributes=True)

    id: str
    enonce: str
    reponse: str
    explication: Optional[str] = None
    matiere: str
    chapitre: str
    competence_id: str
    examen: str
    serie: Optional[str] = None
    annee: Optional[int] = None
    type: str
    choix: Optional[List[str]] = None
    points: Optional[int] = None
    irt_a: Optional[float] = None
    irt_b: Optional[float] = None
    irt_c: Optional[float] = None
    irt_calibrated: bool = False
    created_at: Optional[datetime] = None


# ─── Batch ───────────────────────────────────────────────────────────
class QuestionBatchImport(BaseModel):
    """Payload d'import batch de questions."""

    questions: List[QuestionCreate] = Field(
        ..., min_length=1, max_length=2000
    )
    overwrite_existing: bool = Field(
        False,
        description="Si True, ecrase les questions existantes de meme ID",
    )


class QuestionBatchExport(BaseModel):
    """Payload d'export batch (filtres + format)."""

    format: str = Field("json", description="json | csv")
    filters: Optional[Dict[str, Any]] = Field(
        None,
        description="Filtres: {matiere, examen, serie, annee, chapitre}",
    )


class BatchResult(BaseModel):
    """Resultat d'un import batch."""

    created: int = 0
    updated: int = 0
    skipped: int = 0
    errors: List[Dict[str, Any]] = Field(default_factory=list)


class ExportResult(BaseModel):
    """Resultat d'un export batch."""

    format: str
    content: str
    count: int


# ─── Stats ───────────────────────────────────────────────────────────
class AdminStats(BaseModel):
    """Statistiques contenu pour le dashboard admin.

    Les dictionnaires ``by_*`` mappent une cle (matiere, examen, etc.) a
    un compte. ``duplicate_warnings`` liste les prefixes d'enonces
    detectes plusieurs fois (potentiels doublons).
    """

    total_questions: int
    by_matiere: Dict[str, int] = Field(default_factory=dict)
    by_examen: Dict[str, int] = Field(default_factory=dict)
    by_serie: Dict[str, int] = Field(default_factory=dict)
    by_annee: Dict[int, int] = Field(default_factory=dict)
    by_type: Dict[str, int] = Field(default_factory=dict)
    irt_calibrated_count: int = 0
    irt_calibrated_percent: float = 0.0
    last_updated: Optional[datetime] = None
    questions_without_explanation: int = 0
    duplicate_warnings: List[Dict[str, Any]] = Field(default_factory=list)


# ─── Logs ────────────────────────────────────────────────────────────
class AdminActionLog(BaseModel):
    """Log d'une action admin (create / update / delete / import / export)."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    admin_id: str
    action: str
    question_id: Optional[str] = None
    timestamp: datetime
    details: Optional[Dict[str, Any]] = None
