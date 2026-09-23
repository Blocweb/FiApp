-- =============================================================================
-- FiApp — Esquema Supabase PostgreSQL
-- Versión corregida con catálogo de productos
--
-- NOTA DE RECONCILIACIÓN (Fase de reconciliación repo↔producción):
--   Este script representa el estado FINAL validado en producción. Las tablas
--   operativas son tenant-aware (tenant_id), el aislamiento se resuelve por
--   tenant + membership activa, y las policies legacy basadas únicamente en
--   owner_id = auth.uid() fueron reemplazadas. La sección 7 (RECONCILIACIÓN
--   MULTI-TENANT) contiene el modelo de seguridad vigente y debe aplicarse
--   después de las secciones 1-6. Ver también
--   migrations/005_rls_reconciliation.sql.
-- =============================================================================

-- =============================================================================
-- 0. EXTENSIONES
-- =============================================================================

create extension if not exists "pgcrypto";
create extension if not exists "pg_trgm";


-- =============================================================================
-- 1. TABLAS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1.1 profiles
-- -----------------------------------------------------------------------------

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    nombre_negocio varchar(150) not null default 'Mi tienda',
    email varchar(255) not null,
    plan varchar(20) not null default 'gratuito'
        check(plan in ('gratuito','pro')),
    rol varchar(20) not null default 'propietario'
        check(rol in ('propietario','empleado')),
    modo_oscuro boolean not null default false,
    respaldo_nube boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- -----------------------------------------------------------------------------
-- 1.2 metodos_pago
-- -----------------------------------------------------------------------------

create table public.metodos_pago (
    id smallserial primary key,
    nombre varchar(40) not null unique,
    activo boolean not null default true,
    orden smallint not null default 0
);


-- -----------------------------------------------------------------------------
-- 1.3 clientes
-- -----------------------------------------------------------------------------

create table public.clientes (
    id uuid primary key default gen_random_uuid(),

    tenant_id uuid not null
        references public.tenants(id)
        on delete restrict,

    owner_id uuid not null
        references public.profiles(id)
        on delete cascade,

    nombre varchar(150) not null,
    telefono varchar(30) not null default '',
    direccion varchar(255) not null default '',
    notas text not null default '',

    color_hex char(7) not null default '#2563EB',

    saldo numeric(12,2) not null default 0
        check(saldo >= 0),

    ultimo_movimiento_en timestamptz,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    deleted_at timestamptz
);


-- -----------------------------------------------------------------------------
-- 1.4 productos
-- Catálogo del negocio
-- -----------------------------------------------------------------------------

create table public.productos (

    id uuid primary key default gen_random_uuid(),

    tenant_id uuid not null
        references public.tenants(id)
        on delete restrict,

    owner_id uuid not null
        references public.profiles(id)
        on delete cascade,

    nombre varchar(150) not null,

    descripcion text not null default '',

    precio numeric(12,2) not null
        check(precio >= 0),

    activo boolean not null default true,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now(),

    deleted_at timestamptz
);


comment on table public.productos is
'Catálogo de productos disponibles para registrar fiados';


-- -----------------------------------------------------------------------------
-- 1.5 transacciones
-- -----------------------------------------------------------------------------

create table public.transacciones (

    id uuid primary key default gen_random_uuid(),

    tenant_id uuid not null
        references public.tenants(id)
        on delete restrict,

    owner_id uuid not null
        references public.profiles(id)
        on delete cascade,

    -- FK legacy conservada deliberadamente (compatibilidad histórica).
    -- La integridad tenant-aware se refuerza con la FK compuesta
    -- (tenant_id, cliente_id) -> clientes(tenant_id, id) definida abajo.
    cliente_id uuid not null
        references public.clientes(id)
        on delete restrict,

    tipo varchar(10) not null
        check(tipo in ('fiado','abono')),

    monto numeric(12,2) not null
        check(monto > 0),

    metodo_pago_id smallint
        references public.metodos_pago(id)
        on delete restrict,

    nota text,

    saldo_posterior numeric(12,2)
        not null default 0,

    fecha_hora timestamptz
        not null default now(),

    created_at timestamptz
        not null default now(),

    deleted_at timestamptz,


    constraint chk_metodo_pago_tipo check(

        (tipo='abono' and metodo_pago_id is not null)

        or

        (tipo='fiado' and metodo_pago_id is null)

    ),

    -- Integridad referencial compuesta por tenant (migración 003).
    constraint fk_transacciones_tenant_cliente
        foreign key (tenant_id, cliente_id)
        references public.clientes (tenant_id, id)
        on delete restrict
);



