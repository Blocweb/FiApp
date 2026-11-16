from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.core.permissions import require_consulta_global
from src.app.core.tenant_context import TenantContext
from src.app.database.connection import get_db
from src.app.services.reporte_service import get_evolucion_mensual, get_resumen_negocio

router = APIRouter(prefix="/reportes", tags=["reportes"])


@router.get("/resumen")
async def resumen_negocio(
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(require_consulta_global),
):
    return await get_resumen_negocio(db, tenant_id=str(contexto.tenant_id))


@router.get("/evolucion")
async def evolucion_mensual(
    db: AsyncSession = Depends(get_db),
    contexto: TenantContext = Depends(require_consulta_global),
):
    return await get_evolucion_mensual(db, tenant_id=str(contexto.tenant_id))
