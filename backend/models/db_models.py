"""models/db_models.py — Modeles ORM SQLAlchemy.

Tables :
    users             : comptes eleves (+ BKT maitrise JSON + theta IRT)
    questions         : banque de questions (+ parametres IRT)
    review_cards      : etat SRS (SM-2) par (user, question)
    responses         : historique brut des reponses (pour calibration IRT)
    simulations       : resultats de simulations completes (pour ML)
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _gen_uuid() -> str:
    return uuid.uuid4().hex


# ─── Users ───────────────────────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_gen_uuid)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    nom: Mapped[str] = mapped_column(String(80), nullable=False)
    prenom: Mapped[str] = mapped_column(String(80), nullable=False)
    niveau_scolaire: Mapped[str] = mapped_column(String(20), nullable=False)
    serie: Mapped[Optional[str]] = mapped_column(String(5), nullable=True)
    etablissement: Mapped[Optional[str]] = mapped_column(String(150), nullable=True)
    ville: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)

    date_inscription: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
    last_active_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    # Suivi BKT : {competence_id: pL}
    bkt_maitrise: Mapped[Dict[str, float]] = mapped_column(JSON, default=dict)

    # Compteurs
    total_sessions: Mapped[int] = mapped_column(Integer, default=0)
    total_questions_answered: Mapped[int] = mapped_column(Integer, default=0)

    # IRT global
    theta_irt: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)

    # Relations
    review_cards: Mapped[list["ReviewCard"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    responses: Mapped[list["Response"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


# ─── Questions ───────────────────────────────────────────────────────
class Question(Base):
    __tablename__ = "questions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    enonce: Mapped[str] = mapped_column(Text, nullable=False)
    reponse: Mapped[str] = mapped_column(Text, nullable=False)
    explication: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    matiere: Mapped[str] = mapped_column(String(80), index=True, nullable=False)
    chapitre: Mapped[str] = mapped_column(String(150), nullable=False)
    competence_id: Mapped[str] = mapped_column(String(80), index=True, nullable=False)
    examen: Mapped[str] = mapped_column(String(20), index=True, nullable=False, default="BEPC")
    serie: Mapped[Optional[str]] = mapped_column(String(5), nullable=True)
    annee: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    type: Mapped[str] = mapped_column(String(20), default="ouvert")
    choix: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    points: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # Parametres IRT
    irt_a: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    irt_b: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    irt_c: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    irt_calibrated: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)

    # Relations
    review_cards: Mapped[list["ReviewCard"]] = relationship(back_populates="question")
    responses: Mapped[list["Response"]] = relationship(back_populates="question")

    __table_args__ = (
        Index("ix_questions_matiere_examen", "matiere", "examen"),
    )


# ─── Review cards (SM-2) ─────────────────────────────────────────────
class ReviewCard(Base):
    __tablename__ = "review_cards"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_gen_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    question_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("questions.id", ondelete="CASCADE"), index=True
    )

    repetitions: Mapped[int] = mapped_column(Integer, default=0)
    easiness_factor: Mapped[float] = mapped_column(Float, default=2.5)
    interval_days: Mapped[int] = mapped_column(Integer, default=0)
    next_review_date: Mapped[datetime] = mapped_column(DateTime, default=_utcnow, index=True)
    last_review_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    total_attempts: Mapped[int] = mapped_column(Integer, default=0)
    correct_attempts: Mapped[int] = mapped_column(Integer, default=0)
    is_learning: Mapped[bool] = mapped_column(Boolean, default=True)

    user: Mapped["User"] = relationship(back_populates="review_cards")
    question: Mapped["Question"] = relationship(back_populates="review_cards")

    __table_args__ = (
        UniqueConstraint("user_id", "question_id", name="uq_user_question"),
    )


# ─── Responses (historique brut pour calibration IRT/ML) ─────────────
class Response(Base):
    __tablename__ = "responses"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_gen_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    question_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("questions.id", ondelete="CASCADE"), index=True
    )
    quality: Mapped[int] = mapped_column(Integer, nullable=False)
    correct: Mapped[bool] = mapped_column(Boolean, nullable=False)
    time_spent_sec: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow, index=True)

    user: Mapped["User"] = relationship(back_populates="responses")
    question: Mapped["Question"] = relationship(back_populates="responses")

    __table_args__ = (
        Index("ix_responses_user_created", "user_id", "created_at"),
        Index("ix_responses_question", "question_id"),
    )


# ─── Simulations (examens blancs) ────────────────────────────────────
class Simulation(Base):
    __tablename__ = "simulations"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_gen_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    examen: Mapped[str] = mapped_column(String(20), nullable=False)
    score: Mapped[float] = mapped_column(Float, nullable=False, comment="Score sur 20")
    duration_sec: Mapped[int] = mapped_column(Integer, default=0)
    nb_questions: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow, index=True)