-- -----------------------------------------------------------------------------
-- 1.6 fiado_items
-- Productos incluidos en cada fiado
-- -----------------------------------------------------------------------------

create table public.fiado_items (

    id uuid primary key default gen_random_uuid(),

    transaccion_id uuid not null
        references public.transacciones(id)
        on delete cascade,


    producto_id uuid
        references public.productos(id)
        on delete set null,


    nombre_producto varchar(150) not null,


    cantidad integer not null default 1
        check(cantidad > 0),


    precio_unitario numeric(12,2) not null
        check(precio_unitario > 0),


    subtotal numeric(12,2)
        generated always as
        (cantidad * precio_unitario)
        stored
);



-- -----------------------------------------------------------------------------
-- 1.7 auditoria
-- -----------------------------------------------------------------------------

create table public.auditoria (

    id bigserial primary key,

    tenant_id uuid not null
        references public.tenants(id)
        on delete restrict,

    owner_id uuid not null,

    tabla varchar(30) not null,

    registro_id uuid not null,

    accion varchar(10) not null
        check(accion in ('INSERT','UPDATE','DELETE')),

    datos_anteriores jsonb,

    datos_nuevos jsonb,

    realizado_por uuid,

    realizado_en timestamptz not null default now()
);



-- -----------------------------------------------------------------------------
-- 1.8 exportaciones
-- -----------------------------------------------------------------------------

create table public.exportaciones (

    id uuid primary key default gen_random_uuid(),

    tenant_id uuid not null
        references public.tenants(id)
        on delete restrict,

    owner_id uuid not null
        references public.profiles(id)
        on delete cascade,

    formato varchar(10) not null
        check(formato in ('excel','pdf')),

    alcance varchar(12) not null
        check(alcance in ('todos','con_deuda')),

    generado_en timestamptz not null default now()

);

-- =============================================================================
-- 2. ÍNDICES
-- =============================================================================


-- CLIENTES

create index idx_clientes_owner
on public.clientes(owner_id);


create index idx_clientes_owner_nombre
on public.clientes(owner_id, nombre);


create index idx_clientes_nombre_trgm
on public.clientes
using gin(nombre gin_trgm_ops);


create index idx_clientes_telefono_trgm
on public.clientes
using gin(telefono gin_trgm_ops);


create index idx_clientes_con_deuda
on public.clientes(owner_id, saldo)
where saldo > 0
and deleted_at is null;



-- PRODUCTOS

create index idx_productos_owner
on public.productos(owner_id);


create index idx_productos_nombre
on public.productos
using gin(nombre gin_trgm_ops);


create index idx_productos_activos
on public.productos(owner_id, activo)
where deleted_at is null;



-- TRANSACCIONES

create index idx_transacciones_owner_fecha
on public.transacciones(owner_id, fecha_hora desc);


create index idx_transacciones_cliente_fecha
on public.transacciones(cliente_id, fecha_hora desc);


create index idx_transacciones_owner_tipo_fecha
on public.transacciones(owner_id, tipo, fecha_hora desc);



-- FIADO ITEMS

create index idx_fiado_items_transaccion
on public.fiado_items(transaccion_id);


create index idx_fiado_items_producto
on public.fiado_items(producto_id);



-- AUDITORIA

create index idx_auditoria_owner
on public.auditoria(owner_id, realizado_en desc);



-- =============================================================================
-- 3. FUNCIONES Y TRIGGERS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 3.1 Actualizar updated_at automáticamente
-- -----------------------------------------------------------------------------

create or replace function public.fn_set_updated_at()

returns trigger

language plpgsql

as $$

begin

    new.updated_at = now();

    return new;

end;

$$;



create trigger trg_profiles_updated_at

before update on public.profiles

for each row

execute function public.fn_set_updated_at();



create trigger trg_clientes_updated_at

before update on public.clientes

for each row

execute function public.fn_set_updated_at();



create trigger trg_productos_updated_at

before update on public.productos

for each row

execute function public.fn_set_updated_at();




-- -----------------------------------------------------------------------------
-- 3.2 Crear profile automáticamente después del registro
-- -----------------------------------------------------------------------------

create or replace function public.fn_handle_new_user()

returns trigger

language plpgsql

security definer

set search_path = public

as $$

begin


insert into public.profiles
(
    id,
    nombre_negocio,
    email
)

values

(
    new.id,

    coalesce(
        new.raw_user_meta_data ->> 'nombre_negocio',
        'Mi tienda'
    ),

    new.email
);


return new;


end;

$$;



create trigger trg_on_auth_user_created

after insert on auth.users

