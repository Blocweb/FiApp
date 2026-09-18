from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.models.cliente import Cliente
from src.app.schemas.cliente import ClienteCreate, ClienteUpdate


async def get_clientes(db: AsyncSession, owner_id: str) -> list[Cliente]:
    query = select(Cliente).where(Cliente.owner_id == owner_id, Cliente.deleted_at.is_(None))
    result = await db.execute(query)
    return result.scalars().all()


async def get_cliente_by_id(db: AsyncSession, cliente_id: str, owner_id: str) -> Cliente | None:
    query = select(Cliente).where(
        Cliente.id == cliente_id,
        Cliente.owner_id == owner_id,
        Cliente.deleted_at.is_(None),
    )
    result = await db.execute(query)
    return result.scalars().first()


async def create_cliente(db: AsyncSession, owner_id: str, cliente_in: ClienteCreate) -> Cliente:
    cliente = Cliente(
        owner_id=owner_id,
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
