"""routers/sessions.py — Sessions de revision (SM-2 + BKT).

Enregistre chaque reponse, met a jour :
    - la carte SM-2 (espacement)
    - le niveau BKT de la competence concernee
    - les compteurs utilisateur
    - l'historique brut (table ``responses``)
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from config import settings
from database import get_db
from models import schemas
from models.db_models import Question, Response, ReviewCard, User
from services import bkt_service, srs_service


router = APIRouter()


# ─── Helpers ─────────────────────────────────────────────────────────
def _utcnow() -> datetime:
    """Datetime UTC courant avec tzinfo (pour serialisation JSON coherente)."""
    return datetime.now(timezone.utc)


def _ensure_aware(dt: datetime) -> datetime:
    """Retourne une datetime tz-aware ; suppose UTC si tz-naive.

    SQLite ne preservant pas le tzinfo, les datetimes lues depuis la base
    sont tz-naive. Il faut donc normaliser avant comparaison.
    """
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def _get_or_create_card(db: Session, user_id: str, question_id: str) -> ReviewCard:
    card = db.execute(
        select(ReviewCard).where(
            ReviewCard.user_id == user_id,
            ReviewCard.question_id == question_id,
        )
    ).scalar_one_or_none()

    if card is None:
        card = ReviewCard(
            user_id=user_id,
            question_id=question_id,
            next_review_date=_utcnow(),
        )
        db.add(card)
        db.flush()
    return card


# ─── POST /sessions ──────────────────────────────────────────────────
@router.post(
    "",
    response_model=schemas.SessionOut,
    status_code=status.HTTP_200_OK,
    summary="Enregistre une session de revision",
)
def record_session(payload: schemas.SessionIn, db: Session = Depends(get_db)):
    """Enregistre une reponse, met a jour SM-2 et BKT.

    Le ``quality`` (0-5) correspond a l'echelle SM-2 :
        0 = Oublie, 1 = Tres difficile, 2 = Difficile,
        3 = Correct, 4 = Bien, 5 = Parfait.
    """
    # Verifier user + question existent
    user = db.get(User, payload.user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Utilisateur {payload.user_id} introuvable",
        )
    question = db.get(Question, payload.question_id)
    if question is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question {payload.question_id} introuvable",
        )

    # ─── 1. SM-2 ────────────────────────────────────────────────────
    card = _get_or_create_card(db, payload.user_id, payload.question_id)
    current_state = srs_service.Sm2State(
        repetitions=card.repetitions,
        easiness_factor=card.easiness_factor,
        interval_days=card.interval_days,
        next_review_date=card.next_review_date,
        last_review_date=card.last_review_date,
        total_attempts=card.total_attempts,
        correct_attempts=card.correct_attempts,
        is_learning=card.is_learning,
    )
    now = _utcnow()
    sm2_result = srs_service.apply_sm2(current_state, payload.quality, now=now)

    card.repetitions = sm2_result.repetitions
    card.easiness_factor = sm2_result.easiness_factor
    card.interval_days = sm2_result.interval_days
    card.next_review_date = sm2_result.next_review_date
    card.last_review_date = sm2_result.last_review_date
    card.total_attempts = sm2_result.total_attempts
    card.correct_attempts = sm2_result.correct_attempts
    card.is_learning = sm2_result.is_learning

    # ─── 2. BKT ─────────────────────────────────────────────────────
    competence_id = question.competence_id
    pL_before = float(user.bkt_maitrise.get(competence_id, bkt_service.init_pL()))
    bkt_result = bkt_service.update_bkt(
        pL=pL_before,
        correct=payload.correct,
        p_learn=settings.BKT_P_LEARN,
        p_slip=settings.BKT_P_SLIP,
        p_guess=settings.BKT_P_GUESS,
    )
    # Mise a jour de la map BKT (le dict JSON est mutable en place)
    user.bkt_maitrise[competence_id] = bkt_result.pL_after
    # Force SQLAlchemy a detecter la modification du champ JSON
    from sqlalchemy.orm.attributes import flag_modified

    flag_modified(user, "bkt_maitrise")

    # ─── 3. Compteurs utilisateur ───────────────────────────────────
    user.total_sessions += 1
    user.total_questions_answered += 1
    user.last_active_date = now

    # ─── 4. Historique brut ─────────────────────────────────────────
    db.add(
        Response(
            user_id=payload.user_id,
            question_id=payload.question_id,
            quality=payload.quality,
            correct=payload.correct,
            time_spent_sec=payload.time_spent_sec,
            created_at=now,
        )
    )

    db.commit()
    db.refresh(card)

    return schemas.SessionOut(
        user_id=payload.user_id,
        question_id=payload.question_id,
        quality=payload.quality,
        correct=payload.correct,
        interval_days=sm2_result.interval_days,
        easiness_factor=round(sm2_result.easiness_factor, 4),
        next_review_date=sm2_result.next_review_date,
        bkt_update=schemas.BktUpdate(
            competence_id=competence_id,
            pL_before=round(pL_before, 4),
            pL_after=round(bkt_result.pL_after, 4),
            mastered=bkt_result.mastered,
        ),
    )


# ─── GET /sessions/{user_id}/due ─────────────────────────────────────
@router.get(
    "/{user_id}/due",
    response_model=List[schemas.DueCardOut],
    summary="Cartes dues pour revision aujourd'hui",
)
def get_due_cards(
    user_id: str,
    limit: int = 20,
    db: Session = Depends(get_db),
):
    """Liste les cartes dont la prochaine revision est echue."""
    now = _utcnow()
    cards = db.execute(
        select(ReviewCard)
        .where(
            ReviewCard.user_id == user_id,
            ReviewCard.next_review_date <= now,
        )
        .order_by(ReviewCard.is_learning.desc(), ReviewCard.next_review_date.asc())
        .limit(limit)
    ).scalars().all()

    return [
        schemas.DueCardOut(
            question_id=c.question_id,
            next_review_date=_ensure_aware(c.next_review_date),
            last_review_date=(
                _ensure_aware(c.last_review_date) if c.last_review_date else None
            ),
            repetitions=c.repetitions,
            easiness_factor=round(c.easiness_factor, 4),
            interval_days=c.interval_days,
            is_learning=c.is_learning,
            total_attempts=c.total_attempts,
            correct_attempts=c.correct_attempts,
            days_overdue=srs_service.days_overdue(
                _ensure_aware(c.next_review_date), now=now
            ),
        )
        for c in cards
    ]


# ─── GET /sessions/{user_id}/stats ───────────────────────────────────
@router.get(
    "/{user_id}/stats",
    response_model=schemas.SrsStatsOut,
    summary="Statistiques agrgees de revision",
)
def get_user_stats(user_id: str, db: Session = Depends(get_db)):
    """Statistiques SM-2 (miroir de SrsStats Flutter)."""
    now = _utcnow()
    in_7d = now + timedelta(days=7)

    cards = db.execute(
        select(ReviewCard).where(ReviewCard.user_id == user_id)
    ).scalars().all()

    total = len(cards)
    due_today = sum(
        1
        for c in cards
        if srs_service.is_due(_ensure_aware(c.next_review_date), now=now)
    )
    mastered = sum(
        1
        for c in cards
        if not c.is_learning
        and srs_service.success_rate(c.total_attempts, c.correct_attempts) >= 0.8
    )
    learning = sum(1 for c in cards if c.is_learning)
    new_cards = sum(1 for c in cards if c.total_attempts == 0)
    due_in_7 = sum(
        1 for c in cards if _ensure_aware(c.next_review_date) <= in_7d
    )

    return schemas.SrsStatsOut(
        total_cards=total,
        due_today=due_today,
        mastered=mastered,
        learning=learning,
        new_cards=new_cards,
        due_in_7_days=due_in_7,
    )
