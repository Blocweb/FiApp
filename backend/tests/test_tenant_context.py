"""Tests de la resolución centralizada del tenant (Tarea 3.1).

Se ejercitan las consultas async reales sobre SQLite en memoria mediante la
fixture `async_sqlite_session`, más la función `resolve_tenant_context` de forma
aislada. No se depende de PostgreSQL ni de Supabase reales.
"""

import uuid

import pytest
from fastapi import HTTPException

from src.app.core.tenant_context import UsuarioAutenticado
from src.app.dependencies.tenant import resolve_tenant_context
from src.app.models.profile import Profile
from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario
from src.app.services.tenant_service import (
    get_membresia,
    listar_membresias_activas,
    tenant_es_operativo,
)


async def _crear_profile(session, email: str | None = None) -> Profile:
    profile = Profile(id=uuid.uuid4(), email=email or f"{uuid.uuid4().hex[:8]}@fiapp.test")
    session.add(profile)
    await session.commit()
    return profile


async def _crear_tenant(session, estado: str = "activo", nombre: str = "Negocio") -> Tenant:
    tenant = Tenant(id=uuid.uuid4(), nombre_comercial=nombre, estado=estado)
    session.add(tenant)
    await session.commit()
    return tenant


async def _crear_membresia(
    session, tenant: Tenant, profile: Profile, rol: str = "propietario", activo: bool = True
) -> TenantUsuario:
    membresia = TenantUsuario(
        id=uuid.uuid4(),
        tenant_id=tenant.id,
        profile_id=profile.id,
        rol=rol,
        activo=activo,
    )
    session.add(membresia)
    await session.commit()
    return membresia


def _usuario(profile: Profile) -> UsuarioAutenticado:
    return UsuarioAutenticado(id=profile.id, email=profile.email)


# ---------------------------------------------------------------------------
# Servicio: listado de membresías propias
# ---------------------------------------------------------------------------

@pytest.mark.anyio
async def test_listar_membresias_vacio_para_usuario_sin_tenants(async_sqlite_session):
    """Un usuario sin membresías obtiene una lista vacía, sin errores."""
    profile = await _crear_profile(async_sqlite_session)
    membresias = await listar_membresias_activas(async_sqlite_session, profile_id=profile.id)
    assert membresias == []


@pytest.mark.anyio
async def test_listar_membresias_solo_activas(async_sqlite_session):
    """El listado excluye membresías inactivas."""
    profile = await _crear_profile(async_sqlite_session)
    tenant_activo = await _crear_tenant(async_sqlite_session, nombre="Activo")
    tenant_inactivo = await _crear_tenant(async_sqlite_session, nombre="Inactivo")
    await _crear_membresia(async_sqlite_session, tenant_activo, profile, activo=True)
    await _crear_membresia(async_sqlite_session, tenant_inactivo, profile, activo=False)

    membresias = await listar_membresias_activas(async_sqlite_session, profile_id=profile.id)

    assert len(membresias) == 1
    assert membresias[0].tenant.nombre_comercial == "Activo"


@pytest.mark.anyio
async def test_listar_membresias_no_incluye_tenants_ajenos(async_sqlite_session):
    """El listado nunca incluye tenants de otro usuario."""
    profile_a = await _crear_profile(async_sqlite_session)
    profile_b = await _crear_profile(async_sqlite_session)
    tenant_a = await _crear_tenant(async_sqlite_session, nombre="Tenant A")
    tenant_b = await _crear_tenant(async_sqlite_session, nombre="Tenant B")
    await _crear_membresia(async_sqlite_session, tenant_a, profile_a)
    await _crear_membresia(async_sqlite_session, tenant_b, profile_b)

    membresias = await listar_membresias_activas(async_sqlite_session, profile_id=profile_a.id)

    assert [m.tenant.id for m in membresias] == [tenant_a.id]


