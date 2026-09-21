// GET /app-info → flattened app_config (versions, status, apk link, message).

import { adminClient, HttpError, json, serve } from "../_shared/http.ts";

serve(async (req) => {
  if (req.method !== "GET") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const { data, error } = await db.from("app_config").select("key, value");
  if (error) throw new HttpError(500, error.message);
  const config: Record<string, unknown> = {};
  for (const row of data ?? []) config[row.key] = row.value;
  return json({
    app_status: config.app_status ?? "ok",
    message: config.message ?? null,
    min_version: config.min_version ?? null,
    latest_version: config.latest_version ?? null,
    apk_link: config.apk_link ?? null,
    trial_days: config.trial_days ?? 7,
  });
});
