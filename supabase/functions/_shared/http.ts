import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-portal-token, x-admin-token",
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
};

export class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Wraps a handler with CORS preflight + uniform error responses. */
export function serve(handler: (req: Request) => Promise<Response>): void {
  Deno.serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    try {
      return await handler(req);
    } catch (e) {
      if (e instanceof HttpError) return json({ error: e.message }, e.status);
      console.error(e);
      return json({ error: "Internal error" }, 500);
    }
  });
}

/** Service-role client: RLS is bypassed, so every function must authorize explicitly. */
export function adminClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) throw new HttpError(500, "Supabase environment is not configured");
  return createClient(url, key, { auth: { persistSession: false } });
}

export async function readJson<T = Record<string, unknown>>(req: Request): Promise<T> {
  try {
    const text = await req.text();
    return (text ? JSON.parse(text) : {}) as T;
  } catch {
    throw new HttpError(400, "Invalid JSON body");
  }
}

const MAC_RE = /^([0-9A-F]{2}:){5}[0-9A-F]{2}$/;

export function normalizeMac(raw: unknown): string {
  const mac = String(raw ?? "").trim().toUpperCase().replace(/-/g, ":");
  if (!MAC_RE.test(mac)) throw new HttpError(400, "Invalid MAC address");
  return mac;
}

export function requireString(value: unknown, name: string, max = 2048): string {
  const s = typeof value === "string" ? value.trim() : "";
  if (!s) throw new HttpError(400, `${name} is required`);
  if (s.length > max) throw new HttpError(400, `${name} is too long`);
  return s;
}

export function optionalString(value: unknown, max = 2048): string | null {
  if (value === undefined || value === null) return null;
  const s = String(value).trim();
  if (s.length > max) throw new HttpError(400, "Value is too long");
  return s || null;
}