@pytest.mark.anyio
async def test_listar_membresias_usuario_multi_tenant(async_sqlite_session):
    """Un usuario con varias membresías las ve todas."""
    profile = await _crear_profile(async_sqlite_session)
    t1 = await _crear_tenant(async_sqlite_session, nombre="Uno")
    t2 = await _crear_tenant(async_sqlite_session, nombre="Dos")
    await _crear_membresia(async_sqlite_session, t1, profile, rol="propietario")
    await _crear_membresia(async_sqlite_session, t2, profile, rol="cobrador")

    membresias = await listar_membresias_activas(async_sqlite_session, profile_id=profile.id)

    roles_por_tenant = {m.tenant.nombre_comercial: m.rol for m in membresias}
    assert roles_por_tenant == {"Uno": "propietario", "Dos": "cobrador"}


# ---------------------------------------------------------------------------
# Servicio: consulta de membresía concreta
# ---------------------------------------------------------------------------

@pytest.mark.anyio
async def test_get_membresia_inexistente_devuelve_none(async_sqlite_session):
    """Sin membresía, la consulta devuelve None (no lanza excepción)."""
    profile = await _crear_profile(async_sqlite_session)
    tenant = await _crear_tenant(async_sqlite_session)
    membresia = await get_membresia(async_sqlite_session, profile_id=profile.id, tenant_id=tenant.id)
    assert membresia is None


@pytest.mark.anyio
async def test_get_membresia_tenant_ajeno_devuelve_none(async_sqlite_session):
    """Consultar un tenant de otro usuario devuelve None, igual que si no existiera."""
    profile_a = await _crear_profile(async_sqlite_session)
    profile_b = await _crear_profile(async_sqlite_session)
    tenant_b = await _crear_tenant(async_sqlite_session)
    await _crear_membresia(async_sqlite_session, tenant_b, profile_b)

    membresia = await get_membresia(async_sqlite_session, profile_id=profile_a.id, tenant_id=tenant_b.id)

    assert membresia is None


@pytest.mark.anyio
async def test_get_membresia_carga_tenant(async_sqlite_session):
    """La membresía devuelta trae su tenant precargado (sin lazy load)."""
    profile = await _crear_profile(async_sqlite_session)
    tenant = await _crear_tenant(async_sqlite_session, nombre="Cargado")
    await _crear_membresia(async_sqlite_session, tenant, profile, rol="supervisor")

    membresia = await get_membresia(async_sqlite_session, profile_id=profile.id, tenant_id=tenant.id)

    assert membresia is not None
    assert membresia.tenant.nombre_comercial == "Cargado"
    assert membresia.rol == "supervisor"


# ---------------------------------------------------------------------------
# Regla de estado operativo
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("estado", ["suspendido", "mora", "cancelado"])
def test_tenant_no_operativo(estado):
    """Solo `activo` es operativo en esta fase."""
    tenant = Tenant(id=uuid.uuid4(), nombre_comercial="X", estado=estado)
    assert tenant_es_operativo(tenant) is False


def test_tenant_activo_es_operativo():
    tenant = Tenant(id=uuid.uuid4(), nombre_comercial="X", estado="activo")
    assert tenant_es_operativo(tenant) is True


# ---------------------------------------------------------------------------
# Resolución del contexto (función aislada)
# ---------------------------------------------------------------------------

@pytest.mark.anyio
async def test_resolve_contexto_valido(async_sqlite_session):
    """Usuario A con membresía activa en tenant A obtiene contexto válido."""
    profile = await _crear_profile(async_sqlite_session)
    tenant = await _crear_tenant(async_sqlite_session, nombre="Mi Negocio")
    await _crear_membresia(async_sqlite_session, tenant, profile, rol="propietario")

    contexto = await resolve_tenant_context(
        usuario=_usuario(profile),
        profile=profile,
        tenant_id=tenant.id,
        db=async_sqlite_session,
    )

    assert contexto.tenant_id == tenant.id
    assert contexto.profile_id == profile.id
    assert contexto.rol == "propietario"
    assert contexto.membresia.activo is True
    assert contexto.tenant.nombre_comercial == "Mi Negocio"


