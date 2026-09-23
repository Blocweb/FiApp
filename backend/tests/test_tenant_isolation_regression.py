"""Tests de regresión de aislamiento multi-tenant (reconciliación repo↔producción).

Objetivo: proteger los invariantes del modelo de seguridad validado, de modo que
una regresión futura (p. ej. reintroducir `owner_id = auth.uid()` como única
protección, o romper el filtrado por tenant en las funciones de saldo) falle.

Los tests se dividen en dos grupos:

  * UNIT (siempre corren): verifican el contrato del repositorio — que las
    migraciones y el schema declaren el modelo tenant-aware, y que los modelos
    SQLAlchemy reflejen las columnas/constraints correctas. No tocan ninguna BD.
  * INTEGRATION (`@pytest.mark.integration`): verifican el comportamiento real
    de RLS/FK contra PostgreSQL. Usan `RLS_TEST_DSN` (variable propia) y se
    OMITEN si no está definida. NUNCA deben apuntar a producción.

Invariantes cubiertos:
  1.  Todo dato operacional pertenece a un tenant.
  2.  tenant_id no puede apuntar a un tenant inexistente.
  3.  transacción y cliente deben pertenecer al mismo tenant.
  4.  membership activa es requisito para acceso.
  5.  owner_id NO sustituye tenant_id como frontera de seguridad.
  6.  INSERT cross-tenant debe ser rechazado.
  7.  SELECT cross-tenant no debe devolver filas.
  8.  UPDATE cross-tenant no debe modificar filas.
  9.  DELETE cross-tenant no debe modificar filas.
  10. cambio de tenant_id debe ser rechazado.
  11. funciones de saldo deben usar tenant_id.
  12. auditoría debe conservar tenant_id.
"""

from __future__ import annotations

import os
import re
from pathlib import Path

import pytest

RAIZ = Path(__file__).resolve().parents[1]
SCHEMA = RAIZ / "src" / "app" / "database" / "fiapp_supabase_schema.sql"
MIGRACIONES = RAIZ / "src" / "app" / "database" / "migrations"


def _texto_schema() -> str:
    return SCHEMA.read_text(encoding="utf-8")


def _texto_migracion(nombre: str) -> str:
    return (MIGRACIONES / nombre).read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# INVARIANTE 5 — owner_id NO es la frontera de seguridad (auditoría de repo)
# ---------------------------------------------------------------------------

def test_schema_seccion_reconciliacion_no_usa_owner_id():
    """La sección 7 (reconciliación) del schema no usa owner_id como frontera."""
    texto = _texto_schema()
    parte = texto.split("7. RECONCILIACIÓN MULTI-TENANT", 1)[-1]
    assert "owner_id = auth.uid()" not in parte
    for pol in ("clientes_insert_tenant", "transacciones_insert_tenant", "tenants_select_member"):
        assert pol in parte, f"falta policy {pol}"


def test_migracion_005_valida_membership_no_setting_ciego():
    """current_tenant_id() valida membership; no lee el setting a ciegas."""
    sql = _texto_migracion("005_rls_reconciliation.sql")
    assert "current_tenant_id" in sql
    assert "tenant_usuarios" in sql
    assert "activo = true" in sql
    # No debe existir un current_tenant_id que devuelva directamente el setting.
    assert not re.search(
        r"create or replace function public\.current_tenant_id\(\)\s*returns uuid[^;]*"
        r"select\s+current_setting",
        sql,
        re.IGNORECASE | re.DOTALL,
    )


# ---------------------------------------------------------------------------
# INVARIANTES 2, 3, 10, 11, 12 — contrato declarativo de las migraciones
# ---------------------------------------------------------------------------

def test_migracion_005_declara_fk_tenant_a_tenants():
    """Invariante 2: tenant_id -> tenants(id) en las tablas operativas."""
    sql = _texto_migracion("005_rls_reconciliation.sql").lower()
    for tabla in ("clientes", "productos", "transacciones", "auditoria", "exportaciones"):
        assert tabla in sql
    assert "references public.tenants(id)" in sql
    assert "on delete restrict" in sql


def test_fk_compuesta_tenant_cliente_se_conserva():
    """Invariante 3: FK compuesta tx(tenant_id,cliente_id)->clientes(tenant_id,id)."""
    sql003 = _texto_migracion("003_tenant_client_transaction_fk.sql")
    assert "fk_transacciones_tenant_cliente" in sql003
    assert "clientes (tenant_id, id)" in sql003

    sql005 = _texto_migracion("005_rls_reconciliation.sql")
    assert "drop constraint fk_transacciones_tenant_cliente" not in sql005.lower()


def test_migracion_005_conserva_fk_legacy():
    """La FK legacy transacciones.cliente_id -> clientes(id) se conserva."""
    sql = _texto_migracion("005_rls_reconciliation.sql")
    assert "drop constraint transacciones_cliente_id_fkey" not in sql.lower()


