from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class PerfilResponse(BaseModel):
    id: UUID
    nombre_negocio: str
    email: EmailStr
    plan: str
    rol: str
    modo_oscuro: bool
    respaldo_nube: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PerfilUpdate(BaseModel):
    nombre_negocio: Optional[str] = Field(None, max_length=150)
    modo_oscuro: Optional[bool] = None
    respaldo_nube: Optional[bool] = None
