// Starts a pairing session for an installation (TV, phone, tablet).
//   POST /pairing-create
//     { kind: "device" | "playlist", device_uuid, secret_hash?, device_type, platform, app_version,
//       manufacturer?, model?, os?, os_version?, name?,
//       device_secret? (required when the install is already paired),
//       mac?, device_key? (legacy install: its row and playlists are reused) }
//   → { session_id, code, token, expires_at, url }
// The QR encodes `url` (a temporary single-use token); the secret itself never leaves the device.

import {
  authenticateDevice,
  DEVICE_UUID_RE,
  type DeviceRow,
  randomCode,
  randomToken,
  readInstallCredentials,
  safeEqual,
  sha256Hex,
} from "../_shared/device.ts";
import { adminClient, HttpError, json, optionalString, readJson, requireString, serve } from "../_shared/http.ts";

const SESSION_TTL_MS = 10 * 60 * 1000;

serve(async (req) => {
  if (req.method !== "POST") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const body = await readJson(req);

  const kind = body.kind === "playlist" ? "playlist" : "device";
  const uuid = requireString(body.device_uuid, "device_uuid", 64).toLowerCase();
  if (!DEVICE_UUID_RE.test(uuid)) throw new HttpError(400, "Invalid device_uuid");
  const secretHash = optionalString(body.secret_hash, 128);
  if (kind === "device" && !secretHash) throw new HttpError(400, "secret_hash is required");

  const deviceType = ["mobile", "tablet", "tv"].includes(String(body.device_type)) ? String(body.device_type) : "mobile";
  const meta = {
    device_type: deviceType,
    platform: optionalString(body.platform, 40),
    app_version: optionalString(body.app_version, 40),
    manufacturer: optionalString(body.manufacturer, 80),
    model: optionalString(body.model, 80),
    os: optionalString(body.os, 40),
    os_version: optionalString(body.os_version, 40),
    last_seen_at: new Date().toISOString(),
  };

  // Opportunistic housekeeping: codes must not linger past their expiry.
  await db.rpc("expire_pairing_sessions");

  const { data: found, error } = await db.from("devices").select("*").eq("device_uuid", uuid).maybeSingle();
  if (error) throw new HttpError(500, error.message);
  let device = found as DeviceRow | null;

  if (!device && body.mac && (body.device_key ?? body.key)) {
    // Legacy install upgrading: keep its row so its playlists follow it into the account.
    try {
      const legacy = await authenticateDevice(db, body.mac, body.device_key ?? body.key);
      if (!legacy.device_uuid) device = legacy;
    } catch {
      // Unknown or mismatched MAC: start fresh below.
    }
  }

  if (device) {
    // A paired install must prove it is the same device before it can be re-paired or add playlists.
    const paired = device.account_id && device.status === "active" && device.secret_hash;
    if (paired) {
      // The app sends the secret as `x-device-secret`; the body field is kept for older clients.
      const secret = readInstallCredentials(req, body)?.secret ?? optionalString(body.device_secret, 200);
      if (!secret || !safeEqual(device.secret_hash!, await sha256Hex(secret))) {
        throw new HttpError(401, kind === "playlist" ? "UNPAIRED" : "Device secret required to re-pair");
      }
    } else if (kind === "playlist") {
      throw new HttpError(401, "UNPAIRED");
    }
    const { error: e } = await db.from("devices").update({ ...meta, device_uuid: uuid }).eq("id", device.id);
    if (e) throw new HttpError(500, e.message);
  } else {
    const { data, error: e } = await db
      .from("devices")
      .insert({ ...meta, device_uuid: uuid, name: optionalString(body.name, 60) })
      .select("*")
      .single();
    if (e) throw new HttpError(500, e.message);
    device = data as DeviceRow;
  }

  // One live session per device and kind.
  await db.from("pairing_sessions").update({ status: "cancelled" }).eq("device_id", device.id).eq("kind", kind).eq("status", "pending");

  const token = randomToken();
  const tokenHash = await sha256Hex(token);
  const expiresAt = new Date(Date.now() + SESSION_TTL_MS).toISOString();
  let session: { id: string; code: string } | null = null;
  for (let attempt = 0; attempt < 5 && !session; attempt++) {
    const code = randomCode();
    const { data, error: e } = await db
      .from("pairing_sessions")
      .insert({ kind, device_id: device.id, code, token_hash: tokenHash, secret_hash: kind === "device" ? secretHash : null, expires_at: expiresAt })
      .select("id, code")
      .single();
    if (!e) session = data as { id: string; code: string };
    else if (!/duplicate key|unique/i.test(e.message)) throw new HttpError(500, e.message);
  }
  if (!session) throw new HttpError(500, "Could not allocate a pairing code");

  // Public portal URL: admin config first (editable without redeploy), env secret as fallback.
  const { data: cfg } = await db.from("app_config").select("value").eq("key", "portal_url").maybeSingle();
  const configured = typeof cfg?.value === "string" ? cfg.value : "";
  const portal = (configured || Deno.env.get("PORTAL_URL") || "").trim().replace(/\/$/, "");
  const path = kind === "device" ? "/activate" : "/add-playlist";
  console.log(`pairing ${kind} created device=${device.id} session=${session.id}`);
  return json({
    session_id: session.id,
    code: session.code,
    token,
    expires_at: expiresAt,
    url: portal ? `${portal}${path}?token=${encodeURIComponent(token)}` : null,
  }, 201);
});
