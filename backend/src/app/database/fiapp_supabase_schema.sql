-- =============================================================================
-- FiApp — Esquema Supabase PostgreSQL
-- Versión corregida con catálogo de productos
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

    owner_id uuid not null
        references public.profiles(id)
        on delete cascade,

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

    )
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

set search_path = public

as $$

declare

saldo_actual numeric(12,2);

owner_cliente uuid;


begin


select saldo, owner_id

into saldo_actual, owner_cliente

from public.clientes

where id = new.cliente_id

for update;



if owner_cliente is null then

raise exception 'Cliente no existe';

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

set search_path = public

as $$


declare

v_cliente_id uuid;


begin


v_cliente_id :=
coalesce(new.cliente_id, old.cliente_id);



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

and deleted_at is null

),

0

),


ultimo_movimiento_en =

(

select max(fecha_hora)

from public.transacciones

where cliente_id = v_cliente_id

and deleted_at is null

)


where id = v_cliente_id;



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

set search_path = public

as $$


declare

v_owner uuid;


begin


v_owner :=
coalesce(new.owner_id, old.owner_id);



insert into public.auditoria
(
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
-- 5. ROW LEVEL SECURITY
-- =============================================================================


alter table public.profiles enable row level security;

alter table public.clientes enable row level security;

alter table public.productos enable row level security;

alter table public.transacciones enable row level security;

alter table public.fiado_items enable row level security;

alter table public.metodos_pago enable row level security;

alter table public.auditoria enable row level security;

alter table public.exportaciones enable row level security;



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


create policy clientes_select_own

on public.clientes

for select

using(owner_id = auth.uid());



create policy clientes_insert_own

on public.clientes

for insert

with check(owner_id = auth.uid());



create policy clientes_update_own

on public.clientes

for update

using(owner_id = auth.uid())

with check(owner_id = auth.uid());



create policy clientes_delete_own

on public.clientes

for delete

using(owner_id = auth.uid());





-- =============================================================================
-- 5.3 PRODUCTOS
-- =============================================================================


create policy productos_select_own

on public.productos

for select

using(owner_id = auth.uid());



create policy productos_insert_own

on public.productos

for insert

with check(owner_id = auth.uid());



create policy productos_update_own

on public.productos

for update

using(owner_id = auth.uid())

with check(owner_id = auth.uid());



create policy productos_delete_own

on public.productos

for delete

using(owner_id = auth.uid());




-- =============================================================================
-- 5.4 TRANSACCIONES
-- =============================================================================


create policy transacciones_select_own

on public.transacciones

for select

using(owner_id = auth.uid());



create policy transacciones_insert_own

on public.transacciones

for insert

with check

(

owner_id = auth.uid()


and exists

(

select 1

from public.clientes c

where c.id = cliente_id

and c.owner_id = auth.uid()

)

);



create policy transacciones_update_own

on public.transacciones

for update

using(owner_id = auth.uid())

with check(owner_id = auth.uid());



create policy transacciones_delete_own

on public.transacciones

for delete

using(owner_id = auth.uid());





-- =============================================================================
-- 5.5 FIADO ITEMS
-- =============================================================================


create policy fiado_items_select_own

on public.fiado_items

for select

using

(

exists

(

select 1

from public.transacciones t

where t.id = transaccion_id

and t.owner_id = auth.uid()

)

);




create policy fiado_items_insert_own

on public.fiado_items

for insert

with check

(

exists

(

select 1

from public.transacciones t

where t.id = transaccion_id

and t.owner_id = auth.uid()

)

);



create policy fiado_items_update_own

on public.fiado_items

for update

using

(

exists

(

select 1

from public.transacciones t

where t.id = transaccion_id

and t.owner_id = auth.uid()

)

)

with check

(

exists

(

select 1

from public.transacciones t

where t.id = transaccion_id

and t.owner_id = auth.uid()

)

);



create policy fiado_items_delete_own

on public.fiado_items

for delete

using

(

exists

(

select 1

from public.transacciones t

where t.id = transaccion_id

and t.owner_id = auth.uid()

)

);





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


create policy auditoria_select_own

on public.auditoria

for select

using(owner_id = auth.uid());





-- =============================================================================
-- 5.8 EXPORTACIONES
-- =============================================================================


create policy exportaciones_select_own

on public.exportaciones

for select

using(owner_id = auth.uid());



create policy exportaciones_insert_own

on public.exportaciones

for insert

with check(owner_id = auth.uid());





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