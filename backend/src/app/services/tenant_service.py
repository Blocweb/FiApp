"""Consultas de tenants y membresías para la resolución centralizada.

Este módulo NO autoriza por sí mismo: solo lee de la base de datos. La decisión
de acceso se toma en la dependencia de contexto, que comprueba la membresía
activa y el estado del tenant antes de conceder acceso.
"""

from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario

# Estados de tenant permitidos para operar en esta fase (Fase 3.1).
# `suspendido`, `mora` y `cancelado` se rechazan explícitamente.
ESTADOS_TENANT_OPERATIVOS: frozenset[str] = frozenset({"activo"})


async def listar_membresias_activas(
    db: AsyncSession,
    profile_id: UUID,
) -> list[TenantUsuario]:
    """Membresías activas del usuario, con su tenant precargado.

    Solo devuelve membresías ligadas a tenants operativos, que es lo único que
    tiene sentido ofrecer como selección al cliente. El tenant se carga con
    `selectinload` para evitar relaciones lazy en contexto async.
    """
    query = (
        select(TenantUsuario)
        .where(
            TenantUsuario.profile_id == profile_id,
            TenantUsuario.activo.is_(True),
        )
        .options(selectinload(TenantUsuario.tenant))
        .order_by(TenantUsuario.created_at.asc())
    )
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_membresia(
    db: AsyncSession,
    profile_id: UUID,
    tenant_id: UUID,
) -> TenantUsuario | None:
    """Membresía del usuario en el tenant indicado, sin importar su estado.

    Devuelve `None` tanto si el tenant no existe como si no hay membresía. La
    dependencia de contexto trata ambos casos con la misma respuesta genérica
    para no revelar la existencia de tenants ajenos.
    """
    query = (
        select(TenantUsuario)
        .join(Tenant, Tenant.id == TenantUsuario.tenant_id)
        .where(
            TenantUsuario.profile_id == profile_id,
            TenantUsuario.tenant_id == tenant_id,
        )
        .options(selectinload(TenantUsuario.tenant))
    )
    result = await db.execute(query)
    return result.scalars().first()


def tenant_es_operativo(tenant: Tenant) -> bool:
    """Indica si el tenant puede operar mediante el contexto en esta fase."""
    return tenant.estado in ESTADOS_TENANT_OPERATIVOS


async def tiene_membresias(db: AsyncSession, profile_id: UUID) -> bool:
    """Indica si el usuario tiene alguna membresía, activa o no."""
    query = select(TenantUsuario.id).where(TenantUsuario.profile_id == profile_id).limit(1)
    result = await db.execute(query)
    return result.first() is not None


async def crear_tenant_personal(db: AsyncSession, profile) -> TenantUsuario:
    """Crea el negocio propio de un usuario recién registrado.

    `fn_handle_new_user` solo crea el profile, así que un dueño que se registra
    desde la app no tendría negocio. Se usa el mismo criterio de la migración
    002: el tenant personal usa el id del profile y el usuario queda como
    propietario. Solo debe llamarse cuando el usuario no tiene ninguna
    membresía; un trabajador desactivado conserva su membresía inactiva y
    nunca recibe un negocio propio.
    """
    tenant = await db.get(Tenant, profile.id)
    if tenant is None:
        tenant = Tenant(
            id=profile.id,
            nombre_comercial=(profile.nombre_negocio or "Mi tienda")[:150],
            estado="activo",
        )
        db.add(tenant)
        await db.flush()
    membresia = TenantUsuario(id=uuid4(), tenant_id=tenant.id, profile_id=profile.id, rol="propietario", activo=True)
    db.add(membresia)
    await db.commit()
    return membresia


async def membresias_activas_o_tenant_personal(db: AsyncSession, profile) -> list[TenantUsuario]:
    """Membresías activas; si el usuario es nuevo, le crea su negocio propio."""
    membresias = await listar_membresias_activas(db, profile_id=profile.id)
    if not membresias and not await tiene_membresias(db, profile_id=profile.id):
        await crear_tenant_personal(db, profile)
        membresias = await listar_membresias_activas(db, profile_id=profile.id)
    return membresias
