from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.database.connection import get_db
from src.app.schemas.perfil import PerfilResponse, PerfilUpdate
from src.app.services.auth_service import get_current_profile, update_profile

router = APIRouter(prefix="/perfil", tags=["perfil"])


@router.get("/", response_model=PerfilResponse)
async def obtener_perfil(profile=Depends(get_current_profile)):
    return profile


@router.put("/", response_model=PerfilResponse)
async def actualizar_perfil(
    perfil_in: PerfilUpdate,
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    return await update_profile(
        profile=profile,
        nombre_negocio=perfil_in.nombre_negocio,
        modo_oscuro=perfil_in.modo_oscuro,
        respaldo_nube=perfil_in.respaldo_nube,
        db=db,
        nombre=perfil_in.nombre,
    )