@pytest.mark.anyio
async def test_resolve_contexto_tenant_ajeno_rechazado(async_sqlite_session):
    """Usuario A no puede resolver el tenant de B: 403."""
    profile_a = await _crear_profile(async_sqlite_session)
    profile_b = await _crear_profile(async_sqlite_session)
    tenant_b = await _crear_tenant(async_sqlite_session)
    await _crear_membresia(async_sqlite_session, tenant_b, profile_b)

    with pytest.raises(HTTPException) as exc_info:
        await resolve_tenant_context(
            usuario=_usuario(profile_a),
            profile=profile_a,
            tenant_id=tenant_b.id,
            db=async_sqlite_session,
        )

    assert exc_info.value.status_code == 403


@pytest.mark.anyio
async def test_resolve_contexto_tenant_inexistente_rechazado(async_sqlite_session):
    """Un tenant inexistente produce el mismo 403 que uno ajeno."""
    profile = await _crear_profile(async_sqlite_session)

    with pytest.raises(HTTPException) as exc_info:
        await resolve_tenant_context(
            usuario=_usuario(profile),
            profile=profile,
            tenant_id=uuid.uuid4(),
            db=async_sqlite_session,
        )

    assert exc_info.value.status_code == 403


@pytest.mark.anyio
async def test_resolve_contexto_membresia_inactiva_rechazado(async_sqlite_session):
    """Una membresía inactiva impide operar aunque el tenant exista."""
    profile = await _crear_profile(async_sqlite_session)
    tenant = await _crear_tenant(async_sqlite_session)
    await _crear_membresia(async_sqlite_session, tenant, profile, activo=False)

    with pytest.raises(HTTPException) as exc_info:
        await resolve_tenant_context(
            usuario=_usuario(profile),
            profile=profile,
            tenant_id=tenant.id,
            db=async_sqlite_session,
        )

    assert exc_info.value.status_code == 403


@pytest.mark.parametrize("estado", ["suspendido", "mora", "cancelado"])
@pytest.mark.anyio
async def test_resolve_contexto_tenant_no_operativo_rechazado(async_sqlite_session, estado):
    """Suspender, mora o cancelar el tenant bloquea el acceso."""
    profile = await _crear_profile(async_sqlite_session)
    tenant = await _crear_tenant(async_sqlite_session, estado=estado)
    await _crear_membresia(async_sqlite_session, tenant, profile)

    with pytest.raises(HTTPException) as exc_info:
        await resolve_tenant_context(
            usuario=_usuario(profile),
            profile=profile,
            tenant_id=tenant.id,
            db=async_sqlite_session,
        )

    assert exc_info.value.status_code == 403


@pytest.mark.anyio
async def test_resolve_contexto_rol_por_tenant(async_sqlite_session):
    """El rol proviene de la membresía, distinto según el tenant."""
    profile = await _crear_profile(async_sqlite_session)
    t1 = await _crear_tenant(async_sqlite_session, nombre="T1")
    t2 = await _crear_tenant(async_sqlite_session, nombre="T2")
    await _crear_membresia(async_sqlite_session, t1, profile, rol="propietario")
    await _crear_membresia(async_sqlite_session, t2, profile, rol="cobrador")

    ctx1 = await resolve_tenant_context(
        usuario=_usuario(profile), profile=profile, tenant_id=t1.id, db=async_sqlite_session
    )
    ctx2 = await resolve_tenant_context(
        usuario=_usuario(profile), profile=profile, tenant_id=t2.id, db=async_sqlite_session
    )

    assert ctx1.rol == "propietario"
    assert ctx2.rol == "cobrador"


@pytest.mark.anyio
async def test_resolve_contexto_ignora_profiles_rol(async_sqlite_session):
    """`profiles.rol` no influye: el rol efectivo es el de la membresía."""
    profile = Profile(id=uuid.uuid4(), email="empleado@fiapp.test", rol="empleado")
    async_sqlite_session.add(profile)
    await async_sqlite_session.commit()
    tenant = await _crear_tenant(async_sqlite_session)
    await _crear_membresia(async_sqlite_session, tenant, profile, rol="administrador")

    contexto = await resolve_tenant_context(
        usuario=_usuario(profile), profile=profile, tenant_id=tenant.id, db=async_sqlite_session
    )

    assert contexto.profile.rol == "empleado"
    assert contexto.rol == "administrador"
