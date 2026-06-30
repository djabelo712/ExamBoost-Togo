"""routers/predict.py — Predictions (score + risque de decrochage).

Strategie :
    - GET /predict-score/{user_id} : score attendu a l'examen (XGBoost ou heuristique BKT)
    - GET /predict-dropout/{user_id} : probabilite de decrochage (mock pour demo DJANTA)
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Dict, List

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from database import get_db
from models import schemas
from models.db_models import Question, Response, Simulation, User
from services import irt_service, ml_service, srs_service


router = APIRouter()


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _build_pL_by_matiere(user: User, db: Session) -> Dict[str, float]:
    """Construit un dict {matiere: pL_moyen} depuis le BKT de l'utilisateur.

    La map ``user.bkt_maitrise`` est indexee par ``competence_id`` ; on
    agrege par matiere en moyennant les pL des competences qui y
    appartiennent.
    """
    if not user.bkt_maitrise:
        return {}

    # Recupere le mapping competence_id -> matiere
    competences = list(user.bkt_maitrise.keys())
    rows = db.execute(
        select(Question.competence_id, Question.matiere).where(
            Question.competence_id.in_(competences)
        ).distinct()
    ).all()
    comp_to_matiere = {row[0]: row[1] for row in rows}

    by_matiere: Dict[str, List[float]] = {}
    for comp_id, pL in user.bkt_maitrise.items():
        matiere = comp_to_matiere.get(comp_id, "Autre")
        by_matiere.setdefault(matiere, []).append(float(pL))

    return {m: sum(v) / len(v) for m, v in by_matiere.items()}


def _sessions_last_days(user_id: str, days: int, db: Session) -> int:
    since = _utcnow() - timedelta(days=days)
    return int(
        db.execute(
            select(func.count(Response.id)).where(
                Response.user_id == user_id,
                Response.created_at >= since,
            )
        ).scalar()
        or 0
    )


def _avg_time_per_q(user_id: str, db: Session) -> float:
    row = db.execute(
        select(func.avg(Response.time_spent_sec)).where(Response.user_id == user_id)
    ).scalar()
    return float(row or 0.0)


def _last_simulation_score(user_id: str, db: Session) -> float:
    row = db.execute(
        select(Simulation.score)
        .where(Simulation.user_id == user_id)
        .order_by(Simulation.created_at.desc())
        .limit(1)
    ).scalar_one_or_none()
    return float(row) if row is not None else 0.0


def _simulations_count(user_id: str, db: Session) -> int:
    return int(
        db.execute(
            select(func.count(Simulation.id)).where(Simulation.user_id == user_id)
        ).scalar()
        or 0
    )


def _total_responses(user_id: str, db: Session) -> int:
    return int(
        db.execute(
            select(func.count(Response.id)).where(Response.user_id == user_id)
        ).scalar()
        or 0
    )


def _last_active_days_ago(user: User) -> int:
    if not user.last_active_date:
        return 365  # jamais actif = grande valeur
    last = user.last_active_date
    if last.tzinfo is None:
        last = last.replace(tzinfo=timezone.utc)
    delta = _utcnow() - last
    return max(0, delta.days)


# ─── GET /predict-score/{user_id} ────────────────────────────────────
@router.get(
    "/predict-score/{user_id}",
    response_model=schemas.PredictScoreOut,
    summary="Prediction du score a l'examen",
)
def predict_score(
    user_id: str,
    examen: str = Query("BEPC", description="BEPC, BAC1, BAC2"),
    db: Session = Depends(get_db),
):
    """Predit le score (sur 20) que l'utilisateur obtiendrait a l'examen.

    Methode :
        - Si >= 100 reponses et modele XGBoost disponible -> XGBoost
        - Sinon -> heuristique basee sur la moyenne des P(L) BKT
    """
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Utilisateur {user_id} introuvable",
        )

    pL_by_matiere = _build_pL_by_matiere(user, db)
    total_responses = _total_responses(user_id, db)
    sessions_7j = _sessions_last_days(user_id, 7, db)
    avg_time = _avg_time_per_q(user_id, db)
    sims_completed = _simulations_count(user_id, db)
    last_sim_score = _last_simulation_score(user_id, db)
    pL_global = (
        sum(pL_by_matiere.values()) / len(pL_by_matiere)
        if pL_by_matiere
        else 0.0
    )

    # Mapping matieres -> pL pour les features ML
    pL_maths = pL_by_matiere.get("Mathematiques", 0.0)
    pL_fr = pL_by_matiere.get("Francais", 0.0)
    pL_sciences = pL_by_matiere.get("Sciences", pL_by_matiere.get("SVT", 0.0))

    features = [
        pL_global,
        pL_maths,
        pL_fr,
        pL_sciences,
        float(sessions_7j),
        float(avg_time),
        float(sims_completed),
        float(last_sim_score),
    ]

    prediction = ml_service.predict_score(
        features=features,
        pL_by_matiere=pL_by_matiere,
        total_responses=total_responses,
    )

    # Breakdown par matiere
    breakdown: List[schemas.ScoreBreakdownItem] = []
    for matiere, pL in sorted(pL_by_matiere.items()):
        # Estime le nombre de questions repondues dans cette matiere
        nb = int(
            db.execute(
                select(func.count(Response.id))
                .join(Question, Response.question_id == Question.id)
                .where(
                    Response.user_id == user_id,
                    Question.matiere == matiere,
                )
            ).scalar()
            or 0
        )
        breakdown.append(
            schemas.ScoreBreakdownItem(
                matiere=matiere,
                score_estime=round(float(pL) * 20.0, 2),
                pL_moyen=round(float(pL), 4),
                nb_questions=nb,
            )
        )

    return schemas.PredictScoreOut(
        user_id=user_id,
        examen=examen,
        predicted_score=prediction.predicted_score,
        confidence=prediction.confidence,
        method=prediction.method,
        breakdown=breakdown,
        total_responses=total_responses,
    )


# ─── GET /predict-dropout/{user_id} ──────────────────────────────────
@router.get(
    "/predict-dropout/{user_id}",
    response_model=schemas.PredictDropoutOut,
    summary="Probabilite de decrochage (mock)",
)
def predict_dropout_route(user_id: str, db: Session = Depends(get_db)):
    """Estime le risque de decrochage de l'utilisateur.

    Modele volontairement simple et transparent (regle metier) pour le
    pitch DJANTA. Sera remplace par un XGBoost classifier une fois assez
    de donnees collectees.
    """
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Utilisateur {user_id} introuvable",
        )

    pL_by_matiere = _build_pL_by_matiere(user, db)
    pL_global = (
        sum(pL_by_matiere.values()) / len(pL_by_matiere)
        if pL_by_matiere
        else 0.0
    )
    sessions_7j = _sessions_last_days(user_id, 7, db)
    avg_time = _avg_time_per_q(user_id, db)
    sims = _simulations_count(user_id, db)
    last_active = _last_active_days_ago(user)

    pred = ml_service.predict_dropout(
        sessions_7j=sessions_7j,
        avg_time_per_q=avg_time,
        last_active_days_ago=last_active,
        simulations_completed=sims,
        pL_global=pL_global,
    )

    return schemas.PredictDropoutOut(
        user_id=user_id,
        dropout_probability=pred.probability,
        risk_level=pred.risk_level,
        factors=pred.factors,
    )
