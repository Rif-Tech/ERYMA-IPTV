-- Public portal URL shown by devices and embedded in pairing QR codes. Editable from /admin/config;
-- falls back to the PORTAL_URL function secret when null. Never "localhost": it must be reachable
-- from the devices' network.
insert into public.app_config (key, value)
values ('portal_url', 'null')
on conflict (key) do nothing;
