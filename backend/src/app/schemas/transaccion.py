from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from src.app.schemas.fiado_item import FiadoItemBase, FiadoItemResponse


class TransaccionBase(BaseModel):
    cliente_id: str
    monto: Decimal = Field(..., gt=0)
    nota: Optional[str] = None


class TransaccionFiadoCreate(TransaccionBase):
    items: list[FiadoItemBase] = Field(..., min_length=1)

    @model_validator(mode='after')
    def validate_total(self):
        total = sum((item.cantidad * item.precio_unitario for item in self.items), Decimal('0'))
        if self.monto != total:
            raise ValueError('El monto debe coincidir con la suma de los productos.')
        return self


class TransaccionAbonoCreate(TransaccionBase):
    metodo_pago_id: int | None = Field(None, gt=0)
    metodo_pago_nombre: str | None = Field(None, min_length=1, max_length=40)

    @model_validator(mode='after')
    def validate_payment_method(self):
        if self.metodo_pago_id is None and self.metodo_pago_nombre is None:
            raise ValueError('Debes indicar un método de pago.')
        if self.metodo_pago_id is not None and self.metodo_pago_nombre is not None:
            raise ValueError('Indica el método de pago por id o por nombre, no ambos.')
        return self


class TransaccionResponse(BaseModel):
    id: UUID
    cliente_id: UUID
    tipo: str
    monto: float
    metodo_pago_id: int | None = None
    nota: Optional[str] = None
    saldo_posterior: float
    fecha_hora: datetime
    created_at: datetime
    deleted_at: Optional[datetime] = None
    items: list[FiadoItemResponse] = Field(
        default_factory=list,
        validation_alias='fiado_items',
    )

    model_config = ConfigDict(from_attributes=True)


TransaccionFiadoCreate.model_rebuild()
TransaccionResponse.model_rebuild()
