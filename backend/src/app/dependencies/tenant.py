"""Dependencia centralizada de resolución del tenant.

Estrategia única, reutilizable por cualquier router que necesite contexto de
tenant:

    JWT validado por Supabase
        ↓
    profile autenticado
        ↓
    tenant solicitado (header X-Tenant-ID)
        ↓
    membresía en tenant_usuarios
        ↓
    rol efectivo del tenant

`X-Tenant-ID` es únicamente un selector: nunca se acepta como prueba de
autorización. La autorización se decide consultando la membresía real en la
base de datos. No existe fallback al primer tenant del usuario ni uso de un
`tenant_id` recibido en el cuerpo para autorizar, y no se guarda el tenant
activo en estado global del servidor.
"""

from datetime import datetime, timezone
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.core.rls_context import set_rls_context
from src.app.core.tenant_context import TenantContext, UsuarioAutenticado
from src.app.database.connection import get_db
from src.app.models.profile import Profile
from src.app.services.auth_service import get_current_profile, get_current_user
from src.app.services.tenant_service import (
    get_membresia,
    membresias_activas_o_tenant_personal,
    tenant_es_operativo,
)

TENANT_HEADER_NAME = "X-Tenant-ID"

# Respuesta genérica para cualquier tenant inaccesible. Se usa la misma para
# tenant inexistente, sin membresía, membresía inactiva y tenant no operativo,
# de modo que no se pueda deducir si un tenant ajeno existe.
_tenant_no_autorizado = HTTPException(
    status_code=status.HTTP_403_FORBIDDEN,
    detail="No tiene acceso al negocio solicitado",
)


async def resolve_tenant_context(
    usuario: UsuarioAutenticado,
    profile: Profile,
    tenant_id: UUID,
    db: AsyncSession,
) -> TenantContext:
    """Resuelve y valida el contexto de tenant a partir de datos ya verificados.

    Es una función pura respecto al transporte HTTP (no lee el header): recibe
    el tenant ya parseado. Así puede probarse de forma aislada y reutilizarse
    desde distintas dependencias.
    """
    membresia = await get_membresia(db, profile_id=profile.id, tenant_id=tenant_id)

    # Sin membresía o membresía inactiva: mismo rechazo genérico.
    if membresia is None or not membresia.activo:
        raise _tenant_no_autorizado

    if not tenant_es_operativo(membresia.tenant):
        raise _tenant_no_autorizado

    return TenantContext(
        usuario=usuario,
        profile=profile,
        tenant=membresia.tenant,
        membresia=membresia,
        rol=membresia.rol,
        resuelto_en=datetime.now(timezone.utc),
    )


async def _resolver_sin_contexto_postgres(
    usuario: UsuarioAutenticado,
    profile: Profile,
    x_tenant_id: str | None,
    db: AsyncSession,
) -> TenantContext:
    """Resuelve y valida el tenant en motores sin variables de sesión.

    Motores como SQLite (usados en pruebas unitarias) no soportan
    ``set_config``; aquí solo se valida la membresía y se devuelve el contexto.
    La propagación a PostgreSQL se hace exclusivamente en el camino que usa
    ``set_rls_context``.
    """
    if x_tenant_id is None or not x_tenant_id.strip():
        membresias = await membresias_activas_o_tenant_personal(db, profile)
        if not membresias:
            raise _tenant_no_autorizado
        if len(membresias) > 1:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "tenant_required",
                    "message": f"Debe indicar {TENANT_HEADER_NAME} porque el usuario tiene varias membresías activas.",
                },
            )
        return await resolve_tenant_context(
            usuario=usuario,
            profile=profile,
            tenant_id=membresias[0].tenant_id,
            db=db,
        )

    try:
        tenant_id = UUID(x_tenant_id.strip())
    except ValueError:
        raise HTTPException(
            status_code=422,
            detail={
                "code": "tenant_invalid",
                "message": f"El encabezado {TENANT_HEADER_NAME} no es un UUID válido",
            },
        ) from None
    return await resolve_tenant_context(
        usuario=usuario,
        profile=profile,
        tenant_id=tenant_id,
        db=db,
    )

async def get_current_tenant_context(
    usuario: UsuarioAutenticado = Depends(get_current_user),
    profile: Profile = Depends(get_current_profile),
    x_tenant_id: str | None = Header(default=None, alias=TENANT_HEADER_NAME),
    db: AsyncSession = Depends(get_db),
) -> TenantContext:
    """Dependencia FastAPI que expone el contexto de tenant validado.

    Reutiliza `get_current_user()` y `get_current_profile()` mediante el sistema
    de dependencias de FastAPI, por lo que la validación del token con Supabase
    se ejecuta una sola vez por petición, aunque varios parámetros dependan de
    la misma identidad.

    Durante la fase de compatibilidad se permite resolver automáticamente el
    único tenant activo disponible. Si el usuario tiene varias membresías, el
    cliente debe enviar el header explícito para evitar ambigüedad.
    """
    if db.bind is not None and db.bind.dialect.name != "postgresql":
        context = await _resolver_sin_contexto_postgres(
            usuario=usuario,
            profile=profile,
            x_tenant_id=x_tenant_id,
            db=db,
        )
        return context
    if x_tenant_id is None or not x_tenant_id.strip():
        membresias = await membresias_activas_o_tenant_personal(db, profile)
        if not membresias:
            raise _tenant_no_autorizado
        if len(membresias) > 1:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "tenant_required",
                    "message": f"Debe indicar {TENANT_HEADER_NAME} porque el usuario tiene varias membresías activas.",
                },
            )
        tenant_id = membresias[0].tenant_id
        contexto = await resolve_tenant_context(
            usuario=usuario,
            profile=profile,
            tenant_id=tenant_id,
            db=db,
        )
        await set_rls_context(db, contexto)
        return contexto

    try:
        tenant_id = UUID(x_tenant_id.strip())
    except ValueError:
        raise HTTPException(
            status_code=422,
            detail={
                "code": "tenant_invalid",
                "message": f"El encabezado {TENANT_HEADER_NAME} no es un UUID válido",
            },
        ) from None

    contexto = await resolve_tenant_context(
        usuario=usuario,
        profile=profile,
        tenant_id=tenant_id,
        db=db,
    )
    await set_rls_context(db, contexto)
    return contexto
