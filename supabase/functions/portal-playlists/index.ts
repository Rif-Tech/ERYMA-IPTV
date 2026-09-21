// Portal playlist CRUD, authenticated with the token from /portal-login
// (header `Authorization: Bearer <token>` or `x-portal-token`).
//   GET    /portal-playlists                 → { status, device, playlists } (protected ones are masked)
//   GET    /portal-playlists?id=&pin=        → { playlist } (full, PIN verified)
//   POST   /portal-playlists { ...playlist }        → { playlist }
//   PUT    /portal-playlists { id, pin?, ...fields } → { playlist }
//   PATCH  /portal-playlists { order: [id, id, …] } → { ok }
//   DELETE /portal-playlists { id, pin? }           → { ok }

import { authenticatePortal, computeStatus } from "../_shared/device.ts";
import { adminClient, HttpError, json, readJson, requireString, serve } from "../_shared/http.ts";
import {
  assertPin,
  createPlaylist,
  deletePlaylist,
  getPlaylist,
  listPlaylists,
  maskProtected,
  updatePlaylist,
  validatePlaylistInput,
} from "../_shared/playlists.ts";

serve(async (req) => {
  const db = adminClient();
  const device = await authenticatePortal(db, req);

  switch (req.method) {
    case "GET": {
      const url = new URL(req.url);
      const id = url.searchParams.get("id");
      if (id) {
        const playlist = await getPlaylist(db, device.id, id);
        assertPin(playlist, url.searchParams.get("pin"));
        return json({ playlist });
      }
      const [status, playlists] = await Promise.all([computeStatus(db, device), listPlaylists(db, device.id)]);
      return json({
        status,
        device: { mac: device.mac, device_type: device.device_type, created_at: device.created_at, last_seen_at: device.last_seen_at },
        playlists: playlists.map(maskProtected),
      });
    }
    case "POST": {
      const body = await readJson(req);
      return json({ playlist: await createPlaylist(db, device.id, validatePlaylistInput(body)) }, 201);
    }
    case "PUT": {
      const body = await readJson(req);
      const id = requireString(body.id, "id", 64);
      assertPin(await getPlaylist(db, device.id, id), body.pin);
      const { id: _id, pin: _pin, ...rest } = body;
      return json({ playlist: await updatePlaylist(db, device.id, id, validatePlaylistInput(rest, true)) });
    }
    case "PATCH": {
      const body = await readJson<{ order?: unknown }>(req);
      if (!Array.isArray(body.order)) throw new HttpError(400, "order must be an array of ids");
      await Promise.all(
        body.order.map((id, i) => db.from("playlists").update({ position: i }).eq("id", String(id)).eq("device_id", device.id)),
      );
      return json({ ok: true });
    }
    case "DELETE": {
      const body = await readJson(req);
      const id = requireString(body.id, "id", 64);
      assertPin(await getPlaylist(db, device.id, id), body.pin);
      await deletePlaylist(db, device.id, id);
      return json({ ok: true });
    }
    default:
      throw new HttpError(405, "Method not allowed");
  }
});
