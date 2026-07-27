"""add series_tracking table

Revision ID: 832c211e1e6f
Revises: 174152931176
Create Date: 2026-07-22 14:05:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '832c211e1e6f'
down_revision: Union[str, Sequence[str], None] = '174152931176'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('series_tracking',
    sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('tmdb_id', sa.Integer(), nullable=False),
    sa.Column('status', sa.Enum('WATCHING', 'PLAN_TO_WATCH', 'COMPLETED', 'PAUSED', 'DROPPED', name='seriesstatus', native_enum=False, length=20), nullable=False),
    sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('user_id', 'tmdb_id', name='uq_series_tracking_user_show')
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('series_tracking')
