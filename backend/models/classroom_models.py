"""models/classroom_models.py — Modeles Pydantic pour le module Classe
Temps Reel (Kahoot-like + mode devoir asynchrone).

Ces schemas definissent le contrat d'entree/sortie des endpoints REST et
les messages echangés sur la WebSocket ``/classroom/{session_code}``.

Conventions :
  - Toutes les datetimes sont serialisees en ISO 8601 UTC.
  - ``player_id`` est un identifiant client (UUID v4 genere cote Flutter)
    pour eviter toute fuite d'identite eleve vers les autres joueurs.
  - Le role distingue l'enseignant (``teacher``) de l'eleve (``student``).
"""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


# ─── Enums ───────────────────────────────────────────────────────────
class SessionStatus(str, Enum):
    """Cycle de vie d'une session classe."""
    waiting = "waiting"   # Avant le lancement (eleves rejoignent)
    live = "live"         # Quiz en cours
    ended = "ended"       # Session terminee, resultats disponibles


class SessionMode(str, Enum):
    """Mode de la session.

    ``live`` : Kahoot-like, timer 30s par question, diffusion en temps reel.
    ``homework`` : mode devoir asynchrone, eleves rejoignent dans les 7 jours,
    repondent a leur rythme sans timer live.
    """
    live = "live"
    homework = "homework"


class PlayerRole(str, Enum):
    teacher = "teacher"
    student = "student"


class PlayerStatus(str, Enum):
    """Statut d'un eleve pendant une question donnee."""
    connected = "connected"   # Connecte, en attente
    answered = "answered"     # A deja repondu a la question courante
    disconnected = "disconnected"


# ─── Requetes REST ───────────────────────────────────────────────────
class SessionCreateRequest(BaseModel):
    """Payload de creation de session classe."""
    teacher_id: str = Field(..., description="Identifiant enseignant")
    teacher_name: str = Field("Enseignant", description="Nom affiche")
    exam: str = Field("BEPC", description="BEPC / BAC1 / BAC2")
    matiere: Optional[str] = Field(None, description="Matiere filtree")
    question_ids: List[str] = Field(
        ..., min_length=1, max_length=20,
        description="Liste des IDs de questions (max 20)"
    )
    mode: SessionMode = SessionMode.live
    time_limit_seconds: int = Field(30, ge=5, le=120)
    homework_days: int = Field(7, ge=1, le=30, description="Duree de validite du devoir (jours)")


class JoinRequest(BaseModel):
    """Payload pour rejoindre une session via REST (alt. a la WebSocket)."""
    session_code: str = Field(..., min_length=6, max_length=6)
    player_id: str
    player_name: str = Field(..., min_length=1, max_length=40)


# ─── Modeles de sortie ───────────────────────────────────────────────
class ClassroomPlayerOut(BaseModel):
    """Vue publique d'un joueur (sans websocket)."""
    id: str
    name: str
    score: int = 0
    role: PlayerRole = PlayerRole.student
    status: PlayerStatus = PlayerStatus.connected
    last_answer_correct: Optional[bool] = None
    answered_count: int = 0
    joined_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ClassroomSessionOut(BaseModel):
    """Vue publique d'une session."""
    code: str
    teacher_id: str
    teacher_name: str
    exam: str
    matiere: Optional[str] = None
    mode: SessionMode
    status: SessionStatus
    time_limit_seconds: int = 30
    question_ids: List[str]
    current_question_index: int = -1
    current_question_id: Optional[str] = None
    players_count: int = 0
    created_at: datetime
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    homework_expires_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class AnswerResultOut(BaseModel):
    """Resultat de l'enregistrement d'une reponse eleve."""
    correct: bool
    points_earned: int
    total_score: int
    question_id: str
    expected_answer: Optional[str] = None
    explanation: Optional[str] = None


class QuestionStatOut(BaseModel):
    """Statistiques agrégees pour une question donnee."""
    question_id: str
    answered_count: int
    correct_count: int
    success_rate: float
    average_time_seconds: float


class SessionResultsOut(BaseModel):
    """Resultats finaux d'une session classe."""
    session_code: str
    status: SessionStatus
    podium: List[ClassroomPlayerOut] = Field(
        default_factory=list,
        description="Top 3 joueurs (index 0 = 1er)"
    )
    leaderboard: List[ClassroomPlayerOut] = Field(default_factory=list)
    question_stats: List[QuestionStatOut] = Field(default_factory=list)
    total_players: int = 0
    total_questions: int = 0
    ended_at: Optional[datetime] = None


class SessionStatusOut(BaseModel):
    """Statut public d'une session (pour GET /classroom/{code}/status)."""
    code: str
    exists: bool
    status: SessionStatus
    mode: SessionMode
    players_count: int = 0
    current_question_index: int = -1
    total_questions: int = 0
    teacher_name: str = ""
    created_at: Optional[datetime] = None
    homework_expires_at: Optional[datetime] = None


# ─── Messages WebSocket ──────────────────────────────────────────────
# Les messages echanges sur la WebSocket suivent une convention simple :
#   {"type": "<event_name>", ...payload}
# Cote Flutter, ClassroomSocketService parse le champ ``type`` et emet
# l'evenement correspondant via ChangeNotifier.

class WSJoinPayload(BaseModel):
    """Message envoye par le client juste apres accept() de la WS."""
    type: str = "join"
    player_id: str
    player_name: str
    role: PlayerRole = PlayerRole.student


class WSAnswerPayload(BaseModel):
    """Message envoye par un eleve lorsqu'il repond a une question."""
    type: str = "answer"
    question_id: str
    answer: str
    time_taken_seconds: float = 0.0


class WSNextQuestionPayload(BaseModel):
    """Message envoye par l'enseignant pour passer a la question suivante."""
    type: str = "next_question"


class WSEndSessionPayload(BaseModel):
    """Message envoye par l'enseignant pour terminer la session."""
    type: str = "end_session"


class WSForceNextPayload(BaseModel):
    """Message de l'enseignant pour forcer la question suivante
    (sans attendre que tous aient repondu)."""
    type: str = "force_next"


class WSStartPayload(BaseModel):
    """Message de l'enseignant pour demarrer le quiz (mode live)."""
    type: str = "start_quiz"


# ─── Helpers de serialisation ────────────────────────────────────────
def utc_now() -> datetime:
    """Retourne la datetime UTC courante avec tzinfo."""
    return datetime.now(timezone.utc)


def event(message_type: str, **payload: Any) -> Dict[str, Any]:
    """Construit un message WebSocket standardise.

    Toutes les datetimes sont converties en ISO 8601 pour etre
    deserialisables cote Flutter.
    """
    out: Dict[str, Any] = {"type": message_type}
    for k, v in payload.items():
        if isinstance(v, datetime):
            out[k] = v.isoformat()
        elif isinstance(v, BaseModel):
            out[k] = v.model_dump(mode="json")
        elif isinstance(v, list) and v and isinstance(v[0], BaseModel):
            out[k] = [item.model_dump(mode="json") for item in v]
        else:
            out[k] = v
    return out
