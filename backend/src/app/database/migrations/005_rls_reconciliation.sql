-- =============================================================================
-- MIGRACIÓN 005: RECONCILIACIÓN RLS MULTI-TENANT (estado real de producción)
-- =============================================================================
--
-- PROPÓSITO
--   Reconciliar el repositorio con el estado de seguridad multi-tenant ya
--   implementado y validado en producción (Fases 3.3.x), de forma que un
--   entorno nuevo pueda reconstruirse con el MISMO modelo de seguridad.
--
--   Esta migración NO se ha ejecutado contra producción (su estado ya existe).
--   Producción es la referencia; este archivo la representa.
--
-- PRERREQUISITOS (ya presentes vía migraciones 001-003):
--   - public.tenants, public.tenant_usuarios
--   - tenant_id en clientes/productos/transacciones/auditoria/exportaciones
--   - FK compuesta transacciones(tenant_id, cliente_id) -> clientes(tenant_id, id)
--   - UNIQUE clientes(tenant_id, id)
--
-- QUÉ AÑADE ESTA MIGRACIÓN
--   1. 5 FK tenant_id -> tenants(id) ON DELETE RESTRICT
--   2. Funciones financieras tenant-aware (reemplazo)
--   3. fn_auditoria tenant-aware (reemplazo)
--   4. Helpers RLS: current_tenant_id / user_is_active_member_of_tenant / user_tenant_role
--   5. Revoke/Grant de EXECUTE de los helpers
--   6. RLS + policies tenant-aware en: tenants, tenant_usuarios, clientes,
--      productos, transacciones, fiado_items, auditoria, exportaciones
--
-- QUÉ NO TOCA (deliberadamente)
--   - profiles: policies se mantienen en su forma individual (id = auth.uid())
--   - metodos_pago: catálogo global; su policy SELECT no cambia
--   - La FK legacy transacciones.cliente_id -> clientes(id) SE CONSERVA
--   - NO se activa FORCE ROW LEVEL SECURITY
--   - NO se eliminan datos ni memberships
--
-- IDEMPOTENCIA
--   Todas las operaciones usan IF NOT EXISTS / CREATE OR REPLACE / DROP POLICY
--   IF EXISTS, por lo que reejecutarla no rompe.
--
-- SECURITY DEFINER — JUSTIFICACIÓN
--   RLS se evalúa para el rol ejecutor. Los helpers necesitan leer
--   tenant_usuarios (que ahora tiene RLS) para resolver membership. Sin
--   SECURITY DEFINER, la propia policy de tenant_usuarios produciría
--   recursión. Por eso se definen SECURITY DEFINER con
--   `SET search_path = pg_catalog, public`, referencias cualificadas, solo
--   lectura y salida mínima (boolean/text). NO conceden acceso a datos: solo
--   responden a preguntas de autorización sobre el propio auth.uid().
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. FOREIGN KEYS tenant_id -> tenants(id)
-- =============================================================================
DO $$
DECLARE
    t text;
    fk text;
    pares text[][] := ARRAY[
        ['clientes',      'fk_clientes_tenant'],
        ['productos',     'fk_productos_tenant'],
        ['transacciones', 'fk_transacciones_tenant'],
        ['auditoria',     'fk_auditoria_tenant'],
        ['exportaciones', 'fk_exportaciones_tenant']
    ];
    i int;
BEGIN
    FOR i IN 1..array_length(pares, 1) LOOP
        t  := pares[i][1];
        fk := pares[i][2];
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conname = fk AND connamespace = 'public'::regnamespace
        ) THEN
            EXECUTE format(
                'ALTER TABLE public.%I ADD CONSTRAINT %I '
                'FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE RESTRICT',
                t, fk
            );
        END IF;
    END LOOP;
END $$;


-- =============================================================================
-- 2. FUNCIONES FINANCIERAS TENANT-AWARE
-- =============================================================================

-- 2.1 fn_calcular_saldo_posterior
--     Identidad operacional = (tenant_id, cliente_id). Bloquea la fila con
--     FOR UPDATE. NO depende de owner_id para autorizar pertenencia.
CREATE OR REPLACE FUNCTION public.fn_calcular_saldo_posterior()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = pg_catalog, public
AS $function$
DECLARE
    saldo_actual   numeric(12,2);
    owner_cliente  uuid;
    tenant_cliente uuid;
