"""services/srs_service.py — Algorithme SM-2 (Spaced Repetition System).

Miroir exact de ``applyReview`` de ``lib/models/review_card.dart`` :

    Si q >= 3 (correct) :
        repetitions == 0  -> interval = 1
        repetitions == 1  -> interval = 6
        repetitions >= 2  -> interval = floor(interval * EF)
        repetitions += 1
        is_learning = False
    Sinon (q < 3) :
        repetitions = 0
        interval = 1
        is_learning = True

    EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    EF' = max(EF', 1.3)

    next_review_date = now + interval_days
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Optional


@dataclass
class Sm2State:
    """Etat SM-2 d'une carte (miroir de ReviewCard cote Flutter)."""

    repetitions: int = 0
    easiness_factor: float = 2.5
    interval_days: int = 0
    next_review_date: datetime = None  # type: ignore[assignment]
    last_review_date: Optional[datetime] = None
    total_attempts: int = 0
    correct_attempts: int = 0
    is_learning: bool = True

    def __post_init__(self):
        if self.next_review_date is None:
            self.next_review_date = datetime.now(timezone.utc)


@dataclass
class Sm2Result:
    """Resultat de l'application de SM-2."""

    repetitions: int
    easiness_factor: float
    interval_days: int
    next_review_date: datetime
    last_review_date: datetime
    total_attempts: int
    correct_attempts: int
    is_learning: bool


def apply_sm2(state: Sm2State, quality: int, now: Optional[datetime] = None) -> Sm2Result:
    """Applique une etape SM-2 sur ``state`` et renvoie le nouvel etat.

    Parameters
    ----------
    state:
        Etat SM-2 actuel (non modifie en place).
    quality:
        Qualite de la reponse (0 a 5).
    now:
        Horodatage de reference (defaut : utcnow).

    Returns
    -------
    Sm2Result
        Nouvel etat apres mise a jour.
    """
    if not 0 <= quality <= 5:
        raise ValueError("quality doit etre compris entre 0 et 5")

    now = now or datetime.now(timezone.utc)

    # Copie pour ne pas muter l'etat en entree
    reps = state.repetitions
    ef = state.easiness_factor
    interval = state.interval_days
    total_attempts = state.total_attempts + 1
    correct_attempts = state.correct_attempts
    is_learning = state.is_learning

    if quality >= 3:
        # ─── Reponse correcte ─────────────────────────────────────
        correct_attempts += 1
        if reps == 0:
            interval = 1
        elif reps == 1:
            interval = 6
        else:
            interval = int(interval * ef)
        reps += 1
        is_learning = False
    else:
        # ─── Reponse incorrecte (q < 3) ───────────────────────────
        reps = 0
        interval = 1
        is_learning = True

    # Mise a jour du facteur d'aisance EF
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    if ef < 1.3:
        ef = 1.3

    next_review = now + timedelta(days=interval)

    return Sm2Result(
        repetitions=reps,
        easiness_factor=ef,
        interval_days=interval,
        next_review_date=next_review,
        last_review_date=now,
        total_attempts=total_attempts,
        correct_attempts=correct_attempts,
        is_learning=is_learning,
    )


def days_overdue(next_review_date: datetime, now: Optional[datetime] = None) -> int:
    """Retard en jours (0 si pas en retard)."""
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)
    if next_review_date.tzinfo is None:
        next_review_date = next_review_date.replace(tzinfo=timezone.utc)
    if now < next_review_date:
        return 0
    return (now - next_review_date).days


def is_due(next_review_date: datetime, now: Optional[datetime] = None) -> bool:
    """La carte est-elle due maintenant ?"""
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)
    if next_review_date.tzinfo is None:
        next_review_date = next_review_date.replace(tzinfo=timezone.utc)
    return now >= next_review_date


def success_rate(total_attempts: int, correct_attempts: int) -> float:
    """Taux de reussite en pourcentage [0, 1]."""
    if total_attempts == 0:
        return 0.0
    return correct_attempts / total_attempts
