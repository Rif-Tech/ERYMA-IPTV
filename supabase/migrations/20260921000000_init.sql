-- MultIPTV core schema: devices, playlists, app configuration, admin profiles.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Profiles (admins of the portal). Rows are created for auth users on demand.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  role text not null default 'user' check (role in ('admin', 'user')),
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  );
$$;

-- Auto-create a profile for every new auth user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Devices identified by a pseudo MAC + secret device key.
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  mac text not null unique,
  device_key text not null,
  device_type text not null default 'mobile' check (device_type in ('mobile', 'tablet', 'tv')),
  platform text,
  app_version text,
  trial_started_at timestamptz not null default now(),
  activated boolean not null default false,
  activated_at timestamptz,
  expires_at timestamptz,
  note text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index devices_last_seen_idx on public.devices (last_seen_at desc);

-- ---------------------------------------------------------------------------
-- Playlists attached to a device.
create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null references public.devices (id) on delete cascade,
  name text not null,
  type text not null check (type in ('m3u', 'xtream')),
  url text not null,
  username text,
  password text,
  epg_url text,
  is_protected boolean not null default false,
  pin_code text,
  expires_at timestamptz,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index playlists_device_idx on public.playlists (device_id, position);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger playlists_touch_updated_at
  before update on public.playlists
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Key/value app configuration read by the app at startup.
create table public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

insert into public.app_config (key, value) values
  ('trial_days', '7'),
  ('app_status', '"ok"'),
  ('message', 'null'),
  ('min_version', '"1.0.0"'),
  ('latest_version', '"1.0.0"'),
  ('apk_link', 'null');

-- ---------------------------------------------------------------------------
-- Device status computation shared by the API and the portal.
create or replace function public.device_status(d public.devices)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  trial_days integer := coalesce((select (value)::int from public.app_config where key = 'trial_days'), 7);
  trial_ends timestamptz := d.trial_started_at + make_interval(days => trial_days);
  in_trial boolean := not d.activated and now() < trial_ends;
  active boolean := d.activated and (d.expires_at is null or d.expires_at > now());
begin
  return jsonb_build_object(
    'registered', true,
    'activated', active,
    'is_trial', in_trial,
    'expired', not (in_trial or active),
    'trial_ends_at', trial_ends,
    'expires_at', d.expires_at
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Row level security: tables are closed to anon; admins get full access.
-- Devices and the user portal go through Edge Functions (service role).
alter table public.profiles enable row level security;
alter table public.devices enable row level security;
alter table public.playlists enable row level security;
alter table public.app_config enable row level security;

create policy "profiles: self read" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles: admin all" on public.profiles
  for all using (public.is_admin()) with check (public.is_admin());

create policy "devices: admin all" on public.devices
  for all using (public.is_admin()) with check (public.is_admin());

create policy "playlists: admin all" on public.playlists
  for all using (public.is_admin()) with check (public.is_admin());

create policy "app_config: public read" on public.app_config
  for select using (true);

create policy "app_config: admin write" on public.app_config
  for all using (public.is_admin()) with check (public.is_admin());

-- Admin-facing view with the computed status.
create or replace view public.devices_with_status
with (security_invoker = true) as
select d.*, public.device_status(d) as status,
       (select count(*) from public.playlists p where p.device_id = d.id) as playlist_count
from public.devices d;
