from sqlalchemy import CheckConstraint, Column, DateTime, String, text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class Exportacion(Base):
    __tablename__ = "exportaciones"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False)
    owner_id = Column(
        UUID(as_uuid=True),
        ForeignKey("profiles.id", ondelete="CASCADE"),
        nullable=False,
    )

    tenant = relationship("Tenant", back_populates="exportaciones")
    owner = relationship(
        "Profile",
        back_populates="exportaciones",
    )
    formato = Column(String(10), nullable=False)
    alcance = Column(String(12), nullable=False)
    generado_en = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))

    __table_args__ = (
        CheckConstraint("formato in ('excel','pdf')", name="chk_exportaciones_formato"),
        CheckConstraint("alcance in ('todos','con_deuda')", name="chk_exportaciones_alcance"),
    )
