"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { api, ApiError, normalizeMac, type Playlist } from "@/lib/api";
import { clearPortalToken, getPortalToken, setPortalToken } from "@/lib/session";

export type ActionState = { error?: string; ok?: boolean };

export async function loginAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const mac = normalizeMac(String(form.get("mac") ?? ""));
  const key = String(form.get("key") ?? "").trim().toUpperCase();
  if (!mac || !key) return { error: "Adresse MAC et clé requises." };
  try {
    const { token } = await api.portalLogin(mac, key);
    await setPortalToken(token);
  } catch (e) {
    if (e instanceof ApiError && e.status === 401) return { error: "Appareil inconnu ou clé invalide." };
    return { error: e instanceof Error ? e.message : "Erreur inattendue." };
  }
  redirect("/manage-playlists");
}

export async function logoutAction(): Promise<void> {
  await clearPortalToken();
  redirect("/manage-playlists/login");
}

async function requireToken(): Promise<string> {
  const token = await getPortalToken();
  if (!token) redirect("/manage-playlists/login");
  return token;
}

function playlistInput(form: FormData) {
  const type = String(form.get("type") ?? "m3u") as "m3u" | "xtream";
  const isProtected = form.get("is_protected") === "on";
  const pin = String(form.get("pin_code") ?? "").trim();
  const expires = String(form.get("expires_at") ?? "").trim();
  return {
    name: String(form.get("name") ?? "").trim(),
    type,
    url: String(form.get("url") ?? "").trim(),
    username: type === "xtream" ? String(form.get("username") ?? "").trim() || null : null,
    password: type === "xtream" ? String(form.get("password") ?? "") || null : null,
    epg_url: type === "m3u" ? String(form.get("epg_url") ?? "").trim() || null : null,
    is_protected: isProtected,
    pin_code: isProtected ? pin || null : null,
    expires_at: expires ? new Date(expires).toISOString() : null,
  };
}

export async function createPlaylistAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const token = await requireToken();
  try {
    await api.createPlaylist(token, playlistInput(form));
  } catch (e) {
    return { error: e instanceof Error ? e.message : "Erreur inattendue." };
  }
  revalidatePath("/manage-playlists");
  return { ok: true };
}

export async function updatePlaylistAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const token = await requireToken();
  const id = String(form.get("id") ?? "");
  const pin = String(form.get("unlock_pin") ?? "") || undefined;
  try {
    await api.updatePlaylist(token, id, playlistInput(form), pin);
  } catch (e) {
    return { error: e instanceof Error ? e.message : "Erreur inattendue." };
  }
  revalidatePath("/manage-playlists");
  return { ok: true };
}

/** Returns the full playlist (credentials included) once the PIN is verified server-side. */
export async function revealPlaylistAction(id: string, pin: string): Promise<{ playlist?: Playlist; error?: string }> {
  const token = await requireToken();
  try {
    return { playlist: (await api.revealPlaylist(token, id, pin)).playlist };
  } catch (e) {
    if (e instanceof ApiError && e.status === 403) return { error: "Code PIN incorrect." };
    return { error: e instanceof Error ? e.message : "Erreur inattendue." };
  }
}

export async function deletePlaylistAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const token = await requireToken();
  const pin = String(form.get("pin") ?? "") || undefined;
  try {
    await api.deletePlaylist(token, String(form.get("id") ?? ""), pin);
  } catch (e) {
    if (e instanceof ApiError && e.status === 403) return { error: "Code PIN incorrect." };
    return { error: e instanceof Error ? e.message : "Erreur inattendue." };
  }
  revalidatePath("/manage-playlists");
  return { ok: true };
}

export async function movePlaylistAction(form: FormData): Promise<void> {
  const token = await requireToken();
  const id = String(form.get("id") ?? "");
  const direction = String(form.get("direction") ?? "up");
  const { playlists } = await api.playlists(token);
  const ids = playlists.map((p) => p.id);
  const i = ids.indexOf(id);
  const j = direction === "up" ? i - 1 : i + 1;
  if (i < 0 || j < 0 || j >= ids.length) return;
  [ids[i], ids[j]] = [ids[j], ids[i]];
  await api.reorderPlaylists(token, ids);
  revalidatePath("/manage-playlists");
}
