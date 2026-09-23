-- Removes the legacy MAC / device-key identity. Devices only exist through an account pairing now.
-- Orphan legacy playlists (owned by a device, never claimed by an account) are unreachable
-- through the API and are deleted along with device-only columns.

-- ---------------------------------------------------------------------------
-- The old view references both tables: drop it first.
drop view if exists public.devices_with_status;
drop function if exists public.device_status(public.devices);

-- ---------------------------------------------------------------------------
-- Legacy playlists: keep account-owned rows, drop device-only ones.
delete from public.playlists where account_id is null;

alter table public.playlists
  drop constraint if exists playlists_owner_check,
  drop column if exists device_id,
  alter column account_id set not null;

-- ---------------------------------------------------------------------------
-- Devices: no MAC / key / per-device trial.
alter table public.devices
  drop column if exists mac,
  drop column if exists device_key,
  drop column if exists trial_started_at,
  drop column if exists activated,
  drop column if exists activated_at,
  drop column if exists expires_at;

create view public.devices_with_status
with (security_invoker = true) as
select d.*,
       (select pr.email from public.profiles pr where pr.id = d.account_id) as account_email
from public.devices d;

grant select on public.devices_with_status to authenticated;

-- ---------------------------------------------------------------------------
-- confirm_pairing without the legacy claim / activation carry-over.
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
    if (st->>'expired')::boolean then
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
