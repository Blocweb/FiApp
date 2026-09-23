-- Bootstrap mínimo compatible con Supabase para pruebas RLS aisladas.
-- NO es producción: emula auth.users, auth.uid(), auth.role() y los roles
-- de Supabase para poder ejercitar las policies reales.

create schema if not exists auth;

create table if not exists auth.users (
    id uuid primary key default gen_random_uuid(),
    email varchar(255),
    raw_user_meta_data jsonb default '{}'::jsonb,
    created_at timestamptz not null default now()
);

-- auth.uid(): lee request.jwt.claim.sub o request.jwt.claims->>'sub'
create or replace function auth.uid() returns uuid
language sql stable as $$
    select coalesce(
        nullif(current_setting('request.jwt.claim.sub', true), '')::uuid,
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid
    );
$$;

create or replace function auth.role() returns text
language sql stable as $$
    select coalesce(
        nullif(current_setting('request.jwt.claim.role', true), ''),
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
    );
$$;

-- Roles de Supabase
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'anon') then
        create role anon nologin noinherit;
    end if;
    if not exists (select 1 from pg_roles where rolname = 'authenticated') then
        create role authenticated nologin noinherit;
    end if;
    if not exists (select 1 from pg_roles where rolname = 'service_role') then
        create role service_role nologin noinherit bypassrls;
    end if;
end $$;

-- Privilegios equivalentes a Supabase: la seguridad debe decidirla RLS, no la
-- ausencia de GRANT. Sin estos GRANT, 'authenticated' quedaría bloqueado por
-- permisos y enmascararía el comportamiento real de las policies.
grant usage on schema public to anon, authenticated, service_role;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to authenticated, service_role;
grant execute on all functions in schema public to authenticated, service_role;

-- Conceder también sobre objetos que se creen después (migraciones/policies).
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant usage, select on sequences to authenticated;
alter default privileges in schema public grant execute on functions to authenticated;
alter default privileges in schema public grant select, insert, update, delete on tables to service_role;
alter default privileges in schema public grant execute on functions to service_role;
