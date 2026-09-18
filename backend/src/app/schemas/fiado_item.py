from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class FiadoItemBase(BaseModel):
    producto_id: UUID | None = None
    nombre_producto: str = Field(..., max_length=150)
    cantidad: int = Field(1, gt=0)
    precio_unitario: Decimal = Field(..., gt=0)


class FiadoItemCreate(FiadoItemBase):
    pass


class FiadoItemResponse(FiadoItemBase):
    id: UUID
    precio_unitario: float
    subtotal: float

    model_config = ConfigDict(from_attributes=True)
