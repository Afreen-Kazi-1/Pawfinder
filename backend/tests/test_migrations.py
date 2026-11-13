import os
import tempfile
import pytest
from alembic.config import Config
from alembic import command


def test_alembic_migration_lifecycle():
    """Test programmatic Alembic upgrade to head and downgrade to base on an isolated temporary database."""
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as tmp_db:
        tmp_db_path = tmp_db.name

    try:
        # Construct path to backend/alembic.ini
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        ini_path = os.path.join(base_dir, "alembic.ini")

        alembic_cfg = Config(ini_path)
        # Override sqlalchemy.url with the temporary database file
        alembic_cfg.set_main_option("sqlalchemy.url", f"sqlite:///{tmp_db_path}")

        # Run migration upgrade to head
        command.upgrade(alembic_cfg, "head")

        # Run migration downgrade to base
        command.downgrade(alembic_cfg, "base")

        # Re-upgrade to head
        command.upgrade(alembic_cfg, "head")

    finally:
        if os.path.exists(tmp_db_path):
            try:
                os.remove(tmp_db_path)
            except Exception:
                pass

