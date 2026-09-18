"""Tests HTTP de los endpoints /tenants/ y /tenants/current (Tarea 3.1).

Se usa `TestClient` con sobreescritura de dependencias para simular la
autenticación; las membresías se resuelven contra una sesión SQLite async real.
Se verifica el contrato de errores del header y el aislamiento del contexto.
"""

import datetime
import uuid
from contextlib import asynccontextmanager

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import event
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from src.app.core.tenant_context import UsuarioAutenticado
from src.app.database.connection import Base, get_db
from src.app.models.profile import Profile
from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario
from src.app.services.auth_service import get_current_profile, get_current_user

BEARER = {"Authorization": "Bearer test-token"}


@asynccontextmanager
async def _session_scope():
    """Sesión SQLite async en memoria con las tablas de los modelos."""
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)

    @event.listens_for(engine.sync_engine, "connect")
    def _register(dbapi_connection, connection_record):
        dbapi_connection.execute("PRAGMA foreign_keys=ON")
        dbapi_connection.create_function(
            "now", 0, lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
        )
        dbapi_connection.create_function("gen_random_uuid", 0, lambda: str(uuid.uuid4()))

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    factory = async_sessionmaker(bind=engine, expire_on_commit=False)
    try:
        async with factory() as session:
            yield session
    finally:
        await engine.dispose()


def _build_client(app, session, profile, usuario_id=None):
    """Instala overrides de dependencias y devuelve un TestClient."""

    async def _override_db():
        yield session

    async def _override_user():
        return UsuarioAutenticado(id=usuario_id or profile.id, email=profile.email)

    async def _override_profile():
        return profile

    app.dependency_overrides[get_db] = _override_db
    app.dependency_overrides[get_current_user] = _override_user
    app.dependency_overrides[get_current_profile] = _override_profile
    return TestClient(app)


async def _seed(session):
    """Crea un usuario con varios tenants propios y uno ajeno."""
    profile = Profile(id=uuid.uuid4(), email="dueno@fiapp.test")
    otro_profile = Profile(id=uuid.uuid4(), email="otro@fiapp.test")
    tenant_propio = Tenant(id=uuid.uuid4(), nombre_comercial="Tienda Propia", estado="activo")
    tenant_ajeno = Tenant(id=uuid.uuid4(), nombre_comercial="Tienda Ajena", estado="activo")
    tenant_suspendido = Tenant(id=uuid.uuid4(), nombre_comercial="Suspendida", estado="suspendido")
    tenant_mora = Tenant(id=uuid.uuid4(), nombre_comercial="En Mora", estado="mora")
    tenant_cancelado = Tenant(id=uuid.uuid4(), nombre_comercial="Cancelada", estado="cancelado")
    session.add_all(
        [
            profile,
            otro_profile,
            tenant_propio,
            tenant_ajeno,
            tenant_suspendido,
            tenant_mora,
            tenant_cancelado,
        ]
    )
    await session.commit()

    session.add_all(
        [
            TenantUsuario(
                id=uuid.uuid4(), tenant_id=tenant_propio.id, profile_id=profile.id, rol="propietario"
            ),
            TenantUsuario(
                id=uuid.uuid4(),
                tenant_id=tenant_suspendido.id,
                profile_id=profile.id,
                rol="administrador",
            ),
            TenantUsuario(
                id=uuid.uuid4(), tenant_id=tenant_mora.id, profile_id=profile.id, rol="supervisor"
            ),
            TenantUsuario(
                id=uuid.uuid4(), tenant_id=tenant_cancelado.id, profile_id=profile.id, rol="cobrador"
            ),
            TenantUsuario(
                id=uuid.uuid4(),
                tenant_id=tenant_ajeno.id,
                profile_id=otro_profile.id,
                rol="propietario",
            ),
        ]
    )
    await session.commit()
    return {
        "profile": profile,
        "tenant_propio": tenant_propio,
        "tenant_ajeno": tenant_ajeno,
        "tenant_suspendido": tenant_suspendido,
        "tenant_mora": tenant_mora,
        "tenant_cancelado": tenant_cancelado,
    }


