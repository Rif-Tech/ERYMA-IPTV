// Watch progress sync, scoped to profile + playlist + provider item (never merged across playlists).
//   GET /device-progress?profile_id=&playlist_id=[&since=ISO]        → { items }
//   PUT /device-progress { profile_id, playlist_id, items: [...] }   → { ok, upserted }
// items: { kind, item_id, parent_id?, position_ms, duration_ms, completed, last_watched_at }

import { authenticateInstall, mapSqlError, readInstallCredentials } from "../_shared/device.ts";
import { adminClient, HttpError, json, optionalString, readJson, requireString, serve } from "../_shared/http.ts";

const KINDS = new Set(["live", "vod", "series"]);
const MAX_ITEMS = 200;

async function assertAccess(db: ReturnType<typeof adminClient>, accountId: string, profileId: string, playlistId: string) {
  const { data, error } = await db
    .from("profile_playlists")
    .select("profile_id, viewer_profiles!inner(account_id)")
    .eq("profile_id", profileId)
    .eq("playlist_id", playlistId)
    .eq("viewer_profiles.account_id", accountId)
    .maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (!data) throw new HttpError(403, "PROFILE_HAS_NO_ACCESS");
}

serve(async (req) => {
  const db = adminClient();
  const body = req.method === "GET" ? {} : await readJson(req);
  const creds = readInstallCredentials(req, body);
  if (!creds) throw new HttpError(401, "UNPAIRED");
  const device = await authenticateInstall(db, creds.uuid, creds.secret);
  const url = new URL(req.url);

  if (req.method === "GET") {
    const profileId = requireString(url.searchParams.get("profile_id"), "profile_id", 64);
    const playlistId = requireString(url.searchParams.get("playlist_id"), "playlist_id", 64);
    await assertAccess(db, device.account_id!, profileId, playlistId);
    let q = db
      .from("watch_progress")
      .select("kind, item_id, parent_id, position_ms, duration_ms, completed, last_watched_at")
      .eq("profile_id", profileId)
      .eq("playlist_id", playlistId)
      .order("last_watched_at", { ascending: false })
      .limit(500);
    const since = url.searchParams.get("since");
    if (since) q = q.gt("updated_at", new Date(since).toISOString());
    const { data, error } = await q;
    if (error) throw new HttpError(500, error.message);
    return json({ items: data ?? [] });
  }

  if (req.method !== "PUT" && req.method !== "POST") throw new HttpError(405, "Method not allowed");
  const profileId = requireString(body.profile_id, "profile_id", 64);
  const playlistId = requireString(body.playlist_id, "playlist_id", 64);
  await assertAccess(db, device.account_id!, profileId, playlistId);

  const items = Array.isArray(body.items) ? body.items.slice(0, MAX_ITEMS) : [];
  const rows = [];
  for (const raw of items as Record<string, unknown>[]) {
    const kind = String(raw.kind ?? "");
    if (!KINDS.has(kind)) continue;
    const itemId = optionalString(raw.item_id, 200);
    if (!itemId) continue;
    const position = Math.max(0, Number(raw.position_ms) || 0);
    const duration = Math.max(0, Number(raw.duration_ms) || 0);
    rows.push({
      profile_id: profileId,
      playlist_id: playlistId,
      kind,
      item_id: itemId,
      parent_id: optionalString(raw.parent_id, 200),
      position_ms: position,
      duration_ms: duration,
      completed: raw.completed === true || (duration > 0 && position >= duration * 0.95),
      last_watched_at: raw.last_watched_at ? new Date(String(raw.last_watched_at)).toISOString() : new Date().toISOString(),
    });
  }
  if (rows.length === 0) return json({ ok: true, upserted: 0 });
  const { error } = await db.from("watch_progress").upsert(rows, { onConflict: "profile_id,playlist_id,kind,item_id" });
  if (error) throw mapSqlError(error.message);
  return json({ ok: true, upserted: rows.length });
});
