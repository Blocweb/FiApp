-- =============================================================================
-- MIGRACIÓN 001: Creación de entidades base para Multi-Tenancy
-- Tarea 1.1 - Fase 1: tenants y tenant_usuarios
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tabla: tenants
-- Representa a la organización o negocio dentro de FiApp SaaS.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_comercial VARCHAR(150) NOT NULL,
    identificacion_fiscal VARCHAR(50),
    moneda CHAR(3) NOT NULL DEFAULT 'COP',
    telefono VARCHAR(30),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo'
        CHECK (estado IN ('activo', 'suspendido', 'mora', 'cancelado')),
    configuracion JSONB NOT NULL DEFAULT '{"dias_gracia": 0, "interes_mora_defecto": 0.0}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.tenants IS 'Organizaciones o negocios registrados en FiApp SaaS';

-- Trigger para updated_at automático utilizando la función genérica existente
DROP TRIGGER IF EXISTS trg_tenants_updated_at ON public.tenants;
CREATE TRIGGER trg_tenants_updated_at
    BEFORE UPDATE ON public.tenants
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_updated_at();


-- -----------------------------------------------------------------------------
-- 2. Tabla: tenant_usuarios
-- Representa la membresía y rol de una persona (profile) dentro de un tenant.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tenant_usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL
        REFERENCES public.tenants(id)
        ON DELETE CASCADE,
    profile_id UUID NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,
    rol VARCHAR(20) NOT NULL
        CHECK (rol IN ('propietario', 'administrador', 'supervisor', 'cobrador')),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_tenant_usuarios_tenant_profile UNIQUE (tenant_id, profile_id)
);

COMMENT ON TABLE public.tenant_usuarios IS 'Membresías del personal y roles asignados por negocio';


-- -----------------------------------------------------------------------------
-- 3. Índices Estratégicos
-- Optimizados para consultas de autorización, listado por negocio y resolución de rol.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_tenant_usuarios_tenant
    ON public.tenant_usuarios(tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenant_usuarios_profile
    ON public.tenant_usuarios(profile_id);

CREATE INDEX IF NOT EXISTS idx_tenant_usuarios_rol
    ON public.tenant_usuarios(tenant_id, rol);

CREATE INDEX IF NOT EXISTS idx_tenant_usuarios_auth_lookup
    ON public.tenant_usuarios(profile_id, tenant_id)
    WHERE activo = true;

CREATE INDEX IF NOT EXISTS idx_tenants_estado
    ON public.tenants(estado)
    WHERE estado = 'activo';
