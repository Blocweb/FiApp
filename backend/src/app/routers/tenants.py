"""Endpoints de descubrimiento y verificación del tenant activo.

Estos endpoints permiten al cliente saber a qué negocios pertenece el usuario
autenticado y confirmar el contexto del tenant seleccionado. No exponen
usuarios del negocio, configuración interna ni datos financieros.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.core.tenant_context import TenantContext
from src.app.database.connection import get_db
from src.app.dependencies.tenant import get_current_tenant_context
from src.app.models.profile import Profile
from src.app.schemas.tenant import (
    TenantCurrentResponse,
    TenantListadoResponse,
    TenantResumen,
)
from src.app.services.auth_service import get_current_profile
from src.app.services.tenant_service import listar_membresias_activas

router = APIRouter(prefix="/tenants", tags=["tenants"])


@router.get("/", response_model=TenantListadoResponse)
async def listar_tenants(
    db: AsyncSession = Depends(get_db),
    profile: Profile = Depends(get_current_profile),
) -> TenantListadoResponse:
    """Lista los negocios donde el usuario tiene membresía activa.

    No requiere `X-Tenant-ID`, para evitar un bloqueo circular durante la
    selección inicial del negocio. Devolve solo la información mínima: id,
    nombre comercial, estado y el rol del propio usuario.
    """
    membresias = await listar_membresias_activas(db, profile_id=profile.id)
    return TenantListadoResponse(
        tenants=[
            TenantResumen(
                id=membresia.tenant.id,
                nombre_comercial=membresia.tenant.nombre_comercial,
                estado=membresia.tenant.estado,
                rol=membresia.rol,
            )
            for membresia in membresias
        ]
    )


@router.get("/current", response_model=TenantCurrentResponse)
async def obtener_tenant_actual(
    contexto: TenantContext = Depends(get_current_tenant_context),
) -> TenantCurrentResponse:
    """Devuelve el tenant seleccionado y el rol del usuario en ese contexto.

    Requiere el encabezado `X-Tenant-ID`. Solo responde cuando el tenant existe,
    el usuario tiene membresía activa y el tenant está operativo.
    """
    return TenantCurrentResponse(
        tenant_id=contexto.tenant_id,
        nombre_comercial=contexto.tenant.nombre_comercial,
        estado=contexto.tenant.estado,
        rol=contexto.rol,
        usuario_id=contexto.usuario.id,
        email=contexto.profile.email,
        membresia_id=contexto.membresia_id,
        membresia_activa=bool(contexto.membresia.activo),
        seleccionado_en=contexto.resuelto_en,
    )
