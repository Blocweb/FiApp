from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, ForeignKeyConstraint, Numeric, SmallInteger, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class Transaccion(Base):
    __tablename__ = "transacciones"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="RESTRICT"), nullable=False)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    cliente_id = Column(UUID(as_uuid=True), ForeignKey("clientes.id", ondelete="RESTRICT"), nullable=False)
    tipo = Column(String(10), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    metodo_pago_id = Column(SmallInteger, ForeignKey("metodos_pago.id", ondelete="RESTRICT"), nullable=True)
    nota = Column(Text)
    saldo_posterior = Column(Numeric(12, 2), nullable=False, server_default=text("0"))
    fecha_hora = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    deleted_at = Column(DateTime(timezone=True))

    tenant = relationship("Tenant", back_populates="transacciones", foreign_keys=[tenant_id])
    cliente = relationship("Cliente", back_populates="transacciones", foreign_keys=[cliente_id])
    metodo_pago = relationship("MetodoPago", back_populates="transacciones")
    fiado_items = relationship("FiadoItem", back_populates="transaccion", cascade="all, delete-orphan")
    owner = relationship("Profile", back_populates="transacciones", foreign_keys=[owner_id])

    @property
    def registrado_por_nombre(self) -> str | None:
        """HU03 (T17): nombre de quien registró el movimiento.

        Requiere que la relación ``owner`` esté precargada (``selectinload``).
        """
        owner = self.__dict__.get("owner")
        if owner is None:
            return None
        return owner.nombre or owner.email

    __table_args__ = (
        ForeignKeyConstraint(
            ["tenant_id", "cliente_id"],
            ["clientes.tenant_id", "clientes.id"],
            name="fk_transacciones_cliente_tenant",
        ),
        CheckConstraint("monto > 0", name="chk_transacciones_monto"),
        CheckConstraint("tipo in ('fiado','abono')", name="chk_transacciones_tipo"),
        CheckConstraint(
            "((tipo='abono' and metodo_pago_id is not null) or (tipo='fiado' and metodo_pago_id is null))",
            name="chk_metodo_pago_tipo",
        ),
    )
