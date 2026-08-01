from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.app.models.cliente import Cliente
from src.app.models.fiado_item import FiadoItem
from src.app.models.transaccion import Transaccion
from src.app.schemas.transaccion import TransaccionAbonoCreate, TransaccionFiadoCreate


async def get_transacciones_por_cliente(
    db: AsyncSession,
    cliente_id: str,
    owner_id: str,
) -> list[Transaccion]:
    query = (
        select(Transaccion)
        .where(Transaccion.cliente_id == cliente_id, Transaccion.owner_id == owner_id)
        .options(selectinload(Transaccion.fiado_items))
        .order_by(Transaccion.created_at.desc())
    )
    result = await db.execute(query)
    return result.scalars().all()


async def create_fiado(
    db: AsyncSession,
    owner_id: str,
    cliente: Cliente,
    transaccion_in: TransaccionFiadoCreate,
) -> Transaccion:
    monto = Decimal(str(transaccion_in.monto))
    transaccion = Transaccion(
        owner_id=owner_id,
        cliente_id=cliente.id,
        tipo="fiado",
        monto=monto,
    )
    db.add(transaccion)
    await db.flush()

    for item_in in transaccion_in.items:
        item = FiadoItem(
            transaccion_id=transaccion.id,
            producto_id=item_in.producto_id,
            nombre_producto=item_in.nombre_producto,
            cantidad=item_in.cantidad,
            precio_unitario=Decimal(str(item_in.precio_unitario)),
        )
        db.add(item)

    await db.commit()
    await db.refresh(transaccion)
    return transaccion


async def create_abono(
    db: AsyncSession,
    owner_id: str,
    cliente: Cliente,
    transaccion_in: TransaccionAbonoCreate,
) -> Transaccion:
    monto = Decimal(str(transaccion_in.monto))
    if monto <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El monto de abono debe ser mayor que cero.",
        )

    transaccion = Transaccion(
        owner_id=owner_id,
        cliente_id=cliente.id,
        tipo="abono",
        monto=monto,
        metodo_pago_id=transaccion_in.metodo_pago_id,
    )
    db.add(transaccion)

    await db.commit()
    await db.refresh(transaccion)
    return transaccion
