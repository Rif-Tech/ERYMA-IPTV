"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createSupabaseServer, requireAdmin } from "@/lib/supabase";
import type { ActionState } from "../manage-playlists/actions";

export async function adminLoginAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await createSupabaseServer();
  const { error } = await supabase.auth.signInWithPassword({
    email: String(form.get("email") ?? ""),
    password: String(form.get("password") ?? ""),
  });
  if (error) return { error: "Identifiants invalides." };
  redirect("/admin");
}

export async function adminLogoutAction(): Promise<void> {
  const supabase = await createSupabaseServer();
  await supabase.auth.signOut();
  redirect("/admin/login");
}

async function admin() {
  const ctx = await requireAdmin();
  if (!ctx.isAdmin) redirect("/admin/login");
  return ctx.supabase;
}

export async function setActivationAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const id = String(form.get("id"));
  const mode = String(form.get("mode"));
  const expires = String(form.get("expires_at") ?? "").trim();
  const patch =
    mode === "deactivate"
      ? { activated: false, activated_at: null, expires_at: null }
      : { activated: true, activated_at: new Date().toISOString(), expires_at: expires ? new Date(expires).toISOString() : null };
  const { error } = await supabase.from("devices").update(patch).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(`/admin/devices/${id}`);
  revalidatePath("/admin");
}

export async function extendTrialAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const id = String(form.get("id"));
  // Restarting the trial clock is the simplest way to grant more days.
  const { error } = await supabase.from("devices").update({ trial_started_at: new Date().toISOString() }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(`/admin/devices/${id}`);
}

export async function saveNoteAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const id = String(form.get("id"));
  const { error } = await supabase.from("devices").update({ note: String(form.get("note") ?? "").slice(0, 500) }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(`/admin/devices/${id}`);
}

export async function deleteDeviceAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const { error } = await supabase.from("devices").delete().eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  redirect("/admin");
}

export async function deletePlaylistAdminAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const deviceId = String(form.get("device_id"));
  const { error } = await supabase.from("playlists").delete().eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath(`/admin/devices/${deviceId}`);
}

/** Empty → null (fallback to the PORTAL_URL secret); invalid → false. */
function normalizePortalUrl(raw: string): string | null | false {
  const s = raw.trim().replace(/\/+$/, "");
  if (!s) return null;
  try {
    const u = new URL(s);
    if (u.protocol !== "http:" && u.protocol !== "https:") return false;
    return s;
  } catch {
    return false;
  }
}

export async function saveConfigAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await admin();
  const entries: Record<string, unknown> = {
    app_status: String(form.get("app_status") ?? "ok"),
    message: String(form.get("message") ?? "").trim() || null,
    min_version: String(form.get("min_version") ?? "").trim() || null,
    latest_version: String(form.get("latest_version") ?? "").trim() || null,
    apk_link: String(form.get("apk_link") ?? "").trim() || null,
    portal_url: normalizePortalUrl(String(form.get("portal_url") ?? "")),
    trial_days: Math.max(0, Number(form.get("trial_days") ?? 7) || 0),
  };
  if (entries.portal_url === false) return { error: "L'URL du portail doit commencer par http:// ou https://." };
  for (const [key, value] of Object.entries(entries)) {
    const { error } = await supabase.from("app_config").upsert({ key, value, updated_at: new Date().toISOString() });
    if (error) return { error: error.message };
  }
  revalidatePath("/admin/config");
  return { ok: true };
}
