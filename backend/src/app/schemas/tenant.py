from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class TenantResumen(BaseModel):
    """Información mínima de un tenant para que el cliente seleccione el negocio.

    No expone usuarios, configuración interna ni datos financieros.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    nombre_comercial: str
    estado: str
    rol: str


class TenantListadoResponse(BaseModel):
    """Respuesta de `GET /tenants/`: solo tenants con membresía activa."""

    tenants: list[TenantResumen]


class TenantCurrentResponse(BaseModel):
    """Respuesta de `GET /tenants/current`: contexto del tenant seleccionado."""

    model_config = ConfigDict(from_attributes=True)

    tenant_id: UUID
    nombre_comercial: str
    estado: str
    rol: str
    usuario_id: UUID
    email: str
    membresia_id: UUID
    membresia_activa: bool
    seleccionado_en: datetime
