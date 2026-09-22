-- Account-based model: accounts (= auth users), plans/subscriptions, viewer profiles, account-owned
-- playlists, install-identified devices, temporary pairing sessions and synced watch progress.
-- Additive only: legacy MAC/device-key columns stay (nullable) until the transition is over.

-- ---------------------------------------------------------------------------
-- Plans and accounts

create table public.plans (
  id text primary key,
  name text not null,
  max_devices integer not null,
  max_profiles integer not null,
  max_playlists integer not null,
  -- Reserved for a future concurrent-streams limit; not enforced yet.
  max_streams integer not null default 1,
  created_at timestamptz not null default now()
);

insert into public.plans (id, name, max_devices, max_profiles, max_playlists, max_streams) values
  ('trial', 'Essai', 3, 5, 5, 1),
  ('standard', 'Standard', 5, 5, 20, 2);

-- One account per auth user; `profiles` keeps the portal role and is not duplicated.
create table public.accounts (
  id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger accounts_touch_updated_at
  before update on public.accounts
  for each row execute function public.touch_updated_at();

-- One subscription row per account; the admin edits plan/status/expiry.
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null unique references public.accounts (id) on delete cascade,
  plan_id text not null references public.plans (id),
  status text not null default 'trial' check (status in ('trial', 'active', 'expired', 'cancelled')),
  started_at timestamptz not null default now(),
  expires_at timestamptz,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger subscriptions_touch_updated_at
  before update on public.subscriptions
  for each row execute function public.touch_updated_at();

-- Viewing profiles (John, Sarah, Kids…). Distinct from `profiles` (Supabase Auth role).
create table public.viewer_profiles (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts (id) on delete cascade,
  name text not null check (length(name) between 1 and 40),
  avatar text not null default 'blue',
  is_kids boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index viewer_profiles_account_idx on public.viewer_profiles (account_id, position);

create trigger viewer_profiles_touch_updated_at
  before update on public.viewer_profiles
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Playlists become account resources (device_id kept for legacy rows)

alter table public.playlists
  add column account_id uuid references public.accounts (id) on delete cascade,
  alter column device_id drop not null,
  add constraint playlists_owner_check check (account_id is not null or device_id is not null);

create index playlists_account_idx on public.playlists (account_id, position);

create table public.profile_playlists (
  profile_id uuid not null references public.viewer_profiles (id) on delete cascade,
  playlist_id uuid not null references public.playlists (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (profile_id, playlist_id)
);

create index profile_playlists_playlist_idx on public.profile_playlists (playlist_id);

-- Both sides must belong to the same account (RLS cannot express cross-row checks).
create or replace function public.check_profile_playlist()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  a1 uuid := (select account_id from public.viewer_profiles where id = new.profile_id);
  a2 uuid := (select account_id from public.playlists where id = new.playlist_id);
begin
  if a1 is null or a2 is null or a1 <> a2 then
    raise exception 'PROFILE_PLAYLIST_ACCOUNT_MISMATCH' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger profile_playlists_check
  before insert or update on public.profile_playlists
  for each row execute function public.check_profile_playlist();

-- ---------------------------------------------------------------------------
-- Devices: install identity + account ownership + remembered context

alter table public.devices
  alter column mac drop not null,
  alter column device_key drop not null,
  add column account_id uuid references public.accounts (id) on delete cascade,
  add column device_uuid text unique,
  -- sha256 of the secret the installation generated; the plaintext never reaches the server.
  add column secret_hash text,
  add column name text,
  add column manufacturer text,
  add column model text,
  add column os text,
  add column os_version text,
  add column status text not null default 'active' check (status in ('active', 'revoked')),
  add column revoked_at timestamptz,
  add column active_profile_id uuid references public.viewer_profiles (id) on delete set null,
  add column active_playlist_id uuid references public.playlists (id) on delete set null,
  add column updated_at timestamptz not null default now();

create index devices_account_idx on public.devices (account_id, status);

create trigger devices_touch_updated_at
  before update on public.devices
  for each row execute function public.touch_updated_at();

-- `select d.*` views freeze their column list: rebuild with the new columns and the owner e-mail.
drop view if exists public.devices_with_status;
create view public.devices_with_status
with (security_invoker = true) as
select d.*, public.device_status(d) as status_legacy,
       (select count(*) from public.playlists p where p.device_id = d.id) as playlist_count,
       (select pr.email from public.profiles pr where pr.id = d.account_id) as account_email
from public.devices d;

-- ---------------------------------------------------------------------------
-- Pairing sessions (device ↔ account, playlist ↔ account through a device)

create table public.pairing_sessions (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('device', 'playlist')),
  device_id uuid not null references public.devices (id) on delete cascade,
  account_id uuid references public.accounts (id) on delete set null,
  code text not null,
  token_hash text not null,
  -- Hash of the device secret proposed by the installation; promoted to devices.secret_hash on confirm.
  secret_hash text,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'expired', 'cancelled')),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  result jsonb
);

