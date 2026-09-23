from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.core.tenant_context import TenantContext
from src.app.database.connection import get_db
from src.app.dependencies.tenant import get_current_tenant_context
from src.app.schemas.transaccion import (
    TransaccionAbonoCreate,
    TransaccionFiadoCreate,
    TransaccionResponse,
)
from src.app.services.cliente_service import get_cliente_by_id
from src.app.services.transaccion_service import (
    create_abono,
    create_fiado,
    get_transacciones,
    get_transacciones_por_cliente,
)

router = APIRouter(prefix="/transacciones", tags=["transacciones"])


@router.get("/", response_model=list[TransaccionResponse])
async def listar_transacciones(
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(get_current_tenant_context),
):
    return await get_transacciones(db, tenant_id=str(contexto.tenant_id))


@router.post("/fiado", response_model=TransaccionResponse, status_code=status.HTTP_201_CREATED)
async def crear_fiado(
    datos: TransaccionFiadoCreate,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(get_current_tenant_context),
):
    cliente = await get_cliente_by_id(db, cliente_id=datos.cliente_id, tenant_id=str(contexto.tenant_id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    transaccion = await create_fiado(
        db,
        tenant_id=str(contexto.tenant_id),
        owner_id=str(contexto.profile_id),
        cliente=cliente,
        transaccion_in=datos,
    )
    return transaccion


@router.post("/abono", response_model=TransaccionResponse, status_code=status.HTTP_201_CREATED)
async def crear_abono(
    datos: TransaccionAbonoCreate,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(get_current_tenant_context),
):
    cliente = await get_cliente_by_id(db, cliente_id=datos.cliente_id, tenant_id=str(contexto.tenant_id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    transaccion = await create_abono(
        db,
        tenant_id=str(contexto.tenant_id),
        owner_id=str(contexto.profile_id),
        cliente=cliente,
        transaccion_in=datos,
    )
    return transaccion


@router.get("/cliente/{cliente_id}", response_model=list[TransaccionResponse])
async def transacciones_por_cliente(
    cliente_id: str,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(get_current_tenant_context),
):
    cliente = await get_cliente_by_id(db, cliente_id=cliente_id, tenant_id=str(contexto.tenant_id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    transacciones = await get_transacciones_por_cliente(
        db,
        cliente_id=cliente_id,
        tenant_id=str(contexto.tenant_id),
    )
    return transacciones
