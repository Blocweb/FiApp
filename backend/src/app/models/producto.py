from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Numeric, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class Producto(Base):
    __tablename__ = "productos"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="RESTRICT"), nullable=False)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    nombre = Column(String(150), nullable=False)
    descripcion = Column(Text, nullable=False, server_default=text("''"))
    precio = Column(Numeric(12, 2), nullable=False)
    activo = Column(Boolean, nullable=False, server_default=text("true"))
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    deleted_at = Column(DateTime(timezone=True))

    tenant = relationship("Tenant", back_populates="productos")
    owner = relationship("Profile", back_populates="productos")