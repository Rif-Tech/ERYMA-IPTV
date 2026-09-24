// POST /device-logs { items: [{ level, category, message, context?, client_id?, created_at? }] }
// Auth: install headers (x-device-id/x-device-secret).
// Diagnostic logs for troubleshooting a specific device/account, retained 48h (purge_app_logs).
// Never send a playlist URL, username, password or PIN here — the panel proxy strips them, but
// callers must not rely on that: pass a category/message that is already safe to store.

import { authenticateAny } from "../_shared/device.ts";
import { adminClient, HttpError, json, optionalString, readJson, serve } from "../_shared/http.ts";

const LEVELS = new Set(["debug", "info", "warn", "error"]);
const MAX_ITEMS = 500;

serve(async (req) => {
  if (req.method !== "POST" && req.method !== "PUT") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const body = await readJson(req);
  const { device } = await authenticateAny(db, req, body);

  const items = Array.isArray(body.items) ? body.items.slice(0, MAX_ITEMS) : [];
  const rows = [];
  for (const raw of items as Record<string, unknown>[]) {
    const level = String(raw.level ?? "");
    if (!LEVELS.has(level)) continue;
    const category = optionalString(raw.category, 100) ?? "app";
    const message = optionalString(raw.message, 2000);
    if (!message) continue;
    // Free-form but bounded: a decoder/mpv error or an HTTP status code, not a whole stack dump.
    const context = raw.context && typeof raw.context === "object" ? raw.context : null;
    // An invalid date must not fail the whole batch (see device-progress's known RangeError pitfall).
    let createdAt = new Date();
    if (raw.created_at) {
      const parsed = new Date(String(raw.created_at));
      if (!Number.isNaN(parsed.getTime())) createdAt = parsed;
    }
    rows.push({
      device_id: device.id,
      account_id: device.account_id,
      level,
      category,
      message,
      context,
      client_id: optionalString(raw.client_id, 64),
      created_at: createdAt.toISOString(),
    });
  }
  if (rows.length === 0) return json({ ok: true, inserted: 0 });

  // ignoreDuplicates + the partial unique index on client_id makes a retried batch a no-op instead
  // of duplicating rows; entries without a client_id always insert (NULLs never conflict).
  const { error } = await db.from("app_logs").upsert(rows, { onConflict: "client_id", ignoreDuplicates: true });
  if (error) throw new HttpError(500, error.message);

  // Opportunistic retention: roughly 1 in 20 calls purges rows older than 48h (higher volume than
  // watch_events, hence a higher purge probability).
  if (Math.random() < 0.05) await db.rpc("purge_app_logs");

  return json({ ok: true, inserted: rows.length });
});
