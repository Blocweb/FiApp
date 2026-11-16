"""Pruebas del Sprint 1: HU01 (T07), HU02 (T14) y HU03 (T20).

Se usa `TestClient` con dependencias sobrescritas para simular el usuario
autenticado y una base SQLite async en memoria con las tablas de los modelos.
La creación de cuentas en Supabase Auth se reemplaza por un doble de prueba.
"""

import datetime
import uuid
from contextlib import asynccontextmanager
from decimal import Decimal
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import event, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from main import app
from src.app.core.tenant_context import UsuarioAutenticado
from src.app.database.connection import Base, get_db
from src.app.models.cliente import Cliente
from src.app.models.profile import Profile
from src.app.models.tenant import Tenant
from src.app.models.tenant_usuario import TenantUsuario
from src.app.models.transaccion import Transaccion
from src.app.services.auth_service import get_current_profile, get_current_user

BEARER = {"Authorization": "Bearer test-token"}

CLIENTE_VALIDO = {
    "name": "Carlos Ruiz",
    "identification": "1.036.555.444",
    "phone": "300 555 4444",
    "address": "Calle 10",
    "dataConsent": True,
}


@asynccontextmanager
async def _session_scope():
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


class _Usuarios:
    """Cambia el usuario autenticado entre peticiones del mismo TestClient."""

    def __init__(self, session):
        self.session = session
        self.actual: Profile | None = None

    def client(self) -> TestClient:
        async def _db():
            yield self.session

        async def _user():
            return UsuarioAutenticado(id=self.actual.id, email=self.actual.email)

        async def _profile():
            return self.actual

        app.dependency_overrides[get_db] = _db
        app.dependency_overrides[get_current_user] = _user
        app.dependency_overrides[get_current_profile] = _profile
        return TestClient(app)


async def _seed(session):
    """Negocio con propietario, administrador, cobrador activo y cobrador inactivo."""
    tenant = Tenant(id=uuid.uuid4(), nombre_comercial="Almacén El Hermano", estado="activo")
    otro_tenant = Tenant(id=uuid.uuid4(), nombre_comercial="Otro negocio", estado="activo")
    perfiles = {
        nombre: Profile(id=uuid.uuid4(), email=f"{nombre}@fiapp.co", nombre=nombre.title())
        for nombre in ("dueno", "admin", "cobrador", "inactivo", "ajeno")
    }
    session.add_all([tenant, otro_tenant, *perfiles.values()])
    await session.commit()
    membresias = {
        "dueno": TenantUsuario(id=uuid.uuid4(), tenant_id=tenant.id, profile_id=perfiles["dueno"].id, rol="propietario"),
        "admin": TenantUsuario(id=uuid.uuid4(), tenant_id=tenant.id, profile_id=perfiles["admin"].id, rol="administrador"),
        "cobrador": TenantUsuario(id=uuid.uuid4(), tenant_id=tenant.id, profile_id=perfiles["cobrador"].id, rol="cobrador"),
        "inactivo": TenantUsuario(
            id=uuid.uuid4(), tenant_id=tenant.id, profile_id=perfiles["inactivo"].id, rol="cobrador", activo=False
        ),
        "ajeno": TenantUsuario(id=uuid.uuid4(), tenant_id=otro_tenant.id, profile_id=perfiles["ajeno"].id, rol="propietario"),
    }
    session.add_all(membresias.values())
    await session.commit()
    return tenant, perfiles, membresias


@pytest.fixture(autouse=True)
def _limpiar_overrides():
    yield
    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# HU01 · Gestionar usuarios y roles (T07)
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_usuario_nuevo_recibe_su_negocio_como_propietario():
    async with _session_scope() as session:
        nuevo = Profile(id=uuid.uuid4(), email="nuevo@fiapp.co", nombre_negocio="Taller Nuevo")
        session.add(nuevo)
        await session.commit()
        usuarios = _Usuarios(session)
        usuarios.actual = nuevo

        resp = usuarios.client().get("/tenants/current", headers=BEARER)

        assert resp.status_code == 200
        assert resp.json()["rol"] == "propietario"
        assert resp.json()["nombre_comercial"] == "Taller Nuevo"


