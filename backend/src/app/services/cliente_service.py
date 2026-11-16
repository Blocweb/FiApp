import uuid
from datetime import datetime, timezone

from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import func

from src.app.core.ids import as_uuid
from src.app.models.cliente import Cliente
from src.app.schemas.cliente import ClienteCreate, ClienteUpdate


class ClienteDuplicadoError(Exception):
    """Ya existe un cliente activo con la misma identificación (HU02 · T10)."""

    def __init__(self, existente: Cliente | None, identificacion: str):
        self.existente = existente
        self.identificacion = identificacion
        nombre = existente.nombre if existente is not None else "otro cliente"
        super().__init__(f"Ya existe un cliente con la identificación {identificacion}: {nombre}")


def _id(value):
    """Usa UUID cuando el texto es un UUID válido (PostgreSQL y SQLite)."""
    return as_uuid(value) or value


def _escape_like(value: str) -> str:
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


async def get_clientes(
    db: AsyncSession,
    tenant_id: str | None = None,
    owner_id: str | None = None,
    busqueda: str | None = None,
) -> list[Cliente]:
    """Clientes activos del negocio, opcionalmente filtrados por nombre (T13)."""
    effective_tenant_id = _id(tenant_id or owner_id)
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    query = select(Cliente).where(Cliente.tenant_id == effective_tenant_id, Cliente.deleted_at.is_(None))
    termino = " ".join((busqueda or "").split())
    if termino:
        patron = f"%{_escape_like(termino)}%"
        query = query.where(
            or_(
                Cliente.nombre.ilike(patron, escape="\\"),
                Cliente.identificacion.ilike(patron, escape="\\"),
            )
        )
    query = query.order_by(Cliente.nombre.asc())
    result = await db.execute(query)
    return result.scalars().all()


async def get_cliente_by_id(
    db: AsyncSession,
    cliente_id: str,
    tenant_id: str | None = None,
    owner_id: str | None = None,
) -> Cliente | None:
    effective_tenant_id = _id(tenant_id or owner_id)
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    cliente_uuid = as_uuid(cliente_id)
    if cliente_uuid is None:
        return None
    query = select(Cliente).where(
        Cliente.id == cliente_uuid,
        Cliente.tenant_id == effective_tenant_id,
        Cliente.deleted_at.is_(None),
    )
    result = await db.execute(query)
    return result.scalars().first()


async def get_cliente_por_identificacion(
    db: AsyncSession,
    tenant_id,
    identificacion: str,
    excluir_id=None,
) -> Cliente | None:
    query = select(Cliente).where(
        Cliente.tenant_id == _id(tenant_id),
        Cliente.identificacion == identificacion,
        Cliente.deleted_at.is_(None),
    )
    if excluir_id is not None:
        query = query.where(Cliente.id != excluir_id)
    result = await db.execute(query)
    return result.scalars().first()


async def _commit_o_duplicado(db: AsyncSession, tenant_id, identificacion: str | None) -> None:
    """Confirma la transacción; si choca con el índice único, avisa el duplicado."""
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        if identificacion is None:
            raise
        existente = await get_cliente_por_identificacion(db, tenant_id, identificacion)
        raise ClienteDuplicadoError(existente, identificacion) from None


async def create_cliente(
    db: AsyncSession,
    tenant_id: str | None = None,
    owner_id: str | None = None,
    cliente_in: ClienteCreate | None = None,
) -> Cliente:
    if cliente_in is None:
        raise ValueError("cliente_in es obligatorio")
    effective_tenant_id = _id(tenant_id or owner_id)
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")

    # T10: aviso cuando el cliente ya existe en el negocio.
    existente = await get_cliente_por_identificacion(db, effective_tenant_id, cliente_in.identificacion)
    if existente is not None:
        raise ClienteDuplicadoError(existente, cliente_in.identificacion)

    cliente = Cliente(
        id=uuid.uuid4(),
        tenant_id=effective_tenant_id,
        owner_id=_id(owner_id) or effective_tenant_id,
        nombre=cliente_in.nombre,
        identificacion=cliente_in.identificacion,
        telefono=cliente_in.telefono or "",
        direccion=cliente_in.direccion or "",
        notas=cliente_in.notas or "",
        color_hex=cliente_in.color_hex or "#2563EB",
        # T12: autorización de tratamiento de datos (Ley 1581 de 2012).
        autoriza_datos=True,
        autoriza_datos_en=datetime.now(timezone.utc),
    )
    db.add(cliente)
    await _commit_o_duplicado(db, effective_tenant_id, cliente_in.identificacion)
    await db.refresh(cliente)
    return cliente


async def update_cliente(db: AsyncSession, cliente: Cliente, cliente_in: ClienteUpdate) -> Cliente:
    if cliente_in.identificacion is not None and cliente_in.identificacion != cliente.identificacion:
        existente = await get_cliente_por_identificacion(
            db, cliente.tenant_id, cliente_in.identificacion, excluir_id=cliente.id
        )
        if existente is not None:
            raise ClienteDuplicadoError(existente, cliente_in.identificacion)
        cliente.identificacion = cliente_in.identificacion
    if cliente_in.nombre is not None:
        cliente.nombre = " ".join(cliente_in.nombre.split())
    if cliente_in.telefono is not None:
        cliente.telefono = cliente_in.telefono
    if cliente_in.direccion is not None:
        cliente.direccion = cliente_in.direccion
    if cliente_in.notas is not None:
        cliente.notas = cliente_in.notas
    if cliente_in.color_hex is not None:
        cliente.color_hex = cliente_in.color_hex
    if cliente_in.autoriza_datos and not cliente.autoriza_datos:
        cliente.autoriza_datos = True
        cliente.autoriza_datos_en = datetime.now(timezone.utc)

    await _commit_o_duplicado(db, cliente.tenant_id, cliente.identificacion)
    await db.refresh(cliente)
    return cliente


async def delete_cliente(db: AsyncSession, cliente: Cliente) -> None:
    cliente.deleted_at = func.now()
    await db.commit()
