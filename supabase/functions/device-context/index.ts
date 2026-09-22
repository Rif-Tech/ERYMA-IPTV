// Remembers which profile/playlist this installation is using.
//   PUT /device-context { profile_id, playlist_id } (headers x-device-id / x-device-secret) → { ok }
// Ownership and profile→playlist access are validated by set_device_context in SQL.

import { authenticateInstall, mapSqlError, readInstallCredentials } from "../_shared/device.ts";
import { adminClient, HttpError, json, optionalString, readJson, serve } from "../_shared/http.ts";

serve(async (req) => {
  if (req.method !== "PUT" && req.method !== "POST") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const body = await readJson(req);
  const creds = readInstallCredentials(req, body);
  if (!creds) throw new HttpError(401, "UNPAIRED");
  const device = await authenticateInstall(db, creds.uuid, creds.secret);

  const { error } = await db.rpc("set_device_context", {
    p_device: device.id,
    p_profile: optionalString(body.profile_id, 64),
    p_playlist: optionalString(body.playlist_id, 64),
  });
  if (error) throw mapSqlError(error.message);
  return json({ ok: true });
});
