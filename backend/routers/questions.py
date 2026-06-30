"""routers/questions.py — Banque de questions (BEPC / BAC)."""

from __future__ import annotations

import random
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from database import get_db
from models import schemas
from models.db_models import Question
from routers.auth import get_admin_user
from models.db_models import User


router = APIRouter()


# ─── Helpers ─────────────────────────────────────────────────────────
def _to_out(q: Question) -> schemas.QuestionOut:
    return schemas.QuestionOut(
        id=q.id,
        enonce=q.enonce,
        reponse=q.reponse,
        explication=q.explication,
        matiere=q.matiere,
        chapitre=q.chapitre,
        competence_id=q.competence_id,
        examen=q.examen,
        serie=q.serie,
        annee=q.annee,
        type=q.type,
        choix=q.choix,
        points=q.points,
        irt=schemas.IrtParams(a=q.irt_a, b=q.irt_b, c=q.irt_c, calibre=q.irt_calibrated),
    )


# ─── GET /questions ──────────────────────────────────────────────────
@router.get(
    "",
    response_model=schemas.QuestionListOut,
    summary="Liste paginee de questions avec filtres",
)
def list_questions(
    matiere: Optional[str] = Query(None, description="Filtre par matiere"),
    examen: Optional[str] = Query(None, description="BEPC, BAC1, BAC2"),
    serie: Optional[str] = Query(None, description="A, C, D..."),
    competence_id: Optional[str] = Query(None),
    chapitre: Optional[str] = Query(None),
    limit: int = Query(20, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """Renvoie une page de questions filtree par matiere / examen / serie."""
    stmt = select(Question)
    count_stmt = select(func.count(Question.id))

    if matiere:
        stmt = stmt.where(Question.matiere == matiere)
        count_stmt = count_stmt.where(Question.matiere == matiere)
    if examen:
        stmt = stmt.where(Question.examen == examen)
        count_stmt = count_stmt.where(Question.examen == examen)
    if serie:
        stmt = stmt.where(Question.serie == serie)
        count_stmt = count_stmt.where(Question.serie == serie)
    if competence_id:
        stmt = stmt.where(Question.competence_id == competence_id)
        count_stmt = count_stmt.where(Question.competence_id == competence_id)
    if chapitre:
        stmt = stmt.where(Question.chapitre == chapitre)
        count_stmt = count_stmt.where(Question.chapitre == chapitre)

    total = db.execute(count_stmt).scalar() or 0
    stmt = stmt.order_by(Question.id).limit(limit).offset(offset)
    items = db.execute(stmt).scalars().all()

    return schemas.QuestionListOut(
        items=[_to_out(q) for q in items],
        total=total,
        limit=limit,
        offset=offset,
    )


# ─── GET /questions/{id} ─────────────────────────────────────────────
@router.get(
    "/{question_id}",
    response_model=schemas.QuestionOut,
    summary="Detail d'une question",
)
def get_question(question_id: str, db: Session = Depends(get_db)):
    q = db.get(Question, question_id)
    if q is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question {question_id} introuvable",
        )
    return _to_out(q)


# ─── POST /questions (admin only) ────────────────────────────────────
@router.post(
    "",
    response_model=schemas.QuestionOut,
    status_code=status.HTTP_201_CREATED,
    summary="Cree une nouvelle question (admin)",
)
def create_question(
    payload: schemas.QuestionCreate,
    db: Session = Depends(get_db),
    _: User = Depends(get_admin_user),
):
    """Cree une question dans la banque. Reserve aux administrateurs."""
    qid = payload.id or f"TG-{payload.examen}-{payload.matiere[:3].upper()}-{uuid.uuid4().hex[:6]}"

    if db.get(Question, qid) is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"La question {qid} existe deja",
        )

    q = Question(
        id=qid,
        enonce=payload.enonce,
        reponse=payload.reponse,
        explication=payload.explication,
        matiere=payload.matiere,
        chapitre=payload.chapitre,
        competence_id=payload.competence_id,
        examen=payload.examen,
        serie=payload.serie,
        annee=payload.annee,
        type=payload.type,
        choix=payload.choix,
        points=payload.points,
        irt_a=payload.irt.a,
        irt_b=payload.irt.b,
        irt_c=payload.irt.c,
        irt_calibrated=payload.irt.calibre,
    )
    db.add(q)
    db.commit()
    db.refresh(q)
    return _to_out(q)


# ─── GET /questions/random ───────────────────────────────────────────
@router.get(
    "/random/list",
    response_model=List[schemas.QuestionOut],
    summary="Tirage aleatoire de questions (simulation)",
)
def random_questions(
    n: int = Query(10, ge=1, le=100),
    matiere: Optional[str] = Query(None),
    examen: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """Tire ``n`` questions au hasard (pour les simulations d'examen)."""
    stmt = select(Question)
    if matiere:
        stmt = stmt.where(Question.matiere == matiere)
    if examen:
        stmt = stmt.where(Question.examen == examen)
    # SQLite/PostgreSQL supportent func.random()
    stmt = stmt.order_by(func.random()).limit(n)
    items = db.execute(stmt).scalars().all()
    return [_to_out(q) for q in items]