BEGIN
    IF NEW.tenant_id IS NULL THEN
        RAISE EXCEPTION 'La transaccion requiere tenant_id';
    END IF;

    SELECT saldo, owner_id, tenant_id
      INTO saldo_actual, owner_cliente, tenant_cliente
      FROM public.clientes
     WHERE id = NEW.cliente_id
       AND tenant_id = NEW.tenant_id
     FOR UPDATE;

    IF tenant_cliente IS NULL THEN
        RAISE EXCEPTION 'Cliente no existe o no pertenece al tenant de la transaccion';
    END IF;

    IF NEW.tipo = 'fiado' THEN
        NEW.saldo_posterior = saldo_actual + NEW.monto;
    ELSE
        IF NEW.monto > saldo_actual THEN
            RAISE EXCEPTION 'El abono supera la deuda actual';
        END IF;
        NEW.saldo_posterior = saldo_actual - NEW.monto;
    END IF;

    RETURN NEW;
END;
$function$;


-- 2.2 fn_actualizar_cliente_tras_transaccion
--     El SUM(...) y el UPDATE están restringidos por tenant_id. Una transacción
--     de Tenant A no puede recalcular el saldo de un cliente de Tenant B.
CREATE OR REPLACE FUNCTION public.fn_actualizar_cliente_tras_transaccion()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = pg_catalog, public
AS $function$
DECLARE
    v_cliente_id uuid;
    v_tenant_id  uuid;
BEGIN
    v_cliente_id := COALESCE(NEW.cliente_id, OLD.cliente_id);
    v_tenant_id  := CASE WHEN TG_OP = 'DELETE' THEN OLD.tenant_id ELSE NEW.tenant_id END;

    IF v_tenant_id IS NULL THEN
        RAISE EXCEPTION 'La transaccion requiere tenant_id';
    END IF;

    UPDATE public.clientes
       SET saldo = COALESCE(
               (
                   SELECT SUM(CASE WHEN tipo = 'fiado' THEN monto ELSE -monto END)
                     FROM public.transacciones
                    WHERE cliente_id = v_cliente_id
                      AND tenant_id  = v_tenant_id
                      AND deleted_at IS NULL
               ),
               0
           ),
           ultimo_movimiento_en = (
                   SELECT MAX(fecha_hora)
                     FROM public.transacciones
                    WHERE cliente_id = v_cliente_id
                      AND tenant_id  = v_tenant_id
                      AND deleted_at IS NULL
           )
     WHERE id = v_cliente_id
       AND tenant_id = v_tenant_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente no existe o no pertenece al tenant de la transaccion';
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$function$;


-- =============================================================================
-- 3. fn_auditoria TENANT-AWARE
--     INSERT -> NEW.tenant_id ; UPDATE -> NEW.tenant_id ; DELETE -> OLD.tenant_id
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_auditoria()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = pg_catalog, public
AS $function$
DECLARE
    v_owner     uuid;
    v_tenant_id uuid;
BEGIN
    v_owner     := COALESCE(NEW.owner_id, OLD.owner_id);
    v_tenant_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.tenant_id ELSE NEW.tenant_id END;

    INSERT INTO public.auditoria
    (tenant_id, owner_id, tabla, registro_id, accion,
     datos_anteriores, datos_nuevos, realizado_por)
    VALUES
    (v_tenant_id, v_owner, TG_TABLE_NAME, COALESCE(NEW.id, OLD.id), TG_OP,
     CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN TO_JSONB(OLD) ELSE NULL END,
     CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN TO_JSONB(NEW) ELSE NULL END,
     auth.uid());

    RETURN COALESCE(NEW, OLD);
END;
$function$;


-- =============================================================================
-- 4. HELPERS RLS
-- =============================================================================

-- 4.1 current_tenant_id()
--     NO confía ciegamente en app.tenant_id: lo valida contra una membership
--     ACTIVA de auth.uid(). Devuelve NULL si no hay contexto válido o si el
--     usuario no pertenece al tenant solicitado.
CREATE OR REPLACE FUNCTION public.current_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
    SELECT tu.tenant_id
      FROM public.tenant_usuarios tu
     WHERE tu.profile_id = auth.uid()
       AND tu.tenant_id = NULLIF(btrim(current_setting('app.tenant_id', true)), '')::uuid
       AND tu.activo = true
     LIMIT 1;
$function$;

