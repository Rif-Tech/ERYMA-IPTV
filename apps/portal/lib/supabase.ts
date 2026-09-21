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

export async function requireAdmin() {
  const supabase = await createSupabaseServer();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { supabase, user: null, isAdmin: false };
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).maybeSingle();
  return { supabase, user, isAdmin: profile?.role === "admin" };
}
