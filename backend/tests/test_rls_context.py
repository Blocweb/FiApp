"""Tests obligatorios del contexto RLS transaccional — Fase 3.3.2.

Los tests 1 a 8 de la especificación se ejecutan sobre PostgreSQL real, porque
``app.tenant_id`` y ``app.user_id`` se implementan con ``set_config``, que
PostgreSQL interpreta y SQLite no. Cuando ``DATABASE_URL`` no apunta a
PostgreSQL, los tests de integración se omiten explícitamente.

Además del camino PostgreSQL, se valida aquí la parte dependiente de la sesión:
que ``set_rls_context`` rechace cualquier objeto que no sea un ``TenantContext``
validado (Test 8), y que el contexto Python quede eliminado con
``clear_rls_context``.
"""

from __future__ import annotations

import uuid

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from src.app.core.rls_context import (
    RLS_TENANT_SETTING,
    RLS_USER_SETTING,
    clear_rls_context,
    set_rls_context,
)
from src.app.core.tenant_context import TenantContext, UsuarioAutenticado
from src.app.database.connection import get_settings
from src.app.models.profile import Profile
from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario


def _engine_url() -> str:
    settings = get_settings()
    return getattr(settings, "database_url", "") or ""


@pytest.fixture
def pg_url() -> str:
    url = _engine_url()
    if "postgresql" not in url:
        pytest.skip("DATABASE_URL no apunta a PostgreSQL: se omiten tests RLS de integración")
    return url


@pytest.fixture
async def pg_engine(pg_url: str):
    engine = create_async_engine(pg_url, echo=False)
    try:
        yield engine
    finally:
        await engine.dispose()


@pytest.fixture
async def pg_session_factory(pg_engine):
    return async_sessionmaker(bind=pg_engine, expire_on_commit=False)


def _contexto(tenant_id: uuid.UUID, user_id: uuid.UUID) -> TenantContext:
    """Construye un TenantContext; en producción siempre lo genera FastAPI."""
    profile = Profile(id=user_id, email=f"user_{user_id.hex[:6]}@fiapp.test")
    tenant = Tenant(id=tenant_id, nombre_comercial="Negocio", estado="activo")
    membresia = TenantUsuario(
        id=uuid.uuid4(),
        tenant_id=tenant_id,
        profile_id=user_id,
        rol="propietario",
        activo=True,
    )
    return TenantContext(
        usuario=UsuarioAutenticado(id=user_id, email=profile.email),
        profile=profile,
        tenant=tenant,
        membresia=membresia,
        rol="propietario",
        resuelto_en=__import__("datetime").datetime.now(__import__("datetime").timezone.utc),
    )


async def _leer_setting(session, nombre: str) -> str | None:
    """Devuelve el valor de un setting, tratando cadena vacia como ausente.

    Tras el fin de una transacción ``SET LOCAL``/``set_config(..., true)``
    desaparece y ``current_setting(nombre, true)`` devuelve cadena vacía.
    """
    result = await session.execute(
        text("SELECT current_setting(:nombre, true)"),
        {"nombre": nombre},
    )
    valor = result.scalar_one_or_none()
    return valor or None


# ---------------------------------------------------------------------------
# Test 8 — La función exige un TenantContext validado
# ---------------------------------------------------------------------------

@pytest.mark.anyio
async def test_set_rls_context_rechaza_valor_no_tenant_context(async_sqlite_session):
    """No debe aceptar UUIDs crudos ni strings provenientes del request."""
    with pytest.raises(TypeError):
        await set_rls_context(async_sqlite_session, str(uuid.uuid4()))
    with pytest.raises(TypeError):
        await set_rls_context(async_sqlite_session, uuid.uuid4())
    with pytest.raises(TypeError):
        await set_rls_context(async_sqlite_session, None)


@pytest.mark.anyio
async def test_clear_rls_context_elimina_referencia(async_sqlite_session):
    """El estado Python del contexto se elimina al terminar el request."""
    contexto = _contexto(uuid.uuid4(), uuid.uuid4())
    async_sqlite_session.info["fiapp_rls_context"] = contexto

    clear_rls_context(async_sqlite_session)

    assert "fiapp_rls_context" not in async_sqlite_session.info


# ---------------------------------------------------------------------------
# Tests 1-7 — PostgreSQL real: SET LOCAL, commit, rollback, pool, excepción
# ---------------------------------------------------------------------------

@pytest.mark.integration
@pytest.mark.anyio
async def test_1_tenant_establecido(pg_session_factory):
    """Dentro de la transacción, current_setting devuelve el tenant."""
    tenant_id, user_id = uuid.uuid4(), uuid.uuid4()
    async with pg_session_factory() as session:
        await set_rls_context(session, _contexto(tenant_id, user_id))
        assert await _leer_setting(session, RLS_TENANT_SETTING) == str(tenant_id)
        await session.rollback()


