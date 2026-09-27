-- PRIME CREATIVES — PIN-ONLY SUPABASE SETUP
-- Run this whole script in Supabase SQL Editor.
-- IMPORTANT: In Supabase Dashboard -> Authentication -> Providers,
-- enable Anonymous Sign-Ins.

create extension if not exists pgcrypto;

-- ADMIN PIN + SERVER SESSION TABLES
create table if not exists public.admin_credentials (
  id uuid primary key default gen_random_uuid(),
  pin_hash text not null,
  pin_salt text not null default 'bcrypt',
  iterations integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  last_used_at timestamptz not null default now()
);

create table if not exists public.admin_pin_attempts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  failed_count integer not null default 0,
  locked_until timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_access_log (
  id uuid primary key default gen_random_uuid(),
  event text not null,
  user_agent text,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

delete from public.admin_credentials;

-- CONTENT TABLES
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  title text not null default '', description text not null default '', short_description text not null default '',
  category text not null default 'Branding', client_name text not null default '', image_url text not null default '',
  image_urls text[] not null default '{}', tools_used text[] not null default '{}', status text not null default 'draft',
  is_visible boolean not null default true, featured boolean not null default false, display_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(), title text not null default '', description text not null default '',
  icon text not null default '', is_visible boolean not null default true, display_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(), name text not null default '', email text not null default '',
  phone text not null default '', message text not null default '', is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.site_settings (
  id uuid primary key default gen_random_uuid(), tagline text not null default '', whatsapp_url text not null default '',
  email text not null default '', phone text not null default '', instagram_url text not null default '',
  linkedin_url text not null default '', accepting_projects boolean not null default true, stat_projects integer not null default 0,
  stat_clients integer not null default 0, stat_years integer not null default 0, stat_satisfaction integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

insert into public.site_settings (tagline, accepting_projects)
select 'Building Brands That Leave a Lasting Impression', true
where not exists (select 1 from public.site_settings);

-- STORAGE
insert into storage.buckets (id, name, public)
values ('project-images','project-images',true)
on conflict (id) do update set public = true;

-- RLS
alter table public.admin_credentials enable row level security;
alter table public.admin_sessions enable row level security;
alter table public.admin_pin_attempts enable row level security;
alter table public.admin_access_log enable row level security;
alter table public.projects enable row level security;
alter table public.services enable row level security;
alter table public.contact_messages enable row level security;
alter table public.site_settings enable row level security;

-- FUNCTIONS
create or replace function public.admin_is_admin_session()
returns boolean language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  if auth.uid() is null then return false; end if;
  select exists (select 1 from public.admin_sessions s where s.user_id = auth.uid() and s.expires_at > now()) into ok;
  if ok then update public.admin_sessions set last_used_at = now() where user_id = auth.uid() and expires_at > now(); end if;
  return coalesce(ok, false);
end; $$;

revoke all on function public.admin_is_admin_session() from public;
grant execute on function public.admin_is_admin_session() to anon, authenticated;

create or replace function public.admin_has_pin() returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.admin_credentials); $$;
revoke all on function public.admin_has_pin() from public;
grant execute on function public.admin_has_pin() to anon, authenticated;

create or replace function public.admin_setup_pin(p_pin text) returns boolean language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Authentication session required'; end if;
  if p_pin is null or p_pin !~ '^[0-9]{4}$' then raise exception 'PIN must be exactly 4 digits'; end if;
  if exists(select 1 from public.admin_credentials) then return false; end if;
  insert into public.admin_credentials(pin_hash, pin_salt, iterations) values (crypt(p_pin, gen_salt('bf', 10)), 'bcrypt', 0);
  insert into public.admin_sessions(user_id, expires_at) values (auth.uid(), now() + interval '8 hours');
  return true;
end; $$;
revoke all on function public.admin_setup_pin(text) from public;
grant execute on function public.admin_setup_pin(text) to anon, authenticated;

create or replace function public.admin_verify_pin(p_pin text) returns boolean language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); stored_hash text; current_failed integer := 0; current_locked timestamptz; good boolean := false;
begin
  if uid is null then return false; end if;
  if p_pin is null or p_pin !~ '^[0-9]{4}$' then return false; end if;
  select failed_count, locked_until into current_failed, current_locked from public.admin_pin_attempts where user_id = uid;
  if current_locked is not null and current_locked > now() then return false; end if;
  select pin_hash into stored_hash from public.admin_credentials limit 1;
  if stored_hash is null then return false; end if;
  good := (crypt(p_pin, stored_hash) = stored_hash);
  if not good then
    insert into public.admin_pin_attempts(user_id, failed_count, locked_until, updated_at) values (uid, 1, null, now())
    on conflict (user_id) do update set failed_count = public.admin_pin_attempts.failed_count + 1, locked_until = case when public.admin_pin_attempts.failed_count + 1 >= 5 then now() + interval '10 minutes' else null end, updated_at = now();
    return false;
  end if;
  delete from public.admin_pin_attempts where user_id = uid;
  delete from public.admin_sessions where user_id = uid;
  insert into public.admin_sessions(user_id, expires_at) values (uid, now() + interval '8 hours');
  return true;
end; $$;
revoke all on function public.admin_verify_pin(text) from public;
grant execute on function public.admin_verify_pin(text) to anon, authenticated;

-- PUBLIC POLICIES
create policy public_projects_read on public.projects for select to anon, authenticated using (status='published' and is_visible=true);
create policy public_services_read on public.services for select to anon, authenticated using (is_visible=true);
create policy public_settings_read on public.site_settings for select to anon, authenticated using (true);
create policy public_contact_insert on public.contact_messages for insert to anon, authenticated with check (true);
