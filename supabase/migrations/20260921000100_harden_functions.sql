-- Lock down SECURITY DEFINER helpers: not callable through the public REST API.
-- device_status stays callable by signed-in users: the admin view devices_with_status
-- (security_invoker) needs it, and RLS on devices still restricts the rows.
revoke execute on function public.device_status(public.devices) from public, anon;
grant execute on function public.device_status(public.devices) to authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
