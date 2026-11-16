import logging

from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.core.config import get_settings
from src.app.database.connection import get_db
from src.app.routers.clientes import router as clientes_router
from src.app.routers.perfil import router as perfil_router
from src.app.routers.reportes import router as reportes_router
from src.app.routers.tenants import router as tenants_router
from src.app.routers.transacciones import router as transacciones_router
from src.app.routers.usuarios import router as usuarios_router
logger = logging.getLogger(__name__)
settings = get_settings()

app = FastAPI(title="FiApp API", version="1.0.0")


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.info(
        "Validation rejected for %s %s (%s errors)",
        request.method,
        request.url.path,
        len(exc.errors()),
    )
    return JSONResponse(status_code=422, content={"detail": _errores_serializables(exc.errors())})


def _errores_serializables(errores) -> list[dict]:
    """Convierte el contexto de los errores de validación a texto.

    Pydantic incluye la excepción original (``ctx.error``) cuando un validador
    lanza ``ValueError``; sin esta conversión la respuesta 422 fallaba con 500.
    """
    resultado = []
    for error in errores:
        error = dict(error)
        if "ctx" in error:
            error["ctx"] = {clave: str(valor) for clave, valor in error["ctx"].items()}
        error.pop("url", None)
        resultado.append(error)
    return resultado


app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(clientes_router)
app.include_router(transacciones_router)
app.include_router(reportes_router)
app.include_router(perfil_router)
app.include_router(tenants_router)
app.include_router(usuarios_router)

@app.get("/")
async def root():
    return {"message": "FiApp API funcionando"}


@app.get("/health", tags=["health"])
async def healthcheck(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
    except SQLAlchemyError as exc:
        logger.warning("Database health check failed: %s", exc.__class__.__name__)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database unavailable",
        ) from None

    return {"status": "ok"}
