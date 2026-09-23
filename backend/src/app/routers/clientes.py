from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.core.tenant_context import TenantContext
from src.app.database.connection import get_db
from src.app.dependencies.tenant import get_current_tenant_context
from src.app.models.cliente import Cliente
from src.app.schemas.cliente import ClienteCreate, ClienteResponse, ClienteUpdate
from src.app.services.cliente_service import (
    create_cliente,
    delete_cliente,
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
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
):
    if profile is not None or isinstance(contexto, Depends):
        if profile is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Perfil autenticado requerido")
        clientes = await get_clientes(db, owner_id=str(profile.id))
        return [_to_cliente_response(c) for c in clientes]

    clientes = await get_clientes(db, tenant_id=str(contexto.tenant_id))
    return [_to_cliente_response(c) for c in clientes]


@router.post("/", response_model=ClienteResponse, status_code=status.HTTP_201_CREATED)
async def crear_cliente(
    cliente_in: ClienteCreate,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
):
    if profile is not None or isinstance(contexto, Depends):
        if profile is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Perfil autenticado requerido")
        cliente = await create_cliente(
            db,
            owner_id=str(profile.id),
            cliente_in=cliente_in,
        )
        return _to_cliente_response(cliente)

    cliente = await create_cliente(
        db,
        tenant_id=str(contexto.tenant_id),
        owner_id=str(contexto.profile_id),
        cliente_in=cliente_in,
    )
    return _to_cliente_response(cliente)


@router.get("/{id}", response_model=ClienteResponse)
async def obtener_cliente(
    id: str,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
):
    if profile is not None or isinstance(contexto, Depends):
        if profile is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Perfil autenticado requerido")
        cliente = await get_cliente_by_id(db, cliente_id=id, owner_id=str(profile.id))
    else:
        cliente = await get_cliente_by_id(db, cliente_id=id, tenant_id=str(contexto.tenant_id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    return _to_cliente_response(cliente)


@router.put("/{id}", response_model=ClienteResponse)
async def actualizar_cliente(
    id: str,
    cliente_in: ClienteUpdate,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
):
    if profile is not None or isinstance(contexto, Depends):
        if profile is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Perfil autenticado requerido")
        cliente = await get_cliente_by_id(db, cliente_id=id, owner_id=str(profile.id))
    else:
        cliente = await get_cliente_by_id(db, cliente_id=id, tenant_id=str(contexto.tenant_id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    cliente = await update_cliente(db, cliente=cliente, cliente_in=cliente_in)
    return _to_cliente_response(cliente)


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def eliminar_cliente(
    id: str,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
):
    if profile is not None or isinstance(contexto, Depends):
        if profile is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Perfil autenticado requerido")
        cliente = await get_cliente_by_id(db, cliente_id=id, owner_id=str(profile.id))
    else:
        cliente = await get_cliente_by_id(db, cliente_id=id, tenant_id=str(contexto.tenant_id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    if cliente.saldo > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se puede eliminar un cliente con saldo pendiente o deuda activa.",
        )
    await delete_cliente(db, cliente=cliente)
