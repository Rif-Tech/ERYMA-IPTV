"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { requireUser } from "@/lib/supabase";
import type { ActionState } from "@/lib/types";

async function owner() {
  const ctx = await requireUser();
  if (!ctx.user) redirect("/login?next=/account");
  return { supabase: ctx.supabase, user: ctx.user };
}

/** Plan limits for the signed-in account (RLS lets a user read only their own overview row). */
async function limits(supabase: Awaited<ReturnType<typeof owner>>["supabase"], userId: string): Promise<{ max_profiles: number; max_playlists: number }> {
  const { data } = await supabase.from("accounts_overview").select("status").eq("id", userId).maybeSingle();
  const s = (data?.status ?? {}) as { max_profiles?: number; max_playlists?: number };
  return { max_profiles: s.max_profiles ?? 5, max_playlists: s.max_playlists ?? 20 };
}

// ---- Devices ---------------------------------------------------------------

export async function renameDeviceAction(form: FormData): Promise<void> {
  const { supabase } = await owner();
  const name = String(form.get("name") ?? "").trim().slice(0, 60);
  const { error } = await supabase.from("devices").update({ name: name || null }).eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/account");
}

/** Revoking keeps the row (history, name) but the install must pair again to regain access. */
export async function revokeDeviceAction(form: FormData): Promise<void> {
  const { supabase } = await owner();
  const { error } = await supabase
    .from("devices")
    .update({ status: "revoked", revoked_at: new Date().toISOString(), secret_hash: null, active_profile_id: null, active_playlist_id: null })
    .eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/account");
}

export async function deleteDeviceAction(form: FormData): Promise<void> {
  const { supabase } = await owner();
  const { error } = await supabase.from("devices").delete().eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/account");
}

// ---- Profiles --------------------------------------------------------------

export async function saveProfileAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const { supabase, user } = await owner();
  const id = String(form.get("id") ?? "");
  const name = String(form.get("name") ?? "").trim();
  if (!name || name.length > 40) return { error: "Le nom doit contenir entre 1 et 40 caractères." };
  const avatar = String(form.get("avatar") ?? "blue");
  const isKids = form.get("is_kids") === "on";
  const playlistIds = form.getAll("playlist_ids").map(String);

  let profileId = id;
  if (id) {
    const { error } = await supabase.from("viewer_profiles").update({ name, avatar, is_kids: isKids }).eq("id", id);
    if (error) return { error: error.message };
  } else {
    const { count } = await supabase.from("viewer_profiles").select("id", { count: "exact", head: true }).eq("account_id", user.id);
    const max = (await limits(supabase, user.id)).max_profiles;
    if ((count ?? 0) >= max) return { error: `Votre plan permet ${max} profils au maximum.` };
    const { data, error } = await supabase
      .from("viewer_profiles")
      .insert({ account_id: user.id, name, avatar, is_kids: isKids, position: count ?? 0 })
      .select("id")
      .single();
    if (error) return { error: error.message };
    profileId = data.id as string;
  }

  // Replace the access list with what was ticked.
  const { error: delErr } = await supabase.from("profile_playlists").delete().eq("profile_id", profileId);
  if (delErr) return { error: delErr.message };
  if (playlistIds.length) {
    const { error } = await supabase.from("profile_playlists").insert(playlistIds.map((playlist_id) => ({ profile_id: profileId, playlist_id })));
    if (error) return { error: error.message };
  }
  revalidatePath("/account/profiles");
  return { ok: true };
}

export async function deleteProfileAction(form: FormData): Promise<void> {
  const { supabase, user } = await owner();
  const { count } = await supabase.from("viewer_profiles").select("id", { count: "exact", head: true }).eq("account_id", user.id);
  // The last profile is what every device falls back to; keep at least one.
  if ((count ?? 0) <= 1) return;
  const { error } = await supabase.from("viewer_profiles").delete().eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/account/profiles");
}

// ---- Playlists ---------------------------------------------------------------

