import logging

from fastapi import APIRouter, Depends

from src.app.schemas.perfil import PerfilResponse
from src.app.services.auth_service import get_current_profile

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api", tags=["api"])


@router.get("/profile", response_model=PerfilResponse)
async def obtener_perfil_api(profile=Depends(get_current_profile)):
    logger.warning(
        "[TEMP AUTH DEBUG] GET /api/profile response profile.id=%s profile.email=%s",
        profile.id,
        profile.email,
    )
    return {
        "id": str(profile.id),
        "nombre_negocio": profile.nombre_negocio,
        "email": profile.email,
        "plan": profile.plan,
        "rol": profile.rol,
        "modo_oscuro": profile.modo_oscuro,
        "respaldo_nube": profile.respaldo_nube,
        "created_at": profile.created_at,
        "updated_at": profile.updated_at,
    }