for each row

execute function public.fn_handle_new_user();




-- -----------------------------------------------------------------------------
-- 3.3 Calcular saldo después de una transacción
-- -----------------------------------------------------------------------------

create or replace function public.fn_calcular_saldo_posterior()

returns trigger

language plpgsql

security definer

set search_path = pg_catalog, public

as $$

declare

saldo_actual numeric(12,2);

owner_cliente uuid;

tenant_cliente uuid;


begin

if new.tenant_id is null then

raise exception 'La transaccion requiere tenant_id';

end if;

select saldo, owner_id, tenant_id

into saldo_actual, owner_cliente, tenant_cliente

from public.clientes

where id = new.cliente_id

and tenant_id = new.tenant_id

for update;



if tenant_cliente is null then

raise exception 'Cliente no existe o no pertenece al tenant de la transaccion';

end if;



if owner_cliente <> new.owner_id then

raise exception 'Cliente no pertenece al negocio';

end if;



if new.tipo = 'fiado' then


new.saldo_posterior =
saldo_actual + new.monto;



else


if new.monto > saldo_actual then

raise exception
'El abono supera la deuda actual';

end if;



new.saldo_posterior =
saldo_actual - new.monto;


end if;



return new;


end;

$$;



create trigger trg_transacciones_saldo_posterior

before insert on public.transacciones

for each row

execute function public.fn_calcular_saldo_posterior();




-- -----------------------------------------------------------------------------
-- 3.4 Actualizar saldo cliente
-- -----------------------------------------------------------------------------

create or replace function public.fn_actualizar_cliente_tras_transaccion()

returns trigger

language plpgsql

security definer

set search_path = pg_catalog, public

as $$


declare

v_cliente_id uuid;

v_tenant_id uuid;


begin


v_cliente_id :=
coalesce(new.cliente_id, old.cliente_id);

v_tenant_id :=
case
when tg_op = 'DELETE' then old.tenant_id
else new.tenant_id
end;

if v_tenant_id is null then

raise exception 'La transaccion requiere tenant_id';

end if;



update public.clientes

set

saldo =
coalesce(

(
select sum(

case

when tipo='fiado'
then monto

else -monto

end

)

from public.transacciones

where cliente_id = v_cliente_id

and tenant_id = v_tenant_id

and deleted_at is null

),

0

),


ultimo_movimiento_en =

(

select max(fecha_hora)

from public.transacciones

where cliente_id = v_cliente_id

and tenant_id = v_tenant_id

and deleted_at is null

)


where id = v_cliente_id

and tenant_id = v_tenant_id;

if not found then

raise exception 'Cliente no existe o no pertenece al tenant de la transaccion';

end if;



return coalesce(new, old);


end;

$$;



create trigger trg_transacciones_actualizar_cliente

after insert or update or delete

on public.transacciones

for each row

execute function public.fn_actualizar_cliente_tras_transaccion();




-- -----------------------------------------------------------------------------
-- 3.5 Auditoría automática
-- -----------------------------------------------------------------------------

create or replace function public.fn_auditoria()

returns trigger

language plpgsql

security definer

set search_path = pg_catalog, public

as $$


declare

v_owner uuid;

v_tenant_id uuid;


begin


v_owner :=
coalesce(new.owner_id, old.owner_id);

v_tenant_id :=
case
when tg_op = 'DELETE' then old.tenant_id
else new.tenant_id
end;

if v_tenant_id is null then

raise exception 'La auditoria requiere tenant_id';

end if;



insert into public.auditoria
(
tenant_id,
owner_id,
tabla,
registro_id,
accion,
datos_anteriores,
datos_nuevos,
realizado_por
)


values

(
v_tenant_id,
v_owner,

tg_table_name,

coalesce(new.id, old.id),

tg_op,


case

when tg_op in ('UPDATE','DELETE')

then to_jsonb(old)

else null

end,


case

when tg_op in ('INSERT','UPDATE')

then to_jsonb(new)

else null

end,


auth.uid()

);



return coalesce(new,old);


end;

$$;



create trigger trg_auditoria_clientes

after insert or update or delete

on public.clientes

for each row

execute function public.fn_auditoria();



create trigger trg_auditoria_productos

after insert or update or delete

on public.productos

for each row

execute function public.fn_auditoria();



create trigger trg_auditoria_transacciones

after insert or update or delete

on public.transacciones

for each row

execute function public.fn_auditoria();

-- =============================================================================
-- 4. VISTAS PARA REPORTES
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 4.1 Resumen general del negocio
-- -----------------------------------------------------------------------------