-- 4.2 user_is_active_member_of_tenant(uuid)
CREATE OR REPLACE FUNCTION public.user_is_active_member_of_tenant(p_tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
    SELECT EXISTS (
        SELECT 1
          FROM public.tenant_usuarios tu
         WHERE tu.tenant_id = p_tenant_id
           AND tu.profile_id = auth.uid()
           AND tu.activo = true
    );
$function$;

-- 4.3 user_tenant_role(uuid)
CREATE OR REPLACE FUNCTION public.user_tenant_role(p_tenant_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
    SELECT tu.rol
      FROM public.tenant_usuarios tu
     WHERE tu.tenant_id = p_tenant_id
       AND tu.profile_id = auth.uid()
       AND tu.activo = true
     LIMIT 1;
$function$;


-- =============================================================================
-- 5. PERMISOS DE LOS HELPERS
-- =============================================================================
REVOKE ALL ON FUNCTION public.current_tenant_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.user_is_active_member_of_tenant(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.user_tenant_role(uuid) FROM PUBLIC;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        GRANT EXECUTE ON FUNCTION public.current_tenant_id() TO authenticated;
        GRANT EXECUTE ON FUNCTION public.user_is_active_member_of_tenant(uuid) TO authenticated;
        GRANT EXECUTE ON FUNCTION public.user_tenant_role(uuid) TO authenticated;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        GRANT EXECUTE ON FUNCTION public.current_tenant_id() TO service_role;
        GRANT EXECUTE ON FUNCTION public.user_is_active_member_of_tenant(uuid) TO service_role;
        GRANT EXECUTE ON FUNCTION public.user_tenant_role(uuid) TO service_role;
    END IF;
END $$;


-- =============================================================================
-- 6. RLS
-- =============================================================================
-- RLS debe estar habilitado en TODAS las tablas operativas. Se reafirma aquí de
-- forma idempotente para que un entorno reconstruido desde el repo no quede con
-- RLS desactivado aunque la sección base se haya aplicado de otro modo.
ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.productos     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transacciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiado_items   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.metodos_pago  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auditoria     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exportaciones ENABLE ROW LEVEL SECURITY;

-- 6.1 TENANTS
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenants_select_member ON public.tenants;
DROP POLICY IF EXISTS tenants_update_admin ON public.tenants;

CREATE POLICY tenants_select_member ON public.tenants
    FOR SELECT TO authenticated
    USING (public.user_is_active_member_of_tenant(id));

CREATE POLICY tenants_update_admin ON public.tenants
    FOR UPDATE TO authenticated
    USING (
        id = public.current_tenant_id()
        AND public.user_tenant_role(id) IN ('propietario','administrador')
    )
    WITH CHECK (
        id = public.current_tenant_id()
        AND public.user_tenant_role(id) IN ('propietario','administrador')
    );

-- 6.2 TENANT_USUARIOS
ALTER TABLE public.tenant_usuarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_usuarios_select_own ON public.tenant_usuarios;
DROP POLICY IF EXISTS tenant_usuarios_select_tenant ON public.tenant_usuarios;
DROP POLICY IF EXISTS tenant_usuarios_insert_admin ON public.tenant_usuarios;
DROP POLICY IF EXISTS tenant_usuarios_update_admin ON public.tenant_usuarios;
DROP POLICY IF EXISTS tenant_usuarios_delete_admin ON public.tenant_usuarios;

CREATE POLICY tenant_usuarios_select_own ON public.tenant_usuarios
    FOR SELECT TO authenticated
    USING (profile_id = auth.uid());

CREATE POLICY tenant_usuarios_select_tenant ON public.tenant_usuarios
    FOR SELECT TO authenticated
    USING (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario','administrador','supervisor')
    );

CREATE POLICY tenant_usuarios_insert_admin ON public.tenant_usuarios
    FOR INSERT TO authenticated
    WITH CHECK (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario','administrador')
        AND (rol <> 'propietario' OR public.user_tenant_role(tenant_id) = 'propietario')
    );

CREATE POLICY tenant_usuarios_update_admin ON public.tenant_usuarios
    FOR UPDATE TO authenticated
    USING (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario','administrador')
    )
    WITH CHECK (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario','administrador')
        AND (rol <> 'propietario' OR public.user_tenant_role(tenant_id) = 'propietario')
    );

CREATE POLICY tenant_usuarios_delete_admin ON public.tenant_usuarios
    FOR DELETE TO authenticated
    USING (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario','administrador')
    );

-- 6.3 CLIENTES
DROP POLICY IF EXISTS clientes_select_own ON public.clientes;
DROP POLICY IF EXISTS clientes_insert_own ON public.clientes;
DROP POLICY IF EXISTS clientes_update_own ON public.clientes;
DROP POLICY IF EXISTS clientes_delete_own ON public.clientes;

CREATE POLICY clientes_select_tenant ON public.clientes
    FOR SELECT TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY clientes_insert_tenant ON public.clientes
    FOR INSERT TO authenticated
    WITH CHECK (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY clientes_update_tenant ON public.clientes
    FOR UPDATE TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id))
    WITH CHECK (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY clientes_delete_tenant ON public.clientes
    FOR DELETE TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

-- 6.4 PRODUCTOS
DROP POLICY IF EXISTS productos_select_own ON public.productos;
DROP POLICY IF EXISTS productos_insert_own ON public.productos;
DROP POLICY IF EXISTS productos_update_own ON public.productos;
DROP POLICY IF EXISTS productos_delete_own ON public.productos;

CREATE POLICY productos_select_tenant ON public.productos
    FOR SELECT TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY productos_insert_tenant ON public.productos
    FOR INSERT TO authenticated
    WITH CHECK (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY productos_update_tenant ON public.productos
    FOR UPDATE TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id))
    WITH CHECK (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY productos_delete_tenant ON public.productos
    FOR DELETE TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

-- 6.5 TRANSACCIONES (el cliente debe pertenecer al mismo tenant)
DROP POLICY IF EXISTS transacciones_select_own ON public.transacciones;
DROP POLICY IF EXISTS transacciones_insert_own ON public.transacciones;
DROP POLICY IF EXISTS transacciones_update_own ON public.transacciones;
DROP POLICY IF EXISTS transacciones_delete_own ON public.transacciones;

CREATE POLICY transacciones_select_tenant ON public.transacciones
    FOR SELECT TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY transacciones_insert_tenant ON public.transacciones
    FOR INSERT TO authenticated
    WITH CHECK (
        public.user_is_active_member_of_tenant(tenant_id)
        AND EXISTS (
            SELECT 1 FROM public.clientes c
             WHERE c.id = cliente_id
               AND c.tenant_id = transacciones.tenant_id
        )
    );

CREATE POLICY transacciones_update_tenant ON public.transacciones
    FOR UPDATE TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id))
    WITH CHECK (
        public.user_is_active_member_of_tenant(tenant_id)
        AND EXISTS (
            SELECT 1 FROM public.clientes c
             WHERE c.id = cliente_id
               AND c.tenant_id = transacciones.tenant_id
        )
    );

CREATE POLICY transacciones_delete_tenant ON public.transacciones
    FOR DELETE TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

-- 6.6 FIADO_ITEMS (tenant derivado de transacciones; sin tenant_id propio)
DROP POLICY IF EXISTS fiado_items_select_own ON public.fiado_items;
DROP POLICY IF EXISTS fiado_items_insert_own ON public.fiado_items;
DROP POLICY IF EXISTS fiado_items_update_own ON public.fiado_items;
DROP POLICY IF EXISTS fiado_items_delete_own ON public.fiado_items;

CREATE POLICY fiado_items_select_tenant ON public.fiado_items
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.transacciones t
             WHERE t.id = transaccion_id
               AND public.user_is_active_member_of_tenant(t.tenant_id)
        )
    );

