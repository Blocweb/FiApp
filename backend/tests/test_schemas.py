import pytest
from pydantic import ValidationError

from src.app.schemas.cliente import ClienteCreate
from src.app.schemas.transaccion import TransaccionFiadoCreate


def test_cliente_create_accepts_frontend_aliases():
    cliente = ClienteCreate(name="Ana", phone="3001234567")

    assert cliente.nombre == "Ana"
    assert cliente.telefono == "3001234567"


def test_fiado_requires_amount_to_match_items():
    with pytest.raises(ValidationError):
        TransaccionFiadoCreate(
            cliente_id="client-id",
            monto="10.00",
            items=[
                {
                    "nombre_producto": "Arroz",
                    "cantidad": 2,
                    "precio_unitario": "8.00",
                }
            ],
        )

def test_cliente_update_aliases():
    from src.app.schemas.cliente import ClienteUpdate
    cliente = ClienteUpdate(name="Carlos", phone="3119876543", colorHex="#10B981")
    assert cliente.nombre == "Carlos"
    assert cliente.telefono == "3119876543"
    assert cliente.color_hex == "#10B981"


def test_abono_create_schema():
    from src.app.schemas.transaccion import TransaccionAbonoCreate
    abono = TransaccionAbonoCreate(cliente_id="c123", monto="50.00", metodo_pago_nombre="Efectivo")
    assert abono.cliente_id == "c123"
    assert float(abono.monto) == 50.00
    assert abono.metodo_pago_nombre == "Efectivo"