create or replace view public.v_resumen_negocio as

select

    p.id as owner_id,


    coalesce(
        sum(c.saldo)
        filter(where c.deleted_at is null),
        0
    ) as total_por_cobrar,


    count(c.id)
    filter(where c.deleted_at is null)
    as total_clientes,


    count(c.id)
    filter(
        where c.deleted_at is null
        and c.saldo > 0
    )
    as clientes_con_deuda,


    coalesce(

        (
            select sum(t.monto)

            from public.transacciones t

            where t.owner_id = p.id

            and t.tipo = 'abono'

            and t.deleted_at is null

            and t.fecha_hora >= date_trunc('day', now())

        ),

        0

    ) as cobros_hoy



from public.profiles p


left join public.clientes c

on c.owner_id = p.id


group by p.id;




-- -----------------------------------------------------------------------------
-- 4.2 Evolución mensual
-- -----------------------------------------------------------------------------

create or replace view public.v_evolucion_mensual as


select


t.owner_id,


date_trunc(
'month',
t.fecha_hora
)
as mes,


sum(t.monto)
filter(
where t.tipo='fiado'
)
as total_fiado,


sum(t.monto)
filter(
where t.tipo='abono'
)
as total_abono,


count(*)
filter(
where t.tipo='fiado'
)
as cantidad_fiados,


count(*)
filter(
where t.tipo='abono'
)
as cantidad_abonos



from public.transacciones t


where t.deleted_at is null


group by

t.owner_id,

date_trunc(
'month',
t.fecha_hora
);




-- =============================================================================
-- [DEPRECATED] Las policies legacy basadas en owner_id = auth.uid() para
-- clientes, productos, transacciones, fiado_items, auditoria y exportaciones
-- están DESACTIVADAS (comentadas). El modelo de seguridad vigente es la
-- sección 7 (RECONCILIACIÓN MULTI-TENANT). Se conservan activas únicamente
-- las policies de profiles y metodos_pago.
-- 5. ROW LEVEL SECURITY
-- =============================================================================


-- [SUPERSEDED] alter table public.profiles enable row level security;

-- [SUPERSEDED] alter table public.clientes enable row level security;

-- [SUPERSEDED] alter table public.productos enable row level security;

-- [SUPERSEDED] alter table public.transacciones enable row level security;

-- [SUPERSEDED] alter table public.fiado_items enable row level security;

-- [SUPERSEDED] alter table public.metodos_pago enable row level security;

-- [SUPERSEDED] alter table public.auditoria enable row level security;

-- [SUPERSEDED] alter table public.exportaciones enable row level security;



-- =============================================================================
-- 5.1 PROFILES
-- =============================================================================


create policy profiles_select_own

on public.profiles

for select

using(id = auth.uid());



create policy profiles_update_own

on public.profiles

for update

using(id = auth.uid());




-- =============================================================================
-- 5.2 CLIENTES
-- =============================================================================


-- [SUPERSEDED] create policy clientes_select_own

-- [SUPERSEDED] on public.clientes

-- [SUPERSEDED] for select

-- [SUPERSEDED] using(owner_id = auth.uid());



-- [SUPERSEDED] create policy clientes_insert_own

-- [SUPERSEDED] on public.clientes

-- [SUPERSEDED] for insert

-- [SUPERSEDED] with check(owner_id = auth.uid());



-- [SUPERSEDED] create policy clientes_update_own

-- [SUPERSEDED] on public.clientes

-- [SUPERSEDED] for update

-- [SUPERSEDED] using(owner_id = auth.uid())

-- [SUPERSEDED] with check(owner_id = auth.uid());



-- [SUPERSEDED] create policy clientes_delete_own

-- [SUPERSEDED] on public.clientes

-- [SUPERSEDED] for delete

-- [SUPERSEDED] using(owner_id = auth.uid());





-- =============================================================================
-- 5.3 PRODUCTOS
-- =============================================================================


-- [SUPERSEDED] create policy productos_select_own

-- [SUPERSEDED] on public.productos

-- [SUPERSEDED] for select

-- [SUPERSEDED] using(owner_id = auth.uid());



-- [SUPERSEDED] create policy productos_insert_own

-- [SUPERSEDED] on public.productos

-- [SUPERSEDED] for insert

-- [SUPERSEDED] with check(owner_id = auth.uid());



-- [SUPERSEDED] create policy productos_update_own

-- [SUPERSEDED] on public.productos

-- [SUPERSEDED] for update

-- [SUPERSEDED] using(owner_id = auth.uid())

-- [SUPERSEDED] with check(owner_id = auth.uid());