CREATE POLICY fiado_items_insert_tenant ON public.fiado_items
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.transacciones t
             WHERE t.id = transaccion_id
               AND public.user_is_active_member_of_tenant(t.tenant_id)
        )
    );

CREATE POLICY fiado_items_update_tenant ON public.fiado_items
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.transacciones t
             WHERE t.id = transaccion_id
               AND public.user_is_active_member_of_tenant(t.tenant_id)
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.transacciones t
             WHERE t.id = transaccion_id
               AND public.user_is_active_member_of_tenant(t.tenant_id)
        )
    );

CREATE POLICY fiado_items_delete_tenant ON public.fiado_items
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.transacciones t
             WHERE t.id = transaccion_id
               AND public.user_is_active_member_of_tenant(t.tenant_id)
        )
    );

-- 6.7 AUDITORIA (solo lectura tenant-aware; escritura vía trigger SECURITY DEFINER)
DROP POLICY IF EXISTS auditoria_select_own ON public.auditoria;

CREATE POLICY auditoria_select_tenant ON public.auditoria
    FOR SELECT TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

-- 6.8 EXPORTACIONES
DROP POLICY IF EXISTS exportaciones_select_own ON public.exportaciones;
DROP POLICY IF EXISTS exportaciones_insert_own ON public.exportaciones;
DROP POLICY IF EXISTS exportaciones_update_own ON public.exportaciones;
DROP POLICY IF EXISTS exportaciones_delete_own ON public.exportaciones;

CREATE POLICY exportaciones_select_tenant ON public.exportaciones
    FOR SELECT TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY exportaciones_insert_tenant ON public.exportaciones
    FOR INSERT TO authenticated
    WITH CHECK (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY exportaciones_update_tenant ON public.exportaciones
    FOR UPDATE TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id))
    WITH CHECK (public.user_is_active_member_of_tenant(tenant_id));

CREATE POLICY exportaciones_delete_tenant ON public.exportaciones
    FOR DELETE TO authenticated
    USING (public.user_is_active_member_of_tenant(tenant_id));

-- 6.9 PROFILES y METODOS_PAGO: sin cambios (se mantienen sus policies actuales).

COMMIT;

-- =============================================================================
-- FIN MIGRACIÓN 005
-- =============================================================================
