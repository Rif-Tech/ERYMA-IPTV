import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { safeEqual } from "./device.ts";
import { HttpError, optionalString, requireString } from "./http.ts";

export interface PlaylistRow {
  id: string;
  device_id: string | null;
  account_id: string | null;
  name: string;
  type: "m3u" | "xtream";
  url: string;
  username: string | null;
  password: string | null;
  epg_url: string | null;
  is_protected: boolean;
  pin_code: string | null;
  expires_at: string | null;
  position: number;
  created_at: string;
  updated_at: string;
}

export const MAX_PLAYLISTS_PER_DEVICE = 20;

/** Validates a playlist payload from the app or the portal. */
export function validatePlaylistInput(body: Record<string, unknown>, partial = false) {
  const out: Record<string, unknown> = {};

  if (!partial || body.name !== undefined) out.name = requireString(body.name, "name", 120);
  if (!partial || body.type !== undefined) {
    const type = String(body.type ?? "m3u");
    if (type !== "m3u" && type !== "xtream") throw new HttpError(400, "type must be m3u or xtream");
    out.type = type;
  }
  if (!partial || body.url !== undefined) {
    const url = requireString(body.url, "url");
    if (!/^https?:\/\//i.test(url) && !(out.type === "xtream" && /^[\w.-]+(:\d+)?/.test(url))) {
      throw new HttpError(400, "url must start with http:// or https://");
    }
    out.url = url;
  }
  if (body.username !== undefined) out.username = optionalString(body.username, 200);
  if (body.password !== undefined) out.password = optionalString(body.password, 200);
  if (body.epg_url !== undefined) out.epg_url = optionalString(body.epg_url);
  if (body.is_protected !== undefined) out.is_protected = Boolean(body.is_protected);
  if (body.pin_code !== undefined) {
    const pin = optionalString(body.pin_code, 12);
    if (pin && !/^\d{4,8}$/.test(pin)) throw new HttpError(400, "pin_code must be 4 to 8 digits");
    out.pin_code = pin;
  }
  if (body.expires_at !== undefined) {
    const v = body.expires_at;
    out.expires_at = v ? new Date(String(v)).toISOString() : null;
  }
  if (body.position !== undefined) out.position = Number(body.position) || 0;

  const type = out.type as string | undefined;
  if (type === "xtream" && !partial && (!out.username || !out.password)) {
    throw new HttpError(400, "username and password are required for Xtream playlists");
  }
  if (out.is_protected === true && out.pin_code === null) {
    throw new HttpError(400, "pin_code is required when is_protected is true");
  }
  return convertGetPhp(out);
}

/** `http://host/get.php?username=u&password=p…` is an Xtream account: store it as such. */
export function convertGetPhp(input: Record<string, unknown>): Record<string, unknown> {
  if (input.type !== "m3u" || typeof input.url !== "string") return input;
  let u: URL;
  try {
    u = new URL(input.url);
  } catch {
    return input;
  }
  const username = u.searchParams.get("username");
  const password = u.searchParams.get("password");
  if (!/\/get\.php$/i.test(u.pathname) || !username || !password) return input;
  const base = `${u.protocol}//${u.host}${u.pathname.replace(/\/get\.php$/i, "")}`;
  return { ...input, type: "xtream", url: base, username, password };
}

export async function listPlaylists(db: SupabaseClient, deviceId: string): Promise<PlaylistRow[]> {
  const { data, error } = await db
    .from("playlists")
    .select("*")
    .eq("device_id", deviceId)
    .order("position", { ascending: true })
    .order("created_at", { ascending: true });
  if (error) throw new HttpError(500, error.message);
  return (data ?? []) as PlaylistRow[];
}

export async function listAccountPlaylists(db: SupabaseClient, accountId: string): Promise<PlaylistRow[]> {
  const { data, error } = await db
    .from("playlists")
    .select("*")
    .eq("account_id", accountId)
    .order("position", { ascending: true })
    .order("created_at", { ascending: true });
  if (error) throw new HttpError(500, error.message);
  return (data ?? []) as PlaylistRow[];
}

export async function getPlaylist(db: SupabaseClient, deviceId: string, id: string): Promise<PlaylistRow> {
  const { data, error } = await db.from("playlists").select("*").eq("id", id).eq("device_id", deviceId).maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (!data) throw new HttpError(404, "Playlist not found");
  return data as PlaylistRow;
}

/** Hides credentials of PIN-protected playlists in portal listings. */
export function maskProtected(p: PlaylistRow): PlaylistRow & { locked: boolean } {
  if (!p.is_protected) return { ...p, locked: false };
  let host = "•••";
  try {
    host = new URL(p.url).host;
  } catch { /* keep placeholder */ }
  return { ...p, url: `${host}/•••`, username: null, password: null, epg_url: null, pin_code: null, locked: true };
}

/** Throws 403 unless [pin] matches the playlist's PIN (no-op for unprotected playlists). */
export function assertPin(p: PlaylistRow, pin: unknown): void {
  if (!p.is_protected || !p.pin_code) return;
  const given = typeof pin === "string" ? pin.trim() : "";
  if (!given || !safeEqual(given, p.pin_code)) throw new HttpError(403, "PIN incorrect");
}

export async function createPlaylist(db: SupabaseClient, deviceId: string, input: Record<string, unknown>) {
  const existing = await listPlaylists(db, deviceId);
  if (existing.length >= MAX_PLAYLISTS_PER_DEVICE) throw new HttpError(409, "Too many playlists for this device");
  const position = input.position ?? (existing.length ? Math.max(...existing.map((p) => p.position)) + 1 : 0);
  const { data, error } = await db
    .from("playlists")
    .insert({ ...input, device_id: deviceId, position })
    .select("*")
    .single();
  if (error) throw new HttpError(500, error.message);
  return data as PlaylistRow;
}

export async function updatePlaylist(db: SupabaseClient, deviceId: string, id: string, input: Record<string, unknown>) {
  const { data, error } = await db
    .from("playlists")
    .update(input)
    .eq("id", id)
    .eq("device_id", deviceId)
    .select("*")
    .maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (!data) throw new HttpError(404, "Playlist not found");
  return data as PlaylistRow;
}

export async function deletePlaylist(db: SupabaseClient, deviceId: string, id: string) {
  const { error, count } = await db.from("playlists").delete({ count: "exact" }).eq("id", id).eq("device_id", deviceId);
  if (error) throw new HttpError(500, error.message);
  if (!count) throw new HttpError(404, "Playlist not found");
}
