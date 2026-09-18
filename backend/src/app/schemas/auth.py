from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class TokenData(BaseModel):
    """Identidad autenticada derivada del token validado por Supabase.

    `sub` es obligatorio y tipado como UUID porque corresponde al identificador
    del usuario en Supabase Auth, que es la clave de `public.profiles`.
    """

    model_config = ConfigDict(from_attributes=True)

    sub: UUID
    email: Optional[str] = None