-- [SUPERSEDED] create policy productos_delete_own

-- [SUPERSEDED] on public.productos

-- [SUPERSEDED] for delete

-- [SUPERSEDED] using(owner_id = auth.uid());




-- =============================================================================
-- 5.4 TRANSACCIONES
-- =============================================================================


-- [SUPERSEDED] create policy transacciones_select_own

-- [SUPERSEDED] on public.transacciones

-- [SUPERSEDED] for select

-- [SUPERSEDED] using(owner_id = auth.uid());



-- [SUPERSEDED] create policy transacciones_insert_own

-- [SUPERSEDED] on public.transacciones

-- [SUPERSEDED] for insert

-- [SUPERSEDED] with check

-- [SUPERSEDED] (

-- [SUPERSEDED] owner_id = auth.uid()


-- [SUPERSEDED] and exists

-- [SUPERSEDED] (

-- [SUPERSEDED] select 1

-- [SUPERSEDED] from public.clientes c

-- [SUPERSEDED] where c.id = cliente_id

-- [SUPERSEDED] and c.owner_id = auth.uid()

-- [SUPERSEDED] )

-- [SUPERSEDED] );



-- [SUPERSEDED] create policy transacciones_update_own

-- [SUPERSEDED] on public.transacciones

-- [SUPERSEDED] for update

-- [SUPERSEDED] using(owner_id = auth.uid())

-- [SUPERSEDED] with check(owner_id = auth.uid());



-- [SUPERSEDED] create policy transacciones_delete_own

-- [SUPERSEDED] on public.transacciones

-- [SUPERSEDED] for delete

-- [SUPERSEDED] using(owner_id = auth.uid());





-- =============================================================================
-- 5.5 FIADO ITEMS
-- =============================================================================


-- [SUPERSEDED] create policy fiado_items_select_own

-- [SUPERSEDED] on public.fiado_items

-- [SUPERSEDED] for select

-- [SUPERSEDED] using

-- [SUPERSEDED] (

-- [SUPERSEDED] exists

-- [SUPERSEDED] (

-- [SUPERSEDED] select 1

-- [SUPERSEDED] from public.transacciones t

-- [SUPERSEDED] where t.id = transaccion_id

-- [SUPERSEDED] and t.owner_id = auth.uid()

-- [SUPERSEDED] )

-- [SUPERSEDED] );




-- [SUPERSEDED] create policy fiado_items_insert_own

-- [SUPERSEDED] on public.fiado_items

-- [SUPERSEDED] for insert

-- [SUPERSEDED] with check

-- [SUPERSEDED] (

-- [SUPERSEDED] exists

-- [SUPERSEDED] (

-- [SUPERSEDED] select 1

-- [SUPERSEDED] from public.transacciones t

-- [SUPERSEDED] where t.id = transaccion_id

-- [SUPERSEDED] and t.owner_id = auth.uid()

-- [SUPERSEDED] )

-- [SUPERSEDED] );



-- [SUPERSEDED] create policy fiado_items_update_own

-- [SUPERSEDED] on public.fiado_items

-- [SUPERSEDED] for update

-- [SUPERSEDED] using

-- [SUPERSEDED] (

-- [SUPERSEDED] exists

-- [SUPERSEDED] (

-- [SUPERSEDED] select 1

-- [SUPERSEDED] from public.transacciones t

-- [SUPERSEDED] where t.id = transaccion_id

-- [SUPERSEDED] and t.owner_id = auth.uid()

-- [SUPERSEDED] )

-- [SUPERSEDED] )

-- [SUPERSEDED] with check

-- [SUPERSEDED] (

-- [SUPERSEDED] exists

-- [SUPERSEDED] (

-- [SUPERSEDED] select 1

-- [SUPERSEDED] from public.transacciones t

-- [SUPERSEDED] where t.id = transaccion_id

-- [SUPERSEDED] and t.owner_id = auth.uid()

-- [SUPERSEDED] )

-- [SUPERSEDED] );



-- [SUPERSEDED] create policy fiado_items_delete_own

-- [SUPERSEDED] on public.fiado_items

-- [SUPERSEDED] for delete

-- [SUPERSEDED] using

-- [SUPERSEDED] (

-- [SUPERSEDED] exists

-- [SUPERSEDED] (

-- [SUPERSEDED] select 1

-- [SUPERSEDED] from public.transacciones t

-- [SUPERSEDED] where t.id = transaccion_id

-- [SUPERSEDED] and t.owner_id = auth.uid()

-- [SUPERSEDED] )

-- [SUPERSEDED] );





-- =============================================================================
-- 5.6 METODOS DE PAGO
-- =============================================================================


