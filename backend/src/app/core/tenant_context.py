"""Contexto de tenant resuelto y validado para una petición.

El contexto se construye ÚNICAMENTE después de comprobar, en este orden:

    JWT validado por Supabase
        ↓
    profile autenticado
        ↓
    tenant solicitado (X-Tenant-ID)
        ↓
    membresía activa en tenant_usuarios
        ↓
    rol dentro del tenant

El rol de autorización procede exclusivamente de `tenant_usuarios.rol`.
`profiles.rol` nunca se utiliza para autorizar el acceso a un tenant.
"""

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from src.app.models.profile import Profile
from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario


@dataclass(frozen=True, slots=True)
class UsuarioAutenticado:
    """Identidad procedente del token validado por Supabase Auth."""

    id: UUID
    email: str | None = None


@dataclass(frozen=True, slots=True)
class TenantContext:
    """Resultado de la resolución centralizada del tenant para una petición.

    Representa al usuario autenticado, su profile, el tenant seleccionado, la
    membresía que lo vincula y el rol efectivo dentro de ese tenant.
    """

    usuario: UsuarioAutenticado
    profile: Profile
    tenant: Tenant
    membresia: TenantUsuario
    rol: str
    resuelto_en: datetime

    @property
    def tenant_id(self) -> UUID:
        return self.tenant.id

    @property
    def profile_id(self) -> UUID:
        return self.profile.id

    @property
    def membresia_id(self) -> UUID:
        return self.membresia.id
