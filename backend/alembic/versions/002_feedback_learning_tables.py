"""add feedback learning tables

Revision ID: 002_feedback_learning_tables
Revises: 001_initial_schema
Create Date: 2026-05-20
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "002_feedback_learning_tables"
down_revision: Union[str, None] = "001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "voice_feedback",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("source_transaction_id", sa.Integer(), sa.ForeignKey("transactions.id"), nullable=True),
        sa.Column("session_id", sa.String(length=100), nullable=True),
        sa.Column("raw_transcript", sa.Text(), nullable=True),
        sa.Column("parsed_payload", sa.Text(), nullable=True),
        sa.Column("corrected_payload", sa.Text(), nullable=True),
        sa.Column("is_correct", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_voice_feedback_user_id", "voice_feedback", ["user_id"])
    op.create_index("ix_voice_feedback_source_transaction_id", "voice_feedback", ["source_transaction_id"])
    op.create_index("ix_voice_feedback_session_id", "voice_feedback", ["session_id"])

    op.create_table(
        "recommendation_feedback",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("insight_id", sa.Integer(), sa.ForeignKey("insights.id"), nullable=False),
        sa.Column("session_id", sa.String(length=100), nullable=False),
        sa.Column("recommendation_text", sa.Text(), nullable=False),
        sa.Column("accepted", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_recommendation_feedback_user_id", "recommendation_feedback", ["user_id"])
    op.create_index("ix_recommendation_feedback_insight_id", "recommendation_feedback", ["insight_id"])
    op.create_index("ix_recommendation_feedback_session_id", "recommendation_feedback", ["session_id"])


def downgrade() -> None:
    op.drop_index("ix_recommendation_feedback_session_id", table_name="recommendation_feedback")
    op.drop_index("ix_recommendation_feedback_insight_id", table_name="recommendation_feedback")
    op.drop_index("ix_recommendation_feedback_user_id", table_name="recommendation_feedback")
    op.drop_table("recommendation_feedback")

    op.drop_index("ix_voice_feedback_session_id", table_name="voice_feedback")
    op.drop_index("ix_voice_feedback_source_transaction_id", table_name="voice_feedback")
    op.drop_index("ix_voice_feedback_user_id", table_name="voice_feedback")
    op.drop_table("voice_feedback")