create unique index pairing_sessions_code_pending_idx on public.pairing_sessions (code) where status = 'pending';
create unique index pairing_sessions_token_idx on public.pairing_sessions (token_hash);
create index pairing_sessions_device_idx on public.pairing_sessions (device_id, created_at desc);
create index pairing_sessions_expiry_idx on public.pairing_sessions (expires_at) where status = 'pending';

-- ---------------------------------------------------------------------------
-- Watch progress: profile + playlist + provider item (never cross-playlist)

create table public.watch_progress (
  id bigint generated always as identity primary key,
  profile_id uuid not null references public.viewer_profiles (id) on delete cascade,
  playlist_id uuid not null references public.playlists (id) on delete cascade,
  kind text not null check (kind in ('live', 'vod', 'series')),
  item_id text not null,
  parent_id text,
  position_ms integer not null default 0,
  duration_ms integer not null default 0,
  completed boolean not null default false,
  last_watched_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (profile_id, playlist_id, kind, item_id)
);

create index watch_progress_recent_idx on public.watch_progress (profile_id, playlist_id, kind, last_watched_at desc);

create trigger watch_progress_touch_updated_at
  before update on public.watch_progress
  for each row execute function public.touch_updated_at();

create or replace function public.check_watch_progress()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.profile_playlists pp where pp.profile_id = new.profile_id and pp.playlist_id = new.playlist_id) then
    raise exception 'PROFILE_HAS_NO_ACCESS' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger watch_progress_check
  before insert or update on public.watch_progress
  for each row execute function public.check_watch_progress();

-- Legacy telemetry gains an optional owner.
alter table public.watch_events add column account_id uuid references public.accounts (id) on delete set null;

-- ---------------------------------------------------------------------------
-- Account lifecycle

