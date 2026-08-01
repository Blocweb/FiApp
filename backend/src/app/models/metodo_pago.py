from sqlalchemy import Boolean, Column, SmallInteger, String, text
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class MetodoPago(Base):
    __tablename__ = "metodos_pago"

    id = Column(SmallInteger, primary_key=True)
    nombre = Column(String(40), nullable=False, unique=True)
    activo = Column(Boolean, nullable=False, server_default=text("true"))
    orden = Column(SmallInteger, nullable=False, server_default=text("0"))

    transacciones = relationship("Transaccion", back_populates="metodo_pago")
