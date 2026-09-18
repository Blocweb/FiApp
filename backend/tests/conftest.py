import datetime
import os
import uuid
import pytest
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker

from src.app.database.connection import Base
from src.app.core.config import get_settings


@pytest.fixture
def sqlite_session():
    """Sesión SQLite en memoria para tests unitarios rápidos y aislados.

    Registra funciones compatibles como now() y gen_random_uuid(), y activa
    las foreign keys (PRAGMA foreign_keys=ON) para validar constraints.
    """
    engine = create_engine("sqlite:///:memory:", echo=False)

    @event.listens_for(engine, "connect")
    def register_sqlite_functions(dbapi_connection, connection_record):
        dbapi_connection.execute("PRAGMA foreign_keys=ON")
        dbapi_connection.create_function(
            "now", 0, lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
        )
        dbapi_connection.create_function(
            "gen_random_uuid", 0, lambda: str(uuid.uuid4())
        )

    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)
    session = session_factory()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def postgres_session():
    """Sesión PostgreSQL para tests de integración reales.

    Utiliza DATABASE_URL (sync) si está disponible; de lo contrario salta el test.
    Crea las tablas definidas en los modelos antes de ejecutar los tests.
    """
    settings = get_settings()
    raw_url = getattr(settings, "database_url", os.getenv("DATABASE_URL", ""))

    if not raw_url:
        pytest.skip("DATABASE_URL no configurada para tests de integración PostgreSQL")

    # Si la URL usa asyncpg, convertir a postgresql estándar para engine síncrono si existe driver,
    # o usar asyncpg para engine asíncrono
    sync_url = raw_url.replace("postgresql+asyncpg://", "postgresql://")

    try:
        engine = create_engine(sync_url, echo=False)
        with engine.connect():
            pass
        Base.metadata.create_all(engine)
    except Exception as exc:
        pytest.skip(f"No se pudo conectar a PostgreSQL para integración: {exc}")

    session_factory = sessionmaker(bind=engine)
    session = session_factory()
    try:
        yield session
    finally:
        session.rollback()
        session.close()