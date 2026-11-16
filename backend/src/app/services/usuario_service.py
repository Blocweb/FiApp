"""Gestión de usuarios del negocio (HU01 · T02, T03).

Las cuentas se crean en Supabase Auth con la Admin API (clave service role,
solo disponible en el servidor). El trigger `fn_handle_new_user` crea el
profile y aquí se agrega la membresía al negocio con el rol elegido. Los
usuarios nunca se borran: se desactiva su membresía, y la resolución del
tenant rechaza las membresías inactivas en cada petición.
"""

import logging
from uuid import UUID, uuid4

import httpx
from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.app.core.config import get_settings
from src.app.core.permissions import ROL_ADMINISTRADOR, ROL_PROPIETARIO
from src.app.core.tenant_context import TenantContext
from src.app.models.profile import Profile
from src.app.models.tenant_usuario import TenantUsuario
from src.app.schemas.usuario import UsuarioCreate, UsuarioResponse, UsuarioUpdate

logger = logging.getLogger(__name__)


def to_usuario_response(membresia: TenantUsuario, contexto: TenantContext) -> UsuarioResponse:
    profile = membresia.profile
    return UsuarioResponse(
        id=membresia.id,
        profile_id=membresia.profile_id,
        nombre=profile.nombre if profile else None,
        email=profile.email if profile else "",
        rol=membresia.rol,
        activo=bool(membresia.activo),
        es_usted=membresia.profile_id == contexto.profile_id,
        created_at=membresia.created_at,
    )


async def listar_usuarios(db: AsyncSession, tenant_id: UUID) -> list[TenantUsuario]:
    query = (
        select(TenantUsuario)
        .where(TenantUsuario.tenant_id == tenant_id)
        .options(selectinload(TenantUsuario.profile))
        .order_by(TenantUsuario.activo.desc(), TenantUsuario.created_at.asc())
    )
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_usuario(db: AsyncSession, tenant_id: UUID, membresia_id: UUID) -> TenantUsuario | None:
    query = (
        select(TenantUsuario)
        .where(TenantUsuario.id == membresia_id, TenantUsuario.tenant_id == tenant_id)
        .options(selectinload(TenantUsuario.profile))
        .execution_options(populate_existing=True)
    )
    result = await db.execute(query)
    return result.scalars().first()


def _admin_headers() -> dict[str, str]:
    key = get_settings().supabase_service_role_key or ""
    return {"apikey": key, "Authorization": f"Bearer {key}"}


async def _crear_cuenta_supabase(datos: UsuarioCreate, nombre_negocio: str) -> UUID:
    """Crea el usuario en Supabase Auth (correo ya confirmado) y devuelve su id."""
    settings = get_settings()
    if not settings.supabase_service_role_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="La creación de usuarios no está configurada en el servidor",
        )
    url = f"{settings.supabase_url.rstrip('/')}/auth/v1/admin/users"
    body = {
        "email": datos.email,
        "password": datos.password,
        "email_confirm": True,
        "user_metadata": {"nombre": datos.nombre, "nombre_negocio": nombre_negocio},
    }
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(url, json=body, headers=_admin_headers())
    except httpx.HTTPError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No se pudo contactar el servicio de autenticación",
        ) from None

    if response.status_code in (409, 422):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe una cuenta con ese correo",
        )
    if response.status_code not in (200, 201):
        logger.warning("Supabase admin create user failed: %s", response.status_code)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="El servicio de autenticación rechazó la creación del usuario",
        )
    return UUID(response.json()["id"])


async def _borrar_cuenta_supabase(user_id: UUID) -> None:
    """Compensación si falla el registro de la membresía (mejor esfuerzo)."""
    settings = get_settings()
    url = f"{settings.supabase_url.rstrip('/')}/auth/v1/admin/users/{user_id}"
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            await client.delete(url, headers=_admin_headers())
    except httpx.HTTPError:
        logger.warning("No se pudo revertir la cuenta %s en Supabase", user_id)


async def crear_usuario(db: AsyncSession, contexto: TenantContext, datos: UsuarioCreate) -> TenantUsuario:
    """Crea la cuenta propia de un trabajador y lo agrega al negocio (T03)."""
    if datos.rol == ROL_ADMINISTRADOR and contexto.rol != ROL_PROPIETARIO:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el propietario puede crear administradores",
        )

    existente = (
        await db.execute(select(Profile).where(func.lower(Profile.email) == datos.email))
    ).scalars().first()
    if existente is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe una cuenta con ese correo",
        )

    user_id = await _crear_cuenta_supabase(datos, contexto.tenant.nombre_comercial)
    try:
        profile = await db.get(Profile, user_id)
        if profile is None:
            # Normalmente ya lo creó el trigger fn_handle_new_user.
            profile = Profile(
                id=user_id,
                email=datos.email,
                nombre_negocio=contexto.tenant.nombre_comercial,
            )
            db.add(profile)
        profile.nombre = datos.nombre
        profile.rol = "empleado"
        membresia = TenantUsuario(
            id=uuid4(),
            tenant_id=contexto.tenant_id,
            profile_id=user_id,
            rol=datos.rol,
            activo=True,
        )
        db.add(membresia)
        await db.commit()
    except SQLAlchemyError:
        await db.rollback()
        await _borrar_cuenta_supabase(user_id)
        raise

    return await get_usuario(db, contexto.tenant_id, membresia.id)


async def actualizar_usuario(
    db: AsyncSession,
    contexto: TenantContext,
    membresia: TenantUsuario,
    cambios: UsuarioUpdate,
) -> TenantUsuario:
    """Activa/desactiva un usuario o cambia su rol (T02, T03)."""
    if membresia.profile_id == contexto.profile_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No puede cambiar su propio usuario",
        )
    if membresia.rol == ROL_PROPIETARIO:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="El propietario del negocio no se puede modificar",
        )
    toca_administrador = membresia.rol == ROL_ADMINISTRADOR or cambios.rol == ROL_ADMINISTRADOR
    if toca_administrador and contexto.rol != ROL_PROPIETARIO:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el propietario puede gestionar administradores",
        )

    if cambios.activo is not None:
        membresia.activo = cambios.activo
    if cambios.rol is not None:
        membresia.rol = cambios.rol
    await db.commit()
    return await get_usuario(db, contexto.tenant_id, membresia.id)
