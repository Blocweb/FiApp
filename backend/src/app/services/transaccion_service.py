from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.app.models.cliente import Cliente
from src.app.models.fiado_item import FiadoItem
from src.app.models.metodo_pago import MetodoPago
from src.app.models.transaccion import Transaccion
from src.app.schemas.transaccion import TransaccionAbonoCreate, TransaccionFiadoCreate


def _transaction_query(tenant_id: str | None = None, owner_id: str | None = None):
    effective_tenant_id = tenant_id or owner_id
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    return (
        select(Transaccion)
        .where(Transaccion.tenant_id == effective_tenant_id, Transaccion.deleted_at.is_(None))
        .options(selectinload(Transaccion.fiado_items))
        .order_by(Transaccion.created_at.desc())
    )


async def _get_transaction_by_id(
    db: AsyncSession,
    transaction_id: str,
    tenant_id: str | None = None,
    owner_id: str | None = None,
) -> Transaccion:
    effective_tenant_id = tenant_id or owner_id
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    result = await db.execute(
        _transaction_query(effective_tenant_id).where(Transaccion.id == transaction_id)
    )
    return result.scalar_one()


async def get_transacciones_por_cliente(
    db: AsyncSession,
    cliente_id: str,
    tenant_id: str | None = None,
    owner_id: str | None = None,
) -> list[Transaccion]:
    effective_tenant_id = tenant_id or owner_id
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    result = await db.execute(
        _transaction_query(effective_tenant_id).where(Transaccion.cliente_id == cliente_id)
    )
    return result.scalars().all()


async def get_transacciones(db: AsyncSession, tenant_id: str | None = None, owner_id: str | None = None) -> list[Transaccion]:
    effective_tenant_id = tenant_id or owner_id
    if effective_tenant_id is None:
        raise ValueError("Se requiere tenant_id o owner_id")
    result = await db.execute(_transaction_query(effective_tenant_id))
    return result.scalars().all()


async def create_fiado(
    db: AsyncSession,
    tenant_id: str,
    owner_id: str,
    cliente: Cliente,
    transaccion_in: TransaccionFiadoCreate,
) -> Transaccion:
    transaccion = Transaccion(
        tenant_id=tenant_id,
        owner_id=owner_id,
        cliente_id=cliente.id,
        tipo="fiado",
        monto=transaccion_in.monto,
        nota=transaccion_in.nota,
    )
    try:
        db.add(transaccion)
        await db.flush()

        for item_in in transaccion_in.items:
            db.add(
                FiadoItem(
                    transaccion_id=transaccion.id,
                    producto_id=item_in.producto_id,
                    nombre_producto=item_in.nombre_producto,
                    cantidad=item_in.cantidad,
                    precio_unitario=item_in.precio_unitario,
                )
            )

        await db.commit()
    except SQLAlchemyError:
        await db.rollback()
        raise

    return await _get_transaction_by_id(db, str(transaccion.id), tenant_id)


async def create_abono(
    db: AsyncSession,
    tenant_id: str,
    owner_id: str,
    cliente: Cliente,
    transaccion_in: TransaccionAbonoCreate,
) -> Transaccion:
    monto = transaccion_in.monto
    if monto > Decimal(cliente.saldo):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El abono no puede superar la deuda actual.",
        )

    method_query = select(MetodoPago).where(MetodoPago.activo.is_(True))
    if transaccion_in.metodo_pago_id is not None:
        method_query = method_query.where(MetodoPago.id == transaccion_in.metodo_pago_id)
    else:
        method_query = method_query.where(
            MetodoPago.nombre == transaccion_in.metodo_pago_nombre
        )
    payment_method = (await db.execute(method_query)).scalar_one_or_none()
    if payment_method is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Método de pago inválido o inactivo.",
        )

    transaccion = Transaccion(
        tenant_id=tenant_id,
        owner_id=owner_id,
        cliente_id=cliente.id,
        tipo="abono",
        monto=monto,
        metodo_pago_id=payment_method.id,
        nota=transaccion_in.nota,
    )
    try:
        db.add(transaccion)
        await db.commit()
    except SQLAlchemyError:
        await db.rollback()
        raise

    return await _get_transaction_by_id(db, str(transaccion.id), tenant_id)
