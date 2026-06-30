"""models/schemas.py — Modeles Pydantic pour la validation/serialisation API.

Ces schemas sont independants de la base de donnees. Ils definissent le
contrat d'entree/sortie de chaque endpoint FastAPI (response_model).
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator


# ─── Auth ────────────────────────────────────────────────────────────
class UserCreate(BaseModel):
    """Payload d'inscription d'un nouvel utilisateur."""

    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)
    nom: str = Field(..., min_length=1, max_length=80)
    prenom: str = Field(..., min_length=1, max_length=80)
    niveau_scolaire: str = Field(..., description="3eme, 2nde, 1ere, Terminale")
    serie: Optional[str] = Field(None, description="A, C, D, B, F (null pour BEPC)")
    etablissement: Optional[str] = None
    ville: Optional[str] = None

    @field_validator("niveau_scolaire")
    @classmethod
    def _check_niveau(cls, v: str) -> str:
        v = v.strip().lower()
        allowed = {"3eme", "2nde", "1ere", "terminale", "tle"}
        if v not in allowed:
            raise ValueError(
                f"niveau_scolaire doit etre dans {sorted(allowed)}, recu: {v}"
            )
        return v


class UserLogin(BaseModel):
    """Payload de connexion."""

    email: EmailStr
    password: str


class UserOut(BaseModel):
    """User public (sans password_hash)."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    nom: str
    prenom: str
    niveau_scolaire: str
    serie: Optional[str] = None
    etablissement: Optional[str] = None
    ville: Optional[str] = None
    date_inscription: datetime
    theta_irt: Optional[float] = None
    total_sessions: int = 0
    total_questions_answered: int = 0
    bkt_maitrise: Dict[str, float] = Field(default_factory=dict)


class Token(BaseModel):
    """Reponse JWT standard."""

    access_token: str
    token_type: str = "bearer"
    user_id: str
    user: Optional[UserOut] = None


# ─── Questions ───────────────────────────────────────────────────────
class IrtParams(BaseModel):
    a: Optional[float] = None
    b: Optional[float] = None
    c: Optional[float] = None
    calibre: bool = False


class QuestionCreate(BaseModel):
    """Payload de creation de question (admin only)."""

    id: Optional[str] = Field(None, description="Optionnel ; genere si absent")
    enonce: str = Field(..., min_length=3)
    reponse: str = Field(..., min_length=1)
    explication: Optional[str] = None
    matiere: str = Field(..., description="Mathematiques, Francais, Sciences, etc.")
    chapitre: str
    competence_id: str
    examen: str = Field("BEPC", description="BEPC, BAC1, BAC2, Probatoire")
    serie: Optional[str] = None
    annee: Optional[int] = None
    type: str = Field("ouvert", description="ouvert, qcm, redaction, calcul, vraiFaux")
    choix: Optional[List[str]] = None
    points: Optional[int] = None
    irt: IrtParams = Field(default_factory=IrtParams)


class QuestionOut(BaseModel):
    """Question serialisee pour l'API."""

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
    irt: IrtParams


class QuestionListOut(BaseModel):
    """Liste paginee de questions."""

    items: List[QuestionOut]
    total: int
    limit: int
    offset: int


# ─── Sessions / SRS ──────────────────────────────────────────────────
class SessionIn(BaseModel):
    """Enregistre une reponse de l'utilisateur (qualite SM-2 0-5)."""

    user_id: str
    question_id: str
    quality: int = Field(..., ge=0, le=5, description="Qualite SM-2 (0-5)")
    time_spent_sec: int = Field(0, ge=0, description="Temps en secondes")
    correct: Optional[bool] = Field(
        None, description="Si null, derive de quality (q>=3 => correct)"
    )

    @model_validator(mode="after")
    def _derive_correct(self):
        """Si ``correct`` est null, le derive de ``quality`` (q>=3 => True)."""
        if self.correct is None:
            self.correct = self.quality >= 3
        return self


class BktUpdate(BaseModel):
    competence_id: str
    pL_before: float
    pL_after: float
    mastered: bool


class SessionOut(BaseModel):
    """Reponse apres enregistrement d'une session."""

    user_id: str
    question_id: str
    quality: int
    correct: bool
    interval_days: int
    easiness_factor: float
    next_review_date: datetime
    bkt_update: BktUpdate


class DueCardOut(BaseModel):
    question_id: str
    next_review_date: datetime
    last_review_date: Optional[datetime] = None
    repetitions: int
    easiness_factor: float
    interval_days: int
    is_learning: bool
    total_attempts: int
    correct_attempts: int
    days_overdue: int


class SrsStatsOut(BaseModel):
    """Statistiques de revision (miroir de SrsStats Flutter)."""

    total_cards: int
    due_today: int
    mastered: int
    learning: int
    new_cards: int
    due_in_7_days: int


# ─── Predictions ─────────────────────────────────────────────────────
class ScoreBreakdownItem(BaseModel):
    matiere: str
    score_estime: float
    pL_moyen: float
    nb_questions: int


class PredictScoreOut(BaseModel):
    user_id: str
    examen: str
    predicted_score: float = Field(..., description="Score sur 20")
    confidence: float = Field(..., ge=0.0, le=1.0)
    method: str = Field(..., description="heuristic | xgboost | insufficient_data")
    breakdown: List[ScoreBreakdownItem] = Field(default_factory=list)
    total_responses: int


class PredictDropoutOut(BaseModel):
    user_id: str
    dropout_probability: float = Field(..., ge=0.0, le=1.0)
    risk_level: str = Field(..., description="faible | modere | eleve")
    factors: Dict[str, Any] = Field(default_factory=dict)
