from sqlalchemy import CHAR, CheckConstraint, Column, DateTime, JSON, String, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class Tenant(Base):
    __tablename__ = "tenants"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    nombre_comercial = Column(String(150), nullable=False)
    identificacion_fiscal = Column(String(50))
    moneda = Column(CHAR(3), nullable=False, server_default=text("'COP'"))
    telefono = Column(String(30))
    estado = Column(String(20), nullable=False, server_default=text("'activo'"))
    configuracion = Column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=False,
        server_default=text("'{\"dias_gracia\": 0, \"interes_mora_defecto\": 0.0}'"),
    )
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))

    usuarios = relationship("TenantUsuario", back_populates="tenant", cascade="all, delete-orphan")
    clientes = relationship("Cliente", back_populates="tenant")
    productos = relationship("Producto", back_populates="tenant")
    transacciones = relationship("Transaccion", back_populates="tenant")
    exportaciones = relationship("Exportacion", back_populates="tenant")
    auditorias = relationship("Auditoria", back_populates="tenant")

    __table_args__ = (
        CheckConstraint(
            "estado IN ('activo', 'suspendido', 'mora', 'cancelado')",
            name="chk_tenants_estado",
        ),
    )