create policy metodos_pago_select_all

on public.metodos_pago

for select

using(auth.role()='authenticated');





-- =============================================================================
-- 5.7 AUDITORIA
-- =============================================================================


-- [SUPERSEDED] create policy auditoria_select_own

-- [SUPERSEDED] on public.auditoria

-- [SUPERSEDED] for select

-- [SUPERSEDED] using(owner_id = auth.uid());





-- =============================================================================
-- 5.8 EXPORTACIONES
-- =============================================================================


-- [SUPERSEDED] create policy exportaciones_select_own

-- [SUPERSEDED] on public.exportaciones

-- [SUPERSEDED] for select

-- [SUPERSEDED] using(owner_id = auth.uid());



-- [SUPERSEDED] create policy exportaciones_insert_own

-- [SUPERSEDED] on public.exportaciones

-- [SUPERSEDED] for insert

-- [SUPERSEDED] with check(owner_id = auth.uid());





-- =============================================================================
-- 6. DATOS INICIALES
-- =============================================================================


insert into public.metodos_pago
(
nombre,
orden
)

values

('Efectivo',1),

('Transferencia',2),

('Nequi',3),

('Daviplata',4),

('Otro',5)


on conflict(nombre)

do nothing;



-- =============================================================================
-- FIN DEL SCRIPT FiApp
-- =============================================================================

-- =============================================================================
-- 7. RECONCILIACIÓN MULTI-TENANT (estado final validado en producción)
-- =============================================================================
-- Esta sección SUSTITUYE las policies legacy definidas en la sección 5.
-- Las policies de la sección 5 quedan como referencia histórica; el modelo de
-- seguridad vigente es el siguiente (equivalente a
-- migrations/005_rls_reconciliation.sql).
--
-- Frontera de aislamiento: tenant_id.
-- Autorización: auth.uid() + membership activa en tenant_usuarios.
-- owner_id se conserva como dato histórico, NO como frontera de seguridad.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 7.1 FK tenant_id -> tenants(id) (idempotente)
-- -----------------------------------------------------------------------------
do $$
declare
    t text;
    fk text;
    pares text[][] := array[
        ['clientes',      'fk_clientes_tenant'],
        ['productos',     'fk_productos_tenant'],
        ['transacciones', 'fk_transacciones_tenant'],
        ['auditoria',     'fk_auditoria_tenant'],
        ['exportaciones', 'fk_exportaciones_tenant']
    ];
    i int;
begin
    for i in 1..array_length(pares, 1) loop
        t := pares[i][1];
        fk := pares[i][2];
        if not exists (
            select 1 from pg_constraint
            where conname = fk and connamespace = 'public'::regnamespace
        ) then
            execute format(
                'alter table public.%I add constraint %I '
                'foreign key (tenant_id) references public.tenants(id) on delete restrict',
                t, fk
            );
        end if;
    end loop;
end $$;


-- -----------------------------------------------------------------------------
-- 7.2 Helpers RLS
-- -----------------------------------------------------------------------------
-- Por qué SECURITY DEFINER: RLS se evalúa para el rol ejecutor. Estos helpers
-- deben leer tenant_usuarios (que tiene RLS) para resolver membership. Sin
-- SECURITY DEFINER, la policy de tenant_usuarios produciría recursión. No
-- exponen datos: devuelven boolean/text sobre el propio auth.uid().
-- -----------------------------------------------------------------------------

-- Tenant activo VALIDADO contra membership activa de auth.uid().
-- No confía ciegamente en app.tenant_id.
create or replace function public.current_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
    select tu.tenant_id
      from public.tenant_usuarios tu
     where tu.profile_id = auth.uid()
       and tu.tenant_id = nullif(btrim(current_setting('app.tenant_id', true)), '')::uuid
       and tu.activo = true
     limit 1;
$$;

