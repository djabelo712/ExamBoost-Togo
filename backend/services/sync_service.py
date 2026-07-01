"""services/sync_service.py — Logique de merge cote serveur (sync cloud).

Applique chaque action recue depuis l'app mobile a l'etat serveur :
    - reviewAnswer   -> apply_sm2() + update_bkt() + insert Response
    - bktUpdate      -> update_bkt() sur User.bkt_maitrise
    - simulationResult -> insert Simulation
    - userProgress   -> max() sur compteurs monotones (User.total_sessions,
                        User.total_questions_answered)
    - badgeUnlock    -> TODO quand le modele Badge existe cote serveur

Resolution de conflits (CRDT-like) :
    - ReviewCard : Last-Write-Wins sur last_review_date
    - BKT pL     : LWW sur timestamp ; egalite -> conservateur (min)
    - Badges     : Union (OR) — un badge debloque ne peut pas etre re-verrouille
    - Compteurs  : max(local, remote)

Idempotence :
    Chaque action est identifiee par ``action_id`` (UUID v4 cote client).
    On maintient une table ``sync_applied_actions`` (creee au demarrage)
    pour garantir qu'une action re-envoyee (retry) n'est pas appliquee
    deux fois. Cette table est definie ici (Table SQLAlchemy imperative)
    pour ne pas modifier ``models/db_models.py``.

Miroir cote Flutter : ``lib/services/conflict_resolver.dart``.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, Optional

from sqlalchemy import Column, DateTime, Index, String, Table, Text, select
from sqlalchemy.orm import Session

from config import settings
from database import Base, engine
from models.db_models import Question, Response, ReviewCard, Simulation, User
from services import bkt_service, srs_service


# ─── Table d'idempotence (creee au demarrage si absente) ────────────
# On definit cette table imperativement (pas de modele declaratif) pour
# eviter de toucher a ``models/db_models.py`` (reserve a l'agent wiring).
sync_applied_actions = Table(
    "sync_applied_actions",
    Base.metadata,
    Column("action_id", String(64), primary_key=True),
    Column("user_id", String(36), index=True, nullable=False),
    Column("action_type", String(40), nullable=False),
    Column("applied_at", DateTime, default=lambda: datetime.now(timezone.utc)),
    Column("result_json", Text, nullable=True),
    Index("ix_sync_applied_user", "user_id"),
    Index("ix_sync_applied_type", "action_type"),
)


def ensure_sync_tables() -> None:
    """Cree les tables specifiques au sync si elles n'existent pas.

    A appeler au demarrage (depuis ``main.py`` lifespan ou ce module).
    """
    sync_applied_actions.create(bind=engine, checkfirst=True)


# Flag pour l'init paresseux (au cas ou ensure_sync_tables() n'est pas
# appele explicitement au demarrage — garanti par la premiere requete).
_tables_ready = False


def _ensure_tables_lazy() -> None:
    """Init paresseux thread-safe-ish (suffisant pour SQLite en dev)."""
    global _tables_ready
    if _tables_ready:
        return
    ensure_sync_tables()
    _tables_ready = True


# ─── Schemas (Pydantic) ─────────────────────────────────────────────
# Definis ici plutot que dans ``models/schemas.py`` pour ne pas modifier
# ce fichier partage par les autres agents. Le router ``sync.py`` les importe.

from pydantic import BaseModel, Field


class SyncActionRequest(BaseModel):
    """Payload d'une action a synchroniser."""

    action_id: str = Field(..., description="UUID v4 cote client (idempotency)")
    type: str = Field(
        ...,
        description="reviewAnswer | bktUpdate | simulationResult | userProgress | badgeUnlock",
    )
    payload: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime
    user_id: Optional[str] = Field(
        None, description="Optionnel : surcharge si absent du JWT (pour debug)"
    )
    retry_count: int = Field(0, ge=0)


class SyncBatchRequest(BaseModel):
    """Batch d'actions (max 50)."""

    actions: list[SyncActionRequest] = Field(..., max_length=50)


class SyncActionResponse(BaseModel):
    """Reponse apres traitement d'une action."""

    action_id: str
    applied: bool  # True si nouvellement applique, False si deja vu (idempotent)
    result: Dict[str, Any] = Field(default_factory=dict)
    conflict: Optional[str] = Field(
        None, description="localKept | remoteAdopted | merged | noConflict"
    )
    error: Optional[str] = None


class SyncBatchResponse(BaseModel):
    """Reponse apres traitement d'un batch."""

    total: int
    applied: int
    skipped: int  # idempotents
    failed: int
    results: list[SyncActionResponse]