@pytest.mark.integration
@pytest.mark.anyio
async def test_2_user_establecido(pg_session_factory):
    """Dentro de la transacción, current_setting devuelve el usuario."""
    tenant_id, user_id = uuid.uuid4(), uuid.uuid4()
    async with pg_session_factory() as session:
        await set_rls_context(session, _contexto(tenant_id, user_id))
        assert await _leer_setting(session, RLS_USER_SETTING) == str(user_id)
        await session.rollback()


@pytest.mark.integration
@pytest.mark.anyio
async def test_3_commit_no_hereda_contexto(pg_session_factory):
    """Tras COMMIT, una transacción nueva no conserva el tenant anterior."""
    tenant_id, user_id = uuid.uuid4(), uuid.uuid4()
    async with pg_session_factory() as session:
        await set_rls_context(session, _contexto(tenant_id, user_id))
        await session.commit()

        clear_rls_context(session)
        await session.execute(text("SELECT 1"))
        assert await _leer_setting(session, RLS_TENANT_SETTING) is None
        await session.rollback()


@pytest.mark.integration
@pytest.mark.anyio
async def test_4_rollback_no_hereda_contexto(pg_session_factory):
    """Tras ROLLBACK, una transacción nueva no conserva el tenant anterior."""
    tenant_id, user_id = uuid.uuid4(), uuid.uuid4()
    async with pg_session_factory() as session:
        await set_rls_context(session, _contexto(tenant_id, user_id))
        await session.rollback()

        clear_rls_context(session)
        await session.execute(text("SELECT 1"))
        assert await _leer_setting(session, RLS_TENANT_SETTING) is None
        await session.rollback()


@pytest.mark.integration
@pytest.mark.anyio
async def test_5_pool_no_mezcla_tenants(pg_session_factory):
    """A→A, B→B, A→A, B→B sobre conexiones potencialmente reutilizadas."""
    tenant_a, tenant_b = uuid.uuid4(), uuid.uuid4()
    user = uuid.uuid4()

    for esperado in (tenant_a, tenant_b, tenant_a, tenant_b):
        async with pg_session_factory() as session:
            await set_rls_context(session, _contexto(esperado, user))
            assert await _leer_setting(session, RLS_TENANT_SETTING) == str(esperado)

        # Nueva sesión sin contexto: la conexión no debe arrastrar el tenant.
        async with pg_session_factory() as session:
            await session.execute(text("SELECT 1"))
            assert await _leer_setting(session, RLS_TENANT_SETTING) is None
            await session.rollback()


@pytest.mark.integration
@pytest.mark.anyio
async def test_6_excepcion_no_deja_contexto(pg_session_factory):
    """Una excepción no deja el contexto visible en la siguiente petición."""
    tenant_id, user_id = uuid.uuid4(), uuid.uuid4()

    async with pg_session_factory() as session:
        await set_rls_context(session, _contexto(tenant_id, user_id))
        try:
            await session.execute(text("SELECT 1 / 0"))
        except Exception:
            await session.rollback()

        clear_rls_context(session)
        await session.execute(text("SELECT 1"))
        assert await _leer_setting(session, RLS_TENANT_SETTING) is None
        await session.rollback()


@pytest.mark.integration
@pytest.mark.anyio
async def test_7_mismo_usuario_multiples_tenants(pg_session_factory):
    """El mismo usuario puede operar contextos de tenants distintos."""
    user_id = uuid.uuid4()
    tenant_a, tenant_b = uuid.uuid4(), uuid.uuid4()

    async with pg_session_factory() as session:
        await set_rls_context(session, _contexto(tenant_a, user_id))
        assert await _leer_setting(session, RLS_TENANT_SETTING) == str(tenant_a)
        await session.rollback()

    async with pg_session_factory() as session:
        await set_rls_context(session, _contexto(tenant_b, user_id))
        assert await _leer_setting(session, RLS_TENANT_SETTING) == str(tenant_b)
        assert await _leer_setting(session, RLS_USER_SETTING) == str(user_id)
        await session.rollback()


@pytest.mark.integration
@pytest.mark.anyio
async def test_reintento_mantiene_contexto_durante_el_request(pg_session_factory):
    """Dos transacciones de la misma sesión conservan el tenant autorizado."""
    tenant_id, user_id = uuid.uuid4(), uuid.uuid4()
    async with pg_session_factory() as session:
        await set_rls_context(session, _contexto(tenant_id, user_id))

        await session.commit()
        # Nueva transacción automática de la MISMA sesión: el listener reaplica.
        assert await _leer_setting(session, RLS_TENANT_SETTING) == str(tenant_id)
        await session.rollback()
