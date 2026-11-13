import uuid
from datetime import datetime, timezone
from typing import Generator
from sqlalchemy import create_engine, TypeDecorator, CHAR, JSON
from sqlalchemy.dialects.postgresql import UUID as PG_UUID, JSONB as PG_JSONB
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

# Cross-platform GUID type supporting PostgreSQL UUID and SQLite String(36)
class GUID(TypeDecorator):
    """Platform-independent GUID type.
    Uses PostgreSQL's UUID type, otherwise uses CHAR(36),
    storing as stringified hex values.
    """
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_UUID(as_uuid=True))
        else:
            return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        elif dialect.name == "postgresql":
            return str(value)
        else:
            if isinstance(value, uuid.UUID):
                return str(value)
            return str(uuid.UUID(str(value)))

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        if isinstance(value, uuid.UUID):
            return str(value)
        return str(value)


# Cross-platform JSON type supporting PostgreSQL JSONB and generic JSON for SQLite
class JSONType(TypeDecorator):
    """Platform-independent JSON type."""
    impl = JSON
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_JSONB)
        else:
            return dialect.type_descriptor(JSON)


def get_engine_args(url: str = settings.DATABASE_URL):
    if url.startswith("sqlite"):
        return {"connect_args": {"check_same_thread": False}}
    return {"pool_pre_ping": True}


def create_db_engine(url: str = settings.DATABASE_URL):
    """Creates a SQLAlchemy engine configured for the target database."""
    return create_engine(url, **get_engine_args(url))


def create_session_factory(db_engine):
    """Creates a sessionmaker bound to the given engine."""
    return sessionmaker(autocommit=False, autoflush=False, bind=db_engine)


engine = create_db_engine(settings.DATABASE_URL)
SessionLocal = create_session_factory(engine)

Base = declarative_base()


def get_utc_now() -> datetime:
    """Returns the current UTC timestamp."""
    return datetime.now(timezone.utc)


def get_db() -> Generator[Session, None, None]:
    """Dependency to retrieve database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
