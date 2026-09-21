// GET /featured?mac=&key=&mode=curated|popular|tmdb&lang=fr-FR
// Returns the hero entries for the requested source in one uniform shape. Matching against the
// device's playlists happens on the device (the server never sees playlist contents).

import { adminClient, HttpError, json, serve } from "../_shared/http.ts";
import { authenticateDevice } from "../_shared/device.ts";
import { details, parseLang, trending, type TmdbSummary } from "../_shared/tmdb.ts";

interface FeaturedEntry {
  id: string;
  kind: "movie" | "tv" | "live" | "custom";
  tmdb_id: number | null;
  title: string;
  subtitle: string | null;
  overview: string | null;
  year: number | null;
  poster_url: string | null;
  backdrop_url: string | null;
  link_kind: "channel" | "movie" | "series" | "url" | null;
  link_query: string | null;
  require_match: boolean;
  event_at?: string | null;
  event_end_at?: string | null;
}

/** Events stay listed until their end (start + 3 h when no end is set). */
function isOver(e: FeaturedEntry, now: number): boolean {
  if (!e.event_at) return false;
  const end = e.event_end_at ? Date.parse(e.event_end_at) : Date.parse(e.event_at) + 3 * 60 * 60 * 1000;
  return Number.isFinite(end) && end < now;
}

function fromTmdb(s: TmdbSummary, id: string, subtitle: string | null = null): FeaturedEntry {
  return {
    id,
    kind: s.kind,
    tmdb_id: s.tmdb_id,
    title: s.title,
    subtitle,
    overview: s.overview,
    year: s.year,
    poster_url: s.poster_url,
    backdrop_url: s.backdrop_url,
    link_kind: null,
    link_query: null,
    require_match: true,
  };
}

serve(async (req) => {
  if (req.method !== "GET") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const url = new URL(req.url);
  await authenticateDevice(db, url.searchParams.get("mac"), url.searchParams.get("key"));
  const mode = url.searchParams.get("mode") ?? "curated";
  const lang = parseLang(url.searchParams.get("lang"));

  if (mode === "curated") {
    const { data, error } = await db
      .from("featured_items")
      .select("id, kind, tmdb_id, title, subtitle, overview, year, poster_url, backdrop_url, link_kind, link_query, require_match, event_at, event_end_at")
      .eq("enabled", true)
      .order("position", { ascending: true })
      .limit(24);
    if (error) throw new HttpError(500, error.message);
    const now = Date.now();
    const items = ((data ?? []) as FeaturedEntry[]).filter((e) => !isOver(e, now)).slice(0, 12);
    return json({ mode, items });
  }

  if (mode === "tmdb") {
    let items: FeaturedEntry[] = [];
    try {
      const [movies, shows] = await Promise.all([trending("movie", lang), trending("tv", lang)]);
      for (let i = 0; i < Math.max(movies.length, shows.length) && items.length < 20; i++) {
        if (movies[i]) items.push(fromTmdb(movies[i], `tmdb:movie:${movies[i].tmdb_id}`));
        if (shows[i]) items.push(fromTmdb(shows[i], `tmdb:tv:${shows[i].tmdb_id}`));
      }
    } catch (e) {
      // A missing TMDB key must not break the home screen: the app falls back to local content.
      if (!(e instanceof HttpError && e.status === 503)) throw e;
      items = [];
    }
    return json({ mode, items });
  }

  if (mode === "popular") {
    const { data, error } = await db.rpc("popular_titles", { days: 7, lim: 12 });
    if (error) throw new HttpError(500, error.message);
    const rows = (data ?? []) as {
      kind: "movie" | "tv" | "live";
      title_key: string;
      title: string;
      year: number | null;
      tmdb_id: number | null;
      devices: number;
      plays: number;
    }[];
    // Enrich with TMDB artwork when an id is known; ignore failures (no key, unknown id).
    const items: FeaturedEntry[] = await Promise.all(
      rows.map(async (r) => {
        let art: TmdbSummary | null = null;
        if (r.tmdb_id && (r.kind === "movie" || r.kind === "tv")) {
          try {
            art = await details(r.kind, r.tmdb_id, lang);
          } catch (_) {
            art = null;
          }
        }
        return {
          id: `popular:${r.kind}:${r.title_key}`,
          kind: r.kind,
          tmdb_id: r.tmdb_id,
          title: art?.title ?? r.title,
          subtitle: null,
          overview: art?.overview ?? null,
          year: art?.year ?? r.year,
          poster_url: art?.poster_url ?? null,
          backdrop_url: art?.backdrop_url ?? null,
          link_kind: r.kind === "live" ? "channel" : null,
          link_query: r.kind === "live" ? r.title : r.title_key,
          require_match: true,
        };
      }),
    );
    return json({ mode, items });
  }

  throw new HttpError(400, "Unknown mode");
});
