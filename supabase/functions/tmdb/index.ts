// GET /tmdb?action=search|trending|details&type=movie|tv&q=...&id=...&lang=fr-FR
// Proxies TMDB so the API key never leaves the server. Callable by a device (install headers or
// legacy mac/key) or an admin.

import { adminClient, HttpError, json, serve } from "../_shared/http.ts";
import { authenticateDeviceOrAdmin } from "../_shared/device.ts";
import { details, parseKind, parseLang, search, trending } from "../_shared/tmdb.ts";

serve(async (req) => {
  if (req.method !== "GET") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  await authenticateDeviceOrAdmin(db, req);

  const url = new URL(req.url);
  const action = url.searchParams.get("action") ?? "search";
  const lang = parseLang(url.searchParams.get("lang"));

  switch (action) {
    case "search": {
      const q = (url.searchParams.get("q") ?? "").trim();
      if (q.length < 2) throw new HttpError(400, "q is too short");
      const type = url.searchParams.get("type");
      if (type === "movie" || type === "tv") return json({ results: await search(type, q, lang) });
      // No type: search both and interleave so the admin sees movies and series together.
      const [movies, shows] = await Promise.all([search("movie", q, lang), search("tv", q, lang)]);
      const out = [];
      for (let i = 0; i < Math.max(movies.length, shows.length); i++) {
        if (movies[i]) out.push(movies[i]);
        if (shows[i]) out.push(shows[i]);
      }
      return json({ results: out.slice(0, 20) });
    }
    case "trending": {
      const type = url.searchParams.get("type");
      if (type === "movie" || type === "tv") return json({ results: await trending(type, lang) });
      const [movies, shows] = await Promise.all([trending("movie", lang), trending("tv", lang)]);
      const out = [];
      for (let i = 0; i < Math.max(movies.length, shows.length); i++) {
        if (movies[i]) out.push(movies[i]);
        if (shows[i]) out.push(shows[i]);
      }
      return json({ results: out });
    }
    case "details": {
      const kind = parseKind(url.searchParams.get("type"));
      const id = Number(url.searchParams.get("id"));
      if (!Number.isInteger(id) || id <= 0) throw new HttpError(400, "id is required");
      return json(await details(kind, id, lang));
    }
    default:
      throw new HttpError(400, "Unknown action");
  }
});
