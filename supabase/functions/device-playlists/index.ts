// Device-facing playlist API (authenticated by MAC + device key).
//   GET    /device-playlists?mac=&key=          → { status, playlists }
//   POST   /device-playlists { mac, key, ...playlist } → { playlist }
//   PUT    /device-playlists { mac, key, id, ...fields } → { playlist }
//   DELETE /device-playlists { mac, key, id }   → { ok }

import { authenticateDevice, computeStatus } from "../_shared/device.ts";
import { adminClient, HttpError, json, readJson, requireString, serve } from "../_shared/http.ts";
import { createPlaylist, deletePlaylist, listPlaylists, updatePlaylist, validatePlaylistInput } from "../_shared/playlists.ts";

serve(async (req) => {
  const db = adminClient();

  if (req.method === "GET") {
    const url = new URL(req.url);
    const device = await authenticateDevice(db, url.searchParams.get("mac"), url.searchParams.get("key"));
    await db.from("devices").update({ last_seen_at: new Date().toISOString() }).eq("id", device.id);
    const status = await computeStatus(db, device);
    // Credentials are returned only to the authenticated device (HTTPS in production).
    const playlists = status.expired ? [] : await listPlaylists(db, device.id);
    return json({ status, playlists });
  }

  const body = await readJson(req);
  const device = await authenticateDevice(db, body.mac, body.key ?? body.device_key);

  if (req.method === "POST") {
    const input = validatePlaylistInput(body);
    const playlist = await createPlaylist(db, device.id, input);
    return json({ playlist }, 201);
  }

  if (req.method === "PUT") {
    const id = requireString(body.id, "id", 64);
    const { mac: _m, key: _k, device_key: _dk, id: _id, ...rest } = body;
    return json({ playlist: await updatePlaylist(db, device.id, id, validatePlaylistInput(rest, true)) });
  }

  if (req.method === "DELETE") {
    await deletePlaylist(db, device.id, requireString(body.id, "id", 64));
    return json({ ok: true });
  }

  throw new HttpError(405, "Method not allowed");
});
