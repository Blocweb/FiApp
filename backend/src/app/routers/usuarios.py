"""Gestión de usuarios y roles del negocio (HU01).

Solo el propietario y los administradores acceden a estas rutas (T05).
"""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.core.permissions import require_admin
from src.app.core.tenant_context import TenantContext
from src.app.database.connection import get_db
from src.app.schemas.usuario import UsuarioCreate, UsuarioResponse, UsuarioUpdate
from src.app.services.usuario_service import (
    actualizar_usuario,
    crear_usuario,
    get_usuario,
    listar_usuarios,
    to_usuario_response,
)

router = APIRouter(prefix="/usuarios", tags=["usuarios"])


@router.get("/", response_model=list[UsuarioResponse])
async def listar(
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(require_admin),
):
    membresias = await listar_usuarios(db, contexto.tenant_id)
    return [to_usuario_response(m, contexto) for m in membresias]


@router.post("/", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED)
async def crear(
    datos: UsuarioCreate,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(require_admin),
):
    membresia = await crear_usuario(db, contexto, datos)
    return to_usuario_response(membresia, contexto)


@router.patch("/{membresia_id}", response_model=UsuarioResponse)
async def actualizar(
    membresia_id: UUID,
    cambios: UsuarioUpdate,
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(require_admin),
):
    membresia = await get_usuario(db, contexto.tenant_id, membresia_id)
    if membresia is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    membresia = await actualizar_usuario(db, contexto, membresia, cambios)
    return to_usuario_response(membresia, contexto)