-- ¿auth.uid() es miembro activo del tenant indicado?
create or replace function public.user_is_active_member_of_tenant(p_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
    select exists (
        select 1
          from public.tenant_usuarios tu
         where tu.tenant_id = p_tenant_id
           and tu.profile_id = auth.uid()
           and tu.activo = true
    );
$$;

-- Rol efectivo de auth.uid() en el tenant indicado (o NULL).
create or replace function public.user_tenant_role(p_tenant_id uuid)
returns text
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
    select tu.rol
      from public.tenant_usuarios tu
     where tu.tenant_id = p_tenant_id
       and tu.profile_id = auth.uid()
       and tu.activo = true
     limit 1;
$$;

-- Permisos: EXECUTE solo a roles relevantes; nunca a PUBLIC.
revoke all on function public.current_tenant_id() from public;
revoke all on function public.user_is_active_member_of_tenant(uuid) from public;
revoke all on function public.user_tenant_role(uuid) from public;

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        grant execute on function public.current_tenant_id() to authenticated;
        grant execute on function public.user_is_active_member_of_tenant(uuid) to authenticated;
        grant execute on function public.user_tenant_role(uuid) to authenticated;
    end if;
    if exists (select 1 from pg_roles where rolname = 'service_role') then
        grant execute on function public.current_tenant_id() to service_role;
        grant execute on function public.user_is_active_member_of_tenant(uuid) to service_role;
        grant execute on function public.user_tenant_role(uuid) to service_role;
    end if;
end $$;


-- -----------------------------------------------------------------------------
-- 7.3 Policies tenant-aware (reemplazan las legacy de la sección 5)
-- -----------------------------------------------------------------------------

-- RLS debe estar HABILITADO en TODAS las tablas operativas. La sección 5 legacy
-- quedó desactivada (comentada), por lo que aquí se reafirma explícitamente.
alter table public.profiles       enable row level security;
alter table public.clientes       enable row level security;
alter table public.productos      enable row level security;
alter table public.transacciones  enable row level security;
alter table public.fiado_items    enable row level security;
alter table public.metodos_pago   enable row level security;
alter table public.auditoria      enable row level security;
alter table public.exportaciones  enable row level security;

-- TENANTS
alter table public.tenants enable row level security;
drop policy if exists tenants_select_member on public.tenants;
drop policy if exists tenants_update_admin on public.tenants;

create policy tenants_select_member on public.tenants
    for select to authenticated
    using (public.user_is_active_member_of_tenant(id));

create policy tenants_update_admin on public.tenants
    for update to authenticated
    using (
        id = public.current_tenant_id()
        and public.user_tenant_role(id) in ('propietario','administrador')
    )
    with check (
        id = public.current_tenant_id()
        and public.user_tenant_role(id) in ('propietario','administrador')
    );

-- TENANT_USUARIOS
alter table public.tenant_usuarios enable row level security;
drop policy if exists tenant_usuarios_select_own on public.tenant_usuarios;
drop policy if exists tenant_usuarios_select_tenant on public.tenant_usuarios;
drop policy if exists tenant_usuarios_insert_admin on public.tenant_usuarios;
drop policy if exists tenant_usuarios_update_admin on public.tenant_usuarios;
drop policy if exists tenant_usuarios_delete_admin on public.tenant_usuarios;

create policy tenant_usuarios_select_own on public.tenant_usuarios
    for select to authenticated
    using (profile_id = auth.uid());

create policy tenant_usuarios_select_tenant on public.tenant_usuarios
    for select to authenticated
    using (
        tenant_id = public.current_tenant_id()
        and public.user_tenant_role(tenant_id) in ('propietario','administrador','supervisor')
    );

create policy tenant_usuarios_insert_admin on public.tenant_usuarios
    for insert to authenticated
    with check (
        tenant_id = public.current_tenant_id()
        and public.user_tenant_role(tenant_id) in ('propietario','administrador')
        and (rol <> 'propietario' or public.user_tenant_role(tenant_id) = 'propietario')
    );

create policy tenant_usuarios_update_admin on public.tenant_usuarios
    for update to authenticated
    using (
        tenant_id = public.current_tenant_id()
        and public.user_tenant_role(tenant_id) in ('propietario','administrador')
    )
    with check (
        tenant_id = public.current_tenant_id()
        and public.user_tenant_role(tenant_id) in ('propietario','administrador')
        and (rol <> 'propietario' or public.user_tenant_role(tenant_id) = 'propietario')
    );

create policy tenant_usuarios_delete_admin on public.tenant_usuarios
    for delete to authenticated
    using (
        tenant_id = public.current_tenant_id()
        and public.user_tenant_role(tenant_id) in ('propietario','administrador')
    );

-- CLIENTES
drop policy if exists clientes_select_own on public.clientes;
drop policy if exists clientes_insert_own on public.clientes;
drop policy if exists clientes_update_own on public.clientes;
drop policy if exists clientes_delete_own on public.clientes;

create policy clientes_select_tenant on public.clientes
    for select to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

create policy clientes_insert_tenant on public.clientes
    for insert to authenticated
    with check (public.user_is_active_member_of_tenant(tenant_id));

create policy clientes_update_tenant on public.clientes
    for update to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id))
    with check (public.user_is_active_member_of_tenant(tenant_id));

