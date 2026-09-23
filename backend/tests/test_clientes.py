import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from src.app.models.cliente import Cliente
from src.app.routers.clientes import (
    crear_cliente,
    eliminar_cliente,
)
from src.app.schemas.cliente import ClienteCreate
from src.app.services.cliente_service import get_clientes


@pytest.mark.anyio
async def test_crear_cliente_derive_owner_id_from_jwt():
    mock_db = AsyncMock()
    mock_profile = MagicMock()
    mock_profile.id = "user-1234-uuid"

    cliente_in = ClienteCreate(name="Juan Pérez", phone="3001234567")

    # Mock create_cliente service
    mock_cliente_obj = MagicMock()
    mock_cliente_obj.id = "cliente-abc-uuid"
    mock_cliente_obj.nombre = "Juan Pérez"
    mock_cliente_obj.telefono = "3001234567"
    mock_cliente_obj.direccion = ""
    mock_cliente_obj.notas = ""
    mock_cliente_obj.color_hex = "#2563EB"
    mock_cliente_obj.saldo = 0
    mock_cliente_obj.ultimo_movimiento_en = None
    mock_cliente_obj.created_at = datetime.now()
    mock_cliente_obj.updated_at = datetime.now()

    from unittest.mock import patch
    with patch("src.app.routers.clientes.create_cliente", new_callable=AsyncMock) as mock_service:
        mock_service.return_value = mock_cliente_obj
        res = await crear_cliente(cliente_in=cliente_in, db=mock_db, profile=mock_profile)

        # Verificar que se pasa owner_id derivado del perfil autenticado
        mock_service.assert_called_once_with(
            mock_db,
            owner_id="user-1234-uuid",
            cliente_in=cliente_in,
        )
        assert res.id == "cliente-abc-uuid"
        assert res.nombre == "Juan Pérez"
        # Comprobar serialización con alias (contrato para Flutter)
        dump = res.model_dump(by_alias=True)
        assert dump["name"] == "Juan Pérez"
        assert dump["phone"] == "3001234567"
        assert dump["balance"] == 0.0
        assert dump["lastMovement"] is None


@pytest.mark.anyio
async def test_get_clientes_filtra_por_tenant_id():
    db = AsyncMock()
    tenant_a = uuid.uuid4()
    tenant_b = uuid.uuid4()

    cliente_a = Cliente(id=uuid.uuid4(), tenant_id=tenant_a, owner_id=uuid.uuid4(), nombre="A")
    cliente_b = Cliente(id=uuid.uuid4(), tenant_id=tenant_b, owner_id=uuid.uuid4(), nombre="B")

    result = MagicMock()
    result.scalars.return_value.all.return_value = [cliente_a]
    db.execute.return_value = result

    clientes = await get_clientes(db, tenant_id=tenant_a)

    assert clientes == [cliente_a]
    db.execute.assert_called_once()


@pytest.mark.anyio
async def test_eliminar_cliente_soft_delete():
    mock_db = AsyncMock()
    mock_profile = MagicMock()
    mock_profile.id = "user-1234-uuid"

    mock_cliente_obj = MagicMock()
    mock_cliente_obj.id = "cliente-abc-uuid"
    mock_cliente_obj.saldo = 0

    from unittest.mock import patch
    with patch("src.app.routers.clientes.get_cliente_by_id", new_callable=AsyncMock) as mock_get, \
         patch("src.app.routers.clientes.delete_cliente", new_callable=AsyncMock) as mock_delete:
        mock_get.return_value = mock_cliente_obj

        await eliminar_cliente(id="cliente-abc-uuid", db=mock_db, profile=mock_profile)

        mock_get.assert_called_once_with(
            mock_db,
            cliente_id="cliente-abc-uuid",
            owner_id="user-1234-uuid",
        )
        mock_delete.assert_called_once_with(mock_db, cliente=mock_cliente_obj)


@pytest.mark.anyio
async def test_eliminar_cliente_con_deuda_retorna_400():
    mock_db = AsyncMock()
    mock_profile = MagicMock()
    mock_profile.id = "user-1234-uuid"

    mock_cliente_obj = MagicMock()
    mock_cliente_obj.id = "cliente-abc-uuid"
    mock_cliente_obj.saldo = 15000.0

    from unittest.mock import patch
    with patch("src.app.routers.clientes.get_cliente_by_id", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = mock_cliente_obj

        with pytest.raises(HTTPException) as exc_info:
            await eliminar_cliente(id="cliente-abc-uuid", db=mock_db, profile=mock_profile)

        assert exc_info.value.status_code == 400
        assert "saldo pendiente" in exc_info.value.detail

