from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, String, JSON, ForeignKey, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class Auditoria(Base):
    __tablename__ = "auditoria"

    id = Column(BigInteger, primary_key=True)
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="RESTRICT"), nullable=False)
    owner_id = Column(UUID(as_uuid=True), nullable=False)
    tabla = Column(String(30), nullable=False)
    registro_id = Column(UUID(as_uuid=True), nullable=False)
    accion = Column(String(10), nullable=False)
    datos_anteriores = Column(JSON)
    datos_nuevos = Column(JSON)
    realizado_por = Column(UUID(as_uuid=True))
    realizado_en = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))

    tenant = relationship("Tenant", back_populates="auditorias")

    __table_args__ = (
        CheckConstraint("accion in ('INSERT','UPDATE','DELETE')", name="chk_auditoria_accion"),
    )
