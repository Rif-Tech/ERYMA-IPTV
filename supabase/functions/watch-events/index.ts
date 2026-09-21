// POST /watch-events {mac, key, kind: movie|tv|live, title_key, title, year?, tmdb_id?}
// Anonymous playback statistics used for the "most watched right now" hero source.

import { adminClient, HttpError, json, readJson, requireString, serve } from "../_shared/http.ts";
import { authenticateDevice } from "../_shared/device.ts";

serve(async (req) => {
  if (req.method !== "POST") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const body = await readJson(req);
  const device = await authenticateDevice(db, body.mac, body.key);

  const kind = String(body.kind ?? "");
  if (!["movie", "tv", "live"].includes(kind)) throw new HttpError(400, "kind must be movie, tv or live");
  const titleKey = requireString(body.title_key, "title_key", 200).toLowerCase();
  const title = requireString(body.title, "title", 300);
  const year = Number.isInteger(body.year) && (body.year as number) > 1800 ? (body.year as number) : null;
  const tmdbId = Number.isInteger(body.tmdb_id) && (body.tmdb_id as number) > 0 ? (body.tmdb_id as number) : null;

  // One event per device/title/hour keeps zapping and resumes from inflating the ranking.
  const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { data: recent, error: recentErr } = await db
    .from("watch_events")
    .select("id")
    .eq("device_id", device.id)
    .eq("kind", kind)
    .eq("title_key", titleKey)
    .gt("watched_at", since)
    .limit(1);
  if (recentErr) throw new HttpError(500, recentErr.message);
  if ((recent ?? []).length > 0) return json({ ok: true, deduplicated: true });

  const { error } = await db.from("watch_events").insert({
    device_id: device.id,
    kind,
    title_key: titleKey,
    title,
    year,
    tmdb_id: tmdbId,
  });
  if (error) throw new HttpError(500, error.message);

  // Opportunistic retention: roughly 1 in 50 calls purges rows older than 30 days.
  if (Math.random() < 0.02) await db.rpc("purge_watch_events");

  return json({ ok: true });
});
