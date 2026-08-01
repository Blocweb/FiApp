from sqlalchemy import CheckConstraint, Column, Computed, ForeignKey, Integer, Numeric, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class FiadoItem(Base):
    __tablename__ = "fiado_items"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    transaccion_id = Column(UUID(as_uuid=True), ForeignKey("transacciones.id", ondelete="CASCADE"), nullable=False)
    producto_id = Column(UUID(as_uuid=True), ForeignKey("productos.id", ondelete="SET NULL"), nullable=True)
    nombre_producto = Column(String(150), nullable=False)
    cantidad = Column(Integer, nullable=False, server_default=text("1"))
    precio_unitario = Column(Numeric(12, 2), nullable=False)
    subtotal = Column(Numeric(12, 2), Computed("cantidad * precio_unitario", persisted=True))

    transaccion = relationship("Transaccion", back_populates="fiado_items")

    __table_args__ = (
        CheckConstraint("cantidad > 0", name="chk_fiado_items_cantidad"),
        CheckConstraint("precio_unitario > 0", name="chk_fiado_items_precio_unitario"),
    )
