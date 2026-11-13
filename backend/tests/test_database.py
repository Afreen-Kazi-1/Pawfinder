from sqlalchemy import text
from sqlalchemy.orm import Session
from app.core.database import create_db_engine, create_session_factory, get_db


def test_database_connection(db_session: Session):
    """Test raw database connectivity execution."""
    result = db_session.execute(text("SELECT 1")).scalar()
    assert result == 1


def test_database_session_lifecycle(db_session: Session):
    """Test session commit, rollback, and query lifecycle."""
    # Test session is active
    assert db_session.is_active

    # Execute a statement and commit
    db_session.execute(text("SELECT 1"))
    db_session.commit()

    # Execute and rollback
    db_session.execute(text("SELECT 1"))
    db_session.rollback()


def test_get_db_generator():
    """Test get_db dependency generator yields an active session and closes it."""
    gen = get_db()
    session = next(gen)
    assert isinstance(session, Session)
    assert session.is_active
    try:
        next(gen)
    except StopIteration:
        pass

