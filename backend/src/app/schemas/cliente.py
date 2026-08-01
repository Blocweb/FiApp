from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ClienteBase(BaseModel):
    nombre: str = Field(..., alias='name', max_length=150)
    telefono: Optional[str] = Field('', alias='phone', max_length=30)
    direccion: Optional[str] = Field('', alias='address', max_length=255)
    notas: Optional[str] = Field('', alias='notes', max_length=2000)
    color_hex: Optional[str] = Field('#2563EB', alias='colorHex', min_length=7, max_length=7)

    model_config = ConfigDict(from_attributes=True, populate_by_name=True, extra='ignore')


class ClienteCreate(ClienteBase):
    pass


class ClienteUpdate(ClienteBase):
    nombre: Optional[str]
    telefono: Optional[str]
    direccion: Optional[str]
    notas: Optional[str]
    color_hex: Optional[str]


class ClienteResponse(ClienteBase):
    id: str
    saldo: float = Field(..., alias='balance')
    ultimo_movimiento_en: Optional[datetime] = Field(None, alias='lastMovement')
    created_at: datetime = Field(..., alias='createdAt')
    updated_at: datetime = Field(..., alias='updatedAt')

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )
