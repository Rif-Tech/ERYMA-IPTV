import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { HttpError, normalizeMac, requireString } from "./http.ts";

export interface DeviceRow {
  id: string;
  mac: string;
  device_key: string;
  device_type: string;
  platform: string | null;
  app_version: string | null;
  trial_started_at: string;
  activated: boolean;
  activated_at: string | null;
  expires_at: string | null;
  last_seen_at: string;
  created_at: string;
}

export interface DeviceStatus {
  registered: boolean;
  activated: boolean;
  is_trial: boolean;
  expired: boolean;
  trial_ends_at: string | null;
  expires_at: string | null;
}

/** Looks up a device by MAC + key; constant-time key comparison. */
export async function authenticateDevice(
  db: SupabaseClient,
  macRaw: unknown,
  keyRaw: unknown,
): Promise<DeviceRow> {
  const mac = normalizeMac(macRaw);
  const key = requireString(keyRaw, "device_key", 64).toUpperCase();
  const { data, error } = await db.from("devices").select("*").eq("mac", mac).maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (!data || !safeEqual(String(data.device_key).toUpperCase(), key)) {
    throw new HttpError(401, "Unknown device or invalid key");
  }
  return data as DeviceRow;
}

export async function computeStatus(db: SupabaseClient, device: DeviceRow): Promise<DeviceStatus> {
  const { data, error } = await db.rpc("device_status", { d: device });
  if (error) throw new HttpError(500, error.message);
  return data as DeviceStatus;
}

export function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

// ---------------------------------------------------------------------------
// Portal session tokens: HMAC-SHA256 signed `{mac, exp}` payload.

const encoder = new TextEncoder();

async function hmacKey(): Promise<CryptoKey> {
  const secret = Deno.env.get("PORTAL_TOKEN_SECRET") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!secret) throw new HttpError(500, "PORTAL_TOKEN_SECRET is not configured");
  return crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, [
    "sign",
    "verify",
  ]);
}

function b64url(bytes: ArrayBuffer | Uint8Array): string {
  const arr = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  return btoa(String.fromCharCode(...arr)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function fromB64url(s: string): Uint8Array<ArrayBuffer> {
  const padded = s.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - (s.length % 4)) % 4);
  const bin = atob(padded);
  const out = new Uint8Array(new ArrayBuffer(bin.length));
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

export async function signPortalToken(mac: string, ttlSeconds = 60 * 60 * 24): Promise<string> {
  const payload = b64url(encoder.encode(JSON.stringify({ mac, exp: Math.floor(Date.now() / 1000) + ttlSeconds })));
  const sig = await crypto.subtle.sign("HMAC", await hmacKey(), encoder.encode(payload));
  return `${payload}.${b64url(sig)}`;
}

export async function verifyPortalToken(token: string): Promise<{ mac: string }> {
  const [payload, sig] = token.split(".");
  if (!payload || !sig) throw new HttpError(401, "Invalid token");
  const ok = await crypto.subtle.verify("HMAC", await hmacKey(), fromB64url(sig), encoder.encode(payload));
  if (!ok) throw new HttpError(401, "Invalid token");
  const data = JSON.parse(new TextDecoder().decode(fromB64url(payload))) as { mac: string; exp: number };
  if (!data.exp || data.exp < Math.floor(Date.now() / 1000)) throw new HttpError(401, "Token expired");
  return { mac: data.mac };
}

/** Resolves the device for a `Bearer <portal token>` request. */
export async function authenticatePortal(db: SupabaseClient, req: Request): Promise<DeviceRow> {
  const header = req.headers.get("x-portal-token") ?? req.headers.get("authorization") ?? "";
  const token = header.replace(/^Bearer\s+/i, "").trim();
  if (!token) throw new HttpError(401, "Missing token");
  const { mac } = await verifyPortalToken(token);
  const { data, error } = await db.from("devices").select("*").eq("mac", mac).maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (!data) throw new HttpError(401, "Unknown device");
  return data as DeviceRow;
}

/** Verifies a Supabase Auth JWT (`Authorization: Bearer`) and requires the admin role. */
export async function authenticateAdmin(db: SupabaseClient, req: Request): Promise<{ id: string }> {
  const token = (req.headers.get("x-admin-token") ?? req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!token) throw new HttpError(401, "Missing token");
  const { data: userData, error: userErr } = await db.auth.getUser(token);
  if (userErr || !userData.user) throw new HttpError(401, "Invalid session");
  const { data, error } = await db.from("profiles").select("role").eq("id", userData.user.id).maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (data?.role !== "admin") throw new HttpError(403, "Admin only");
  return { id: userData.user.id };
}

/** Accepts either a device (`mac`/`key` query params) or an admin session. */
export async function authenticateDeviceOrAdmin(db: SupabaseClient, req: Request): Promise<void> {
  const url = new URL(req.url);
  if (url.searchParams.get("mac")) {
    await authenticateDevice(db, url.searchParams.get("mac"), url.searchParams.get("key"));
    return;
  }
  await authenticateAdmin(db, req);
}
