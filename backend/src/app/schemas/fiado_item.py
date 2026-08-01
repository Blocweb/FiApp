from pydantic import BaseModel, ConfigDict, Field


class FiadoItemBase(BaseModel):
    producto_id: str | None = None
    nombre_producto: str = Field(..., max_length=150)
    cantidad: int = Field(1, gt=0)
    precio_unitario: float = Field(..., gt=0)


class FiadoItemCreate(FiadoItemBase):
    pass


class FiadoItemResponse(FiadoItemBase):
    id: str
    subtotal: float

    model_config = ConfigDict(from_attributes=True)
