// Thin TMDB v3 client. The API key lives in the TMDB_API_KEY function secret.

import { HttpError } from "./http.ts";

const API = "https://api.themoviedb.org/3";
const IMG = "https://image.tmdb.org/t/p";

export type TmdbKind = "movie" | "tv";

export interface TmdbSummary {
  tmdb_id: number;
  kind: TmdbKind;
  title: string;
  original_title: string | null;
  year: number | null;
  overview: string | null;
  poster_url: string | null;
  backdrop_url: string | null;
  rating: number | null;
  genres: string[];
}

function apiKey(): string {
  const key = Deno.env.get("TMDB_API_KEY");
  if (!key) throw new HttpError(503, "TMDB_API_KEY is not configured");
  return key;
}

export function posterUrl(path: unknown, size = "w500"): string | null {
  return typeof path === "string" && path ? `${IMG}/${size}${path}` : null;
}

export function backdropUrl(path: unknown, size = "w1280"): string | null {
  return typeof path === "string" && path ? `${IMG}/${size}${path}` : null;
}

// deno-lint-ignore no-explicit-any
export async function tmdbGet(path: string, params: Record<string, string | number | undefined> = {}): Promise<any> {
  const url = new URL(`${API}${path}`);
  url.searchParams.set("api_key", apiKey());
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== "") url.searchParams.set(k, String(v));
  }
  const res = await fetch(url, { headers: { accept: "application/json" } });
  if (res.status === 404) throw new HttpError(404, "TMDB item not found");
  if (!res.ok) throw new HttpError(502, `TMDB error ${res.status}`);
  return await res.json();
}

/** Normalizes a movie/tv payload (search, trending or details) into one shape. */
// deno-lint-ignore no-explicit-any
export function summarize(raw: any, kind: TmdbKind): TmdbSummary {
  const date: string = raw.release_date ?? raw.first_air_date ?? "";
  const year = /^\d{4}/.test(date) ? Number(date.slice(0, 4)) : null;
  const genres: string[] = Array.isArray(raw.genres) ? raw.genres.map((g: { name: string }) => g.name) : [];
  return {
    tmdb_id: Number(raw.id),
    kind,
    title: String(raw.title ?? raw.name ?? ""),
    original_title: (raw.original_title ?? raw.original_name ?? null) as string | null,
    year,
    overview: (raw.overview as string) || null,
    poster_url: posterUrl(raw.poster_path),
    backdrop_url: backdropUrl(raw.backdrop_path),
    rating: typeof raw.vote_average === "number" && raw.vote_average > 0 ? raw.vote_average : null,
    genres,
  };
}

export function parseKind(raw: unknown): TmdbKind {
  if (raw === "movie" || raw === "tv") return raw;
  throw new HttpError(400, "type must be movie or tv");
}

export function parseLang(raw: unknown): string {
  const s = String(raw ?? "fr-FR").trim();
  return /^[a-z]{2}(-[A-Z]{2})?$/.test(s) ? s : "fr-FR";
}

export async function search(kind: TmdbKind, query: string, lang: string): Promise<TmdbSummary[]> {
  const data = await tmdbGet(`/search/${kind}`, { query, language: lang, include_adult: "false" });
  return ((data.results ?? []) as unknown[]).map((r) => summarize(r, kind));
}

export async function trending(kind: TmdbKind, lang: string): Promise<TmdbSummary[]> {
  const data = await tmdbGet(`/trending/${kind}/week`, { language: lang });
  return ((data.results ?? []) as unknown[]).map((r) => summarize(r, kind));
}

export async function details(kind: TmdbKind, id: number, lang: string): Promise<TmdbSummary> {
  return summarize(await tmdbGet(`/${kind}/${id}`, { language: lang }), kind);
}
