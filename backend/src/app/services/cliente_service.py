from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.models.cliente import Cliente
from src.app.schemas.cliente import ClienteCreate, ClienteUpdate


async def get_clientes(db: AsyncSession, tenant_id: str | None = None, owner_id: str | None = None) -> list[Cliente]:
    effective_tenant_id = tenant_id or owner_id
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    query = select(Cliente).where(Cliente.tenant_id == effective_tenant_id, Cliente.deleted_at.is_(None))
    result = await db.execute(query)
    return result.scalars().all()


async def get_cliente_by_id(
    db: AsyncSession,
    cliente_id: str,
    tenant_id: str | None = None,
    owner_id: str | None = None,
) -> Cliente | None:
    effective_tenant_id = tenant_id or owner_id
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    query = select(Cliente).where(
        Cliente.id == cliente_id,
        Cliente.tenant_id == effective_tenant_id,
        Cliente.deleted_at.is_(None),
    )
    result = await db.execute(query)
    return result.scalars().first()


async def create_cliente(
    db: AsyncSession,
    tenant_id: str | None = None,
    owner_id: str | None = None,
    cliente_in: ClienteCreate | None = None,
) -> Cliente:
    if cliente_in is None:
        raise ValueError("cliente_in es obligatorio")
    effective_tenant_id = tenant_id or owner_id
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    cliente = Cliente(
        tenant_id=effective_tenant_id,
        owner_id=owner_id or effective_tenant_id,
        nombre=cliente_in.nombre,
        telefono=cliente_in.telefono or "",
        direccion=cliente_in.direccion or "",
        notas=cliente_in.notas or "",
        color_hex=cliente_in.color_hex or "#2563EB",
    )
    db.add(cliente)
    await db.commit()
    await db.refresh(cliente)
    return cliente


async def update_cliente(db: AsyncSession, cliente: Cliente, cliente_in: ClienteUpdate) -> Cliente:
    if cliente_in.nombre is not None:
        cliente.nombre = cliente_in.nombre
    if cliente_in.telefono is not None:
        cliente.telefono = cliente_in.telefono
    if cliente_in.direccion is not None:
        cliente.direccion = cliente_in.direccion
    if cliente_in.notas is not None:
        cliente.notas = cliente_in.notas
    if cliente_in.color_hex is not None:
        cliente.color_hex = cliente_in.color_hex

    await db.commit()
    await db.refresh(cliente)
    return cliente

async def delete_cliente(db: AsyncSession, cliente: Cliente) -> None:
    from sqlalchemy.sql import func
    cliente.deleted_at = func.now()
    await db.commit()