create policy clientes_delete_tenant on public.clientes
    for delete to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

-- PRODUCTOS
drop policy if exists productos_select_own on public.productos;
drop policy if exists productos_insert_own on public.productos;
drop policy if exists productos_update_own on public.productos;
drop policy if exists productos_delete_own on public.productos;

create policy productos_select_tenant on public.productos
    for select to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

create policy productos_insert_tenant on public.productos
    for insert to authenticated
    with check (public.user_is_active_member_of_tenant(tenant_id));

create policy productos_update_tenant on public.productos
    for update to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id))
    with check (public.user_is_active_member_of_tenant(tenant_id));

create policy productos_delete_tenant on public.productos
    for delete to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

-- TRANSACCIONES
drop policy if exists transacciones_select_own on public.transacciones;
drop policy if exists transacciones_insert_own on public.transacciones;
drop policy if exists transacciones_update_own on public.transacciones;
drop policy if exists transacciones_delete_own on public.transacciones;

create policy transacciones_select_tenant on public.transacciones
    for select to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

create policy transacciones_insert_tenant on public.transacciones
    for insert to authenticated
    with check (
        public.user_is_active_member_of_tenant(tenant_id)
        and exists (
            select 1 from public.clientes c
             where c.id = cliente_id
               and c.tenant_id = transacciones.tenant_id
        )
    );

create policy transacciones_update_tenant on public.transacciones
    for update to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id))
    with check (
        public.user_is_active_member_of_tenant(tenant_id)
        and exists (
            select 1 from public.clientes c
             where c.id = cliente_id
               and c.tenant_id = transacciones.tenant_id
        )
    );

create policy transacciones_delete_tenant on public.transacciones
    for delete to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

-- FIADO_ITEMS (tenant derivado de transacciones; sin tenant_id propio)
drop policy if exists fiado_items_select_own on public.fiado_items;
drop policy if exists fiado_items_insert_own on public.fiado_items;
drop policy if exists fiado_items_update_own on public.fiado_items;
drop policy if exists fiado_items_delete_own on public.fiado_items;

create policy fiado_items_select_tenant on public.fiado_items
    for select to authenticated
    using (
        exists (
            select 1 from public.transacciones t
             where t.id = transaccion_id
               and public.user_is_active_member_of_tenant(t.tenant_id)
        )
    );

create policy fiado_items_insert_tenant on public.fiado_items
    for insert to authenticated
    with check (
        exists (
            select 1 from public.transacciones t
             where t.id = transaccion_id
               and public.user_is_active_member_of_tenant(t.tenant_id)
        )
    );

create policy fiado_items_update_tenant on public.fiado_items
    for update to authenticated
    using (
        exists (
            select 1 from public.transacciones t
             where t.id = transaccion_id
               and public.user_is_active_member_of_tenant(t.tenant_id)
        )
    )
    with check (
        exists (
            select 1 from public.transacciones t
             where t.id = transaccion_id
               and public.user_is_active_member_of_tenant(t.tenant_id)
        )
    );

create policy fiado_items_delete_tenant on public.fiado_items
    for delete to authenticated
    using (
        exists (
            select 1 from public.transacciones t
             where t.id = transaccion_id
               and public.user_is_active_member_of_tenant(t.tenant_id)
        )
    );

-- AUDITORIA (solo lectura tenant-aware; escritura vía trigger SECURITY DEFINER)
drop policy if exists auditoria_select_own on public.auditoria;

create policy auditoria_select_tenant on public.auditoria
    for select to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

-- EXPORTACIONES
drop policy if exists exportaciones_select_own on public.exportaciones;
drop policy if exists exportaciones_insert_own on public.exportaciones;
drop policy if exists exportaciones_update_own on public.exportaciones;
drop policy if exists exportaciones_delete_own on public.exportaciones;

create policy exportaciones_select_tenant on public.exportaciones
    for select to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

create policy exportaciones_insert_tenant on public.exportaciones
    for insert to authenticated
    with check (public.user_is_active_member_of_tenant(tenant_id));

create policy exportaciones_update_tenant on public.exportaciones
    for update to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id))
    with check (public.user_is_active_member_of_tenant(tenant_id));

create policy exportaciones_delete_tenant on public.exportaciones
    for delete to authenticated
    using (public.user_is_active_member_of_tenant(tenant_id));

-- PROFILES y METODOS_PAGO: sin cambios. Se conservan sus policies existentes
-- (individual id = auth.uid() para profiles; SELECT global para metodos_pago).

-- =============================================================================
-- FIN RECONCILIACIÓN MULTI-TENANT
-- =============================================================================
