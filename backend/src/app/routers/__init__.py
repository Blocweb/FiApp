from src.app.routers.clientes import router as clientes_router
from src.app.routers.reportes import router as reportes_router
from src.app.routers.transacciones import router as transacciones_router
from src.app.routers.perfil import router as perfil_router
from src.app.routers.tenants import router as tenants_router
from src.app.routers.usuarios import router as usuarios_router
__all__ = [
    'clientes_router',
    'transacciones_router',
    'reportes_router',
    'perfil_router',
    'tenants_router',
    'usuarios_router',
]
