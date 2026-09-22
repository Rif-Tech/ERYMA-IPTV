import { redirect } from "next/navigation";
import { requireUser } from "@/lib/supabase";
import type { AccountStatus } from "../layout";
import { ProfileList, type PlaylistLite, type ViewerProfile } from "./profile-list";

export default async function ProfilesPage() {
  const { supabase, user } = await requireUser();
  if (!user) redirect("/login?next=/account/profiles");
  const [{ data: profiles }, { data: access }, { data: playlists }, { data: overview }] = await Promise.all([
    supabase.from("viewer_profiles").select("id, name, avatar, is_kids").eq("account_id", user.id).order("position").order("created_at"),
    supabase.from("profile_playlists").select("profile_id, playlist_id"),
    supabase.from("playlists").select("id, name").eq("account_id", user.id).order("position"),
    supabase.from("accounts_overview").select("status").eq("id", user.id).maybeSingle(),
  ]);
  const byProfile = new Map<string, string[]>();
  for (const a of (access ?? []) as { profile_id: string; playlist_id: string }[]) {
    (byProfile.get(a.profile_id) ?? byProfile.set(a.profile_id, []).get(a.profile_id)!).push(a.playlist_id);
  }
  const list: ViewerProfile[] = (profiles ?? []).map((p) => ({ ...p, playlist_ids: byProfile.get(p.id) ?? [] }));
  const max = (overview?.status as AccountStatus | undefined)?.max_profiles ?? 5;

  return (
    <div className="space-y-4">
      <p className="text-sm text-slate-400">
        Chaque profil a son propre historique, ses favoris et sa reprise de lecture, par liste de lecture. {list.length}/{max} profils.
      </p>
      <ProfileList profiles={list} playlists={(playlists ?? []) as PlaylistLite[]} canAdd={list.length < max} />
    </div>
  );
}
