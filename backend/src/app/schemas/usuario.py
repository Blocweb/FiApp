"""Esquemas de la gestión de usuarios del negocio (HU01)."""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

RolAsignable = Literal["administrador", "cobrador"]


class UsuarioCreate(BaseModel):
    """Datos para crear la cuenta propia de un trabajador (T03)."""

    nombre: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=72)
    rol: RolAsignable = "cobrador"

    @field_validator("nombre")
    @classmethod
    def _limpiar_nombre(cls, value: str) -> str:
        value = " ".join(value.split())
        if len(value) < 2:
            raise ValueError("El nombre es obligatorio")
        return value

    @field_validator("email")
    @classmethod
    def _normalizar_email(cls, value: str) -> str:
        return value.strip().lower()


class UsuarioUpdate(BaseModel):
    """Cambios permitidos sobre la membresía: activar/desactivar y rol."""

    activo: bool | None = None
    rol: RolAsignable | None = None


class UsuarioResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID = Field(..., description="Id de la membresía en tenant_usuarios")
    profile_id: UUID
    nombre: str | None
    email: str
    rol: str
    activo: bool
    es_usted: bool = False
    created_at: datetime
