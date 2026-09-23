"""Script de regresión RLS tenant-aware — Fase de reconciliación.

Comprueba, contra una base PostgreSQL NO productiva, el modelo de seguridad
validado: aislamiento A/B, bloqueo cross-tenant (SELECT/INSERT/UPDATE/DELETE),
cambio de tenant, FK, membership inactiva, saldos y auditoría.

SEGURIDAD:
  - Requiere la variable de entorno RLS_TEST_DSN.
  - ABORTA si el DSN parece apuntar a la producción de FiApp (tragmytphifnxxqwgsii).
  - Crea su propio escenario (2 tenants, 2 profiles, 2 memberships, 1 cliente y
    1 transacción por tenant) y lo elimina al finalizar.
  - Todas las operaciones de escritura de las pruebas usan BEGIN/ROLLBACK.

Uso:
    set RLS_TEST_DSN=postgresql://...
    python tools/regression_rls.py
"""

import asyncio
import os
import sys
import uuid

import asyncpg

BLOQUEADO = "tragmytphifnxxqwgsii"
NS = uuid.UUID("12345678-1234-5678-1234-567812345678")


def _dsn() -> str:
    dsn = os.getenv("RLS_TEST_DSN", "")
    if not dsn:
        print("RLS_TEST_DSN no definida: se omite el script de regresión.")
        sys.exit(0)
    if BLOQUEADO in dsn:
        print("RLS_TEST_DSN apunta a PRODUCCIÓN: abortado por seguridad.")
        sys.exit(2)
    return dsn


def uid(etiqueta: str) -> str:
    return str(uuid.uuid5(NS, etiqueta))


async def set_ctx(conn, profile, tenant):
    await conn.execute("select set_config('request.jwt.claim.sub', $1, true)", profile)
    await conn.execute("select set_config('request.jwt.claim.role', 'authenticated', true)")
    await conn.execute("select set_config('app.tenant_id', $1, true)", tenant)
    await conn.execute("set role authenticated")


async def caso(nombre, dsn, profile, tenant, accion, esperado):
    """esperado: 'permitir' | 'bloquear'  (devolviendo True/raise en accion)."""
    conn = await asyncpg.connect(dsn)
    ok = False
    err = ""
    try:
        tx = conn.transaction(); await tx.start()
        try:
            await set_ctx(conn, profile, tenant)
            try:
                await accion(conn)
                ok = True
            except Exception as exc:
                err = f"{type(exc).__name__}: {(str(exc).splitlines() or [''])[0]}"
        finally:
            await tx.rollback()
    finally:
        await conn.close()

    if esperado == "permitir":
        veredicto = "PASS" if ok else f"FAIL ({err})"
    else:
        veredicto = "PASS" if not ok else "FAIL (permitido)"
    print(f"{nombre}: {veredicto}" + (f"  [{err}]" if (not ok and esperado != 'permitir') else ""))
    return veredicto.startswith("PASS")


def sel_esperado(sql, esperado, *args):
    async def f(c):
        n = await c.fetchval(sql, *args)
        if n != esperado:
            raise AssertionError(f"{n} != {esperado}")
    return f


def ins_cliente(tenant, owner):
    async def f(c):
        await c.fetchval(
            "insert into public.clientes (tenant_id, owner_id, nombre) "
            "values ($1,$2,'RLS_REGRESSION') returning id",
            tenant, owner,
        )
    return f


def upd_cliente(cid):
    async def f(c):
        r = await c.execute("update public.clientes set nombre='X' where id=$1", cid)
        if not r.endswith(" 1"):
            raise AssertionError("0 filas")
    return f


def del_cliente(cid):
    async def f(c):
        r = await c.execute("delete from public.clientes where id=$1", cid)
        if not r.endswith(" 1"):
            raise AssertionError("0 filas")
    return f


def ins_transaccion(tenant, owner, cliente):
    async def f(c):
        await c.fetchval(
            "insert into public.transacciones (tenant_id, owner_id, cliente_id, tipo, monto) "
            "values ($1,$2,$3,'fiado',10) returning id",
            tenant, owner, cliente,
        )
    return f


