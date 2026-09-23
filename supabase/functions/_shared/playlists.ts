import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
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

/** Validates a playlist payload from the portal. */
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
