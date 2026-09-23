import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { HttpError } from "./http.ts";

export interface DeviceRow {
  id: string;
  device_type: string;
  platform: string | null;
  app_version: string | null;
  last_seen_at: string;
  created_at: string;
  note: string | null;
  account_id: string | null;
  device_uuid: string | null;
  secret_hash: string | null;
  name: string | null;
  manufacturer: string | null;
  model: string | null;
  os: string | null;
  os_version: string | null;
  status: "active" | "revoked";
  revoked_at: string | null;
  active_profile_id: string | null;
  active_playlist_id: string | null;
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

/** Requires the install identity headers; any other request is anonymous and rejected. */
export async function authenticateAny(
  db: SupabaseClient,
  req: Request,
  body?: Record<string, unknown>,
): Promise<{ device: DeviceRow }> {
  const install = readInstallCredentials(req, body);
  if (!install) throw new HttpError(401, "UNPAIRED");
  return { device: await authenticateInstall(db, install.uuid, install.secret) };
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

export function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function b64url(bytes: ArrayBuffer | Uint8Array): string {
  const arr = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  return btoa(String.fromCharCode(...arr)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
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

/** Accepts a paired install (headers) or an admin session. */
export async function authenticateDeviceOrAdmin(db: SupabaseClient, req: Request): Promise<void> {
  if (readInstallCredentials(req)) {
    await authenticateAny(db, req);
    return;
  }
  await authenticateAdmin(db, req);
}
