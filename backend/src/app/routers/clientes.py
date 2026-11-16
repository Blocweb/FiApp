from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.core.permissions import es_admin
from src.app.core.tenant_context import TenantContext
from src.app.database.connection import get_db
from src.app.dependencies.tenant import get_current_tenant_context
from src.app.models.cliente import Cliente
from src.app.schemas.cliente import ClienteCreate, ClienteResponse, ClienteUpdate
from src.app.services.cliente_service import (
    ClienteDuplicadoError,
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
            "identification": cliente.identificacion,
            "phone": cliente.telefono,
            "address": cliente.direccion,
            "notes": cliente.notas,
            "colorHex": cliente.color_hex,
            "dataConsent": bool(cliente.autoriza_datos),
            "dataConsentAt": cliente.autoriza_datos_en,
            "balance": float(cliente.saldo),
            "lastMovement": cliente.ultimo_movimiento_en,
            "createdAt": cliente.created_at,
            "updatedAt": cliente.updated_at,
        }
    )


def _conflicto_duplicado(error: ClienteDuplicadoError) -> HTTPException:
    """HU02 · T10: aviso de que el cliente ya existe, con sus datos básicos."""
    existente = error.existente
    return HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail={
            "code": "cliente_duplicado",
            "message": str(error),
            "cliente_id": str(existente.id) if existente is not None else None,
            "nombre": existente.nombre if existente is not None else None,
        },
    )


@router.get("/", response_model=list[ClienteResponse])
async def listar_clientes(
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
    q: str | None = None,
):
    """Lista los clientes del negocio. `q` busca por nombre o identificación (T13)."""
    filtros = {"busqueda": q} if q and q.strip() else {}
    if profile is not None:
        clientes = await get_clientes(db, owner_id=str(profile.id), **filtros)
        return [_to_cliente_response(c) for c in clientes]

    clientes = await get_clientes(db, tenant_id=str(contexto.tenant_id), **filtros)
    return [_to_cliente_response(c) for c in clientes]


@router.post("/", response_model=ClienteResponse, status_code=status.HTTP_201_CREATED)
async def crear_cliente(
    cliente_in: ClienteCreate,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
):
    try:
        if profile is not None:
            cliente = await create_cliente(
                db,
                owner_id=str(profile.id),
                cliente_in=cliente_in,
            )
        else:
            cliente = await create_cliente(
                db,
                tenant_id=str(contexto.tenant_id),
                owner_id=str(contexto.profile_id),
                cliente_in=cliente_in,
            )
    except ClienteDuplicadoError as error:
        raise _conflicto_duplicado(error) from None
    return _to_cliente_response(cliente)


@router.get("/{id}", response_model=ClienteResponse)
async def obtener_cliente(
    id: str,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
):
    if profile is not None:
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
    if profile is not None:
        cliente = await get_cliente_by_id(db, cliente_id=id, owner_id=str(profile.id))
    else:
        cliente = await get_cliente_by_id(db, cliente_id=id, tenant_id=str(contexto.tenant_id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    try:
        cliente = await update_cliente(db, cliente=cliente, cliente_in=cliente_in)
    except ClienteDuplicadoError as error:
        raise _conflicto_duplicado(error) from None
    return _to_cliente_response(cliente)


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def eliminar_cliente(
    id: str,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext | None = Depends(get_current_tenant_context),
    profile=None,
):
    if profile is not None:
        cliente = await get_cliente_by_id(db, cliente_id=id, owner_id=str(profile.id))
    else:
        # T05: solo el propietario o un administrador eliminan clientes.
        if not es_admin(contexto):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Su rol no tiene permiso para eliminar clientes",
            )
        cliente = await get_cliente_by_id(db, cliente_id=id, tenant_id=str(contexto.tenant_id))
    if cliente is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado")
    if cliente.saldo > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se puede eliminar un cliente con saldo pendiente o deuda activa.",
        )
    await delete_cliente(db, cliente=cliente)
