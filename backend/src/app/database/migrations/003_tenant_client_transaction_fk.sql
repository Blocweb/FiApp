-- =============================================================================
-- MIGRACION 003: integridad referencial compuesta por tenant
-- =============================================================================
--
-- Objetivo:
--   Garantizar que transacciones(tenant_id, cliente_id) solo referencie
--   clientes(tenant_id, id) dentro del mismo tenant.
--
-- Alcance:
--   - No modifica datos de negocio.
--   - No elimina owner_id ni columnas existentes.
--   - No modifica triggers, RLS, policies, vistas ni ORM.
--   - Se ejecuta dentro de una transaccion y aborta ante datos huerfanos.
-- =============================================================================

BEGIN;

-- PostgreSQL exige una constraint UNIQUE/PRIMARY KEY sobre exactamente las
-- columnas referenciadas por una FK compuesta.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class rel ON rel.oid = c.conrelid
        JOIN pg_namespace ns ON ns.oid = rel.relnamespace
        WHERE ns.nspname = 'public'
          AND rel.relname = 'clientes'
          AND c.contype IN ('p', 'u')
          AND c.conkey = ARRAY[
              (SELECT attnum
               FROM pg_attribute
               WHERE attrelid = rel.oid
                 AND attname = 'tenant_id'
                 AND NOT attisdropped),
              (SELECT attnum
               FROM pg_attribute
               WHERE attrelid = rel.oid
                 AND attname = 'id'
                 AND NOT attisdropped)
          ]::smallint[]
    ) THEN
        ALTER TABLE public.clientes
            ADD CONSTRAINT uq_clientes_tenant_id_id
            UNIQUE (tenant_id, id);
    END IF;
END $$;

-- No crear la FK si existe cualquier pareja tenant_id + cliente_id sin
-- correspondencia exacta en clientes. La excepcion provoca rollback completo.
DO $$
DECLARE
    v_orphan_count bigint;
    v_example_tenant uuid;
    v_example_cliente uuid;
BEGIN
    SELECT COUNT(*)
    INTO v_orphan_count
    FROM public.transacciones t
    LEFT JOIN public.clientes c
        ON c.tenant_id = t.tenant_id
       AND c.id = t.cliente_id
    WHERE c.id IS NULL;

    IF v_orphan_count > 0 THEN
        SELECT t.tenant_id, t.cliente_id
        INTO v_example_tenant, v_example_cliente
        FROM public.transacciones t
        LEFT JOIN public.clientes c
            ON c.tenant_id = t.tenant_id
           AND c.id = t.cliente_id
        WHERE c.id IS NULL
        LIMIT 1;

        RAISE EXCEPTION
            'Migracion abortada: % transacciones huerfanas. Ejemplo tenant_id=%, cliente_id=%',
            v_orphan_count,
            v_example_tenant,
            v_example_cliente;
    END IF;
END $$;

-- Crear la FK solo si no existe ya una FK equivalente.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class rel ON rel.oid = c.conrelid
        JOIN pg_namespace ns ON ns.oid = rel.relnamespace
        JOIN pg_class ref_rel ON ref_rel.oid = c.confrelid
        JOIN pg_namespace ref_ns ON ref_ns.oid = ref_rel.relnamespace
        WHERE ns.nspname = 'public'
          AND rel.relname = 'transacciones'
          AND ref_ns.nspname = 'public'
          AND ref_rel.relname = 'clientes'
          AND c.contype = 'f'
          AND c.conkey = ARRAY[
              (SELECT attnum
               FROM pg_attribute
               WHERE attrelid = rel.oid
                 AND attname = 'tenant_id'
                 AND NOT attisdropped),
              (SELECT attnum
               FROM pg_attribute
               WHERE attrelid = rel.oid
                 AND attname = 'cliente_id'
                 AND NOT attisdropped)
          ]::smallint[]
          AND c.confkey = ARRAY[
              (SELECT attnum
               FROM pg_attribute
               WHERE attrelid = ref_rel.oid
                 AND attname = 'tenant_id'
                 AND NOT attisdropped),
              (SELECT attnum
               FROM pg_attribute
               WHERE attrelid = ref_rel.oid
                 AND attname = 'id'
                 AND NOT attisdropped)
          ]::smallint[]
    ) THEN
        ALTER TABLE public.transacciones
            ADD CONSTRAINT fk_transacciones_tenant_cliente
            FOREIGN KEY (tenant_id, cliente_id)
            REFERENCES public.clientes (tenant_id, id)
            ON DELETE RESTRICT;
    END IF;
END $$;

COMMIT;
