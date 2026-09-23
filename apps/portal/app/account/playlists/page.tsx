import { redirect } from "next/navigation";
import type { Playlist } from "@/lib/types";
import { requireUser } from "@/lib/supabase";
import type { AccountStatus } from "../layout";
import { AccountPlaylists } from "./account-playlists";

export default async function PlaylistsPage({ searchParams }: PageProps<"/account/playlists">) {
  const { supabase, user } = await requireUser();
  if (!user) redirect("/login?next=/account/playlists");
  const params = await searchParams;
  const initialAdd = params.add === "1";
  const justPaired = params.paired === "1";
  const [{ data, error }, { data: overview }] = await Promise.all([
    supabase.from("playlists").select("*").eq("account_id", user.id).order("position").order("created_at"),
    supabase.from("accounts_overview").select("status").eq("id", user.id).maybeSingle(),
  ]);
  if (error) throw new Error(error.message);
  const max = (overview?.status as AccountStatus | undefined)?.max_playlists ?? 20;
  const list = (data ?? []) as Playlist[];
  return (
    <div className="space-y-4">
      {justPaired && (
        <div className="notice-success">
          <span className="text-lg">✓</span>
          <div>
            <p className="font-medium">Appareil connecté</p>
            <p className="text-sm opacity-80">Ajoutez votre première liste de lecture : votre écran la récupère automatiquement en quelques secondes.</p>
          </div>
        </div>
      )}
      <p className="text-sm text-white/60">Les listes appartiennent à votre compte et sont disponibles sur tous vos appareils. {list.length}/{max} listes.</p>
      <AccountPlaylists playlists={list} canAdd={list.length < max} initialAdd={initialAdd && list.length < max} />
    </div>
  );
}
