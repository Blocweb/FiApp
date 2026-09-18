import uuid
import pytest
from sqlalchemy.orm import Session

from src.app.models.profile import Profile
from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario


@pytest.mark.integration
def test_postgres_integration_connection(postgres_session: Session):
    """Test de integración que corre exclusivamente contra PostgreSQL.

    Verifica que la sesión de integración funciona, la base de datos es PostgreSQL
    y el dialecto soporta los tipos nativos (como JSONB).
    """
    bind = postgres_session.get_bind()
    assert bind.dialect.name == "postgresql"


@pytest.mark.integration
def test_postgres_tenant_jsonb_and_cascades(postgres_session: Session):
    """Verifica persistencia real de JSONB y cascadas relacionales en PostgreSQL."""
    p_id = uuid.uuid4()
    profile = Profile(id=p_id, email=f"owner_{p_id.hex[:6]}@example.com")
    t_id = uuid.uuid4()
    tenant = Tenant(
        id=t_id,
        nombre_comercial="Organización PG Real",
        configuracion={"features": ["multicurrency", "roles"], "limite_credito": 1000000},
    )
    postgres_session.add_all([profile, tenant])
    postgres_session.commit()

    m_id = uuid.uuid4()
    membership = TenantUsuario(
        id=m_id,
        tenant_id=t_id,
        profile_id=p_id,
        rol="propietario",
    )
    postgres_session.add(membership)
    postgres_session.commit()

    # Validar lectura de JSONB nativo
    saved_tenant = postgres_session.query(Tenant).filter_by(id=t_id).first()
    assert saved_tenant is not None
    assert saved_tenant.configuracion["limite_credito"] == 1000000
    assert "multicurrency" in saved_tenant.configuracion["features"]

    # Validar eliminación en cascada en PostgreSQL
    postgres_session.delete(saved_tenant)
    postgres_session.commit()

    assert postgres_session.query(TenantUsuario).filter_by(tenant_id=t_id).count() == 0
    assert postgres_session.query(Profile).filter_by(id=p_id).count() == 1