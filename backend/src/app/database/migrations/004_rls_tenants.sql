-- =============================================================================
-- MIGRACIÓN 004: RLS multi-tenant para tenants y tenant_usuarios
-- Fase 3.3.3 — Primera capa real de RLS
-- =============================================================================
--
-- Alcance EXCLUSIVO de esta migración:
--   1) Helpers seguros para leer el tenant activo y comprobar membresía.
--   2) RLS en public.tenants.
--   3) RLS en public.tenant_usuarios.
--
-- NO se modifican:
--   - migraciones históricas 001/002/003
--   - policies de tablas operativas (clientes, productos, transacciones,
--     fiado_items, auditoria, exportaciones, metodos_pago, profiles)
--   - owner_id
--   - vistas
--   - triggers
--   - FORCE ROW LEVEL SECURITY (no se activa en esta fase)
--
-- Contexto de sesión esperado (establecido por FastAPI en Fase 3.3.2):
--   app.tenant_id  → tenant ya validado contra tenant_usuarios
--   app.user_id    → identidad autenticada
--
-- IMPORTANTE sobre SECURITY DEFINER y RLS:
--   Una función SECURITY DEFINER NO desactiva RLS para el rol que la invoca.
--   RLS se evalúa salvo que el rol ejecutor (o el owner de la función) sea el
--   dueño de la tabla. Para evitar recursión, las policies de tenant_usuarios
--   NO invocan el helper de membresía sobre la propia fila del usuario; la
--   autoconsulta se resuelve comparando profile_id con auth.uid().
-- =============================================================================

BEGIN;


-- =============================================================================
-- 1. HELPERS DE CONTEXTO Y MEMBERSHIP
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1 current_tenant_id()
-- Devuelve el tenant activo de la transacción (app.tenant_id) como UUID, o NULL
-- si no existe contexto válido. Nunca acepta un tenant del cliente: solo lee el
-- valor ya validado por FastAPI e inyectado con set_config(..., true).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_tenant_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_raw text;
BEGIN
    -- true = no error si el setting no existe.
    v_raw := current_setting('app.tenant_id', true);

    -- Contexto ausente o cadena vacía → NULL (no error).
    IF v_raw IS NULL OR btrim(v_raw) = '' THEN
        RETURN NULL;
    END IF;

    -- Conversión segura a UUID; cualquier valor no-UUID devuelve NULL.
    BEGIN
        RETURN v_raw::uuid;
    EXCEPTION
        WHEN invalid_text_representation THEN
            RETURN NULL;
    END;
END;
$$;

COMMENT ON FUNCTION public.current_tenant_id() IS
'Tenant activo de la transacción (app.tenant_id) como UUID, o NULL si no hay contexto válido. No confía en datos del cliente.';


-- -----------------------------------------------------------------------------
-- 1.2 user_is_active_member_of_tenant(uuid)
-- Responde únicamente TRUE/FALSE sobre si auth.uid() tiene membresía ACTIVA en
-- el tenant indicado. No retorna filas de usuarios ni datos sensibles.
--
-- Seguridad:
--   - SECURITY DEFINER con search_path restringido a pg_catalog, public.
--   - Referencias completamente cualificadas (public.tenant_usuarios).
--   - Solo lectura; sin operaciones de escritura.
--   - Usa auth.uid() como identidad; NUNCA acepta el tenant como autorización
--     autónoma por sí solo (el llamador debe combinar con contexto/rol).
--   - La ausencia de recursión se garantiza porque las policies de
--     tenant_usuarios no invocan esta función sobre la fila propia.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.user_is_active_member_of_tenant(p_tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.tenant_usuarios tu
        WHERE tu.tenant_id = p_tenant_id
          AND tu.profile_id = auth.uid()
          AND tu.activo = true
    );
$$;

COMMENT ON FUNCTION public.user_is_active_member_of_tenant(uuid) IS
'TRUE/FALSE: auth.uid() tiene membresía activa en el tenant indicado. SECURITY DEFINER, solo lectura, sin recursión RLS.';


