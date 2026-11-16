from typing import Optional
import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from src.app.core.config import get_settings
from src.app.core.tenant_context import UsuarioAutenticado
from src.app.database.connection import get_db
from src.app.models.profile import Profile
from src.app.schemas.auth import TokenData

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="No autorizado",
    headers={"WWW-Authenticate": "Bearer"},
)


async def validate_supabase_token(token: str) -> TokenData:
    settings = get_settings()
    supabase_user_url = f"{settings.supabase_url.rstrip('/')}/auth/v1/user"

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                supabase_user_url,
                headers={
                    "apikey": settings.supabase_anon_key,
                    "Authorization": f"Bearer {token}",
                },
            )
    except httpx.HTTPError:
        raise credentials_exception from None

    if response.status_code != 200:
        raise credentials_exception

    try:
        payload = response.json()
        sub = payload.get("id") or payload.get("sub")
        email = payload.get("email")
        if sub is None:
            raise credentials_exception
        return TokenData(sub=sub, email=email)
    except ValueError:
        raise credentials_exception from None


async def get_current_user(
    token: str = Depends(oauth2_scheme),
) -> UsuarioAutenticado:
    """Resuelve la identidad autenticada validando el token con Supabase Auth.

    No accede a la base de datos local: devuelve únicamente la identidad
    derivada del token. Nunca registra el token ni datos sensibles en logs.
    """
    token_data = await validate_supabase_token(token)
    return UsuarioAutenticado(id=token_data.sub, email=token_data.email)

async def get_current_profile(
    usuario: UsuarioAutenticado = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Profile:
    """Perfil del usuario autenticado.

    Se mantiene compatible con los routers existentes y reutiliza
    `get_current_user()`, de modo que la validación del token con Supabase se
    efectúa una sola vez por petición.
    """
    query = select(Profile).where(Profile.id == usuario.id)
    result = await db.execute(query)
    profile = result.scalars().first()
    if profile is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Perfil no encontrado")
    return profile


async def update_profile(
    profile: Profile,
    nombre_negocio: Optional[str],
    modo_oscuro: Optional[bool],
    respaldo_nube: Optional[bool],
    db: AsyncSession,
    nombre: Optional[str] = None,
) -> Profile:
    if nombre_negocio is not None:
        profile.nombre_negocio = nombre_negocio
    if nombre is not None:
        profile.nombre = nombre.strip() or None
    if modo_oscuro is not None:
        profile.modo_oscuro = modo_oscuro
    if respaldo_nube is not None:
        profile.respaldo_nube = respaldo_nube

    await db.commit()
    await db.refresh(profile)
    return profile
