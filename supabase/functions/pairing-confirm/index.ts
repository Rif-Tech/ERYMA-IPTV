// Confirms a pairing from the signed-in user's phone/browser (Supabase Auth JWT required).
//   GET  /pairing-confirm?code=|token=            → { kind, device: { type, name, model, platform }, expires_at }
//   POST /pairing-confirm { code?|token?, name?, playlist? } → { kind, device_id, playlist_id }
// All checks (device limit, ownership, single use) run inside the atomic SQL function confirm_pairing.

import { authenticateUser, mapSqlError, sha256Hex } from "../_shared/device.ts";
import { adminClient, HttpError, json, optionalString, readJson, serve } from "../_shared/http.ts";
import { validatePlaylistInput } from "../_shared/playlists.ts";

const CODE_RE = /^[A-Z0-9]{6}$/;

async function lookup(db: ReturnType<typeof adminClient>, codeRaw: unknown, tokenRaw: unknown) {
  const code = optionalString(codeRaw, 12)?.toUpperCase().replace(/[\s-]/g, "") ?? null;
  const token = optionalString(tokenRaw, 200);
  if (!code && !token) throw new HttpError(400, "code or token is required");
  if (code && !CODE_RE.test(code)) throw new HttpError(400, "Invalid code");
  const tokenHash = token ? await sha256Hex(token) : null;
  let q = db.from("pairing_sessions").select("id, kind, status, expires_at, device_id, devices(device_type, name, model, manufacturer, platform)");
  q = code ? q.eq("code", code) : q.eq("token_hash", tokenHash!);
  const { data, error } = await q.eq("status", "pending").order("created_at", { ascending: false }).limit(1).maybeSingle();
  if (error) throw new HttpError(500, error.message);
  if (!data) throw new HttpError(404, "PAIRING_NOT_FOUND");
  if (new Date(String(data.expires_at)).getTime() < Date.now()) throw new HttpError(410, "PAIRING_EXPIRED");
  return { session: data, code, tokenHash };
}

serve(async (req) => {
  const db = adminClient();
  const user = await authenticateUser(db, req);

  if (req.method === "GET") {
    const url = new URL(req.url);
    const { session } = await lookup(db, url.searchParams.get("code"), url.searchParams.get("token"));
    return json({ kind: session.kind, expires_at: session.expires_at, device: session.devices });
  }
  if (req.method !== "POST") throw new HttpError(405, "Method not allowed");

  const body = await readJson(req);
  const { session, code, tokenHash } = await lookup(db, body.code, body.token);

  let payload: Record<string, unknown> | null = null;
  if (session.kind === "playlist") {
    const input = body.playlist;
    if (!input || typeof input !== "object") throw new HttpError(400, "playlist is required");
    payload = validatePlaylistInput(input as Record<string, unknown>);
  } else {
    payload = { name: optionalString(body.name, 60) };
  }

  const { data, error } = await db.rpc("confirm_pairing", {
    p_account: user.id,
    p_code: code,
    p_token_hash: tokenHash,
    p_payload: payload,
  });
  if (error) throw mapSqlError(error.message);
  console.log(`pairing ${session.kind} confirmed account=${user.id} device=${session.device_id}`);
  return json(data);
});
