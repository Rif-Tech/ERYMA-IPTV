// Polled by the installation while its code is on screen.
//   GET /pairing-status?session_id=&token= → { status, kind, expires_at, result? }
// The token is the one returned by pairing-create; a stolen session id alone reveals nothing.

import { sha256Hex } from "../_shared/device.ts";
import { adminClient, HttpError, json, requireString, safeEqualStr, serve } from "../_shared/http.ts";

serve(async (req) => {
  if (req.method !== "GET") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const url = new URL(req.url);
  const id = requireString(url.searchParams.get("session_id"), "session_id", 64);
  const token = requireString(url.searchParams.get("token"), "token", 200);

  const { data, error } = await db
    .from("pairing_sessions")
    .select("id, kind, status, expires_at, token_hash, result")
    .eq("id", id)
    .maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (!data || !safeEqualStr(String(data.token_hash), await sha256Hex(token))) throw new HttpError(404, "PAIRING_NOT_FOUND");

  let status = String(data.status);
  if (status === "pending" && new Date(String(data.expires_at)).getTime() < Date.now()) {
    status = "expired";
    await db.from("pairing_sessions").update({ status }).eq("id", id).eq("status", "pending");
  }
  return json({ status, kind: data.kind, expires_at: data.expires_at, result: status === "confirmed" ? data.result : null });
});