function playlistInput(form: FormData): { error?: string; values?: Record<string, unknown> } {
  const name = String(form.get("name") ?? "").trim();
  const type = String(form.get("type") ?? "m3u");
  const url = String(form.get("url") ?? "").trim();
  const username = String(form.get("username") ?? "").trim() || null;
  const password = String(form.get("password") ?? "").trim() || null;
  const isProtected = form.get("is_protected") === "on";
  const pin = String(form.get("pin_code") ?? "").trim() || null;
  if (!name || name.length > 120) return { error: "Le nom est obligatoire (120 caractères max)." };
  if (type !== "m3u" && type !== "xtream") return { error: "Type invalide." };
  if (!/^https?:\/\//i.test(url)) return { error: "L'URL doit commencer par http:// ou https://." };
  if (type === "xtream" && (!username || !password)) return { error: "Identifiant et mot de passe sont requis pour Xtream." };
  if (isProtected && !(pin && /^\d{4,8}$/.test(pin))) return { error: "Le code PIN doit contenir 4 à 8 chiffres." };
  const expires = String(form.get("expires_at") ?? "").trim();
  return {
    values: {
      name,
      type,
      url,
      username: type === "xtream" ? username : null,
      password: type === "xtream" ? password : null,
      epg_url: String(form.get("epg_url") ?? "").trim() || null,
      is_protected: isProtected,
      pin_code: isProtected ? pin : null,
      expires_at: expires ? new Date(expires).toISOString() : null,
    },
  };
}

export async function createPlaylistAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const { supabase, user } = await owner();
  const parsed = playlistInput(form);
  if (parsed.error) return { error: parsed.error };
  const { data: existing } = await supabase.from("playlists").select("position").eq("account_id", user.id);
  const max = (await limits(supabase, user.id)).max_playlists;
  if ((existing?.length ?? 0) >= max) return { error: `Votre plan permet ${max} listes de lecture au maximum.` };
  const position = existing?.length ? Math.max(...existing.map((p) => p.position as number)) + 1 : 0;
  const { data, error } = await supabase
    .from("playlists")
    .insert({ ...parsed.values, account_id: user.id, position })
    .select("id")
    .single();
  if (error) return { error: error.message };
  // New playlists are visible to every profile; the owner restricts access afterwards.
  const { data: profiles } = await supabase.from("viewer_profiles").select("id").eq("account_id", user.id);
  if (profiles?.length) {
    await supabase.from("profile_playlists").insert(profiles.map((p) => ({ profile_id: p.id, playlist_id: data.id })));
  }
  revalidatePath("/account/playlists");
  return { ok: true };
}

export async function updatePlaylistAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const { supabase } = await owner();
  const parsed = playlistInput(form);
  if (parsed.error) return { error: parsed.error };
  const { error } = await supabase.from("playlists").update(parsed.values!).eq("id", String(form.get("id")));
  if (error) return { error: error.message };
  revalidatePath("/account/playlists");
  return { ok: true };
}

export async function deletePlaylistAction(form: FormData): Promise<void> {
  const { supabase } = await owner();
  const { error } = await supabase.from("playlists").delete().eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/account/playlists");
}

export async function movePlaylistAction(form: FormData): Promise<void> {
  const { supabase, user } = await owner();
  const id = String(form.get("id"));
  const dir = String(form.get("dir")) === "up" ? -1 : 1;
  const { data } = await supabase.from("playlists").select("id, position").eq("account_id", user.id).order("position").order("created_at");
  const rows = (data ?? []) as { id: string; position: number }[];
  const i = rows.findIndex((r) => r.id === id);
  const j = i + dir;
  if (i < 0 || j < 0 || j >= rows.length) return;
  const order = rows.map((r) => r.id);
  [order[i], order[j]] = [order[j], order[i]];
  for (const [pos, rowId] of order.entries()) {
    await supabase.from("playlists").update({ position: pos }).eq("id", rowId);
  }
  revalidatePath("/account/playlists");
}