class SyncStatusResponse(BaseModel):
    """Statut de sync pour un utilisateur."""

    user_id: str
    last_action_applied_at: Optional[datetime] = None
    total_actions_applied: int = 0
    server_time: datetime


class PullUpdatesResponse(BaseModel):
    """Mises a jour disponibles cote serveur depuis ``since``."""

    since: datetime
    server_time: datetime
    review_cards: list[Dict[str, Any]] = Field(default_factory=list)
    bkt_maitrise: Dict[str, float] = Field(default_factory=dict)
    user_counters: Optional[Dict[str, Any]] = None


# ─── Helpers ────────────────────────────────────────────────────────


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _ensure_aware(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def _is_applied(db: Session, action_id: str) -> Optional[Dict[str, Any]]:
    """Retourne le result_json si l'action a deja ete appliquee, sinon None."""
    row = db.execute(
        select(sync_applied_actions.c.result_json).where(
            sync_applied_actions.c.action_id == action_id
        )
    ).first()
    if row is None:
        return None
    import json

    raw = row[0]
    if raw is None:
        return {}
    try:
        return json.loads(raw)
    except Exception:
        return {"raw": raw}


def _mark_applied(
    db: Session,
    action_id: str,
    user_id: str,
    action_type: str,
    result: Dict[str, Any],
) -> None:
    import json

    db.execute(
        sync_applied_actions.insert().values(
            action_id=action_id,
            user_id=user_id,
            action_type=action_type,
            applied_at=_utcnow(),
            result_json=json.dumps(result, default=str),
        )
    )


# ─── ConflictResolver (miroir cote Flutter) ─────────────────────────


class ConflictResolver:
    """Resolution de conflits cote serveur (CRDT-like).

    Miroir de ``lib/services/conflict_resolver.dart``.
    """

    @staticmethod
    def resolve_review_card(
        local_card: ReviewCard, remote: Dict[str, Any]
    ) -> tuple[ReviewCard, str]:
        """Resout un conflit sur une ReviewCard. Retourne (card, source).

        source est parmi : 'localKept', 'remoteAdopted', 'noConflict'.
        """
        local_last = (
            _ensure_aware(local_card.last_review_date)
            if local_card.last_review_date
            else None
        )
        remote_last_raw = remote.get("last_review_date")

        if remote_last_raw is None:
            return local_card, "localKept"

        remote_last = _ensure_aware(
            remote_last_raw
            if isinstance(remote_last_raw, datetime)
            else datetime.fromisoformat(str(remote_last_raw))
        )

        if local_last is None:
            _apply_remote_to_card(local_card, remote)
            return local_card, "remoteAdopted"

        if remote_last == local_last:
            return local_card, "noConflict"

        if remote_last > local_last:
            _apply_remote_to_card(local_card, remote)
            return local_card, "remoteAdopted"

        return local_card, "localKept"

    @staticmethod
    def resolve_bkt(
        local_pl: float,
        remote_pl: float,
        local_updated_at: Optional[datetime],
        remote_updated_at: Optional[datetime],
    ) -> tuple[float, str]:
        """Resout un conflit sur P(L) BKT. Retourne (pL, source)."""
        lp = max(0.0, min(1.0, float(local_pl)))
        rp = max(0.0, min(1.0, float(remote_pl)))

        if local_updated_at is None and remote_updated_at is None:
            # Conservateur : min
            return (lp, "localKept") if lp <= rp else (rp, "remoteAdopted")
        if remote_updated_at is None:
            return lp, "localKept"
        if local_updated_at is None:
            return rp, "remoteAdopted"

        if local_updated_at == remote_updated_at:
            # Egalite : conservateur (min)
            resolved = min(lp, rp)
            return resolved, "merged"

        if local_updated_at > remote_updated_at:
            return lp, "localKept"
        return rp, "remoteAdopted"

    @staticmethod
    def resolve_counter(local: int, remote: int) -> tuple[int, str]:
        if local == remote:
            return local, "noConflict"
        return (local, "localKept") if local > remote else (remote, "remoteAdopted")

    @staticmethod
    def resolve_badge(local_unlocked: bool, remote_unlocked: bool) -> tuple[bool, str]:
        if local_unlocked == remote_unlocked:
            return local_unlocked, "noConflict"
        return True, "merged"


def _apply_remote_to_card(card: ReviewCard, remote: Dict[str, Any]) -> None:
    """Applique les champs SM-2 distants a l'objet card local."""
    card.repetitions = int(remote.get("repetitions", card.repetitions))
    card.easiness_factor = float(
        remote.get("easiness_factor", card.easiness_factor)
    )
    card.interval_days = int(remote.get("interval_days", card.interval_days))
    nrd = remote.get("next_review_date")
    if nrd is not None:
        card.next_review_date = (
            nrd if isinstance(nrd, datetime) else datetime.fromisoformat(str(nrd))
        )
    lrd = remote.get("last_review_date")
    if lrd is not None:
        card.last_review_date = (
            lrd if isinstance(lrd, datetime) else datetime.fromisoformat(str(lrd))
        )
    card.total_attempts = int(remote.get("total_attempts", card.total_attempts))
    card.correct_attempts = int(
        remote.get("correct_attempts", card.correct_attempts)
    )
    card.is_learning = bool(remote.get("is_learning", card.is_learning))


# ─── Application des actions ────────────────────────────────────────


class ApplyResult:
    """Resultat interne de l'application d'une action."""

    def __init__(
        self,
        applied: bool,
        result: Optional[Dict[str, Any]] = None,
        conflict: Optional[str] = None,
        error: Optional[str] = None,
    ):
        self.applied = applied
        self.result = result or {}
        self.conflict = conflict
        self.error = error


def apply_action(
    db: Session,
    user: User,
    action: SyncActionRequest,
) -> ApplyResult:
    """Applique une action a l'etat serveur (idempotente via action_id).

    Returns
    -------
    ApplyResult
        - applied=True si l'action a ete nouvellement appliquee
        - applied=False si deja vue (idempotent skip) ou en erreur
    """
    # Init paresseux des tables d'idempotence (au cas ou ensure_sync_tables()
    # n'a pas ete appele au demarrage dans main.py lifespan).
    _ensure_tables_lazy()

    # 1. Idempotence : deja appliquee ?
    previous = _is_applied(db, action.action_id)
    if previous is not None:
        return ApplyResult(
            applied=False,
            result=previous,
            conflict="noConflict",
        )

    # 2. Dispatch selon le type
    try:
        if action.type == "reviewAnswer":
            res = _apply_review_answer(db, user, action)
        elif action.type == "bktUpdate":
            res = _apply_bkt_update(db, user, action)
        elif action.type == "simulationResult":
            res = _apply_simulation_result(db, user, action)
        elif action.type == "userProgress":
            res = _apply_user_progress(db, user, action)
        elif action.type == "badgeUnlock":
            res = _apply_badge_unlock(db, user, action)
        else:
            return ApplyResult(
                applied=False,
                error=f"Type d'action inconnu: {action.type}",
            )
    except Exception as e:
        return ApplyResult(applied=False, error=str(e))

    # 3. Marque comme appliquee (uniquement si succes)
    if res.error is None:
        _mark_applied(
            db,
            action.action_id,
            user.id,
            action.type,
            {"result": res.result, "conflict": res.conflict},
        )

    return res


def _apply_review_answer(
    db: Session, user: User, action: SyncActionRequest
) -> ApplyResult:
    """Applique une reponse SRS (SM-2 + BKT + insertion Response).

    Payload attendu :
        {
            'question_id': str,
            'quality': int (0-5),
            'time_spent_sec': int,
            'correct': bool (optionnel, derive de quality sinon),
            'competence_id': str (optionnel, sinon lu depuis Question)
        }
    """
    payload = action.payload
    question_id = payload.get("question_id")
    quality = int(payload.get("quality", 0))
    if not 0 <= quality <= 5:
        return ApplyResult(applied=False, error=f"quality invalide: {quality}")

    correct = payload.get("correct")
    if correct is None:
        correct = quality >= 3

    time_spent = int(payload.get("time_spent_sec", 0))

    # Recupere la question
    question = db.get(Question, question_id) if question_id else None
    if question is None:
        return ApplyResult(
            applied=False, error=f"Question {question_id} introuvable"
        )

    competence_id = payload.get("competence_id") or question.competence_id

    # Recupere ou cree la carte SM-2
    card = db.execute(
        select(ReviewCard).where(
            ReviewCard.user_id == user.id,
            ReviewCard.question_id == question_id,
        )
    ).scalar_one_or_none()
    if card is None:
        card = ReviewCard(
            user_id=user.id,
            question_id=question_id,
            next_review_date=_utcnow(),
        )
        db.add(card)
        db.flush()

    # Resolution de conflit CRDT avant d'appliquer la nouvelle reponse
    # (utile si l'app a un etat plus recent que le serveur — rare en LWW pur)
    # Ici on applique simplement la nouvelle action : le serveur est autorite.
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
    action_time = _ensure_aware(action.created_at)
    sm2_result = srs_service.apply_sm2(current_state, quality, now=action_time)

    card.repetitions = sm2_result.repetitions
    card.easiness_factor = sm2_result.easiness_factor
    card.interval_days = sm2_result.interval_days
    card.next_review_date = sm2_result.next_review_date
    card.last_review_date = sm2_result.last_review_date
    card.total_attempts = sm2_result.total_attempts
    card.correct_attempts = sm2_result.correct_attempts
    card.is_learning = sm2_result.is_learning

    # BKT
    pL_before = float(user.bkt_maitrise.get(competence_id, bkt_service.init_pL()))
    bkt_result = bkt_service.update_bkt(
        pL=pL_before,
        correct=correct,
        p_learn=settings.BKT_P_LEARN,
        p_slip=settings.BKT_P_SLIP,
        p_guess=settings.BKT_P_GUESS,
    )
    user.bkt_maitrise[competence_id] = bkt_result.pL_after
    from sqlalchemy.orm.attributes import flag_modified

    flag_modified(user, "bkt_maitrise")

    # Compteurs (max monotone)
    new_sessions, src_s = ConflictResolver.resolve_counter(
        user.total_sessions, user.total_sessions + 1
    )
    new_questions, src_q = ConflictResolver.resolve_counter(
        user.total_questions_answered, user.total_questions_answered + 1
    )
    user.total_sessions = new_sessions
    user.total_questions_answered = new_questions
    user.last_active_date = action_time

    # Insertion historique brut
    db.add(
        Response(
            user_id=user.id,
            question_id=question_id,
            quality=quality,
            correct=correct,
            time_spent_sec=time_spent,
            created_at=action_time,
        )
    )

    return ApplyResult(
        applied=True,
        result={
            "question_id": question_id,
            "quality": quality,
            "correct": correct,
            "interval_days": sm2_result.interval_days,
            "easiness_factor": round(sm2_result.easiness_factor, 4),
            "next_review_date": sm2_result.next_review_date.isoformat(),
            "bkt_update": {
                "competence_id": competence_id,
                "pL_before": round(pL_before, 4),
                "pL_after": round(bkt_result.pL_after, 4),
                "mastered": bkt_result.mastered,
            },
        },
        conflict=src_s,
    )


def _apply_bkt_update(
    db: Session, user: User, action: SyncActionRequest
) -> ApplyResult:
    """Maj BKT isolee (pas liee a une question SRS).

    Payload attendu :
        {
            'competence_id': str,
            'correct': bool,
            'pL_before': float (optionnel, pour verification)
        }
    """
    payload = action.payload
    competence_id = payload.get("competence_id")
    if not competence_id:
        return ApplyResult(applied=False, error="competence_id manquant")

    correct = bool(payload.get("correct", False))
    pL_before = float(user.bkt_maitrise.get(competence_id, bkt_service.init_pL()))

    bkt_result = bkt_service.update_bkt(
        pL=pL_before,
        correct=correct,
        p_learn=settings.BKT_P_LEARN,
        p_slip=settings.BKT_P_SLIP,
        p_guess=settings.BKT_P_GUESS,
    )
    user.bkt_maitrise[competence_id] = bkt_result.pL_after
    from sqlalchemy.orm.attributes import flag_modified

    flag_modified(user, "bkt_maitrise")

    return ApplyResult(
        applied=True,
        result={
            "competence_id": competence_id,
            "pL_before": round(pL_before, 4),
            "pL_after": round(bkt_result.pL_after, 4),
            "mastered": bkt_result.mastered,
        },
    )


def _apply_simulation_result(
    db: Session, user: User, action: SyncActionRequest
) -> ApplyResult:
    """Insere un resultat de simulation.

    Payload attendu :
        {
            'examen': str (BEPC, BAC1, BAC2, Probatoire),
            'serie': str | null,
            'score': float (sur 20),
            'duration_sec': int,
            'nb_questions': int
        }
    """
    payload = action.payload
    examen = payload.get("examen")
    if not examen:
        return ApplyResult(applied=False, error="examen manquant")

    score = float(payload.get("score", 0.0))
    duration = int(payload.get("duration_sec", 0))
    nb_q = int(payload.get("nb_questions", 0))

    sim = Simulation(
        user_id=user.id,
        examen=examen,
        score=score,
        duration_sec=duration,
        nb_questions=nb_q,
        created_at=_ensure_aware(action.created_at),
    )
    db.add(sim)

    return ApplyResult(
        applied=True,
        result={
            "simulation_id": "pending",  # disponible apres commit
            "examen": examen,
            "score": score,
        },
    )


def _apply_user_progress(
    db: Session, user: User, action: SyncActionRequest
) -> ApplyResult:
    """Met a jour les compteurs utilisateur (max monotone).

    Payload attendu :
        {
            'questions_answered': int,
            'sessions_count': int,
            'theta_irt': float (optionnel)
        }
    """
    payload = action.payload
    new_q = int(payload.get("questions_answered", user.total_questions_answered))
    new_s = int(payload.get("sessions_count", user.total_sessions))

    final_q, src_q = ConflictResolver.resolve_counter(
        user.total_questions_answered, new_q
    )
    final_s, src_s = ConflictResolver.resolve_counter(
        user.total_sessions, new_s
    )

    user.total_questions_answered = final_q
    user.total_sessions = final_s
    user.last_active_date = _ensure_aware(action.created_at)

    theta = payload.get("theta_irt")
    if theta is not None:
        user.theta_irt = float(theta)

    return ApplyResult(
        applied=True,
        result={
            "total_questions_answered": final_q,
            "total_sessions": final_s,
            "conflict_questions": src_q,
            "conflict_sessions": src_s,
        },
    )


def _apply_badge_unlock(
    db: Session, user: User, action: SyncActionRequest
) -> ApplyResult:
    """Marque un badge comme debloque (idempotent par nature).

    TODO : table ``user_badges`` pas encore definie cote serveur. Pour
    l'instant, on se contente de loguer et de marquer l'action comme
    appliquee. Le wiring complet sera fait quand le modele Badge cote
    backend existera.

    Payload attendu :
        {
            'badge_id': str,
            'unlocked_at': str (ISO8601)
        }
    """
    payload = action.payload
    badge_id = payload.get("badge_id")
    if not badge_id:
        return ApplyResult(applied=False, error="badge_id manquant")

    # Placeholder : on ne fait rien tant que la table user_badges
    # n'existe pas. L'action est quand meme marquee appliquee pour
    # ne pas bloquer la file d'attente cote client.
    return ApplyResult(
        applied=True,
        result={
            "badge_id": badge_id,
            "note": "Badge unlock enregistre (table user_badges a venir)",
        },
    )


# ─── Pull updates ───────────────────────────────────────────────────


def pull_updates(
    db: Session,
    user: User,
    since: datetime,
) -> PullUpdatesResponse:
    """Recupere les mises a jour serveur depuis ``since``.

    Utile pour :
        - Recuperer les ReviewCard maj par un autre device
        - Recuperer les mises a jour BKT
        - Recuperer les compteurs utilisateur
        - (Future) recuperer les nouveaux parametres IRT calibres
    """
    since_aware = _ensure_aware(since)

    # Review cards modifiees depuis `since`
    cards = db.execute(
        select(ReviewCard).where(
            ReviewCard.user_id == user.id,
            ReviewCard.last_review_date >= since_aware,
        )
    ).scalars().all()

    review_cards_payload = [
        {
            "question_id": c.question_id,
            "repetitions": c.repetitions,
            "easiness_factor": round(c.easiness_factor, 4),
            "interval_days": c.interval_days,
            "next_review_date": _ensure_aware(c.next_review_date).isoformat(),
            "last_review_date": (
                _ensure_aware(c.last_review_date).isoformat()
                if c.last_review_date
                else None
            ),
            "total_attempts": c.total_attempts,
            "correct_attempts": c.correct_attempts,
            "is_learning": c.is_learning,
        }
        for c in cards
    ]

    return PullUpdatesResponse(
        since=since_aware,
        server_time=_utcnow(),
        review_cards=review_cards_payload,
        bkt_maitrise=user.bkt_maitrise or {},
        user_counters={
            "total_sessions": user.total_sessions,
            "total_questions_answered": user.total_questions_answered,
            "theta_irt": user.theta_irt,
        },
    )


# ─── Statut ─────────────────────────────────────────────────────────


def get_sync_status(db: Session, user: User) -> SyncStatusResponse:
    """Retourne le statut de sync pour l'utilisateur."""
    _ensure_tables_lazy()
    row = db.execute(
        select(sync_applied_actions.c.applied_at)
        .where(sync_applied_actions.c.user_id == user.id)
        .order_by(sync_applied_actions.c.applied_at.desc())
        .limit(1)
    ).first()

    total = db.execute(
        select(sync_applied_actions.c.action_id)
        .where(sync_applied_actions.c.user_id == user.id)
    ).all()

    return SyncStatusResponse(
        user_id=user.id,
        last_action_applied_at=_ensure_aware(row[0]) if row else None,
        total_actions_applied=len(total),
        server_time=_utcnow(),
    )
