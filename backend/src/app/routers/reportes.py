from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.database.connection import get_db
from src.app.services.auth_service import get_current_profile
from src.app.services.reporte_service import get_evolucion_mensual, get_resumen_negocio

router = APIRouter(prefix="/reportes", tags=["reportes"])


@router.get("/resumen")
async def resumen_negocio(
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    return await get_resumen_negocio(db, owner_id=str(profile.id))


@router.get("/evolucion")
async def evolucion_mensual(
    db: AsyncSession = Depends(get_db),
    profile=Depends(get_current_profile),
):
    return await get_evolucion_mensual(db, owner_id=str(profile.id))
