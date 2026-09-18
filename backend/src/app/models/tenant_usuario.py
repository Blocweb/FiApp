from sqlalchemy import Boolean, CheckConstraint, Column, DateTime, ForeignKey, String, UniqueConstraint, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class TenantUsuario(Base):
    __tablename__ = "tenant_usuarios"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False)
    rol = Column(String(20), nullable=False)
    activo = Column(Boolean, nullable=False, server_default=text("true"))
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))

    tenant = relationship("Tenant", back_populates="usuarios")
    profile = relationship("Profile")

    __table_args__ = (
        UniqueConstraint("tenant_id", "profile_id", name="uq_tenant_usuarios_tenant_profile"),
        CheckConstraint(
            "rol IN ('propietario', 'administrador', 'supervisor', 'cobrador')",
            name="chk_tenant_usuarios_rol",
        ),
    )