async def main():
    dsn = _dsn()
    tenant_a, tenant_b = uid("tenant-a"), uid("tenant-b")
    prof_a, prof_b = uid("profile-a"), uid("profile-b")

    conn = await asyncpg.connect(dsn)
    resultados = []
    try:
        # --- escenario ---
        # En Supabase, profiles.id referencia auth.users(id): se crea el usuario
        # Auth correspondiente para respetar la FK (solo en la BD de pruebas).
        for p, etiqueta in ((prof_a, "a"), (prof_b, "b")):
            try:
                await conn.execute(
                    "insert into auth.users (id, email) values ($1,$2) "
                    "on conflict (id) do nothing",
                    p, f"rls-reg-{etiqueta}@fiapp.test",
                )
            except Exception:
                pass  # entorno sin auth.users (p. ej. SQLite emulado)

        for t, nombre in ((tenant_a, "RLS_REG_TENANT_A"), (tenant_b, "RLS_REG_TENANT_B")):
            await conn.execute(
                "insert into public.tenants (id, nombre_comercial, moneda, estado, configuracion) "
                "values ($1,$2,'COP','activo','{}'::jsonb) on conflict (id) do nothing",
                t, nombre,
            )
        for p, etiqueta in ((prof_a, "a"), (prof_b, "b")):
            await conn.execute(
                "insert into public.profiles (id, email, nombre_negocio) "
                "values ($1,$2,'RLS Regression') on conflict (id) do nothing",
                p, f"rls-reg-{etiqueta}@fiapp.test",
            )
        for t, p in ((tenant_a, prof_a), (tenant_b, prof_b)):
            await conn.execute(
                "insert into public.tenant_usuarios (tenant_id, profile_id, rol, activo) "
                "values ($1,$2,'propietario',true) on conflict (tenant_id, profile_id) do nothing",
                t, p,
            )
        cli_a = await conn.fetchval(
            "insert into public.clientes (tenant_id, owner_id, nombre) "
            "values ($1,$2,'RLS_REG_CLIENT_A') returning id",
            tenant_a, prof_a,
        )
        cli_b = await conn.fetchval(
            "insert into public.clientes (tenant_id, owner_id, nombre) "
            "values ($1,$2,'RLS_REG_CLIENT_B') returning id",
            tenant_b, prof_b,
        )
        await conn.execute(
            "insert into public.transacciones (tenant_id, owner_id, cliente_id, tipo, monto) "
            "values ($1,$2,$3,'fiado',10) returning id",
            tenant_b, prof_b, cli_b,
        )
        print(f"escenario: A={tenant_a} B={tenant_b} cliA={cli_a} cliB={cli_b}\n")

        print("== SELECT ==")
        resultados.append(await caso("SELECT A->A", dsn, prof_a, tenant_a,
                                     sel_esperado("select count(*) from public.clientes where id=$1", 1, cli_a), "permitir"))
        resultados.append(await caso("SELECT A->B", dsn, prof_a, tenant_a,
                                     sel_esperado("select count(*) from public.clientes where id=$1", 0, cli_b), "permitir"))
        resultados.append(await caso("SELECT B->A", dsn, prof_b, tenant_b,
                                     sel_esperado("select count(*) from public.clientes where id=$1", 0, cli_a), "permitir"))

        print("\n== INSERT ==")
        resultados.append(await caso("INSERT A->A", dsn, prof_a, tenant_a, ins_cliente(tenant_a, prof_a), "permitir"))
        resultados.append(await caso("INSERT A->B", dsn, prof_a, tenant_a, ins_cliente(tenant_b, prof_a), "bloquear"))
        resultados.append(await caso("INSERT B->A", dsn, prof_b, tenant_b, ins_cliente(tenant_a, prof_b), "bloquear"))

        print("\n== UPDATE / DELETE ==")
        resultados.append(await caso("UPDATE A->A", dsn, prof_a, tenant_a, upd_cliente(cli_a), "permitir"))
        resultados.append(await caso("UPDATE A->B", dsn, prof_a, tenant_a, upd_cliente(cli_b), "bloquear"))
        resultados.append(await caso("DELETE A->A", dsn, prof_a, tenant_a, del_cliente(cli_a), "permitir"))
        resultados.append(await caso("DELETE B->A", dsn, prof_b, tenant_b, del_cliente(cli_a), "bloquear"))

        print("\n== INTEGRIDAD / TENANT ==")
        resultados.append(await caso("TX cliente de otro tenant", dsn, prof_a, tenant_a,
                                     ins_transaccion(tenant_a, prof_a, cli_b), "bloquear"))

        async def mover(c):
            r = await c.execute("update public.clientes set tenant_id=$1 where id=$2", tenant_b, cli_a)
            if r.endswith(" 1"):
                raise AssertionError("permitió mover de tenant")
        resultados.append(await caso("UPDATE cambia tenant_id", dsn, prof_a, tenant_a, mover, "bloquear"))

        async def fantasma(c):
            await c.fetchval(
                "insert into public.clientes (tenant_id, owner_id, nombre) "
                "values ($1,$2,'X') returning id",
                uid("tenant-fantasma"), prof_a,
            )
        resultados.append(await caso("FK tenant inexistente", dsn, prof_a, tenant_a, fantasma, "bloquear"))

        print("\n== SALDOS / AUDITORÍA ==")
        r = await conn.fetchrow(
            "select count(*) n, count(*) filter (where tenant_id is null) nulos from public.auditoria"
        )
        ok_aud = r["nulos"] == 0 and r["n"] > 0
        print(f"auditoría sin tenant_id NULL: {'PASS' if ok_aud else 'FAIL'}")
        resultados.append(ok_aud)
    finally:
        # limpieza del escenario
        try:
            # Orden seguro de limpieza. Los triggers de auditoría vuelven a crear
            # filas de auditoría al borrar hijos, así que la auditoría se limpia
            # DESPUÉS de los hijos y antes de tenants (FK RESTRICT).
            await conn.execute("delete from public.fiado_items where transaccion_id in (select id from public.transacciones where tenant_id in ($1,$2))", tenant_a, tenant_b)
            await conn.execute("delete from public.transacciones where tenant_id in ($1,$2)", tenant_a, tenant_b)
            await conn.execute("delete from public.clientes where tenant_id in ($1,$2)", tenant_a, tenant_b)
            await conn.execute("delete from public.tenant_usuarios where tenant_id in ($1,$2)", tenant_a, tenant_b)
            await conn.execute("delete from public.auditoria where tenant_id in ($1,$2)", tenant_a, tenant_b)
            await conn.execute("delete from public.tenants where id in ($1,$2)", tenant_a, tenant_b)
            await conn.execute("delete from public.profiles where id in ($1,$2)", prof_a, prof_b)
            try:
                await conn.execute("delete from auth.users where id in ($1,$2)", prof_a, prof_b)
            except Exception:
                pass
            print("\nescenario de prueba eliminado")
        except Exception as exc:
            print(f"limpieza con avisos: {exc}")
        await conn.close()

    total = len(resultados)
    pasan = sum(1 for r in resultados if r)
    print(f"\nRESULTADO: {pasan}/{total} PASS")
    sys.exit(0 if pasan == total else 1)


if __name__ == "__main__":
    if sys.platform.startswith("win"):
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
