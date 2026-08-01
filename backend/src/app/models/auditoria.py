from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, ForeignKey, String, JSON, text
from sqlalchemy.dialects.postgresql import UUID

from src.app.database.connection import Base


class Auditoria(Base):
    __tablename__ = "auditoria"

    id = Column(BigInteger, primary_key=True)
    owner_id = Column(UUID(as_uuid=True), nullable=False)
    tabla = Column(String(30), nullable=False)
    registro_id = Column(UUID(as_uuid=True), nullable=False)
    accion = Column(String(10), nullable=False)
    datos_anteriores = Column(JSON)
    datos_nuevos = Column(JSON)
    realizado_por = Column(UUID(as_uuid=True))
    realizado_en = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))

    __table_args__ = (
        CheckConstraint("accion in ('INSERT','UPDATE','DELETE')", name="chk_auditoria_accion"),
    )
