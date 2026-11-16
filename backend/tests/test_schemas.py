import pytest
from pydantic import ValidationError

from src.app.schemas.cliente import ClienteCreate
from src.app.schemas.transaccion import TransaccionFiadoCreate


def test_cliente_create_accepts_frontend_aliases():
    cliente = ClienteCreate(
        name="Ana",
        phone="3001234567",
        identification="1.036.123.456",
        dataConsent=True,
    )

    assert cliente.nombre == "Ana"
    assert cliente.telefono == "3001234567"
    assert cliente.identificacion == "1036123456"
    assert cliente.autoriza_datos is True


@pytest.mark.parametrize(
    "cambios",
    [
        {"identification": ""},  # T08: identificación obligatoria
        {"identification": "12"},  # demasiado corta
        {"phone": "123"},  # T11: contacto válido
        {"dataConsent": False},  # T12: Ley 1581 de 2012
        {"name": "   "},  # nombre real obligatorio
    ],
)
def test_cliente_create_rechaza_datos_incompletos(cambios):
    datos = {
        "name": "Ana",
        "phone": "3001234567",
        "identification": "1036123456",
        "dataConsent": True,
    }
    datos.update(cambios)
    with pytest.raises(ValidationError):
        ClienteCreate(**datos)


def test_fiado_rechaza_fecha_futura():
    from datetime import datetime, timedelta, timezone

    with pytest.raises(ValidationError):
        TransaccionFiadoCreate(
            cliente_id="client-id",
            monto="16.00",
            fecha_hora=datetime.now(timezone.utc) + timedelta(days=2),
            items=[{"nombre_producto": "Filtro", "cantidad": 2, "precio_unitario": "8.00"}],
        )


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
