import logging
import os
from typing import Optional

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import httpx

from src.app.database.connection import get_db
from src.app.models.profile import Profile
from src.app.schemas.auth import TokenData

load_dotenv()

logger = logging.getLogger(__name__)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_USER_URL = f"{SUPABASE_URL.rstrip('/')}/auth/v1/user" if SUPABASE_URL else None

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="No autorizado",
    headers={"WWW-Authenticate": "Bearer"},
)


def _debug_access_token_label(token: str) -> str:
    if not token:
        return "<none>"
    if len(token) <= 24:
        return token
    return f"{token[:12]}...{token[-8:]} (len={len(token)})"


async def validate_supabase_token(token: str) -> TokenData:
    if not SUPABASE_USER_URL or not SUPABASE_ANON_KEY:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="SUPABASE_URL o SUPABASE_ANON_KEY no están configurados",
        )

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                SUPABASE_USER_URL,
                headers={
                    "apikey": SUPABASE_ANON_KEY,
                    "Authorization": f"Bearer {token}",
                },
            )
    except httpx.HTTPError:
        raise credentials_exception

    if response.status_code != 200:
        raise credentials_exception

    try:
        payload = response.json()
        sub = payload.get("id") or payload.get("sub")
        email = payload.get("email")
        if sub is None:
            raise credentials_exception
        logger.warning(
            "[TEMP AUTH DEBUG] Supabase /auth/v1/user email=%s uuid=%s accessToken=%s",
            email,
            sub,
            _debug_access_token_label(token),
        )
        return TokenData(sub=sub, email=email)
    except ValueError:
        raise credentials_exception


async def get_current_profile(
    request: Request,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> Profile:
    token_data = await validate_supabase_token(token)
    if request.url.path == "/api/profile":
        logger.warning(
            "[TEMP AUTH DEBUG] GET /api/profile token.email=%s token.uuid=%s accessToken=%s",
            token_data.email,
            token_data.sub,
            _debug_access_token_label(token),
        )
    query = select(Profile).where(Profile.id == token_data.sub)
    result = await db.execute(query)
    profile = result.scalars().first()
    if profile is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Perfil no encontrado")
    if request.url.path == "/api/profile":
        logger.warning(
            "[TEMP AUTH DEBUG] GET /api/profile db profile.id=%s profile.email=%s",
            profile.id,
            profile.email,
        )
    return profile


async def update_profile(
    profile: Profile,
    nombre_negocio: Optional[str],
    modo_oscuro: Optional[bool],
    respaldo_nube: Optional[bool],
    db: AsyncSession,
) -> Profile:
    if nombre_negocio is not None:
        profile.nombre_negocio = nombre_negocio
    if modo_oscuro is not None:
        profile.modo_oscuro = modo_oscuro
    if respaldo_nube is not None:
        profile.respaldo_nube = respaldo_nube

    await db.commit()
    await db.refresh(profile)
    return profile
