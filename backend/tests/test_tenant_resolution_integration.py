"""Tests de integración PostgreSQL de la resolución de tenant (Tarea 3.1).

Se marcan con `integration`: requieren PostgreSQL real y se omiten si no hay
`DATABASE_URL` disponible. No requieren Supabase.
"""

import uuid

import pytest
from fastapi import HTTPException
from sqlalchemy.orm import Session

from src.app.core.tenant_context import UsuarioAutenticado
from src.app.dependencies.tenant import resolve_tenant_context
from src.app.models.profile import Profile
from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario
from src.app.services.tenant_service import get_membresia, listar_membresias_activas


class _AsyncSessionAdapter:
    """Adapta una Session síncrona de PostgreSQL al `.execute()` async usado.

    Permite ejercitar las consultas reales de `tenant_service` contra PostgreSQL
    sin duplicar la lógica en una variante síncrona.
    """

    def __init__(self, session: Session):
        self._session = session

    async def execute(self, statement):
        return self._session.execute(statement)


@pytest.mark.integration
@pytest.mark.anyio
async def test_postgres_resolucion_tenant_aislada(postgres_session: Session):
    """En PostgreSQL, la resolución respeta el aislamiento entre tenants."""
    p_id = uuid.uuid4()
    otro_p_id = uuid.uuid4()
    profile = Profile(id=p_id, email=f"owner_{p_id.hex[:6]}@fiapp.com")
    otro_profile = Profile(id=otro_p_id, email=f"otro_{otro_p_id.hex[:6]}@fiapp.com")
    tenant = Tenant(id=uuid.uuid4(), nombre_comercial="PG Propio", estado="activo")
    tenant_ajeno = Tenant(id=uuid.uuid4(), nombre_comercial="PG Ajeno", estado="activo")
    postgres_session.add_all([profile, otro_profile, tenant, tenant_ajeno])
    postgres_session.commit()
    postgres_session.add_all(
        [
            TenantUsuario(
                id=uuid.uuid4(), tenant_id=tenant.id, profile_id=profile.id, rol="propietario"
            ),
            TenantUsuario(
                id=uuid.uuid4(),
                tenant_id=tenant_ajeno.id,
                profile_id=otro_profile.id,
                rol="propietario",
            ),
        ]
    )
    postgres_session.commit()

    db = _AsyncSessionAdapter(postgres_session)

    # Membresía propia resuelta correctamente.
    membresia = await get_membresia(db, profile_id=profile.id, tenant_id=tenant.id)
    assert membresia is not None
    assert membresia.tenant.nombre_comercial == "PG Propio"

    # El listado no incluye el tenant ajeno.
    membresias = await listar_membresias_activas(db, profile_id=profile.id)
    assert [m.tenant_id for m in membresias] == [tenant.id]

    # Resolver el tenant ajeno se rechaza con 403.
    with pytest.raises(HTTPException) as exc_info:
        await resolve_tenant_context(
            usuario=UsuarioAutenticado(id=profile.id, email=profile.email),
            profile=profile,
            tenant_id=tenant_ajeno.id,
            db=db,
        )
    assert exc_info.value.status_code == 403

    # Limpieza.
    postgres_session.delete(tenant)
    postgres_session.delete(tenant_ajeno)
    postgres_session.delete(profile)
    postgres_session.delete(otro_profile)
    postgres_session.commit()


@pytest.mark.integration
@pytest.mark.anyio
async def test_postgres_membresia_inactiva_y_tenant_no_operativo(postgres_session: Session):
    """Membresía inactiva y tenant no operativo se rechazan en PostgreSQL."""
    p_id = uuid.uuid4()
    profile = Profile(id=p_id, email=f"inactivo_{p_id.hex[:6]}@fiapp.com")
    tenant_inactivo = Tenant(id=uuid.uuid4(), nombre_comercial="PG Inactiva", estado="activo")
    tenant_mora = Tenant(id=uuid.uuid4(), nombre_comercial="PG Mora", estado="mora")
    postgres_session.add_all([profile, tenant_inactivo, tenant_mora])
    postgres_session.commit()
    postgres_session.add_all(
        [
            TenantUsuario(
                id=uuid.uuid4(),
                tenant_id=tenant_inactivo.id,
                profile_id=profile.id,
                rol="cobrador",
                activo=False,
            ),
            TenantUsuario(
                id=uuid.uuid4(), tenant_id=tenant_mora.id, profile_id=profile.id, rol="supervisor"
            ),
        ]
    )
    postgres_session.commit()

    db = _AsyncSessionAdapter(postgres_session)

    for tenant in (tenant_inactivo, tenant_mora):
        with pytest.raises(HTTPException) as exc_info:
            await resolve_tenant_context(
                usuario=UsuarioAutenticado(id=profile.id, email=profile.email),
                profile=profile,
                tenant_id=tenant.id,
                db=db,
            )
        assert exc_info.value.status_code == 403

    # El listado solo muestra membresías activas.
    membresias = await listar_membresias_activas(db, profile_id=profile.id)
    assert [m.tenant_id for m in membresias] == [tenant_mora.id]

    postgres_session.delete(tenant_inactivo)
    postgres_session.delete(tenant_mora)
    postgres_session.delete(profile)
    postgres_session.commit()
