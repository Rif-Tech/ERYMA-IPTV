-- Application diagnostic logs (crash context, playback/import/pairing failures), retained 48h.
-- Keyed by device + account for per-user/per-device troubleshooting. Content is technical
-- (level/category/message/context): never a playlist URL or credentials. Native crashes (which
-- never reach Dart, e.g. a 4K decode segfault) are covered separately by Sentry, not this table.

create table if not exists public.app_logs (
  id bigint generated always as identity primary key,
  device_id uuid not null references public.devices (id) on delete cascade,
  account_id uuid references public.accounts (id) on delete set null,
  level text not null check (level in ('debug', 'info', 'warn', 'error')),
  category text not null,
  message text not null,
  context jsonb,
  -- App-generated id so a retried batch (flaky network) does not duplicate rows.
  client_id text,
  created_at timestamptz not null default now()
);

create index if not exists app_logs_created_at_idx on public.app_logs (created_at desc);
create index if not exists app_logs_device_idx on public.app_logs (device_id, created_at desc);
-- Not partial on purpose: a plain unique index still allows unlimited NULL client_id (standard
-- SQL: NULLs are never equal to each other), but it — unlike a partial one — can serve as the
-- ON CONFLICT (client_id) arbiter PostgREST generates for upsert(..., {ignoreDuplicates: true}),
-- which never adds the WHERE predicate a partial index would need to be inferred.
create unique index if not exists app_logs_client_id_idx on public.app_logs (client_id);

alter table public.app_logs enable row level security;

-- Admin only, like watch_events: logs can carry technical detail (stack fragments, URLs stripped
-- of credentials) that a plain account-owner policy should not expose by default.
create policy "app_logs: admin read" on public.app_logs
  for select using (public.is_admin());

grant select on public.app_logs to authenticated;

-- Drops logs older than 48h; called opportunistically by the device-logs function.
create or replace function public.purge_app_logs()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.app_logs where created_at < now() - interval '48 hours';
$$;

revoke execute on function public.purge_app_logs() from public, anon, authenticated;
grant execute on function public.purge_app_logs() to service_role;
