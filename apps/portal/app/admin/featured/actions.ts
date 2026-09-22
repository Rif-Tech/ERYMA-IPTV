"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createSupabaseServer, requireAdmin } from "@/lib/supabase";
import type { ActionState } from "../../manage-playlists/actions";

export type TmdbResult = {
  tmdb_id: number;
  kind: "movie" | "tv";
  title: string;
  original_title: string | null;
  year: number | null;
  overview: string | null;
  poster_url: string | null;
  backdrop_url: string | null;
  rating: number | null;
};

async function admin() {
  const ctx = await requireAdmin();
  if (!ctx.isAdmin) redirect("/admin/login");
  return ctx.supabase;
}

function functionsUrl(): string {
  const base = process.env.SUPABASE_FUNCTIONS_URL ?? `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1`;
  return base.replace(/\/$/, "");
}

/** Searches TMDB through the `tmdb` edge function using the admin's session JWT. */
export async function searchTmdbAction(query: string): Promise<{ results?: TmdbResult[]; error?: string }> {
  await admin();
  const supabase = await createSupabaseServer();
  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;
  if (!token) return { error: "Session expirée." };
  const q = query.trim();
  if (q.length < 2) return { results: [] };
  const url = `${functionsUrl()}/tmdb?action=search&q=${encodeURIComponent(q)}&lang=fr-FR`;
  const res = await fetch(url, {
    headers: { "x-admin-token": token, apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "" },
    cache: "no-store",
  });
  const body = (await res.json().catch(() => ({}))) as { results?: TmdbResult[]; error?: string };
  if (!res.ok) {
    return { error: res.status === 503 ? "Clé TMDB non configurée (secret TMDB_API_KEY)." : body.error ?? `Erreur ${res.status}` };
  }
  return { results: body.results ?? [] };
}

async function nextPosition(supabase: Awaited<ReturnType<typeof admin>>): Promise<number> {
  const { data } = await supabase.from("featured_items").select("position").order("position", { ascending: false }).limit(1);
  return ((data?.[0]?.position as number | undefined) ?? -1) + 1;
}

export async function addTmdbFeaturedAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const raw = String(form.get("payload") ?? "");
  const item = JSON.parse(raw) as TmdbResult;
  const { error } = await supabase.from("featured_items").insert({
    kind: item.kind,
    tmdb_id: item.tmdb_id,
    title: item.title,
    subtitle: String(form.get("subtitle") ?? "").trim() || null,
    overview: item.overview,
    year: item.year,
    poster_url: item.poster_url,
    backdrop_url: item.backdrop_url,
    require_match: true,
    position: await nextPosition(supabase),
  });
  if (error) throw new Error(error.message);
  revalidatePath("/admin/featured");
}

type BannerFields = {
  title: string;
  subtitle: string | null;
  overview: string | null;
  backdrop_url: string | null;
  poster_url: string | null;
  link_kind: string | null;
  link_query: string | null;
  require_match: boolean;
  event_at: string | null;
  event_end_at: string | null;
};

