-- Featured ("À la une") items curated by admins + anonymous watch statistics.

create table if not exists public.featured_items (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('movie', 'tv', 'custom')),
  tmdb_id integer,
  title text not null,
  subtitle text,
  overview text,
  year integer,
  poster_url text,
  backdrop_url text,
  -- Optional target for custom banners: a channel/movie/series looked up by name, or an external URL.
  link_kind text check (link_kind in ('channel', 'movie', 'series', 'url')),
  link_query text,
  -- Hide the entry on devices whose playlists do not contain a matching item.
  require_match boolean not null default true,
  enabled boolean not null default true,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists featured_items_order_idx on public.featured_items (enabled, position);

alter table public.featured_items enable row level security;

create policy "featured_items: admin all" on public.featured_items
  for all using (public.is_admin()) with check (public.is_admin());

grant select, insert, update, delete on public.featured_items to authenticated;

-- One row per playback start. No MAC or playlist data: only what is needed to rank titles.
create table if not exists public.watch_events (
  id bigint generated always as identity primary key,
  device_id uuid not null references public.devices (id) on delete cascade,
  kind text not null check (kind in ('movie', 'tv', 'live')),
  title_key text not null,
  title text not null,
  year integer,
  tmdb_id integer,
  watched_at timestamptz not null default now()
);

create index if not exists watch_events_watched_at_idx on public.watch_events (watched_at desc);
create index if not exists watch_events_title_idx on public.watch_events (kind, title_key);

alter table public.watch_events enable row level security;

create policy "watch_events: admin read" on public.watch_events
  for select using (public.is_admin());

grant select on public.watch_events to authenticated;

-- Most watched titles over the last `days`, ranked by distinct devices then plays.
create or replace function public.popular_titles(days integer default 7, lim integer default 20)
returns table (
  kind text,
  title_key text,
  title text,
  year integer,
  tmdb_id integer,
  devices bigint,
  plays bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    w.kind,
    w.title_key,
    -- Most frequent spelling of the title among the events.
    (array_agg(w.title order by w.watched_at desc))[1] as title,
    max(w.year) as year,
    max(w.tmdb_id) as tmdb_id,
    count(distinct w.device_id) as devices,
    count(*) as plays
  from public.watch_events w
  where w.watched_at > now() - make_interval(days => greatest(days, 1))
  group by w.kind, w.title_key
  order by devices desc, plays desc
  limit greatest(lim, 1);
$$;

revoke execute on function public.popular_titles(integer, integer) from public, anon;
grant execute on function public.popular_titles(integer, integer) to authenticated, service_role;

-- Drops events older than 30 days; called opportunistically by the watch-events function.
create or replace function public.purge_watch_events()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.watch_events where watched_at < now() - interval '30 days';
$$;

revoke execute on function public.purge_watch_events() from public, anon, authenticated;
grant execute on function public.purge_watch_events() to service_role;
