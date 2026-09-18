from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ClienteBase(BaseModel):
    nombre: str = Field(..., alias='name', max_length=150)
    telefono: Optional[str] = Field('', alias='phone', max_length=30)
    direccion: Optional[str] = Field('', alias='address', max_length=255)
    notas: Optional[str] = Field('', alias='notes', max_length=2000)
    color_hex: Optional[str] = Field(
        '#2563EB',
        alias='colorHex',
        pattern=r'^#[0-9A-Fa-f]{6}$',
    )

    model_config = ConfigDict(from_attributes=True, populate_by_name=True, extra='ignore')


class ClienteCreate(ClienteBase):
    pass


class ClienteUpdate(BaseModel):
    nombre: Optional[str] = Field(None, alias='name', max_length=150)
    telefono: Optional[str] = Field(None, alias='phone', max_length=30)
    direccion: Optional[str] = Field(None, alias='address', max_length=255)
    notas: Optional[str] = Field(None, alias='notes', max_length=2000)
    color_hex: Optional[str] = Field(
        None,
        alias='colorHex',
        pattern=r'^#[0-9A-Fa-f]{6}$',
    )

    model_config = ConfigDict(populate_by_name=True, extra='ignore')


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