function optionalUrl(v: FormDataEntryValue | null): string | null | { error: string } {
  const s = String(v ?? "").trim();
  if (!s) return null;
  if (!/^https?:\/\//i.test(s)) return { error: "Les URL d'image doivent commencer par http(s)://." };
  return s;
}

/** Validates the shared banner fields (custom banners and edits of any kind). */
function parseBannerFields(form: FormData, { allowLink }: { allowLink: boolean }): BannerFields | { error: string } {
  const title = String(form.get("title") ?? "").trim();
  if (!title) return { error: "Le titre est obligatoire." };
  const linkKind = allowLink ? String(form.get("link_kind") ?? "") : "";
  const linkQuery = String(form.get("link_query") ?? "").trim();
  if (linkKind && !linkQuery) return { error: "Indiquez la cible du lien." };
  if (linkKind === "url" && !/^https?:\/\//i.test(linkQuery)) return { error: "L'URL doit commencer par http(s)://." };
  const backdrop = optionalUrl(form.get("backdrop_url"));
  if (backdrop && typeof backdrop === "object") return backdrop;
  const poster = optionalUrl(form.get("poster_url"));
  if (poster && typeof poster === "object") return poster;
  // datetime-local values carry no zone: the admin's browser offset is posted alongside.
  const tzOffset = Number(form.get("tz_offset") ?? 0) || 0;
  const toIso = (v: FormDataEntryValue | null): string | null => {
    const s = String(v ?? "").trim();
    if (!s) return null;
    const local = new Date(`${s}:00Z`);
    if (Number.isNaN(local.getTime())) return null;
    return new Date(local.getTime() + tzOffset * 60_000).toISOString();
  };
  const eventAt = toIso(form.get("event_at"));
  const eventEndAt = toIso(form.get("event_end_at"));
  if (eventEndAt && !eventAt) return { error: "Indiquez l'heure de début de l'événement." };
  if (eventAt && eventEndAt && eventEndAt <= eventAt) return { error: "La fin doit être après le début." };
  return {
    title,
    subtitle: String(form.get("subtitle") ?? "").trim() || null,
    overview: String(form.get("overview") ?? "").trim() || null,
    backdrop_url: backdrop,
    poster_url: poster,
    link_kind: linkKind || null,
    link_query: linkKind ? linkQuery : null,
    require_match: form.get("require_match") === "on",
    event_at: eventAt,
    event_end_at: eventEndAt,
  };
}

export async function addCustomFeaturedAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await admin();
  const fields = parseBannerFields(form, { allowLink: true });
  if ("error" in fields) return fields;
  const { error } = await supabase.from("featured_items").insert({
    kind: "custom",
    ...fields,
    position: await nextPosition(supabase),
  });
  if (error) return { error: error.message };
  revalidatePath("/admin/featured");
  return { ok: true };
}

/** Edits an existing item. TMDB entries keep their kind/tmdb_id; only custom banners expose a link target. */
export async function updateFeaturedAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await admin();
  const id = String(form.get("id") ?? "");
  if (!/^[0-9a-f-]{36}$/i.test(id)) return { error: "Identifiant invalide." };
  const { data: existing, error: readError } = await supabase.from("featured_items").select("kind").eq("id", id).maybeSingle();
  if (readError) return { error: readError.message };
  if (!existing) return { error: "Élément introuvable." };
  const fields = parseBannerFields(form, { allowLink: existing.kind === "custom" });
  if ("error" in fields) return fields;
  const yearRaw = String(form.get("year") ?? "").trim();
  const year = yearRaw ? Number(yearRaw) : null;
  if (year !== null && (!Number.isInteger(year) || year < 1800 || year > 2200)) return { error: "Année invalide." };
  const update: Record<string, unknown> = { ...fields, year, updated_at: new Date().toISOString() };
  if (existing.kind !== "custom") {
    // TMDB entries are always resolved against the user's playlist by title/year.
    delete update.link_kind;
    delete update.link_query;
  }
  const { error } = await supabase.from("featured_items").update(update).eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/admin/featured");
  return { ok: true };
}

export async function toggleFeaturedAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const { error } = await supabase
    .from("featured_items")
    .update({ enabled: form.get("enabled") === "true", updated_at: new Date().toISOString() })
    .eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/admin/featured");
}

export async function deleteFeaturedAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const { error } = await supabase.from("featured_items").delete().eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/admin/featured");
}

/** Swaps positions with the neighbour in the given direction. */
export async function moveFeaturedAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const id = String(form.get("id"));
  const dir = String(form.get("dir")) === "up" ? -1 : 1;
  const { data, error } = await supabase.from("featured_items").select("id, position").order("position", { ascending: true });
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as { id: string; position: number }[];
  const i = rows.findIndex((r) => r.id === id);
  const j = i + dir;
  if (i < 0 || j < 0 || j >= rows.length) return;
  // Renumber everything so ties from older inserts cannot block a swap.
  const order = rows.map((r) => r.id);
  [order[i], order[j]] = [order[j], order[i]];
  for (const [pos, rowId] of order.entries()) {
    const { error: e } = await supabase.from("featured_items").update({ position: pos }).eq("id", rowId);
    if (e) throw new Error(e.message);
  }
  revalidatePath("/admin/featured");
}