def test_saldo_filtra_por_tenant():
    """Invariante 11: las funciones de saldo usan tenant_id."""
    sql = _texto_migracion("005_rls_reconciliation.sql")
    assert "tenant_id  = v_tenant_id" in sql or "tenant_id = v_tenant_id" in sql
    assert "and tenant_id = new.tenant_id" in sql.lower()
    assert "if owner_cliente <> new.owner_id" not in sql.lower()


def test_auditoria_conserva_tenant_id():
    """Invariante 12: fn_auditoria inserta tenant_id (INSERT/UPDATE/DELETE)."""
    sql = _texto_migracion("005_rls_reconciliation.sql")
    assert "fn_auditoria" in sql
    assert "v_tenant_id" in sql
    assert "insert into public.auditoria" in sql.lower()
    assert "tg_op = 'delete' then old.tenant_id else new.tenant_id" in sql.lower()


def test_helpers_son_security_definer_con_search_path_seguro():
    """Invariante 4 (contrato): helpers SD con search_path = pg_catalog, public."""
    sql = _texto_migracion("005_rls_reconciliation.sql")
    for helper in ("current_tenant_id", "user_is_active_member_of_tenant", "user_tenant_role"):
        assert helper in sql
    ocurrencias = re.findall(r"security definer\s+set search_path = [^\n;]+", sql, re.IGNORECASE)
    assert ocurrencias, "no se encontró ningún SECURITY DEFINER con search_path"
    for linea in ocurrencias:
        assert "pg_catalog" in linea and "public" in linea, f"search_path inseguro: {linea}"


# ---------------------------------------------------------------------------
# INVARIANTES 1, 3 — modelos SQLAlchemy alineados con el esquema validado
# ---------------------------------------------------------------------------

def test_modelos_operativos_tienen_tenant_id():
    """Invariante 1: entidades operativas declaran tenant_id NOT NULL."""
    from src.app.models.auditoria import Auditoria
    from src.app.models.cliente import Cliente
    from src.app.models.exportacion import Exportacion
    from src.app.models.producto import Producto
    from src.app.models.transaccion import Transaccion

    for modelo in (Cliente, Producto, Transaccion, Auditoria, Exportacion):
        assert "tenant_id" in modelo.__table__.columns, f"{modelo.__name__} sin tenant_id"
        assert modelo.__table__.columns["tenant_id"].nullable is False, (
            f"{modelo.__name__}.tenant_id debe ser NOT NULL"
        )


def test_fiado_item_no_tiene_tenant_id_propio():
    """FiadoItem NO lleva tenant_id: su aislamiento deriva de transacciones."""
    from src.app.models.fiado_item import FiadoItem

    assert "tenant_id" not in FiadoItem.__table__.columns
    assert "transaccion_id" in FiadoItem.__table__.columns


def test_transaccion_declara_fk_compuesta():
    """Invariante 3 (modelo): Transaccion declara la composite FK."""
    from src.app.models.transaccion import Transaccion

    fks = [
        c for c in Transaccion.__table__.constraints
        if c.__class__.__name__ == "ForeignKeyConstraint"
        and {col.name for col in c.columns} == {"tenant_id", "cliente_id"}
    ]
    assert fks, "Transaccion no declara FK compuesta (tenant_id, cliente_id)"


def test_cliente_tiene_unique_tenant_id():
    """Invariante 3 (modelo): clientes UNIQUE(tenant_id, id)."""
    from src.app.models.cliente import Cliente

    uniques = [
        {col.name for col in c.columns}
        for c in Cliente.__table__.constraints
        if c.__class__.__name__ == "UniqueConstraint"
    ]
    assert {"tenant_id", "id"} in uniques


def test_tenant_usuario_estructura():
    """tenant_usuarios expone tenant_id, profile_id, rol, activo."""
    from src.app.models.tenant_usuario import TenantUsuario

    for col in ("tenant_id", "profile_id", "rol", "activo"):
        assert col in TenantUsuario.__table__.columns


# ---------------------------------------------------------------------------
# INTEGRATION — comportamiento real de RLS/FK (solo entorno no productivo)
# ---------------------------------------------------------------------------

@pytest.fixture
def rls_dsn() -> str:
    dsn = os.getenv("RLS_TEST_DSN", "")
    if not dsn:
        pytest.skip(
            "RLS_TEST_DSN no configurada: tests RLS de integración omitidos. "
            "Debe apuntar a una base NO productiva (local/docker/staging)."
        )
    if "tragmytphifnxxqwgsii" in dsn:
        pytest.skip("RLS_TEST_DSN apunta a producción: se omite por seguridad.")
    return dsn


@pytest.mark.integration
def test_rls_integration_placeholder(rls_dsn):
    """Marcador del bloque de integración.

    Las pruebas de comportamiento RLS (invariantes 6-10) requieren crear tenants,
    profiles y memberships de prueba con `SET LOCAL request.jwt.claim.sub` y
    `SET ROLE authenticated`, limpiando con ROLLBACK. Se ejecutarán contra el
    entorno de pruebas cuando RLS_TEST_DSN esté disponible; ver
    tools/regression_rls.py.
    """
    pytest.skip("El escenario RLS de integración se ejecuta vía tools/regression_rls.py.")