@pytest.mark.anyio
async def test_usuario_desactivado_no_accede_ni_recibe_negocio_propio():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        usuarios.actual = perfiles["inactivo"]

        resp = usuarios.client().get("/clientes/", headers=BEARER)

        assert resp.status_code == 403
        membresias = (
            await session.execute(select(TenantUsuario).where(TenantUsuario.profile_id == perfiles["inactivo"].id))
        ).scalars().all()
        assert len(membresias) == 1 and membresias[0].activo is False


@pytest.mark.anyio
async def test_admin_lista_usuarios_y_trabajador_no():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()

        usuarios.actual = perfiles["admin"]
        resp = client.get("/usuarios/", headers=BEARER)
        assert resp.status_code == 200
        emails = {u["email"] for u in resp.json()}
        assert emails == {"dueno@fiapp.co", "admin@fiapp.co", "cobrador@fiapp.co", "inactivo@fiapp.co"}
        assert "ajeno@fiapp.co" not in emails

        usuarios.actual = perfiles["cobrador"]
        assert client.get("/usuarios/", headers=BEARER).status_code == 403


@pytest.mark.anyio
async def test_crear_trabajador_con_cuenta_propia():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        usuarios.actual = perfiles["dueno"]
        nuevo_id = uuid.uuid4()

        with patch(
            "src.app.services.usuario_service._crear_cuenta_supabase",
            return_value=nuevo_id,
        ) as crear_cuenta:
            resp = usuarios.client().post(
                "/usuarios/",
                headers=BEARER,
                json={"nombre": "Pedro  Gómez", "email": "Pedro@Fiapp.co", "password": "segura123", "rol": "cobrador"},
            )

        assert resp.status_code == 201, resp.text
        body = resp.json()
        assert body["nombre"] == "Pedro Gómez"
        assert body["email"] == "pedro@fiapp.co"
        assert body["rol"] == "cobrador" and body["activo"] is True
        assert crear_cuenta.await_count == 1
        profile = await session.get(Profile, nuevo_id)
        assert profile is not None and profile.rol == "empleado"


@pytest.mark.anyio
async def test_crear_usuario_rechaza_correo_existente_y_admin_no_crea_admin():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()

        usuarios.actual = perfiles["dueno"]
        with patch("src.app.services.usuario_service._crear_cuenta_supabase") as crear_cuenta:
            resp = client.post(
                "/usuarios/",
                headers=BEARER,
                json={"nombre": "Repetido", "email": "cobrador@fiapp.co", "password": "segura123"},
            )
            assert resp.status_code == 409
            crear_cuenta.assert_not_called()

        usuarios.actual = perfiles["admin"]
        resp = client.post(
            "/usuarios/",
            headers=BEARER,
            json={"nombre": "Otro Admin", "email": "nuevoadmin@fiapp.co", "password": "segura123", "rol": "administrador"},
        )
        assert resp.status_code == 403


@pytest.mark.anyio
async def test_desactivar_y_reactivar_trabajador():
    async with _session_scope() as session:
        _, perfiles, membresias = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()
        usuarios.actual = perfiles["admin"]
        url = f"/usuarios/{membresias['cobrador'].id}"

        resp = client.patch(url, headers=BEARER, json={"activo": False})
        assert resp.status_code == 200 and resp.json()["activo"] is False

        usuarios.actual = perfiles["cobrador"]
        assert client.get("/clientes/", headers=BEARER).status_code == 403

        usuarios.actual = perfiles["admin"]
        assert client.patch(url, headers=BEARER, json={"activo": True}).json()["activo"] is True
        usuarios.actual = perfiles["cobrador"]
        assert client.get("/clientes/", headers=BEARER).status_code == 200


