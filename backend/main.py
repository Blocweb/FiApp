from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.app.routers.clientes import router as clientes_router
from src.app.routers.reportes import router as reportes_router
from src.app.routers.transacciones import router as transacciones_router
from src.app.routers.perfil import router as perfil_router
from src.app.routers.api.profile import router as api_profile_router

app = FastAPI(title="FiApp API", version="1.0.0")


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    print('Request validation failed:')
    print('URL:', request.url)
    try:
        body = await request.json()
        print('Body:', body)
    except Exception:
        print('Body: <unreadable>')
    print('Errors:', exc.errors())
    return JSONResponse(
        status_code=422,
        content={
            'detail': exc.errors(),
            'body': body if 'body' in locals() else None,
        },
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(clientes_router)
app.include_router(transacciones_router)
app.include_router(reportes_router)
app.include_router(perfil_router)
app.include_router(api_profile_router)


@app.get("/")
async def root():
    return {"message": "FiApp API funcionando"}