@pytest.mark.anyio
async def test_listado_tenants_propios():
    """El listado incluye solo los tenants del usuario con membresía activa."""
    import main

    async with _session_scope() as session:
        datos = await _seed(session)
        client = _build_client(main.app, session, datos["profile"])
        try:
            resp = client.get("/tenants/", headers=BEARER)
            assert resp.status_code == 200
            ids = {t["id"] for t in resp.json()["tenants"]}
            assert str(datos["tenant_propio"].id) in ids
            assert str(datos["tenant_ajeno"].id) not in ids
            # Solo los campos mínimos de selección.
            for tenant in resp.json()["tenants"]:
                assert set(tenant.keys()) == {"id", "nombre_comercial", "estado", "rol"}
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_listado_roles_diferentes_por_tenant():
    """El rol mostrado proviene de cada membresía."""
    import main

    async with _session_scope() as session:
        datos = await _seed(session)
        client = _build_client(main.app, session, datos["profile"])
        try:
            resp = client.get("/tenants/", headers=BEARER)
            roles = {t["id"]: t["rol"] for t in resp.json()["tenants"]}
            assert roles[str(datos["tenant_propio"].id)] == "propietario"
            assert roles[str(datos["tenant_suspendido"].id)] == "administrador"
            assert roles[str(datos["tenant_mora"].id)] == "supervisor"
            assert roles[str(datos["tenant_cancelado"].id)] == "cobrador"
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_seleccion_tenant_propio():
    """La selección válida devuelve el contexto y el rol del usuario."""
    import main

    async with _session_scope() as session:
        datos = await _seed(session)
        client = _build_client(main.app, session, datos["profile"])
        try:
            resp = client.get(
                "/tenants/current",
                headers={**BEARER, "X-Tenant-ID": str(datos["tenant_propio"].id)},
            )
            assert resp.status_code == 200
            body = resp.json()
            assert body["tenant_id"] == str(datos["tenant_propio"].id)
            assert body["nombre_comercial"] == "Tienda Propia"
            assert body["estado"] == "activo"
            assert body["rol"] == "propietario"
            assert body["membresia_activa"] is True
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_tenant_ajeno_rechazado_y_sin_filtrar_existencia():
    """Tenant ajeno e inexistente comparten la misma respuesta genérica."""
    import main

    async with _session_scope() as session:
        datos = await _seed(session)
        client = _build_client(main.app, session, datos["profile"])
        try:
            ajeno = client.get(
                "/tenants/current",
                headers={**BEARER, "X-Tenant-ID": str(datos["tenant_ajeno"].id)},
            )
            inexistente = client.get(
                "/tenants/current",
                headers={**BEARER, "X-Tenant-ID": str(uuid.uuid4())},
            )
            assert ajeno.status_code == 403
            assert inexistente.status_code == 403
            assert ajeno.json()["detail"] == inexistente.json()["detail"]
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_membresia_inactiva_rechazada():
    """Una membresía inactiva impide el acceso aun con tenant activo."""
    import main

    async with _session_scope() as session:
        profile = Profile(id=uuid.uuid4(), email="inactivo@fiapp.test")
        tenant = Tenant(id=uuid.uuid4(), nombre_comercial="Inactiva", estado="activo")
        session.add_all([profile, tenant])
        await session.commit()
        session.add(
            TenantUsuario(
                id=uuid.uuid4(),
                tenant_id=tenant.id,
                profile_id=profile.id,
                rol="cobrador",
                activo=False,
            )
        )
        await session.commit()

        client = _build_client(main.app, session, profile)
        try:
            resp = client.get(
                "/tenants/current", headers={**BEARER, "X-Tenant-ID": str(tenant.id)}
            )
            assert resp.status_code == 403

            resp_list = client.get("/tenants/", headers=BEARER)
            assert resp_list.json()["tenants"] == []
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_usuario_sin_tenants():
    """Un usuario sin membresías obtiene un listado vacío."""
    import main

    async with _session_scope() as session:
        profile = Profile(id=uuid.uuid4(), email="solo@fiapp.test")
        session.add(profile)
        await session.commit()

        client = _build_client(main.app, session, profile)
        try:
            resp = client.get("/tenants/", headers=BEARER)
            assert resp.status_code == 200
            assert resp.json()["tenants"] == []
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_header_ausente_devuelve_400_tenant_required():
    """Sin X-Tenant-ID no hay selección ni fallback: 400 tenant_required."""
    import main

    async with _session_scope() as session:
        datos = await _seed(session)
        client = _build_client(main.app, session, datos["profile"])
        try:
            resp = client.get("/tenants/current", headers=BEARER)
            assert resp.status_code == 400
            assert resp.json()["detail"]["code"] == "tenant_required"
            # No se filtra el id del tenant propio.
            assert str(datos["tenant_propio"].id) not in resp.text
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_header_uuid_invalido_devuelve_422():
    """Un X-Tenant-ID que no es UUID se rechaza con 422."""
    import main

    async with _session_scope() as session:
        datos = await _seed(session)
        client = _build_client(main.app, session, datos["profile"])
        try:
            resp = client.get(
                "/tenants/current", headers={**BEARER, "X-Tenant-ID": "no-es-uuid"}
            )
            assert resp.status_code == 422
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.parametrize("clave", ["tenant_suspendido", "tenant_mora", "tenant_cancelado"])
@pytest.mark.anyio
async def test_tenant_no_operativo_rechazado(clave):
    """Solo `activo` permite operar: suspendido, mora y cancelado dan 403."""
    import main

    async with _session_scope() as session:
        datos = await _seed(session)
        client = _build_client(main.app, session, datos["profile"])
        try:
            resp = client.get(
                "/tenants/current",
                headers={**BEARER, "X-Tenant-ID": str(datos[clave].id)},
            )
            assert resp.status_code == 403
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_sin_bearer_es_401():
    """Sin token Bearer no hay identidad: 401 (dependencia real, sin override)."""
    import main

    async with _session_scope() as session:

        async def _override_db():
            yield session

        main.app.dependency_overrides[get_db] = _override_db
        client = TestClient(main.app)
        try:
            resp = client.get("/tenants/")
            assert resp.status_code == 401
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_perfil_inexistente_es_401():
    """Un usuario autenticado sin profile en la BD recibe 401."""
    import main

    async with _session_scope() as session:

        async def _override_db():
            yield session

        async def _override_user():
            return UsuarioAutenticado(id=uuid.uuid4(), email="fantasma@fiapp.test")

        main.app.dependency_overrides[get_db] = _override_db
        main.app.dependency_overrides[get_current_user] = _override_user
        client = TestClient(main.app)
        try:
            resp = client.get("/tenants/", headers=BEARER)
            assert resp.status_code == 401
        finally:
            main.app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_routers_existentes_siguen_funcionando_sin_tenant():
    """`/perfil/` conserva su contrato y no exige X-Tenant-ID."""
    import main

    async with _session_scope() as session:
        profile = Profile(id=uuid.uuid4(), email="perfil@fiapp.com")
        session.add(profile)
        await session.commit()
        client = _build_client(main.app, session, profile)
        try:
            resp = client.get("/perfil/", headers=BEARER)
            assert resp.status_code == 200
            assert resp.json()["email"] == "perfil@fiapp.com"
        finally:
            main.app.dependency_overrides.clear()
