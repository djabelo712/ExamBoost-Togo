"""Add tutor tables : tutor_conversations + tutor_messages.

Revision ID: 002
Revises: 001
Create Date: 2026-07-02

Ces tables persistent les conversations avec le tuteur IA (Agent W).
Elles ne sont pas encore refletees dans ``models/db_models.py`` (le
router ``routers/tutor.py`` utilise actuellement un rate limiter memoire
et ne persiste pas). L'agent de wiring devra ajouter les ORM
``TutorConversation`` et ``TutorMessage`` correspondants.

Schema :
    tutor_conversations : une conversation par utilisateur (titre optionnel)
    tutor_messages      : messages user/assistant attaches a une conversation
"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# Identifiants de revision Alembic
revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ─── Table tutor_conversations ──────────────────────────────────
    op.create_table(
        "tutor_conversations",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(length=36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("title", sa.String(length=255), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index(
        "ix_tutor_conversations_user_id",
        "tutor_conversations",
        ["user_id"],
    )
    op.create_index(
        "ix_tutor_conversations_updated_at",
        "tutor_conversations",
        ["updated_at"],
    )

    # ─── Table tutor_messages ───────────────────────────────────────
    op.create_table(
        "tutor_messages",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column(
            "conversation_id",
            sa.String(length=36),
            sa.ForeignKey("tutor_conversations.id", ondelete="CASCADE"),
            nullable=False,
        ),
        # role : 'user' | 'assistant' (string courte, contrainte applicative)
        sa.Column("role", sa.String(length=20), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index(
        "ix_tutor_messages_conversation_id",
        "tutor_messages",
        ["conversation_id"],
    )
    op.create_index(
        "ix_tutor_messages_created_at", "tutor_messages", ["created_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_tutor_messages_created_at", table_name="tutor_messages")
    op.drop_index(
        "ix_tutor_messages_conversation_id", table_name="tutor_messages"
    )
    op.drop_table("tutor_messages")

    op.drop_index(
        "ix_tutor_conversations_updated_at", table_name="tutor_conversations"
    )
    op.drop_index(
        "ix_tutor_conversations_user_id", table_name="tutor_conversations"
    )
    op.drop_table("tutor_conversations")