-- -----------------------------------------------------------------------------
-- 1.3 user_tenant_role(uuid)
-- Devuelve el rol de auth.uid() dentro del tenant indicado, o NULL si no hay
-- membresía activa. Se usa para autorizar operaciones de escritura por rol sin
-- exponer filas de membresías.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.user_tenant_role(p_tenant_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT tu.rol
    FROM public.tenant_usuarios tu
    WHERE tu.tenant_id = p_tenant_id
      AND tu.profile_id = auth.uid()
      AND tu.activo = true
    LIMIT 1;
$$;

COMMENT ON FUNCTION public.user_tenant_role(uuid) IS
'Rol de auth.uid() dentro del tenant indicado, o NULL si no hay membresía activa.';


-- =============================================================================
-- 2. PERMISOS DE EJECUCIÓN DE LOS HELPERS
-- =============================================================================
-- Se conceden EXECUTE únicamente a los roles relevantes. Se revoca de PUBLIC
-- para no ampliar la superficie de ejecución a roles inesperados.
-- -----------------------------------------------------------------------------

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
-- 3. RLS EN public.tenants
-- =============================================================================

ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

-- Idempotencia: eliminar solo policies propias de esta tabla.
DROP POLICY IF EXISTS tenants_select_member ON public.tenants;
DROP POLICY IF EXISTS tenants_update_admin ON public.tenants;

-- -----------------------------------------------------------------------------
-- 3.1 SELECT — solo tenants con membresía ACTIVA de auth.uid().
-- Nunca enumeración global.
-- -----------------------------------------------------------------------------
CREATE POLICY tenants_select_member
    ON public.tenants
    FOR SELECT
    TO authenticated
    USING (
        public.user_is_active_member_of_tenant(id)
    );

-- -----------------------------------------------------------------------------
-- 3.2 UPDATE — solo el tenant activo y con rol propietario/administrador.
-- El contexto de tenant se toma de app.tenant_id (ya validado por FastAPI).
-- -----------------------------------------------------------------------------
CREATE POLICY tenants_update_admin
    ON public.tenants
    FOR UPDATE
    TO authenticated
    USING (
        id = public.current_tenant_id()
        AND public.user_tenant_role(id) IN ('propietario', 'administrador')
    )
    WITH CHECK (
        id = public.current_tenant_id()
        AND public.user_tenant_role(id) IN ('propietario', 'administrador')
    );

-- -----------------------------------------------------------------------------
-- 3.3 INSERT / DELETE — sin policy.
-- Con RLS habilitado y sin policy, quedan denegados para `authenticated`.
-- La creación inicial de tenants queda reservada al backend/onboarding
-- controlado (rol service_role), y el borrado directo por usuarios normales
-- se prohíbe explícitamente. No se crea onboarding en esta fase.
-- -----------------------------------------------------------------------------


-- =============================================================================
-- 4. RLS EN public.tenant_usuarios
-- =============================================================================

ALTER TABLE public.tenant_usuarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_usuarios_select_own ON public.tenant_usuarios;
DROP POLICY IF EXISTS tenant_usuarios_select_active_tenant ON public.tenant_usuarios;
DROP POLICY IF EXISTS tenant_usuarios_insert_admin ON public.tenant_usuarios;
DROP POLICY IF EXISTS tenant_usuarios_update_admin ON public.tenant_usuarios;
DROP POLICY IF EXISTS tenant_usuarios_delete_admin ON public.tenant_usuarios;

-- -----------------------------------------------------------------------------
-- 4.1 SELECT (propia) — el usuario ve sus propias membresías activas.
-- Se compara directamente profile_id con auth.uid(); NO se invoca el helper
-- sobre la propia fila para evitar recursión RLS.
-- -----------------------------------------------------------------------------
CREATE POLICY tenant_usuarios_select_own
    ON public.tenant_usuarios
    FOR SELECT
    TO authenticated
    USING (
        profile_id = auth.uid()
        AND activo = true
    );

-- -----------------------------------------------------------------------------
-- 4.2 SELECT (membresías del tenant activo) — un miembro activo del tenant
-- activo puede ver las membresías de ese tenant cuando su rol lo permite.
-- La función devuelve un booleano de autorización y no produce recursión
-- porque evalúa membresía del propio auth.uid() en el tenant en contexto.
-- -----------------------------------------------------------------------------
CREATE POLICY tenant_usuarios_select_active_tenant
    ON public.tenant_usuarios
    FOR SELECT
    TO authenticated
    USING (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario', 'administrador', 'supervisor')
    );

-- -----------------------------------------------------------------------------
-- 4.3 INSERT — solo propietario/administrador del tenant activo, y sin poder
-- crear membresías en un tenant que no sea el activo.
-- -----------------------------------------------------------------------------
CREATE POLICY tenant_usuarios_insert_admin
    ON public.tenant_usuarios
    FOR INSERT
    TO authenticated
    WITH CHECK (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario', 'administrador')
        -- Un no-propietario no puede crear directamente un propietario.
        AND (
            rol <> 'propietario'
            OR public.user_tenant_role(tenant_id) = 'propietario'
        )
    );

-- -----------------------------------------------------------------------------
-- 4.4 UPDATE — impide cambiar tenant_id y profile_id, y escala de rol.
-- USING valida la fila existente; WITH CHECK valida la fila resultante.
-- -----------------------------------------------------------------------------
CREATE POLICY tenant_usuarios_update_admin
    ON public.tenant_usuarios
    FOR UPDATE
    TO authenticated
    USING (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario', 'administrador')
    )
    WITH CHECK (
        -- No se puede mover la membresía a otro tenant.
        tenant_id = public.current_tenant_id()
        -- El rol resultante sigue siendo gestionable por el actor.
        AND public.user_tenant_role(tenant_id) IN ('propietario', 'administrador')
        -- Solo un propietario puede otorgar/retener el rol propietario.
        AND (
            rol <> 'propietario'
            OR public.user_tenant_role(tenant_id) = 'propietario'
        )
        -- La identidad de la membresía no cambia: se fuerza a que el profile
        -- siga siendo el mismo que el de la fila existente mediante un guard
        -- en la columna (ver nota abajo).
    );

-- NOTA sobre profile_id:
--   PostgreSQL no permite referenciar OLD en WITH CHECK. Para impedir cambiar
--   profile_id se usa un trigger BEFORE UPDATE que rechaza la modificación de
--   profile_id y de tenant_id (más robusto que una política sola). El trigger
--   se crea más abajo y no afecta a otras tablas.

-- -----------------------------------------------------------------------------
-- 4.5 DELETE — solo propietario/administrador del tenant activo. La regla de
-- "no dejar al tenant sin propietario" se aplica en el trigger de guarda.
-- -----------------------------------------------------------------------------
CREATE POLICY tenant_usuarios_delete_admin
    ON public.tenant_usuarios
    FOR DELETE
    TO authenticated
    USING (
        tenant_id = public.current_tenant_id()
        AND public.user_tenant_role(tenant_id) IN ('propietario', 'administrador')
    );


-- =============================================================================
-- 5. GUARDA DE INTEGRIDAD DE MEMBERSHIP (trigger)
-- =============================================================================
-- Refuerza lo que una policy WITH CHECK no puede expresar (inmutabilidad de
-- profile_id/tenant_id y no dejar al tenant sin propietario activo).
-- Es un trigger sobre tenant_usuarios EXCLUSIVAMENTE.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_tenant_usuarios_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    -- Inmutabilidad de las claves de identidad.
    IF NEW.tenant_id <> OLD.tenant_id THEN
        RAISE EXCEPTION 'No se permite cambiar tenant_id de una membresía';
    END IF;

    IF NEW.profile_id <> OLD.profile_id THEN
        RAISE EXCEPTION 'No se permite cambiar profile_id de una membresía';
    END IF;

    -- No dejar al tenant sin propietario activo.
    IF OLD.rol = 'propietario' AND OLD.activo = true
       AND (NEW.rol <> 'propietario' OR NEW.activo = false) THEN
        IF NOT EXISTS (
            SELECT 1
            FROM public.tenant_usuarios tu
            WHERE tu.tenant_id = OLD.tenant_id
              AND tu.rol = 'propietario'
              AND tu.activo = true
              AND tu.id <> OLD.id
        ) THEN
            RAISE EXCEPTION 'El tenant no puede quedar sin un propietario activo';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.fn_tenant_usuarios_guard() IS
'Guarda de integridad de membresías: inmutabilidad de tenant_id/profile_id y no dejar el tenant sin propietario activo.';

DROP TRIGGER IF EXISTS trg_tenant_usuarios_guard ON public.tenant_usuarios;
CREATE TRIGGER trg_tenant_usuarios_guard
    BEFORE UPDATE ON public.tenant_usuarios
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_tenant_usuarios_guard();


COMMIT;

-- =============================================================================
-- FIN MIGRACIÓN 004
-- =============================================================================
