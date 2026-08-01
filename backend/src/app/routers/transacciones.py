from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.database.connection import get_db
from src.app.schemas.transaccion import (
    TransaccionAbonoCreate,
    TransaccionFiadoCreate,
    TransaccionResponse,
)
from src.app.services.auth_service import get_current_profile
from src.app.services.cliente_service import get_cliente_by_id
from src.app.services.transaccion_service import (
    create_abono,
    create_fiado,
    get_transacciones_por_cliente,
)

router = APIRouter(prefix="/transacciones", tags=["transacciones"])


@router.post("/fiado", response_model=TransaccionResponse, status_code=status.HTTP_201_CREATED)
async def crear_fiado(
    datos: TransaccionFiadoCreate,
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    cliente = await get_cliente_by_id(db, cliente_id=datos.cliente_id, owner_id=str(profile.id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    transaccion = await create_fiado(db, owner_id=str(profile.id), cliente=cliente, transaccion_in=datos)
    return transaccion


@router.post("/abono", response_model=TransaccionResponse, status_code=status.HTTP_201_CREATED)
async def crear_abono(
    datos: TransaccionAbonoCreate,
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    cliente = await get_cliente_by_id(db, cliente_id=datos.cliente_id, owner_id=str(profile.id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    transaccion = await create_abono(db, owner_id=str(profile.id), cliente=cliente, transaccion_in=datos)
    return transaccion


@router.get("/cliente/{cliente_id}", response_model=list[TransaccionResponse])
async def transacciones_por_cliente(
    cliente_id: str,
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    transacciones = await get_transacciones_por_cliente(db, cliente_id=cliente_id, owner_id=str(profile.id))
    return transacciones
