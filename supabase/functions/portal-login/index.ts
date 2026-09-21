// POST /portal-login { mac, device_key } → { token, device, status }
// Issues a short-lived session token for the web portal.

import { authenticateDevice, computeStatus, signPortalToken } from "../_shared/device.ts";
import { adminClient, HttpError, json, readJson, serve } from "../_shared/http.ts";

serve(async (req) => {
  if (req.method !== "POST") throw new HttpError(405, "Method not allowed");
  const body = await readJson(req);
  const db = adminClient();
  const device = await authenticateDevice(db, body.mac, body.device_key ?? body.key);
  const status = await computeStatus(db, device);
  const token = await signPortalToken(device.mac);
  return json({
    token,
    status,
    device: {
      mac: device.mac,
      device_type: device.device_type,
      platform: device.platform,
      app_version: device.app_version,
      created_at: device.created_at,
      last_seen_at: device.last_seen_at,
    },
  });
});
