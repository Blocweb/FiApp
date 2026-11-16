-- =============================================================================
-- MIGRACIÓN 006: Sprint 1 — HU01 (usuarios y roles) y HU02 (registrar clientes)
--
-- Tareas: T01 (datos de usuario), T08 (identificación, contacto y autorización
-- de datos del cliente), T10 (aviso de cliente duplicado), T12 (Ley 1581 de 2012)
-- y T13 (búsqueda por nombre).
--
-- Migración aditiva e idempotente: no borra ni modifica datos existentes.
-- Los clientes anteriores quedan sin identificación y sin autorización
-- registrada; la API exige ambos datos solo para los clientes nuevos.
-- =============================================================================

BEGIN;

-- T01: nombre de la persona, para mostrar quién registró cada movimiento.
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS nombre VARCHAR(150);

-- T08 / T12: identificación del cliente y autorización de tratamiento de datos.
ALTER TABLE public.clientes
    ADD COLUMN IF NOT EXISTS identificacion VARCHAR(30);

ALTER TABLE public.clientes
    ADD COLUMN IF NOT EXISTS autoriza_datos BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.clientes
    ADD COLUMN IF NOT EXISTS autoriza_datos_en TIMESTAMPTZ;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_clientes_autoriza_datos_fecha'
    ) THEN
        ALTER TABLE public.clientes
            ADD CONSTRAINT chk_clientes_autoriza_datos_fecha
            CHECK (NOT autoriza_datos OR autoriza_datos_en IS NOT NULL);
    END IF;
END $$;

COMMENT ON COLUMN public.clientes.identificacion IS 'Documento del cliente (cédula/NIT), normalizado sin puntos ni espacios';
COMMENT ON COLUMN public.clientes.autoriza_datos IS 'Autorización de tratamiento de datos personales (Ley 1581 de 2012)';
COMMENT ON COLUMN public.clientes.autoriza_datos_en IS 'Fecha y hora en que el cliente dio la autorización';

-- T10: un mismo documento no puede repetirse dentro del negocio.
CREATE UNIQUE INDEX IF NOT EXISTS uq_clientes_tenant_identificacion
    ON public.clientes (tenant_id, identificacion)
    WHERE identificacion IS NOT NULL AND deleted_at IS NULL;

-- T13: búsqueda de clientes por nombre dentro del negocio.
CREATE INDEX IF NOT EXISTS idx_clientes_tenant_nombre
    ON public.clientes (tenant_id, nombre)
    WHERE deleted_at IS NULL;

COMMIT;
