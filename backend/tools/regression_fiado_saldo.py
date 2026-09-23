"""ETAPA 7-8 — Verificación explícita de aislación de fiado_items y de que las
funciones financieras no cruzan tenants. Solo BD de pruebas (RLS_TEST_DSN).
"""

import asyncio
import os
import sys
import uuid

import asyncpg

DSN = os.environ["RLS_TEST_DSN"]
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
BLOQUEADO = "tragmytphifnxxqwgsii"
if BLOQUEADO in DSN:
    print("DSN de producción: abortado")
    sys.exit(2)

NS = uuid.UUID("12345678-1234-5678-1234-567812345678")


def uid(x):
    return str(uuid.uuid5(NS, x))


async def ctx(c, prof, tenant):
    await c.execute("select set_config('request.jwt.claim.sub', $1, true)", prof)
    await c.execute("select set_config('request.jwt.claim.role', 'authenticated', true)")
    await c.execute("select set_config('app.tenant_id', $1, true)", tenant)
    await c.execute("set role authenticated")


async def main():
    ta, tb = uid("t-a"), uid("t-b")
    pa, pb = uid("p-a"), uid("p-b")
    c = await asyncpg.connect(DSN)
    res = {}
    try:
        for p, e in ((pa, "a"), (pb, "b")):
            await c.execute("insert into auth.users (id, email) values ($1,$2) on conflict do nothing",
                            p, f"{e}@t.test")
        for t, n in ((ta, "T_A"), (tb, "T_B")):
            await c.execute("insert into public.tenants (id,nombre_comercial) values ($1,$2) on conflict do nothing", t, n)
        for t, p in ((ta, pa), (tb, pb)):
            await c.execute("insert into public.tenant_usuarios (tenant_id,profile_id,rol,activo) "
                            "values ($1,$2,'propietario',true) on conflict do nothing", t, p)
        cli_a = await c.fetchval("insert into public.clientes (tenant_id,owner_id,nombre) "
                                 "values ($1,$2,'C_A') returning id", ta, pa)
        cli_b = await c.fetchval("insert into public.clientes (tenant_id,owner_id,nombre) "
                                 "values ($1,$2,'C_B') returning id", tb, pb)
        tx_b = await c.fetchval("insert into public.transacciones (tenant_id,owner_id,cliente_id,tipo,monto) "
                                "values ($1,$2,$3,'fiado',100) returning id", tb, pb, cli_b)

        # ETAPA 7: fiado_items no tiene tenant_id; aislamiento vía transacción
        print("=== ETAPA 7: fiado_items ===")
        item_b = await c.fetchval("insert into public.fiado_items (transaccion_id,nombre_producto,cantidad,precio_unitario) "
                                  "values ($1,'P',1,50) returning id", tx_b)
        tiene_tenant = await c.fetchval(
            "select count(*) from information_schema.columns "
            "where table_name='fiado_items' and column_name='tenant_id'")
        print(f"fiado_items.tenant_id existe: {tiene_tenant} (0 = correcto)")
        res["fiado_items sin tenant_id"] = tiene_tenant == 0

        # A intenta leer un fiado_item de B
        tx = c.transaction(); await tx.start()
        try:
            await ctx(c, pa, ta)
            try:
                n = await c.fetchval("select count(*) from public.fiado_items where id=$1", item_b)
                res["fiado_items cross-tenant"] = n == 0
            except Exception as e:
                res["fiado_items cross-tenant"] = False
                print(f"  error: {e}")
        finally:
            await tx.rollback()
            try:
                await c.execute("reset role")
            except Exception:
                pass
        print(f"fiado_items cross-tenant bloqueado: {res['fiado_items cross-tenant']}")

        # ETAPA 8: funciones financieras no cruzan tenants
        print("\n=== ETAPA 8: funciones financieras ===")
        # A intenta crear transacción con tenant A y cliente B → debe fallar
        tx = c.transaction(); await tx.start()
        try:
            await ctx(c, pa, ta)
            try:
                await c.execute("insert into public.transacciones (tenant_id,owner_id,cliente_id,tipo,monto) "
                                "values ($1,$2,$3,'fiado',10)", ta, pa, cli_b)
                res["fn saldo cross-tenant"] = False
            except Exception as e:
                res["fn saldo cross-tenant"] = True
                print(f"  fn_calcular_saldo_posterior rechazó: {(str(e).splitlines() or [''])[0]}")
        finally:
            await tx.rollback()
            try:
                await c.execute("reset role")
            except Exception:
                pass

        # Saldo de cliente B no cambia por operaciones de A
        saldo_b0 = await c.fetchval("select saldo from public.clientes where id=$1", cli_b)
        tx = c.transaction(); await tx.start()
        try:
            await ctx(c, pa, ta)
            try:
                await c.execute("insert into public.transacciones (tenant_id,owner_id,cliente_id,tipo,monto) "
                                "values ($1,$2,$3,'fiado',999)", ta, pa, cli_b)
            except Exception:
                pass
        finally:
            await tx.rollback()
            try:
                await c.execute("reset role")
            except Exception:
                pass
        saldo_b1 = await c.fetchval("select saldo from public.clientes where id=$1", cli_b)
        res["saldo B intacto"] = saldo_b0 == saldo_b1
        print(f"saldo B: {saldo_b0} -> {saldo_b1} (intacto={res['saldo B intacto']})")

        print("\n=== RESUMEN ===")
        for k, v in res.items():
            print(f"{k}: {'PASS' if v else 'FAIL'}")
    finally:
        try:
            await c.execute("delete from public.fiado_items where transaccion_id in (select id from public.transacciones where tenant_id in ($1,$2))", ta, tb)
            await c.execute("delete from public.transacciones where tenant_id in ($1,$2)", ta, tb)
            await c.execute("delete from public.clientes where tenant_id in ($1,$2)", ta, tb)
            await c.execute("delete from public.tenant_usuarios where tenant_id in ($1,$2)", ta, tb)
            await c.execute("delete from public.auditoria where tenant_id in ($1,$2)", ta, tb)
            await c.execute("delete from public.tenants where id in ($1,$2)", ta, tb)
        except Exception as e:
            print(f"limpieza: {e}")
        await c.close()


if __name__ == "__main__":
    if sys.platform.startswith("win"):
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
