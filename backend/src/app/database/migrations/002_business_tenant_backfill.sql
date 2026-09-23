-- =============================================================================
-- MIGRACIÓN 002: tenant_id en datos de negocio + backfill auditable
-- Fase 3.2: compatibilidad, backfill seguro y bloqueo de ambigüedad
-- =============================================================================
--
-- Objetivo:
--   1) Añadir tenant_id a tablas de negocio sin borrar owner_id ni columnas existentes.
--   2) Resolver tenant_id para perfiles con exactamente una membresía activa.
--   3) Crear tenant personal y membresía de propietario para perfiles sin membresía activa.
--   4) Bloquear perfiles con múltiples memberships activas para intervención manual.
--   5) NO aplicar NOT NULL ni FKs definitivas hasta validar ausencia de pendientes.
--
-- Nota importante:
--   - No se adivina ni se reparte tenant_id.
--   - Se mantiene owner_id para compatibilidad y trazabilidad durante la fase.
--   - El caso ambiguo queda bloqueado con diagnóstico y rollback completo.
-- =============================================================================

BEGIN;

-- 0) Contadores antes del backfill para auditoría y protección de integridad.
CREATE TEMP TABLE tenant_backfill_before (
    entidad text,
    total bigint
) ON COMMIT DROP;

INSERT INTO tenant_backfill_before (entidad, total)
SELECT 'clientes', COUNT(*) FROM public.clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM public.productos
UNION ALL
SELECT 'transacciones', COUNT(*) FROM public.transacciones
UNION ALL
SELECT 'fiado_items', COUNT(*) FROM public.fiado_items
UNION ALL
SELECT 'auditoria', COUNT(*) FROM public.auditoria
UNION ALL
SELECT 'exportaciones', COUNT(*) FROM public.exportaciones;

-- 1) Añadir tenant_id nullable para no romper datos actuales ni la app.
ALTER TABLE public.clientes
    ADD COLUMN IF NOT EXISTS tenant_id UUID;

ALTER TABLE public.productos
    ADD COLUMN IF NOT EXISTS tenant_id UUID;

ALTER TABLE public.transacciones
    ADD COLUMN IF NOT EXISTS tenant_id UUID;

ALTER TABLE public.exportaciones
    ADD COLUMN IF NOT EXISTS tenant_id UUID;

ALTER TABLE public.auditoria
    ADD COLUMN IF NOT EXISTS tenant_id UUID;

-- 2) Caso 1: profile con exactamente una membresía activa.
WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.clientes c
SET tenant_id = s.tenant_id
FROM single_active s
WHERE c.owner_id = s.profile_id
  AND c.tenant_id IS NULL;

WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.productos p
SET tenant_id = s.tenant_id
FROM single_active s
WHERE p.owner_id = s.profile_id
  AND p.tenant_id IS NULL;

WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.transacciones t
SET tenant_id = s.tenant_id
FROM single_active s
WHERE t.owner_id = s.profile_id
  AND t.tenant_id IS NULL;

WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.exportaciones e
SET tenant_id = s.tenant_id
FROM single_active s
WHERE e.owner_id = s.profile_id
  AND e.tenant_id IS NULL;

WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.auditoria a
SET tenant_id = s.tenant_id
FROM single_active s
WHERE a.owner_id = s.profile_id
  AND a.tenant_id IS NULL;

-- 3) Caso 2: profile sin ninguna membresía activa.
--    Crear tenant personal determinista y idempotente usando el profile.id como tenant.id.
WITH profiles_sin_membresia AS (
    SELECT p.id AS profile_id,
           p.nombre_negocio
    FROM public.profiles p
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.tenant_usuarios tu
        WHERE tu.profile_id = p.id
          AND tu.activo = true
    )
)
INSERT INTO public.tenants (id, nombre_comercial, identificacion_fiscal, moneda, telefono, estado, configuracion)
SELECT ps.profile_id,
       ps.nombre_negocio,
       NULL,
       'COP',
       NULL,
       'activo',
       '{"dias_gracia": 0, "interes_mora_defecto": 0.0}'::jsonb
FROM profiles_sin_membresia ps
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tenants t
    WHERE t.id = ps.profile_id
);

WITH profiles_sin_membresia AS (
    SELECT p.id AS profile_id
    FROM public.profiles p
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.tenant_usuarios tu
        WHERE tu.profile_id = p.id
          AND tu.activo = true
    )
)
INSERT INTO public.tenant_usuarios (tenant_id, profile_id, rol, activo)
SELECT ps.profile_id,
       ps.profile_id,
       'propietario',
       true
FROM profiles_sin_membresia ps
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tenant_usuarios tu
    WHERE tu.profile_id = ps.profile_id
      AND tu.tenant_id = ps.profile_id
      AND tu.rol = 'propietario'
      AND tu.activo = true
);

-- Reaplicar el backfill para perfiles con tenant personal creado por J.1.
WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.clientes c
SET tenant_id = s.tenant_id
FROM single_active s
WHERE c.owner_id = s.profile_id
  AND c.tenant_id IS NULL;

WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.productos p
SET tenant_id = s.tenant_id
FROM single_active s
WHERE p.owner_id = s.profile_id
  AND p.tenant_id IS NULL;

WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.transacciones t
SET tenant_id = s.tenant_id
FROM single_active s
WHERE t.owner_id = s.profile_id
  AND t.tenant_id IS NULL;

WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.exportaciones e
SET tenant_id = s.tenant_id
FROM single_active s
WHERE e.owner_id = s.profile_id
  AND e.tenant_id IS NULL;

WITH single_active AS (
    SELECT profile_id, MIN(tenant_id) AS tenant_id
    FROM public.tenant_usuarios
    WHERE activo = true
    GROUP BY profile_id
    HAVING COUNT(*) = 1
)
UPDATE public.auditoria a
SET tenant_id = s.tenant_id
FROM single_active s
WHERE a.owner_id = s.profile_id
  AND a.tenant_id IS NULL;

-- 4) Caso 3: profile con múltiples memberships activas.
--    Se bloquea con diagnóstico detallado; no se adivina ni se reparte nada.
DO $$
DECLARE
    v_ambiguous jsonb;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'profile_id', q.profile_id,
            'email', q.email,
            'active_memberships', q.active_memberships,
            'tenant_ids', q.tenant_ids,
            'clientes_pendientes', q.clientes_pendientes,
            'productos_pendientes', q.productos_pendientes,
            'transacciones_pendientes', q.transacciones_pendientes,
            'exportaciones_pendientes', q.exportaciones_pendientes,
            'auditoria_pendiente', q.auditoria_pendiente
        )
    )
    INTO v_ambiguous
    FROM (
        SELECT tu.profile_id,
               p.email,
               COUNT(*) AS active_memberships,
               array_agg(DISTINCT tu.tenant_id ORDER BY tu.tenant_id) AS tenant_ids,
               (
                   SELECT COUNT(*)
                   FROM public.clientes c
                   WHERE c.owner_id = tu.profile_id
                     AND c.tenant_id IS NULL
               ) AS clientes_pendientes,
               (
                   SELECT COUNT(*)
                   FROM public.productos p2
                   WHERE p2.owner_id = tu.profile_id
                     AND p2.tenant_id IS NULL
               ) AS productos_pendientes,
               (
                   SELECT COUNT(*)
                   FROM public.transacciones t
                   WHERE t.owner_id = tu.profile_id
                     AND t.tenant_id IS NULL
               ) AS transacciones_pendientes,
               (
                   SELECT COUNT(*)
                   FROM public.exportaciones e
                   WHERE e.owner_id = tu.profile_id
                     AND e.tenant_id IS NULL
               ) AS exportaciones_pendientes,
               (
                   SELECT COUNT(*)
                   FROM public.auditoria a
                   WHERE a.owner_id = tu.profile_id
                     AND a.tenant_id IS NULL
               ) AS auditoria_pendiente
        FROM public.tenant_usuarios tu
        JOIN public.profiles p ON p.id = tu.profile_id
        WHERE tu.activo = true
        GROUP BY tu.profile_id, p.email
        HAVING COUNT(*) > 1
    ) q;

    IF v_ambiguous IS NOT NULL THEN
        RAISE EXCEPTION 'Migración abortada por profiles con múltiples memberships activas: %', v_ambiguous;
    END IF;
END $$;

-- 5) Validar que no queden filas sin resolver. Si quedan pendientes, abortar.
DO $$
DECLARE
    v_pending_count bigint;
BEGIN
    SELECT COUNT(*) INTO v_pending_count
    FROM (
        SELECT 1 FROM public.clientes WHERE tenant_id IS NULL
        UNION ALL
        SELECT 1 FROM public.productos WHERE tenant_id IS NULL
        UNION ALL
        SELECT 1 FROM public.transacciones WHERE tenant_id IS NULL
        UNION ALL
        SELECT 1 FROM public.exportaciones WHERE tenant_id IS NULL
        UNION ALL
        SELECT 1 FROM public.auditoria WHERE tenant_id IS NULL
    ) pendientes;

    IF v_pending_count > 0 THEN
        RAISE EXCEPTION 'Migración abortada: existen filas pendientes de tenant_id: %', v_pending_count;
    END IF;
END $$;

-- 6) Contadores después del backfill para comprobar integridad.
CREATE TEMP TABLE tenant_backfill_after (
    entidad text,
    total bigint
) ON COMMIT DROP;

INSERT INTO tenant_backfill_after (entidad, total)
SELECT 'clientes', COUNT(*) FROM public.clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM public.productos
UNION ALL
SELECT 'transacciones', COUNT(*) FROM public.transacciones
UNION ALL
SELECT 'fiado_items', COUNT(*) FROM public.fiado_items
UNION ALL
SELECT 'auditoria', COUNT(*) FROM public.auditoria
UNION ALL
SELECT 'exportaciones', COUNT(*) FROM public.exportaciones;

-- 7) Solo aquí, si no quedan pendientes, se puede cerrar la fase de backfill.
ALTER TABLE public.clientes
    ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE public.productos
    ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE public.transacciones
    ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE public.exportaciones
    ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE public.auditoria
    ALTER COLUMN tenant_id SET NOT NULL;

-- 8) Se dejan las FKs definitivas y otros cambios de base de datos para una etapa posterior.
--    Este archivo corrige sólo J.1, J.2 y backfill seguro de tenant_id.

COMMIT;