@pytest.mark.anyio
async def test_reglas_de_modificacion_de_usuarios():
    async with _session_scope() as session:
        _, perfiles, membresias = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()

        usuarios.actual = perfiles["admin"]
        # No puede cambiarse a sí mismo ni tocar al propietario o a otro administrador.
        assert client.patch(f"/usuarios/{membresias['admin'].id}", headers=BEARER, json={"activo": False}).status_code == 400
        assert client.patch(f"/usuarios/{membresias['dueno'].id}", headers=BEARER, json={"activo": False}).status_code == 403
        assert client.patch(f"/usuarios/{membresias['cobrador'].id}", headers=BEARER, json={"rol": "administrador"}).status_code == 403
        # Usuarios de otro negocio no existen para este administrador.
        assert client.patch(f"/usuarios/{membresias['ajeno'].id}", headers=BEARER, json={"activo": False}).status_code == 404

        usuarios.actual = perfiles["dueno"]
        resp = client.patch(f"/usuarios/{membresias['cobrador'].id}", headers=BEARER, json={"rol": "administrador"})
        assert resp.status_code == 200 and resp.json()["rol"] == "administrador"


# ---------------------------------------------------------------------------
# HU02 · Registrar clientes (T14)
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_registrar_cliente_con_identificacion_y_autorizacion():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        usuarios.actual = perfiles["cobrador"]

        resp = usuarios.client().post("/clientes/", headers=BEARER, json=CLIENTE_VALIDO)

        assert resp.status_code == 201, resp.text
        body = resp.json()
        assert body["identification"] == "1036555444"
        assert body["dataConsent"] is True and body["dataConsentAt"] is not None
        assert body["balance"] == 0


@pytest.mark.anyio
async def test_registrar_cliente_sin_autorizacion_es_rechazado():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        usuarios.actual = perfiles["cobrador"]

        resp = usuarios.client().post("/clientes/", headers=BEARER, json={**CLIENTE_VALIDO, "dataConsent": False})

        assert resp.status_code == 422


@pytest.mark.anyio
async def test_cliente_duplicado_avisa_quien_es():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()
        usuarios.actual = perfiles["dueno"]
        primero = client.post("/clientes/", headers=BEARER, json=CLIENTE_VALIDO).json()

        usuarios.actual = perfiles["cobrador"]
        resp = client.post(
            "/clientes/",
            headers=BEARER,
            json={**CLIENTE_VALIDO, "name": "Otro Nombre", "identification": "1036555444"},
        )

        assert resp.status_code == 409
        detalle = resp.json()["detail"]
        assert detalle["code"] == "cliente_duplicado"
        assert detalle["cliente_id"] == primero["id"]
        assert detalle["nombre"] == "Carlos Ruiz"


@pytest.mark.anyio
async def test_misma_identificacion_en_otro_negocio_si_se_permite():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()

        usuarios.actual = perfiles["dueno"]
        assert client.post("/clientes/", headers=BEARER, json=CLIENTE_VALIDO).status_code == 201
        usuarios.actual = perfiles["ajeno"]
        assert client.post("/clientes/", headers=BEARER, json=CLIENTE_VALIDO).status_code == 201


@pytest.mark.anyio
async def test_buscar_clientes_por_nombre():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()
        usuarios.actual = perfiles["dueno"]
        for i, nombre in enumerate(["María García", "Mario Pérez", "Luis Torres"]):
            payload = {**CLIENTE_VALIDO, "name": nombre, "identification": f"10000000{i}"}
            assert client.post("/clientes/", headers=BEARER, json=payload).status_code == 201

        resp = client.get("/clientes/", headers=BEARER, params={"q": "mar"})

        assert resp.status_code == 200
        # El orden con tildes depende de la intercalación del motor.
        assert {c["name"] for c in resp.json()} == {"María García", "Mario Pérez"}
        assert [c["name"] for c in client.get("/clientes/", headers=BEARER, params={"q": "1000000"}).json()]
        assert len(client.get("/clientes/", headers=BEARER).json()) == 3


@pytest.mark.anyio
async def test_trabajador_no_elimina_clientes():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()
        usuarios.actual = perfiles["dueno"]
        cliente_id = client.post("/clientes/", headers=BEARER, json=CLIENTE_VALIDO).json()["id"]

        usuarios.actual = perfiles["cobrador"]
        assert client.delete(f"/clientes/{cliente_id}", headers=BEARER).status_code == 403
        assert client.get("/reportes/resumen", headers=BEARER).status_code == 403

        usuarios.actual = perfiles["admin"]
        assert client.delete(f"/clientes/{cliente_id}", headers=BEARER).status_code == 204


