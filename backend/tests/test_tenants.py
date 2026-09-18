import uuid
import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from src.app.models.profile import Profile
from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario


def test_tenant_model_creation(sqlite_session: Session):
    """Verifica que Tenant puede instanciarse y persistirse correctamente con sus defaults."""
    tenant = Tenant(
        id=uuid.uuid4(),
        nombre_comercial="Distribuidora Los Andes",
        identificacion_fiscal="900123456-7",
        moneda="COP",
        telefono="3001234567",
        estado="activo",
        configuracion={"dias_gracia": 3, "interes_mora_defecto": 2.5},
    )
    sqlite_session.add(tenant)
    sqlite_session.commit()

    saved = sqlite_session.query(Tenant).filter_by(id=tenant.id).first()
    assert saved is not None
    assert saved.nombre_comercial == "Distribuidora Los Andes"
    assert saved.moneda == "COP"
    assert saved.estado == "activo"
    assert saved.configuracion["dias_gracia"] == 3


def test_tenant_usuario_association(sqlite_session: Session):
    """Verifica que TenantUsuario se asocia adecuadamente a Tenant y Profile."""
    profile_id = uuid.uuid4()
    profile = Profile(
        id=profile_id,
        nombre_negocio="Negocio Temporal",
        email="owner@losandes.com",
        plan="pro",
        rol="propietario",
    )
    sqlite_session.add(profile)

    tenant_id = uuid.uuid4()
    tenant = Tenant(
        id=tenant_id,
        nombre_comercial="Distribuidora Los Andes",
    )
    sqlite_session.add(tenant)
    sqlite_session.commit()

    membership = TenantUsuario(
        id=uuid.uuid4(),
        tenant_id=tenant.id,
        profile_id=profile.id,
        rol="propietario",
        activo=True,
    )
    sqlite_session.add(membership)
    sqlite_session.commit()

    saved_membership = sqlite_session.query(TenantUsuario).filter_by(id=membership.id).first()
    assert saved_membership is not None
    assert saved_membership.tenant_id == tenant.id
    assert saved_membership.profile_id == profile.id
    assert saved_membership.rol == "propietario"
    assert saved_membership.activo is True
    assert saved_membership.tenant.nombre_comercial == "Distribuidora Los Andes"


def test_tenant_usuario_unique_tenant_profile(sqlite_session: Session):
    """Verifica que no se pueden crear dos membresías con el mismo tenant_id + profile_id."""
    p_id = uuid.uuid4()
    profile = Profile(id=p_id, email="cobrador@losandes.com")
    sqlite_session.add(profile)

    t_id = uuid.uuid4()
    tenant = Tenant(id=t_id, nombre_comercial="Cobranzas Express")
    sqlite_session.add(tenant)
    sqlite_session.commit()

    m1 = TenantUsuario(tenant_id=t_id, profile_id=p_id, rol="cobrador")
    sqlite_session.add(m1)
    sqlite_session.commit()

    m2 = TenantUsuario(tenant_id=t_id, profile_id=p_id, rol="administrador")
    sqlite_session.add(m2)
    with pytest.raises(IntegrityError):
        sqlite_session.commit()
    sqlite_session.rollback()


def test_tenant_usuario_roles_check(sqlite_session: Session):
    """Verifica que el modelo rechaza roles que no estén en la lista permitida."""
    p_id = uuid.uuid4()
    profile = Profile(id=p_id, email="supervisor@losandes.com")
    t_id = uuid.uuid4()
    tenant = Tenant(id=t_id, nombre_comercial="Supervisión Central")
    sqlite_session.add_all([profile, tenant])
    sqlite_session.commit()

    valid_roles = ["propietario", "administrador", "supervisor", "cobrador"]
    for rol in valid_roles:
        membership = TenantUsuario(
            id=uuid.uuid4(),
            tenant_id=t_id,
            profile_id=p_id,
            rol=rol,
        )
        sqlite_session.add(membership)
        sqlite_session.commit()
        sqlite_session.delete(membership)
        sqlite_session.commit()

    invalid_membership = TenantUsuario(
        id=uuid.uuid4(),
        tenant_id=t_id,
        profile_id=p_id,
        rol="superadmin_falso",
    )
    sqlite_session.add(invalid_membership)
    with pytest.raises(IntegrityError):
        sqlite_session.commit()
    sqlite_session.rollback()


def test_tenant_cascade_delete_usuarios(sqlite_session: Session):
    """Verifica que al eliminar un Tenant se eliminan en cascada sus TenantUsuarios."""
    p_id = uuid.uuid4()
    profile = Profile(id=p_id, email="staff@tienda.com")
    t_id = uuid.uuid4()
    tenant = Tenant(id=t_id, nombre_comercial="Tienda Temporal")
    sqlite_session.add_all([profile, tenant])
    sqlite_session.commit()

    m = TenantUsuario(id=uuid.uuid4(), tenant_id=t_id, profile_id=p_id, rol="cobrador")
    sqlite_session.add(m)
    sqlite_session.commit()

    assert sqlite_session.query(TenantUsuario).filter_by(tenant_id=t_id).count() == 1

    # Eliminación del tenant
    sqlite_session.delete(tenant)
    sqlite_session.commit()

    # Los tenant_usuarios deben haber sido eliminados
    assert sqlite_session.query(TenantUsuario).filter_by(tenant_id=t_id).count() == 0
    # Pero el profile del usuario NO debe ser eliminado
    assert sqlite_session.query(Profile).filter_by(id=p_id).count() == 1
