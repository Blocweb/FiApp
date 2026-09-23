"""Contexto transaccional para futuras políticas RLS de PostgreSQL.

El contexto se origina en un ``TenantContext`` ya validado por FastAPI. Se
almacena únicamente en ``AsyncSession.info`` (estado de una sesión/request), y
se materializa en PostgreSQL mediante ``set_config(..., true)``, equivalente a
``SET LOCAL``. El listener reaplica el valor al comenzar cada nueva
transacción de la misma sesión, lo que cubre el ``autobegin`` de SQLAlchemy
después de un commit sin contaminar conexiones del pool.
"""

from __future__ import annotations
from typing import Any
from sqlalchemy import event, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session
from src.app.core.tenant_context import TenantContext
RLS_TENANT_SETTING = "app.tenant_id"
RLS_USER_SETTING = "app.user_id"
_RLS_CONTEXT_INFO_KEY = "fiapp_rls_context"

_SET_RLS_CONTEXT = text(
    "SELECT set_config(:setting_name, :setting_value, true)"
)


def _context_values(context: TenantContext) -> tuple[str, str]:
    """Extrae IDs únicamente desde el contexto ya autorizado."""
    return str(context.tenant_id), str(context.usuario.id)


def _apply_context(connection: Any, context: TenantContext) -> None:
    """Aplica ambos valores en la transacción actual usando parámetros."""
    tenant_id, user_id = _context_values(context)
    connection.execute(
        _SET_RLS_CONTEXT,
        {"setting_name": RLS_TENANT_SETTING, "setting_value": tenant_id},
    )
    connection.execute(
        _SET_RLS_CONTEXT,
        {"setting_name": RLS_USER_SETTING, "setting_value": user_id},
    )

@event.listens_for(Session, "after_begin")
def _restore_rls_context(
    session: Session,
    transaction: Any,
    connection: Any,
) -> None:
    """Reaplica el contexto al abrir una transacción posterior.

    ``SET LOCAL`` desaparece al terminar la transacción. SQLAlchemy puede abrir
    otra automáticamente después de ``commit()``; reaplicar el contexto aquí
    mantiene el aislamiento durante el resto de la petición, sin usar estado
    global ni dejar valores persistentes en la conexión.
    """
    context = session.info.get(_RLS_CONTEXT_INFO_KEY)
    if context is not None:
        _apply_context(connection, context)

async def set_rls_context(session: AsyncSession, context: TenantContext) -> None:
    """Establece el tenant y usuario autorizados en la transacción actual.

    ``context`` debe proceder de ``get_current_tenant_context``. La función no
    acepta IDs obtenidos del request, body o query string, y no crea ni valida
    membresías por sí misma.
    """
    if not isinstance(context, TenantContext):
        raise TypeError("set_rls_context requiere un TenantContext validado")

    session.info[_RLS_CONTEXT_INFO_KEY] = context
    await session.execute(
        _SET_RLS_CONTEXT,
        {"setting_name": RLS_TENANT_SETTING, "setting_value": str(context.tenant_id)},
    )
    await session.execute(
        _SET_RLS_CONTEXT,
        {"setting_name": RLS_USER_SETTING, "setting_value": str(context.usuario.id)},
    )


def clear_rls_context(session: AsyncSession) -> None:
    """Elimina la referencia Python al contexto al terminar el request."""
    session.info.pop(_RLS_CONTEXT_INFO_KEY, None)