# ---------------------------------------------------------------------------
# HU03 · Registrar ventas a crédito (T20)
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_venta_a_credito_guarda_quien_vendio_y_la_fecha():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()
        usuarios.actual = perfiles["cobrador"]
        cliente_id = client.post("/clientes/", headers=BEARER, json=CLIENTE_VALIDO).json()["id"]
        fecha = "2026-11-10T15:30:00+00:00"

        resp = client.post(
            "/transacciones/fiado",
            headers=BEARER,
            json={
                "cliente_id": cliente_id,
                "monto": "90000",
                "fecha_hora": fecha,
                "items": [
                    {"nombre_producto": "Pastillas de freno", "cantidad": 2, "precio_unitario": "30000"},
                    {"nombre_producto": "Aceite 20W50", "cantidad": 1, "precio_unitario": "30000"},
                ],
            },
        )

        assert resp.status_code == 201, resp.text
        body = resp.json()
        assert body["tipo"] == "fiado"
        assert body["monto"] == 90000
        assert body["registrado_por"] == str(perfiles["cobrador"].id)
        assert body["registrado_por_nombre"] == "Cobrador"
        assert body["fecha_hora"].startswith("2026-11-10T15:30:00")
        assert len(body["items"]) == 2


@pytest.mark.anyio
async def test_venta_a_credito_rechaza_monto_distinto_y_cliente_ajeno():
    async with _session_scope() as session:
        _, perfiles, _ = await _seed(session)
        usuarios = _Usuarios(session)
        client = usuarios.client()
        usuarios.actual = perfiles["ajeno"]
        cliente_ajeno = client.post("/clientes/", headers=BEARER, json=CLIENTE_VALIDO).json()["id"]

        usuarios.actual = perfiles["cobrador"]
        item = {"nombre_producto": "Bujía", "cantidad": 1, "precio_unitario": "12000"}
        resp = client.post(
            "/transacciones/fiado",
            headers=BEARER,
            json={"cliente_id": cliente_ajeno, "monto": "12000", "items": [item]},
        )
        assert resp.status_code == 404

        cliente_id = client.post("/clientes/", headers=BEARER, json=CLIENTE_VALIDO).json()["id"]
        resp = client.post(
            "/transacciones/fiado",
            headers=BEARER,
            json={"cliente_id": cliente_id, "monto": "5000", "items": [item]},
        )
        assert resp.status_code == 422


@pytest.mark.anyio
async def test_trabajador_solo_ve_sus_movimientos_y_admin_ve_todos():
    async with _session_scope() as session:
        tenant, perfiles, _ = await _seed(session)
        cliente = Cliente(
            id=uuid.uuid4(),
            tenant_id=tenant.id,
            owner_id=perfiles["dueno"].id,
            nombre="Cliente Uno",
            saldo=Decimal("0"),
        )
        session.add(cliente)
        await session.commit()
        for quien in ("dueno", "cobrador", "admin"):
            session.add(
                Transaccion(
                    id=uuid.uuid4(),
                    tenant_id=tenant.id,
                    owner_id=perfiles[quien].id,
                    cliente_id=cliente.id,
                    tipo="fiado",
                    monto=Decimal("1000"),
                )
            )
        await session.commit()
        usuarios = _Usuarios(session)
        client = usuarios.client()

        usuarios.actual = perfiles["cobrador"]
        propios = client.get("/transacciones/", headers=BEARER).json()
        assert [t["registrado_por"] for t in propios] == [str(perfiles["cobrador"].id)]
        # El historial del cliente sí muestra todos sus movimientos.
        assert len(client.get(f"/transacciones/cliente/{cliente.id}", headers=BEARER).json()) == 3

        usuarios.actual = perfiles["admin"]
        assert len(client.get("/transacciones/", headers=BEARER).json()) == 3
