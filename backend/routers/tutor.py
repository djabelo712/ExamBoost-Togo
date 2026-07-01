"""routers/tutor.py — Endpoint du tuteur IA (Claude Anthropic).

POST /tutor/ask : pose une question au tuteur IA, avec contexte pedagogique
optionnel et historique de conversation. Rate limiting 30 questions/heure
par utilisateur (in-memory par defaut, Redis si disponible).

Healthcheck : GET /tutor/health pour verifier la configuration Anthropic.
"""

from __future__ import annotations

import time
from collections import defaultdict, deque
from typing import Any, Deque, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from models.db_models import User
from routers.auth import get_current_user
from services import tutor_service


router = APIRouter()


# ─── Schemas Pydantic ─────────────────────────────────────────────────
class TutorContext(BaseModel):
    """Contexte pedagogique optionnel (matiere/chapitre en cours)."""

    matiere: Optional[str] = None
    chapitre: Optional[str] = None
    competence_id: Optional[str] = None
    niveau_scolaire: Optional[str] = None
    serie: Optional[str] = None


class ConversationTurn(BaseModel):
    """Un tour de parole dans l'historique de conversation."""

    role: str = Field(..., pattern="^(user|assistant)$")
    content: str = Field(..., min_length=1, max_length=4000)


class TutorRequest(BaseModel):
    """Payload de la requete POST /tutor/ask."""

    question: str = Field(..., min_length=1, max_length=2000)
    context: Optional[TutorContext] = None
    conversation_history: List[ConversationTurn] = Field(default_factory=list)


class TutorResponse(BaseModel):
    """Reponse du tuteur IA."""

    answer: str
    suggested_followup: List[str] = Field(default_factory=list)
    tokens_used: int = 0
    model: str = "claude-sonnet-4-6"
    fallback: bool = False  # True si reponse mock (sans cle API)


# ─── Rate limiting (in-memory, par user) ─────────────────────────────
# 30 questions / heure / user. Pour Redis : remplacer par redis-py.
RATE_LIMIT_WINDOW_SEC: int = 3600
RATE_LIMIT_MAX_REQUESTS: int = 30

# Map user_id -> deque de timestamps Unix
_user_requests: Dict[str, Deque[float]] = defaultdict(deque)


def _check_rate_limit(user_id: str) -> None:
    """Leve HTTPException 429 si l'utilisateur a depasse le rate limit."""
    now = time.time()
    window_start = now - RATE_LIMIT_WINDOW_SEC
    queue = _user_requests[user_id]
    # Nettoie les timestamps perimes
    while queue and queue[0] < window_start:
        queue.popleft()
    if len(queue) >= RATE_LIMIT_MAX_REQUESTS:
        retry_after = int(queue[0] + RATE_LIMIT_WINDOW_SEC - now) + 1
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=(
                f"Tu as pose {RATE_LIMIT_MAX_REQUESTS} questions en une heure. "
                f"Reessaie dans {retry_after} secondes."
            ),
            headers={"Retry-After": str(retry_after)},
        )
    queue.append(now)


# ─── Endpoint POST /tutor/ask ────────────────────────────────────────
@router.post("/ask", response_model=TutorResponse, tags=["tutor"])
async def ask_tutor(
    request: TutorRequest,
    current_user: User = Depends(get_current_user),
) -> TutorResponse:
    """Answer a student's question using the AI tutor (Claude).

    Body:
        question: str                    — the student's question (max 2000 chars)
        context: Optional[TutorContext]  — current matiere/chapitre if known
        conversation_history: List[ConversationTurn]  — previous turns

    Returns:
        TutorResponse with answer, suggested follow-up questions, tokens used.

    Rate limit: 30 questions/hour per user (in-memory). Returns 429 if exceeded.
    Auth: requires a valid Bearer JWT (Depends get_current_user).
    """
    _check_rate_limit(current_user.id)

    try:
        result: Dict[str, Any] = await tutor_service.generate_answer(
            user=current_user,
            question=request.question,
            context=request.context,
            conversation_history=[
                {"role": t.role, "content": t.content}
                for t in request.conversation_history
            ],
        )
        return TutorResponse(**result)
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001 — on ne leak pas l'erreur interne
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=(
                "Le tuteur IA est temporairement indisponible. "
                "Reessaie dans un instant."
            ),
        ) from exc


# ─── Endpoint GET /tutor/health ──────────────────────────────────────
@router.get("/health", tags=["tutor"])
async def tutor_health() -> dict:
    """Healthcheck du tuteur (utile pour le debug et le monitoring)."""
    return {
        "status": "ok",
        "anthropic_configured": tutor_service.is_anthropic_configured(),
        "model": tutor_service.ANTHROPIC_MODEL,
        "rate_limit_per_hour": RATE_LIMIT_MAX_REQUESTS,
    }
