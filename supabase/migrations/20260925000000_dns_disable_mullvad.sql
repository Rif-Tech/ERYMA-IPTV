-- Mullvad DNS never worked from the app (Sentry, 2026-09-24): its DoH endpoint rejects a TLS
-- handshake on the bare IP, and 194.242.2.2 does not answer plain UDP DNS. Disabled rather than
-- deleted so an admin can re-enable it from /admin/dns. Mirrors kBuiltinDnsServers (app).
update public.dns_servers
set enabled = false, updated_at = now()
where name = 'Mullvad DNS' and enabled;
