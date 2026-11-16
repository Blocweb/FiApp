from sqlalchemy import Boolean, Column, DateTime, String, CheckConstraint, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.app.database.connection import Base


class Profile(Base):
    __tablename__ = "profiles"

    id = Column(UUID(as_uuid=True), primary_key=True)
    nombre_negocio = Column(String(150), nullable=False, server_default=text("'Mi tienda'"))
    email = Column(String(255), nullable=False)
    # HU01 (T01): nombre de la persona (dueño o trabajador).
    nombre = Column(String(150))
    plan = Column(String(20), nullable=False, server_default=text("'gratuito'"))
    rol = Column(String(20), nullable=False, server_default=text("'propietario'"))
    modo_oscuro = Column(Boolean, nullable=False, server_default=text("false"))
    respaldo_nube = Column(Boolean, nullable=False, server_default=text("true"))
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))

    clientes = relationship("Cliente", back_populates="owner", cascade="all, delete-orphan")
    productos = relationship("Producto", back_populates="owner")
    transacciones = relationship("Transaccion", back_populates="owner")
    exportaciones = relationship("Exportacion", back_populates="owner")

    __table_args__ = (
        CheckConstraint("plan in ('gratuito','pro')", name="chk_profiles_plan"),
        CheckConstraint("rol in ('propietario','empleado')", name="chk_profiles_rol"),
    )
