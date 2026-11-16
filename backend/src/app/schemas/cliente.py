import re
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

_IDENTIFICACION_RE = re.compile(r"^[0-9A-Z-]{5,20}$")


def normalizar_identificacion(value: str | None) -> str | None:
    """Quita puntos y espacios y pasa a mayúsculas (ej. '1.036.123 456' -> '1036123456')."""
    if value is None:
        return None
    limpio = re.sub(r"[\s.]", "", value).upper()
    if not limpio:
        return None
    if not _IDENTIFICACION_RE.match(limpio):
        raise ValueError("La identificación debe tener entre 5 y 20 dígitos, letras o guiones")
    return limpio


class ClienteBase(BaseModel):
    nombre: str = Field(..., alias='name', min_length=1, max_length=150)
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
    """Registro de un cliente nuevo (HU02 · T08, T11, T12).

    Exige el nombre real, la identificación, un teléfono de contacto y la
    autorización del cliente para el tratamiento de sus datos (Ley 1581 de 2012).
    """

    identificacion: str = Field(..., alias='identification', max_length=30)
    telefono: str = Field(..., alias='phone', min_length=7, max_length=30)
    autoriza_datos: bool = Field(..., alias='dataConsent')

    @field_validator('nombre')
    @classmethod
    def _limpiar_nombre(cls, value: str) -> str:
        value = ' '.join(value.split())
        if not value:
            raise ValueError('El nombre es obligatorio')
        return value

    @field_validator('identificacion')
    @classmethod
    def _validar_identificacion(cls, value: str) -> str:
        limpio = normalizar_identificacion(value)
        if limpio is None:
            raise ValueError('La identificación es obligatoria')
        return limpio

    @field_validator('telefono')
    @classmethod
    def _validar_telefono(cls, value: str) -> str:
        value = value.strip()
        if len(re.sub(r'\D', '', value)) < 7:
            raise ValueError('El teléfono debe tener al menos 7 dígitos')
        return value

    @field_validator('autoriza_datos')
    @classmethod
    def _exigir_autorizacion(cls, value: bool) -> bool:
        if not value:
            raise ValueError('El cliente debe autorizar el tratamiento de sus datos (Ley 1581 de 2012)')
        return value


class ClienteUpdate(BaseModel):
    nombre: Optional[str] = Field(None, alias='name', min_length=1, max_length=150)
    identificacion: Optional[str] = Field(None, alias='identification', max_length=30)
    telefono: Optional[str] = Field(None, alias='phone', max_length=30)
    direccion: Optional[str] = Field(None, alias='address', max_length=255)
    notas: Optional[str] = Field(None, alias='notes', max_length=2000)
    color_hex: Optional[str] = Field(
        None,
        alias='colorHex',
        pattern=r'^#[0-9A-Fa-f]{6}$',
    )
    # Permite registrar la autorización de clientes creados antes de HU02.
    autoriza_datos: Optional[bool] = Field(None, alias='dataConsent')

    model_config = ConfigDict(populate_by_name=True, extra='ignore')

    @field_validator('identificacion')
    @classmethod
    def _validar_identificacion(cls, value: Optional[str]) -> Optional[str]:
        return normalizar_identificacion(value)

    @field_validator('autoriza_datos')
    @classmethod
    def _no_revocar(cls, value: Optional[bool]) -> Optional[bool]:
        if value is False:
            raise ValueError('La autorización de datos solo se puede registrar, no revocar desde la app')
        return value


class ClienteResponse(ClienteBase):
    id: str
    identificacion: Optional[str] = Field(None, alias='identification')
    autoriza_datos: bool = Field(False, alias='dataConsent')
    autoriza_datos_en: Optional[datetime] = Field(None, alias='dataConsentAt')
    saldo: float = Field(..., alias='balance')
    ultimo_movimiento_en: Optional[datetime] = Field(None, alias='lastMovement')
    created_at: datetime = Field(..., alias='createdAt')
    updated_at: datetime = Field(..., alias='updatedAt')

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )
