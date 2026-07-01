"""Initial schema : users, questions, review_cards, responses, simulations.

Revision ID: 001
Revises:
Create Date: 2026-07-01

Ce script reflete exactement ``backend/models/db_models.py`` (state au
2026-07-01). En production, lancer ``alembic upgrade head`` avant le
premier demarrage de l'app pour creer toutes les tables. ``init_db()``
dans ``database.py`` reste disponible comme garde-fou en dev mais ne doit
plus etre la source de verite en prod.

Tables :
    users         : comptes eleves (+ BKT maitrise JSON + theta IRT)
    questions     : banque de questions (+ parametres IRT 3PL)
    review_cards  : etat SRS (SM-2) par (user, question)
    responses     : historique brut des reponses (calibration IRT/ML)
    simulations   : resultats d'examens blancs (entrainement ML)
"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# Identifiants de revision Alembic
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ─── Table users ────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("email", sa.String(length=255), nullable=False, unique=True),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("nom", sa.String(length=80), nullable=False),
        sa.Column("prenom", sa.String(length=80), nullable=False),
        sa.Column("niveau_scolaire", sa.String(length=20), nullable=False),
        sa.Column("serie", sa.String(length=5), nullable=True),
        sa.Column("etablissement", sa.String(length=150), nullable=True),
        sa.Column("ville", sa.String(length=80), nullable=True),
        sa.Column(
            "date_inscription",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("last_active_date", sa.DateTime(), nullable=True),
        sa.Column("bkt_maitrise", sa.JSON(), nullable=True),
        sa.Column("total_sessions", sa.Integer(), nullable=True),
        sa.Column("total_questions_answered", sa.Integer(), nullable=True),
        sa.Column("theta_irt", sa.Float(), nullable=True),
        sa.Column(
            "is_admin",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )
    op.create_index("ix_users_email", "users", ["email"])

    # ─── Table questions ────────────────────────────────────────────
    op.create_table(
        "questions",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("enonce", sa.Text(), nullable=False),
        sa.Column("reponse", sa.Text(), nullable=False),
        sa.Column("explication", sa.Text(), nullable=True),
        sa.Column("matiere", sa.String(length=80), nullable=False),
        sa.Column("chapitre", sa.String(length=150), nullable=False),
        sa.Column("competence_id", sa.String(length=80), nullable=False),
        sa.Column("examen", sa.String(length=20), nullable=False),
        sa.Column("serie", sa.String(length=5), nullable=True),
        sa.Column("annee", sa.Integer(), nullable=True),
        sa.Column("type", sa.String(length=20), nullable=True),
        sa.Column("choix", sa.JSON(), nullable=True),
        sa.Column("points", sa.Integer(), nullable=True),
        sa.Column("irt_a", sa.Float(), nullable=True),
        sa.Column("irt_b", sa.Float(), nullable=True),
        sa.Column("irt_c", sa.Float(), nullable=True),
        sa.Column(
            "irt_calibrated",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_questions_matiere", "questions", ["matiere"])
    op.create_index("ix_questions_competence_id", "questions", ["competence_id"])
    op.create_index("ix_questions_examen", "questions", ["examen"])
    op.create_index(
        "ix_questions_matiere_examen", "questions", ["matiere", "examen"]
    )

    # ─── Table review_cards (etat SM-2 par user x question) ─────────
    op.create_table(
        "review_cards",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(length=36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "question_id",
            sa.String(length=64),
            sa.ForeignKey("questions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("repetitions", sa.Integer(), nullable=True),
        sa.Column("easiness_factor", sa.Float(), nullable=True),
        sa.Column("interval_days", sa.Integer(), nullable=True),
        sa.Column(
            "next_review_date",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("last_review_date", sa.DateTime(), nullable=True),
        sa.Column("total_attempts", sa.Integer(), nullable=True),
        sa.Column("correct_attempts", sa.Integer(), nullable=True),
        sa.Column(
            "is_learning",
            sa.Boolean(),
            server_default=sa.text("true"),
            nullable=False,
        ),
        sa.UniqueConstraint(
            "user_id", "question_id", name="uq_user_question"
        ),
    )
    op.create_index("ix_review_cards_user_id", "review_cards", ["user_id"])
    op.create_index(
        "ix_review_cards_question_id", "review_cards", ["question_id"]
    )
    op.create_index(
        "ix_review_cards_next_review_date",
        "review_cards",
        ["next_review_date"],
    )

    # ─── Table responses (historique brut pour calibration) ────────
    op.create_table(
        "responses",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(length=36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "question_id",
            sa.String(length=64),
            sa.ForeignKey("questions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("quality", sa.Integer(), nullable=False),
        sa.Column("correct", sa.Boolean(), nullable=False),
        sa.Column("time_spent_sec", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_responses_user_id", "responses", ["user_id"])
    op.create_index(
        "ix_responses_question_id", "responses", ["question_id"]
    )
    op.create_index("ix_responses_created_at", "responses", ["created_at"])
    op.create_index(
        "ix_responses_user_created", "responses", ["user_id", "created_at"]
    )

    # ─── Table simulations (examens blancs) ─────────────────────────
    op.create_table(
        "simulations",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(length=36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("examen", sa.String(length=20), nullable=False),
        sa.Column("score", sa.Float(), nullable=False, comment="Score sur 20"),
        sa.Column("duration_sec", sa.Integer(), nullable=True),
        sa.Column("nb_questions", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_simulations_user_id", "simulations", ["user_id"])
    op.create_index("ix_simulations_created_at", "simulations", ["created_at"])


def downgrade() -> None:
    # Ordre inverse des dependances FK
    op.drop_index("ix_simulations_created_at", table_name="simulations")
    op.drop_index("ix_simulations_user_id", table_name="simulations")
    op.drop_table("simulations")

    op.drop_index("ix_responses_user_created", table_name="responses")
    op.drop_index("ix_responses_created_at", table_name="responses")
    op.drop_index("ix_responses_question_id", table_name="responses")
    op.drop_index("ix_responses_user_id", table_name="responses")
    op.drop_table("responses")

    op.drop_index("ix_review_cards_next_review_date", table_name="review_cards")
    op.drop_index("ix_review_cards_question_id", table_name="review_cards")
    op.drop_index("ix_review_cards_user_id", table_name="review_cards")
    op.drop_table("review_cards")

    op.drop_index("ix_questions_matiere_examen", table_name="questions")
    op.drop_index("ix_questions_examen", table_name="questions")
    op.drop_index("ix_questions_competence_id", table_name="questions")
    op.drop_index("ix_questions_matiere", table_name="questions")
    op.drop_table("questions")

    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
