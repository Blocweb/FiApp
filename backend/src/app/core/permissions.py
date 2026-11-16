"""Control de acceso por rol (HU01 · T05).

El rol efectivo sale siempre de ``tenant_usuarios.rol`` (vía ``TenantContext``).
El backend se conecta a PostgreSQL con un rol que ignora RLS, así que estas
reglas se aplican aquí, en la API, antes de tocar los datos.

Correspondencia con el backlog:
    administrador del backlog -> ``propietario`` o ``administrador``
    trabajador del backlog    -> ``cobrador`` (y ``supervisor`` para consulta)
"""

from collections.abc import Callable

from fastapi import Depends, HTTPException, status

from src.app.core.tenant_context import TenantContext
from src.app.dependencies.tenant import get_current_tenant_context

ROL_PROPIETARIO = "propietario"
ROL_ADMINISTRADOR = "administrador"
ROL_SUPERVISOR = "supervisor"
ROL_COBRADOR = "cobrador"

ROLES_ADMIN: frozenset[str] = frozenset({ROL_PROPIETARIO, ROL_ADMINISTRADOR})
"""Ven toda la información del negocio y gestionan usuarios."""

ROLES_CONSULTA_GLOBAL: frozenset[str] = ROLES_ADMIN | {ROL_SUPERVISOR}
"""Pueden consultar los movimientos y reportes de todo el negocio."""

ROLES_ASIGNABLES: frozenset[str] = frozenset({ROL_ADMINISTRADOR, ROL_COBRADOR})
"""Roles que se pueden asignar desde la gestión de usuarios."""


def es_admin(contexto: TenantContext) -> bool:
    return contexto.rol in ROLES_ADMIN


def ve_todo_el_negocio(contexto: TenantContext) -> bool:
    return contexto.rol in ROLES_CONSULTA_GLOBAL


def require_roles(*roles: str) -> Callable[..., TenantContext]:
    """Dependencia que exige que el usuario tenga uno de los ``roles``."""
    permitidos = frozenset(roles)

    async def _dependencia(
        contexto: TenantContext = Depends(get_current_tenant_context),
    ) -> TenantContext:
        if contexto.rol not in permitidos:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Su rol no tiene permiso para esta acción",
            )
        return contexto

    return _dependencia


require_admin = require_roles(*ROLES_ADMIN)
require_consulta_global = require_roles(*ROLES_CONSULTA_GLOBAL)
