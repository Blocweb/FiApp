from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.database.connection import get_db
from src.app.models.cliente import Cliente
from src.app.schemas.cliente import ClienteCreate, ClienteResponse, ClienteUpdate
from src.app.services.auth_service import get_current_profile
from src.app.services.cliente_service import (
    create_cliente,
    get_cliente_by_id,
    get_clientes,
    update_cliente,
)

router = APIRouter(prefix="/clientes", tags=["clientes"])


def _to_cliente_response(cliente: Cliente) -> ClienteResponse:
    return ClienteResponse.model_validate(
        {
            "id": str(cliente.id),
            "name": cliente.nombre,
            "phone": cliente.telefono,
            "address": cliente.direccion,
            "notes": cliente.notas,
            "colorHex": cliente.color_hex,
            "balance": float(cliente.saldo),
            "lastMovement": cliente.ultimo_movimiento_en,
            "createdAt": cliente.created_at,
            "updatedAt": cliente.updated_at,
        }
    )


@router.get("/", response_model=list[ClienteResponse])
async def listar_clientes(
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    clientes = await get_clientes(db, owner_id=str(profile.id))
    return [_to_cliente_response(c) for c in clientes]


@router.post("/", response_model=ClienteResponse, status_code=status.HTTP_201_CREATED)
async def crear_cliente(
    cliente_in: ClienteCreate,
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    cliente = await create_cliente(db, owner_id=str(profile.id), cliente_in=cliente_in)
    return _to_cliente_response(cliente)


@router.get("/{id}", response_model=ClienteResponse)
async def obtener_cliente(
    id: str,
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    cliente = await get_cliente_by_id(db, cliente_id=id, owner_id=str(profile.id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    return _to_cliente_response(cliente)


@router.put("/{id}", response_model=ClienteResponse)
async def actualizar_cliente(
    id: str,
    cliente_in: ClienteUpdate,
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    cliente = await get_cliente_by_id(db, cliente_id=id, owner_id=str(profile.id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    cliente = await update_cliente(db, cliente=cliente, cliente_in=cliente_in)
    return _to_cliente_response(cliente)
