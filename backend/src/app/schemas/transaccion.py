from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

from src.app.schemas.fiado_item import FiadoItemBase, FiadoItemResponse


class TransaccionBase(BaseModel):
    cliente_id: str
    monto: float = Field(..., gt=0)
    nota: Optional[str] = None


class TransaccionFiadoCreate(TransaccionBase):
    items: List[FiadoItemBase] = []


class TransaccionAbonoCreate(TransaccionBase):
    metodo_pago_id: int


class TransaccionResponse(BaseModel):
    id: str
    cliente_id: str
    tipo: str
    monto: float
    metodo_pago_id: int | None = None
    nota: Optional[str] = None
    saldo_posterior: float
    fecha_hora: datetime
    created_at: datetime
    deleted_at: Optional[datetime] = None
    items: Optional[List[FiadoItemResponse]] = None

    model_config = ConfigDict(from_attributes=True)


TransaccionFiadoCreate.update_forward_refs()
TransaccionResponse.update_forward_refs()
