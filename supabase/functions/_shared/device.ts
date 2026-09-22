import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { HttpError, normalizeMac, requireString } from "./http.ts";

export interface DeviceRow {
  id: string;
  mac: string | null;
  device_key: string | null;
  device_type: string;
  platform: string | null;
  app_version: string | null;
  trial_started_at: string;
  activated: boolean;
  activated_at: string | null;
  expires_at: string | null;
  last_seen_at: string;
  created_at: string;
  // Account model
  account_id: string | null;
  device_uuid: string | null;
  secret_hash: string | null;
  name: string | null;
  manufacturer: string | null;
  model: string | null;
  os: string | null;
  os_version: string | null;
  status: "active" | "revoked";
  active_profile_id: string | null;
  active_playlist_id: string | null;
}

export interface DeviceStatus {
  registered: boolean;
  activated: boolean;
  is_trial: boolean;
  expired: boolean;
  trial_ends_at: string | null;
  expires_at: string | null;
}

export interface AccountStatus {
  plan: string;
  plan_name: string;
  max_devices: number;
  max_profiles: number;
  max_playlists: number;
  activated: boolean;
  is_trial: boolean;
  expired: boolean;
  trial_ends_at: string | null;
  expires_at: string | null;
}

const encoder = new TextEncoder();

export async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(input));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

// No 0/O/1/I/L: the code is read from a TV screen and typed on a phone.
const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

export function randomCode(length = 6): string {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  return Array.from(bytes).map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join("");
}

export function randomToken(bytes = 32): string {
  return b64url(crypto.getRandomValues(new Uint8Array(bytes)));
}

export const DEVICE_UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Install identity: `x-device-id` + `x-device-secret` headers (or body/query fallbacks). */
export function readInstallCredentials(req: Request, body?: Record<string, unknown>): { uuid: string; secret: string } | null {
  const url = new URL(req.url);
  const uuid = req.headers.get("x-device-id") ?? (body?.device_uuid as string | undefined) ?? url.searchParams.get("device_uuid");
  const secret = req.headers.get("x-device-secret") ?? (body?.device_secret as string | undefined) ?? url.searchParams.get("device_secret");
  if (!uuid || !secret) return null;
  return { uuid: String(uuid).toLowerCase(), secret: String(secret) };
}

/** Authenticates a paired installation; revoked or unpaired devices get 401 with code UNPAIRED. */
export async function authenticateInstall(db: SupabaseClient, uuid: string, secret: string): Promise<DeviceRow> {
  if (!DEVICE_UUID_RE.test(uuid)) throw new HttpError(400, "Invalid device id");
  const { data, error } = await db.from("devices").select("*").eq("device_uuid", uuid).maybeSingle();
  if (error) throw new HttpError(500, error.message);
  const row = data as DeviceRow | null;
  if (!row || !row.secret_hash || !safeEqual(row.secret_hash, await sha256Hex(secret))) {
    throw new HttpError(401, "UNPAIRED");
  }
  if (row.status !== "active" || !row.account_id) throw new HttpError(401, "UNPAIRED");
  return row;
}

/** Install credentials first, legacy MAC + key otherwise. */
export async function authenticateAny(
  db: SupabaseClient,
  req: Request,
  body?: Record<string, unknown>,
): Promise<{ device: DeviceRow; legacy: boolean }> {
  const install = readInstallCredentials(req, body);
  if (install) return { device: await authenticateInstall(db, install.uuid, install.secret), legacy: false };
  const url = new URL(req.url);
  const mac = body?.mac ?? url.searchParams.get("mac");
  const key = body?.key ?? body?.device_key ?? url.searchParams.get("key");
  if (!mac) throw new HttpError(401, "Missing device credentials");
  return { device: await authenticateDevice(db, mac, key), legacy: true };
}

/** Verifies a Supabase Auth JWT for any signed-in user and makes sure the account tree exists. */
export async function authenticateUser(db: SupabaseClient, req: Request): Promise<{ id: string; email: string | null }> {
  const token = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!token) throw new HttpError(401, "Missing session");
  const { data, error } = await db.auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, "Invalid session");
  const { error: e } = await db.rpc("ensure_account", { p_user: data.user.id });
  if (e) throw new HttpError(500, e.message);
  return { id: data.user.id, email: data.user.email ?? null };
}

export async function computeAccountStatus(db: SupabaseClient, accountId: string): Promise<AccountStatus> {
  const { data: acc, error } = await db.from("accounts").select("*").eq("id", accountId).maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (!acc) throw new HttpError(404, "Account not found");
  const { data, error: e } = await db.rpc("account_status", { a: acc });
  if (e) throw new HttpError(500, e.message);
  return data as AccountStatus;
}

/** Maps the RAISE EXCEPTION messages of the SQL pairing/context functions to HTTP errors. */
export function mapSqlError(message: string): HttpError {
  const code = message.replace(/^.*?([A-Z_]{6,}).*$/s, "$1");
  const table: Record<string, [number, string]> = {
    PAIRING_NOT_FOUND: [404, "PAIRING_NOT_FOUND"],
    PAIRING_EXPIRED: [410, "PAIRING_EXPIRED"],
    DEVICE_LIMIT: [409, "DEVICE_LIMIT"],
    PLAYLIST_LIMIT: [409, "PLAYLIST_LIMIT"],
    ACCOUNT_EXPIRED: [402, "ACCOUNT_EXPIRED"],
    DEVICE_NOT_OWNED: [403, "DEVICE_NOT_OWNED"],
    DEVICE_NOT_PAIRED: [401, "UNPAIRED"],
    PROFILE_NOT_OWNED: [403, "PROFILE_NOT_OWNED"],
    PROFILE_HAS_NO_ACCESS: [403, "PROFILE_HAS_NO_ACCESS"],
    PROFILE_REQUIRED: [400, "PROFILE_REQUIRED"],
    PAYLOAD_REQUIRED: [400, "PAYLOAD_REQUIRED"],
  };
  const hit = table[code];
  return hit ? new HttpError(hit[0], hit[1]) : new HttpError(500, message);
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

/** Accepts a paired install, a legacy device (`mac`/`key` query params) or an admin session. */
export async function authenticateDeviceOrAdmin(db: SupabaseClient, req: Request): Promise<void> {
  const url = new URL(req.url);
  if (readInstallCredentials(req) || url.searchParams.get("mac")) {
    await authenticateAny(db, req);
    return;
  }
  await authenticateAdmin(db, req);
}
