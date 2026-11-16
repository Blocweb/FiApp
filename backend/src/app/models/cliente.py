from sqlalchemy import CHAR, Boolean, CheckConstraint, Column, DateTime, ForeignKey, Index, Numeric, String, Text, UniqueConstraint, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class Cliente(Base):
    __tablename__ = "clientes"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="RESTRICT"), nullable=False)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    nombre = Column(String(150), nullable=False)
    telefono = Column(String(30), nullable=False, server_default=text("''"))
    direccion = Column(String(255), nullable=False, server_default=text("''"))
    notas = Column(Text, nullable=False, server_default=text("''"))
    color_hex = Column(CHAR(7), nullable=False, server_default=text("'#2563EB'"))
    # HU02 (T08, T12): identificación y autorización de datos (Ley 1581 de 2012).
    identificacion = Column(String(30))
    autoriza_datos = Column(Boolean, nullable=False, server_default=text("false"))
    autoriza_datos_en = Column(DateTime(timezone=True))
    saldo = Column(Numeric(12, 2), nullable=False, server_default=text("0"))
    ultimo_movimiento_en = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    deleted_at = Column(DateTime(timezone=True))

    tenant = relationship("Tenant", back_populates="clientes")
    owner = relationship("Profile", back_populates="clientes")
    transacciones = relationship(
        "Transaccion",
        back_populates="cliente",
        cascade="all, delete-orphan",
        foreign_keys="Transaccion.cliente_id",
    )

    __table_args__ = (
        UniqueConstraint("tenant_id", "id", name="uq_clientes_tenant_id"),
        CheckConstraint("saldo >= 0", name="chk_clientes_saldo"),
        CheckConstraint(
            "NOT autoriza_datos OR autoriza_datos_en IS NOT NULL",
            name="chk_clientes_autoriza_datos_fecha",
        ),
        Index(
            "uq_clientes_tenant_identificacion",
            "tenant_id",
            "identificacion",
            unique=True,
            postgresql_where=text("identificacion IS NOT NULL AND deleted_at IS NULL"),
            sqlite_where=text("identificacion IS NOT NULL AND deleted_at IS NULL"),
        ),
    )
