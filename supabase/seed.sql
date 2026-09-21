-- Local development seed: an admin user and a demo device.
-- Password for admin@multiptv.local is "multiptv-admin" (change it in production!).

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-1111-1111-111111111111',
  'authenticated', 'authenticated',
  'admin@multiptv.local',
  crypt('multiptv-admin', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(), now()
) on conflict (id) do nothing;

update public.profiles set role = 'admin' where id = '11111111-1111-1111-1111-111111111111';

insert into public.devices (mac, device_key, device_type, platform, app_version, activated)
values ('02:00:00:AA:BB:CC', 'DEMO42', 'tv', 'android', '1.0.0', true)
on conflict (mac) do nothing;

insert into public.playlists (device_id, name, type, url)
select id, 'Demo M3U', 'm3u', 'https://iptv-org.github.io/iptv/index.m3u'
from public.devices where mac = '02:00:00:AA:BB:CC'
on conflict do nothing;
