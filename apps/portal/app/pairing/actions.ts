"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { callAsUser, FunctionError, requireUser } from "@/lib/supabase";
import type { ActionState } from "../manage-playlists/actions";

export interface PairingPreview {
  kind: "device" | "playlist";
  expires_at: string;
  device: { device_type: string; name: string | null; model: string | null; manufacturer: string | null; platform: string | null } | null;
}

const pairingErrors: Record<string, string> = {
  PAIRING_NOT_FOUND: "Ce code est inconnu ou a déjà été utilisé. Vérifiez le code affiché sur l'écran.",
  PAIRING_EXPIRED: "Ce code a expiré. L'appareil en affiche un nouveau toutes les 10 minutes.",
  DEVICE_LIMIT: "Nombre maximal d'appareils atteint. Supprimez un appareil existant pour connecter celui-ci.",
  PLAYLIST_LIMIT: "Nombre maximal de listes de lecture atteint pour votre plan.",
  ACCOUNT_EXPIRED: "Votre abonnement est expiré. Contactez l'administrateur pour le renouveler.",
  DEVICE_NOT_OWNED: "Cet appareil n'est pas connecté à votre compte.",
};

export async function describeError(e: unknown): Promise<string> {
  if (e instanceof FunctionError) return pairingErrors[e.message] ?? e.message;
  return e instanceof Error ? e.message : "Erreur inattendue.";
}

/** Normalises what the user typed (spaces, dashes, lowercase) into the 6-character code. */
export async function normalizeCode(raw: unknown): Promise<string> {
  return String(raw ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 6);
}

export async function previewPairing(input: { code?: string; token?: string }): Promise<{ preview?: PairingPreview; error?: string }> {
  const qs = input.token ? `token=${encodeURIComponent(input.token)}` : `code=${encodeURIComponent(input.code ?? "")}`;
  try {
    return { preview: await callAsUser<PairingPreview>(`/pairing-confirm?${qs}`) };
  } catch (e) {
    return { error: await describeError(e) };
  }
}

export async function confirmDeviceAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const { supabase, user } = await requireUser();
  if (!user) redirect("/login");
  const token = String(form.get("token") ?? "") || undefined;
  const code = token ? undefined : await normalizeCode(form.get("code"));
  if (!token && code?.length !== 6) return { error: "Le code comporte 6 caractères." };
  try {
    await callAsUser("/pairing-confirm", {
      method: "POST",
      body: JSON.stringify({ token, code, name: String(form.get("name") ?? "").trim() || undefined }),
    });
  } catch (e) {
    return { error: await describeError(e) };
  }
  revalidatePath("/account");
  // A device without anything to play is useless: send the user straight to the add form.
  const { count } = await supabase.from("playlists").select("id", { count: "exact", head: true }).eq("account_id", user.id);
  redirect((count ?? 0) === 0 ? "/account/playlists?add=1&paired=1" : "/account?paired=1");
}

/** Creates the playlist on the account through the playlist pairing session shown on the TV. */
export async function addPlaylistByCodeAction(pairing: { code?: string; token?: string }, _prev: ActionState, form: FormData): Promise<ActionState> {
  const { user } = await requireUser();
  if (!user) redirect("/login");
  const playlist = {
    name: String(form.get("name") ?? ""),
    type: String(form.get("type") ?? "m3u"),
    url: String(form.get("url") ?? ""),
    username: String(form.get("username") ?? "") || null,
    password: String(form.get("password") ?? "") || null,
    epg_url: String(form.get("epg_url") ?? "") || null,
    is_protected: form.get("is_protected") === "on",
    pin_code: String(form.get("pin_code") ?? "") || null,
    expires_at: String(form.get("expires_at") ?? "") || null,
  };
  try {
    await callAsUser("/pairing-confirm", { method: "POST", body: JSON.stringify({ ...pairing, playlist }) });
  } catch (e) {
    return { error: await describeError(e) };
  }
  revalidatePath("/account/playlists");
  return { ok: true };
}
