-- Admin-managed DNS server presets used by the app to bypass ISP DNS restrictions when loading
-- playlists/streams (see docs/api.md, app-info response).

create table if not exists public.dns_servers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  provider text,
  ipv4 text[] not null default '{}',
  ipv6 text[] not null default '{}',
  doh_url text,
  dot_host text,
  enabled boolean not null default true,
  is_default boolean not null default false,
  position integer not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists dns_servers_order_idx on public.dns_servers (enabled, position);

-- Only one default at a time.
create unique index if not exists dns_servers_single_default_idx on public.dns_servers (is_default) where is_default;

alter table public.dns_servers enable row level security;

create policy "dns_servers: admin all" on public.dns_servers
  for all using (public.is_admin()) with check (public.is_admin());

grant select, insert, update, delete on public.dns_servers to authenticated;

insert into public.dns_servers (name, provider, ipv4, ipv6, doh_url, is_default, position) values
  ('Google Public DNS', 'Google', array['8.8.8.8', '8.8.4.4'], array['2001:4860:4860::8888', '2001:4860:4860::8844'], 'https://8.8.8.8/dns-query', true, 0),
  ('Cloudflare', 'Cloudflare', array['1.1.1.1', '1.0.0.1'], array['2606:4700:4700::1111', '2606:4700:4700::1001'], 'https://1.1.1.1/dns-query', false, 1),
  ('Quad9', 'Quad9', array['9.9.9.9', '149.112.112.112'], array['2620:fe::fe', '2620:fe::9'], 'https://9.9.9.9/dns-query', false, 2),
  ('OpenDNS', 'Cisco', array['208.67.222.222', '208.67.220.220'], array['2620:119:35::35', '2620:119:53::53'], null, false, 3),
  ('AdGuard DNS', 'AdGuard', array['94.140.14.14', '94.140.15.15'], array['2a10:50c0::ad1:ff', '2a10:50c0::ad2:ff'], 'https://94.140.14.14/dns-query', false, 4),
  ('Mullvad DNS', 'Mullvad', array['194.242.2.2'], array['2a07:e340::2'], 'https://194.242.2.2/dns-query', false, 5)
on conflict do nothing;