/** Creates the account, its trial subscription and a default profile for an auth user (idempotent). */
create or replace function public.ensure_account(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.accounts (id) values (p_user) on conflict (id) do nothing;
  insert into public.subscriptions (account_id, plan_id, status) values (p_user, 'trial', 'trial')
  on conflict (account_id) do nothing;
  if not exists (select 1 from public.viewer_profiles where account_id = p_user) then
    insert into public.viewer_profiles (account_id, name, avatar) values (p_user, 'Profil 1', 'blue');
  end if;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  perform public.ensure_account(new.id);
  return new;
end;
$$;

-- Existing auth users (admins created before this migration) get an account too.
do $$
declare u record;
begin
  for u in select id from auth.users loop
    perform public.ensure_account(u.id);
  end loop;
end;
$$;

/** Trial/active/expired for an account, mirroring device_status() semantics. */
create or replace function public.account_status(a public.accounts)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  s public.subscriptions;
  p public.plans;
  trial_days integer := coalesce((select (value)::int from public.app_config where key = 'trial_days'), 7);
  trial_ends timestamptz := a.created_at + make_interval(days => trial_days);
  in_trial boolean;
  active boolean;
begin
  select * into s from public.subscriptions where account_id = a.id;
  select * into p from public.plans where id = coalesce(s.plan_id, 'trial');
  in_trial := coalesce(s.status, 'trial') = 'trial' and now() < trial_ends;
  active := s.status = 'active' and (s.expires_at is null or s.expires_at > now());
  return jsonb_build_object(
    'plan', p.id,
    'plan_name', p.name,
    'max_devices', p.max_devices,
    'max_profiles', p.max_profiles,
    'max_playlists', p.max_playlists,
    'activated', active,
    'is_trial', in_trial,
    'expired', not (in_trial or active),
    'trial_ends_at', trial_ends,
    'expires_at', s.expires_at
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Pairing confirmation: the only path that binds a device (or a playlist) to an account.
-- Atomic: account row locked, device limit checked, session consumed, legacy data claimed.

create or replace function public.confirm_pairing(
  p_account uuid,
  p_code text default null,
  p_token_hash text default null,
  p_payload jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  acc public.accounts;
  st jsonb;
  ses public.pairing_sessions;
  dev public.devices;
  active_devices integer;
  playlist_count integer;
  new_playlist_id uuid;
  claimed integer;
  legacy_expiry timestamptz;
begin
  perform public.ensure_account(p_account);
  select * into acc from public.accounts where id = p_account for update;
  st := public.account_status(acc);

  select * into ses from public.pairing_sessions
  where status = 'pending'
    and ((p_code is not null and code = upper(p_code)) or (p_token_hash is not null and token_hash = p_token_hash))
  order by created_at desc
  limit 1
  for update;
  if ses.id is null then
    raise exception 'PAIRING_NOT_FOUND' using errcode = 'P0001';
  end if;
  if ses.expires_at < now() then
    update public.pairing_sessions set status = 'expired' where id = ses.id;
    raise exception 'PAIRING_EXPIRED' using errcode = 'P0001';
  end if;

  select * into dev from public.devices where id = ses.device_id for update;
  if dev.id is null then
    raise exception 'PAIRING_NOT_FOUND' using errcode = 'P0001';
  end if;

  if ses.kind = 'device' then
    if (st->>'expired')::boolean and not (dev.activated and (dev.expires_at is null or dev.expires_at > now())) then
      raise exception 'ACCOUNT_EXPIRED' using errcode = 'P0001';
    end if;
    select count(*) into active_devices from public.devices
    where account_id = p_account and status = 'active' and id <> dev.id;
    if active_devices >= (st->>'max_devices')::int then
      raise exception 'DEVICE_LIMIT' using errcode = 'P0001';
    end if;

    update public.devices set
      account_id = p_account,
      secret_hash = coalesce(ses.secret_hash, secret_hash),
      status = 'active',
      revoked_at = null,
      name = coalesce(name, p_payload->>'name'),
      -- Context belongs to the previous owner when the device changes hands.
      active_profile_id = case when dev.account_id = p_account then active_profile_id else null end,
      active_playlist_id = case when dev.account_id = p_account then active_playlist_id else null end,
      last_seen_at = now()
    where id = dev.id;

    -- Legacy: playlists that were attached to this MAC/key device now belong to the account.
    update public.playlists set account_id = p_account where device_id = dev.id and account_id is null;
    get diagnostics claimed = row_count;
    if claimed > 0 then
      insert into public.profile_playlists (profile_id, playlist_id)
      select vp.id, pl.id from public.viewer_profiles vp
      cross join public.playlists pl
      where vp.account_id = p_account and pl.account_id = p_account and pl.device_id = dev.id
      on conflict do nothing;
    end if;
    -- Legacy: a manually activated device carries its activation over to the account.
    if dev.activated and (dev.expires_at is null or dev.expires_at > now()) then
      select expires_at into legacy_expiry from public.subscriptions where account_id = p_account;
      update public.subscriptions set
        plan_id = 'standard',
        status = 'active',
        expires_at = case
          when dev.expires_at is null or (status = 'active' and legacy_expiry is null) then null
          when status = 'active' and legacy_expiry is not null then greatest(legacy_expiry, dev.expires_at)
          else dev.expires_at
        end
      where account_id = p_account;
    end if;

  else -- playlist
    if dev.account_id is distinct from p_account or dev.status <> 'active' then
      raise exception 'DEVICE_NOT_OWNED' using errcode = 'P0001';
    end if;
    if p_payload is null then
      raise exception 'PAYLOAD_REQUIRED' using errcode = 'P0001';
    end if;
    select count(*) into playlist_count from public.playlists where account_id = p_account;
    if playlist_count >= (st->>'max_playlists')::int then
      raise exception 'PLAYLIST_LIMIT' using errcode = 'P0001';
    end if;
    insert into public.playlists (account_id, name, type, url, username, password, epg_url, is_protected, pin_code, expires_at, position)
    values (
      p_account,
      p_payload->>'name',
      p_payload->>'type',
      p_payload->>'url',
      p_payload->>'username',
      p_payload->>'password',
      p_payload->>'epg_url',
      coalesce((p_payload->>'is_protected')::boolean, false),
      p_payload->>'pin_code',
      (p_payload->>'expires_at')::timestamptz,
      coalesce((select max(position) + 1 from public.playlists where account_id = p_account), 0)
    )
    returning id into new_playlist_id;
    insert into public.profile_playlists (profile_id, playlist_id)
    select id, new_playlist_id from public.viewer_profiles where account_id = p_account
    on conflict do nothing;
  end if;

  update public.pairing_sessions set
    status = 'confirmed',
    account_id = p_account,
    confirmed_at = now(),
    result = jsonb_build_object('device_id', dev.id, 'playlist_id', new_playlist_id)
  where id = ses.id;

  return jsonb_build_object('kind', ses.kind, 'device_id', dev.id, 'playlist_id', new_playlist_id);
end;
$$;

/** Remembers the device's active profile/playlist after validating ownership and access. */
create or replace function public.set_device_context(p_device uuid, p_profile uuid, p_playlist uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  acc uuid := (select account_id from public.devices where id = p_device and status = 'active');
begin
  if acc is null then
    raise exception 'DEVICE_NOT_PAIRED' using errcode = 'P0001';
  end if;
  if p_profile is not null and not exists (select 1 from public.viewer_profiles where id = p_profile and account_id = acc) then
    raise exception 'PROFILE_NOT_OWNED' using errcode = 'P0001';
  end if;
  if p_playlist is not null then
    if p_profile is null then
      raise exception 'PROFILE_REQUIRED' using errcode = 'P0001';
    end if;
    if not exists (select 1 from public.profile_playlists where profile_id = p_profile and playlist_id = p_playlist) then
      raise exception 'PROFILE_HAS_NO_ACCESS' using errcode = 'P0001';
    end if;
  end if;
  update public.devices set active_profile_id = p_profile, active_playlist_id = p_playlist, last_seen_at = now()
  where id = p_device;
end;
$$;

/** Marks stale pending sessions expired and drops old finished ones. Safe to call often. */
create or replace function public.expire_pairing_sessions()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare n integer;
begin
  update public.pairing_sessions set status = 'expired' where status = 'pending' and expires_at < now();
  get diagnostics n = row_count;
  delete from public.pairing_sessions where status <> 'pending' and created_at < now() - interval '1 day';
  return n;
end;
$$;

-- ---------------------------------------------------------------------------
-- Admin overview

create or replace view public.accounts_overview
with (security_invoker = true) as
select a.id, a.created_at, pr.email, pr.role,
       s.plan_id, s.status as subscription_status, s.expires_at, s.note,
       public.account_status(a) as status,
       (select count(*) from public.devices d where d.account_id = a.id and d.status = 'active') as device_count,
       (select count(*) from public.playlists p where p.account_id = a.id) as playlist_count,
       (select count(*) from public.viewer_profiles v where v.account_id = a.id) as profile_count
from public.accounts a
left join public.profiles pr on pr.id = a.id
left join public.subscriptions s on s.account_id = a.id;

-- ---------------------------------------------------------------------------
-- Row level security: users see their own account tree; admins keep full access;
-- pairing sessions are service-role only (Edge Functions).

alter table public.plans enable row level security;
alter table public.accounts enable row level security;
alter table public.subscriptions enable row level security;
alter table public.viewer_profiles enable row level security;
alter table public.profile_playlists enable row level security;
alter table public.pairing_sessions enable row level security;
alter table public.watch_progress enable row level security;

create policy "plans: public read" on public.plans for select using (true);

create policy "accounts: self read" on public.accounts for select using (auth.uid() = id);
create policy "accounts: admin all" on public.accounts for all using (public.is_admin()) with check (public.is_admin());

create policy "subscriptions: self read" on public.subscriptions for select using (auth.uid() = account_id);
create policy "subscriptions: admin all" on public.subscriptions for all using (public.is_admin()) with check (public.is_admin());

create policy "viewer_profiles: owner all" on public.viewer_profiles
  for all using (auth.uid() = account_id) with check (auth.uid() = account_id);
create policy "viewer_profiles: admin all" on public.viewer_profiles for all using (public.is_admin()) with check (public.is_admin());

create policy "profile_playlists: owner all" on public.profile_playlists
  for all using (exists (select 1 from public.viewer_profiles v where v.id = profile_id and v.account_id = auth.uid()))
  with check (exists (select 1 from public.viewer_profiles v where v.id = profile_id and v.account_id = auth.uid()));
create policy "profile_playlists: admin all" on public.profile_playlists for all using (public.is_admin()) with check (public.is_admin());

-- Owners manage their playlists directly from the portal (credentials included; HTTPS).
create policy "playlists: owner all" on public.playlists
  for all using (auth.uid() = account_id) with check (auth.uid() = account_id);

-- Owners may rename, revoke or delete their devices; pairing is the only way to attach one.
create policy "devices: owner read" on public.devices for select using (auth.uid() = account_id);
create policy "devices: owner update" on public.devices for update using (auth.uid() = account_id) with check (auth.uid() = account_id);
create policy "devices: owner delete" on public.devices for delete using (auth.uid() = account_id);

create policy "watch_progress: owner all" on public.watch_progress
  for all using (exists (select 1 from public.viewer_profiles v where v.id = profile_id and v.account_id = auth.uid()))
  with check (exists (select 1 from public.viewer_profiles v where v.id = profile_id and v.account_id = auth.uid()));
create policy "watch_progress: admin read" on public.watch_progress for select using (public.is_admin());

create policy "pairing_sessions: admin read" on public.pairing_sessions for select using (public.is_admin());

grant select on public.plans to anon, authenticated;
grant select on public.accounts, public.subscriptions to authenticated;
grant select, insert, update, delete on public.viewer_profiles, public.profile_playlists, public.watch_progress to authenticated;
grant select, insert, update, delete on public.playlists to authenticated;
grant select, update, delete on public.devices to authenticated;
grant select on public.pairing_sessions to authenticated;
grant select on public.accounts_overview, public.devices_with_status to authenticated;
grant execute on function public.account_status(public.accounts) to authenticated;
grant execute on function public.ensure_account(uuid) to service_role;
grant execute on function public.confirm_pairing(uuid, text, text, jsonb) to service_role;
grant execute on function public.set_device_context(uuid, uuid, uuid) to service_role;
grant execute on function public.expire_pairing_sessions() to service_role;
