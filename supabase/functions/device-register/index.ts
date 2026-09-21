// POST /device-register  { mac, device_key, device_type, platform, app_version }
// Registers (or refreshes) a device and returns its trial/activation status.

import { computeStatus, type DeviceRow, safeEqual } from "../_shared/device.ts";
import { adminClient, HttpError, json, normalizeMac, optionalString, readJson, requireString, serve } from "../_shared/http.ts";

serve(async (req) => {
  if (req.method !== "POST") throw new HttpError(405, "Method not allowed");
  const body = await readJson(req);
  const mac = normalizeMac(body.mac);
  const key = requireString(body.device_key, "device_key", 64).toUpperCase();
  const deviceType = ["mobile", "tablet", "tv"].includes(String(body.device_type)) ? String(body.device_type) : "mobile";
  const platform = optionalString(body.platform, 40);
  const appVersion = optionalString(body.app_version, 40);

  const db = adminClient();
  const { data: existing, error } = await db.from("devices").select("*").eq("mac", mac).maybeSingle();
  if (error) throw new HttpError(500, error.message);

  let device: DeviceRow;
  if (existing) {
    // The key is bound to the MAC at first registration; a mismatch means another install/clone.
    if (!safeEqual(String(existing.device_key).toUpperCase(), key)) {
      throw new HttpError(409, "This MAC address is already registered with a different device key");
    }
    const { data, error: updErr } = await db
      .from("devices")
      .update({ device_type: deviceType, platform, app_version: appVersion, last_seen_at: new Date().toISOString() })
      .eq("id", existing.id)
      .select("*")
      .single();
    if (updErr) throw new HttpError(500, updErr.message);
    device = data as DeviceRow;
  } else {
    const { data, error: insErr } = await db
      .from("devices")
      .insert({ mac, device_key: key, device_type: deviceType, platform, app_version: appVersion })
      .select("*")
      .single();
    if (insErr) throw new HttpError(500, insErr.message);
    device = data as DeviceRow;
  }

  const status = await computeStatus(db, device);
  return json({ ...status, device: { mac: device.mac, device_type: device.device_type, created_at: device.created_at } });
});
