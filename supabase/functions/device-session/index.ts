// Everything a paired installation needs at startup, in one call.
//   GET /device-session  (headers x-device-id / x-device-secret)
//   → { device, account, profiles, playlists, context }
// 401 UNPAIRED when the device was revoked or deleted: the app returns to the pairing screen.

import { authenticateInstall, computeAccountStatus, readInstallCredentials } from "../_shared/device.ts";
import { adminClient, HttpError, json, serve } from "../_shared/http.ts";

serve(async (req) => {
  if (req.method !== "GET") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const creds = readInstallCredentials(req);
  if (!creds) throw new HttpError(401, "UNPAIRED");
  const device = await authenticateInstall(db, creds.uuid, creds.secret);
  const accountId = device.account_id!;

  await db.from("devices").update({ last_seen_at: new Date().toISOString() }).eq("id", device.id);
  const account = await computeAccountStatus(db, accountId);

  const [{ data: profiles, error: e1 }, { data: access, error: e2 }, { data: playlists, error: e3 }] = await Promise.all([
    db.from("viewer_profiles").select("id, name, avatar, is_kids, position").eq("account_id", accountId).order("position").order("created_at"),
    db.from("profile_playlists").select("profile_id, playlist_id, viewer_profiles!inner(account_id)").eq("viewer_profiles.account_id", accountId),
    // Credentials are only returned to the authenticated device; an expired account gets none.
    account.expired
      ? Promise.resolve({ data: [], error: null })
      : db.from("playlists").select("*").eq("account_id", accountId).order("position").order("created_at"),
  ]);
  if (e1) throw new HttpError(500, e1.message);
  if (e2) throw new HttpError(500, e2.message);
  if (e3) throw new HttpError(500, e3.message);

  const byProfile = new Map<string, string[]>();
  for (const row of (access ?? []) as { profile_id: string; playlist_id: string }[]) {
    (byProfile.get(row.profile_id) ?? byProfile.set(row.profile_id, []).get(row.profile_id)!).push(row.playlist_id);
  }

  return json({
    device: { id: device.id, name: device.name, device_type: device.device_type, status: device.status },
    account,
    profiles: (profiles ?? []).map((p) => ({ ...p, playlist_ids: byProfile.get(p.id) ?? [] })),
    playlists: playlists ?? [],
    context: { profile_id: device.active_profile_id, playlist_id: device.active_playlist_id },
  });
});
