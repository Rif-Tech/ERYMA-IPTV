// GET /app-info → flattened app_config (versions, status, apk link, message, portal URL) plus the
// admin-managed DNS server presets used to bypass ISP DNS restrictions.

import { adminClient, HttpError, json, serve } from "../_shared/http.ts";

serve(async (req) => {
  if (req.method !== "GET") throw new HttpError(405, "Method not allowed");
  const db = adminClient();
  const { data, error } = await db.from("app_config").select("key, value");
  if (error) throw new HttpError(500, error.message);
  const config: Record<string, unknown> = {};
  for (const row of data ?? []) config[row.key] = row.value;
  const portal = (typeof config.portal_url === "string" && config.portal_url) || Deno.env.get("PORTAL_URL") || null;

  const { data: dnsRows, error: dnsError } = await db
    .from("dns_servers")
    .select("id, name, provider, ipv4, ipv6, doh_url, dot_host, is_default")
    .eq("enabled", true)
    .order("position", { ascending: true });
  if (dnsError) throw new HttpError(500, dnsError.message);

  return json({
    app_status: config.app_status ?? "ok",
    message: config.message ?? null,
    min_version: config.min_version ?? null,
    latest_version: config.latest_version ?? null,
    apk_link: config.apk_link ?? null,
    trial_days: config.trial_days ?? 7,
    portal_url: portal ? String(portal).trim().replace(/\/$/, "") : null,
    dns_servers: (dnsRows ?? []).map((r) => ({
      id: r.id,
      name: r.name,
      provider: r.provider,
      ipv4: r.ipv4 ?? [],
      ipv6: r.ipv6 ?? [],
      doh_url: r.doh_url,
      dot_host: r.dot_host,
      is_default: r.is_default,
    })),
  });
});
