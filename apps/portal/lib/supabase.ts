import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

/** Supabase client for the admin area (Supabase Auth session stored in cookies). */
export async function createSupabaseServer() {
  const store = await cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL ?? "http://127.0.0.1:54321",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "",
    {
      cookies: {
        getAll: () => store.getAll(),
        setAll: (all) => {
          try {
            for (const { name, value, options } of all) store.set(name, value, options);
          } catch {
            // Called from a Server Component: cookies are refreshed by the proxy instead.
          }
        },
      },
    },
  );
}

export type SessionUser = { id: string; email: string | null };

/** Current user from the session JWT, verified locally (no Auth round-trip per request). */
export async function currentUser(supabase: Awaited<ReturnType<typeof createSupabaseServer>>): Promise<SessionUser | null> {
  const { data, error } = await supabase.auth.getClaims();
  const claims = data?.claims;
  if (error || !claims?.sub) return null;
  return { id: String(claims.sub), email: typeof claims.email === "string" ? claims.email : null };
}

export async function requireAdmin() {
  const supabase = await createSupabaseServer();
  const user = await currentUser(supabase);
  if (!user) return { supabase, user: null, isAdmin: false };
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).maybeSingle();
  return { supabase, user, isAdmin: profile?.role === "admin" };
}

/** Signed-in end user (any role). */
export async function requireUser() {
  const supabase = await createSupabaseServer();
  const user = await currentUser(supabase);
  return { supabase, user };
}

export function functionsUrl(): string {
  const explicit = process.env.SUPABASE_FUNCTIONS_URL;
  if (explicit) return explicit.replace(/\/$/, "");
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "http://127.0.0.1:54321";
  return `${base.replace(/\/$/, "")}/functions/v1`;
}

export class FunctionError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

/** Calls an Edge Function with the current user's Supabase session (pairing confirmation…). */
export async function callAsUser<T>(path: string, init: RequestInit = {}): Promise<T> {
  const supabase = await createSupabaseServer();
  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;
  if (!token) throw new FunctionError(401, "Session expirée.");
  const res = await fetch(`${functionsUrl()}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "",
      Authorization: `Bearer ${token}`,
      ...(init.headers as Record<string, string> | undefined),
    },
    cache: "no-store",
  });
  const text = await res.text();
  const body = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  if (!res.ok) throw new FunctionError(res.status, String(body.error ?? res.statusText));
  return body as T;
}
