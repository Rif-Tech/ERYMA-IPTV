"use client";

import { useActionState, useState } from "react";
import type { ActionState } from "../../manage-playlists/actions";
import { deleteProfileAction, saveProfileAction } from "../actions";

export const AVATARS = ["blue", "red", "green", "orange", "purple", "pink", "teal", "yellow"] as const;

const avatarClass: Record<string, string> = {
  blue: "bg-blue-500",
  red: "bg-red-500",
  green: "bg-emerald-500",
  orange: "bg-orange-500",
  purple: "bg-violet-500",
  pink: "bg-pink-500",
  teal: "bg-teal-500",
  yellow: "bg-yellow-400",
};

export type ViewerProfile = { id: string; name: string; avatar: string; is_kids: boolean; playlist_ids: string[] };
export type PlaylistLite = { id: string; name: string };

export function Avatar({ color, size = 40 }: { color: string; size?: number }) {
  return <span className={`inline-block rounded-lg ${avatarClass[color] ?? avatarClass.blue}`} style={{ width: size, height: size }} aria-hidden />;
}

export function ProfileList({ profiles, playlists, canAdd }: { profiles: ViewerProfile[]; playlists: PlaylistLite[]; canAdd: boolean }) {
  const [editing, setEditing] = useState<ViewerProfile | null | "new">(null);
  return (
    <div className="space-y-4">
      <ul className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {profiles.map((p) => (
          <li key={p.id} className="card flex items-center gap-3">
            <Avatar color={p.avatar} />
            <div className="min-w-0 flex-1">
              <p className="truncate font-medium">{p.name}{p.is_kids && <span className="badge ml-2 border border-slate-700 text-slate-300">Enfant</span>}</p>
              <p className="text-xs text-slate-400">
                {p.playlist_ids.length === playlists.length ? "Toutes les listes" : `${p.playlist_ids.length} liste${p.playlist_ids.length > 1 ? "s" : ""}`}
              </p>
            </div>
            <button type="button" className="btn-secondary !px-2 !py-1 text-xs" onClick={() => setEditing(p)}>Modifier</button>
          </li>
        ))}
      </ul>
      {canAdd && <button type="button" className="btn-primary" onClick={() => setEditing("new")}>Ajouter un profil</button>}
      {editing && (
        <ProfileDialog
          profile={editing === "new" ? undefined : editing}
          playlists={playlists}
          canDelete={profiles.length > 1}
          onClose={() => setEditing(null)}
        />
      )}
    </div>
  );
}

function ProfileDialog({ profile, playlists, canDelete, onClose }: { profile?: ViewerProfile; playlists: PlaylistLite[]; canDelete: boolean; onClose: () => void }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(
    async (prev, form) => {
      const r = await saveProfileAction(prev, form);
      if (r.ok) onClose();
      return r;
    },
    {},
  );
  const [avatar, setAvatar] = useState(profile?.avatar ?? "blue");
  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/70 p-4 sm:p-8" onClick={onClose} role="presentation">
      <form action={action} onClick={(e) => e.stopPropagation()} className="card w-full max-w-md space-y-4" role="dialog" aria-modal="true">
        {profile && <input type="hidden" name="id" value={profile.id} />}
        <input type="hidden" name="avatar" value={avatar} />
        <h2 className="text-lg font-semibold">{profile ? `Modifier « ${profile.name} »` : "Nouveau profil"}</h2>
        <div>
          <label className="label" htmlFor="profile-name">Nom</label>
          <input id="profile-name" name="name" className="input" defaultValue={profile?.name ?? ""} required maxLength={40} autoFocus />
        </div>
        <div>
          <p className="label">Couleur</p>
          <div className="flex flex-wrap gap-2">
            {AVATARS.map((c) => (
              <button
                key={c}
                type="button"
                onClick={() => setAvatar(c)}
                className={`rounded-lg p-0.5 ${avatar === c ? "ring-2 ring-white" : ""}`}
                aria-label={c}
              >
                <Avatar color={c} size={32} />
              </button>
            ))}
          </div>
        </div>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" name="is_kids" defaultChecked={profile?.is_kids ?? false} className="h-4 w-4" />
          Profil enfant
        </label>
        <div>
          <p className="label">Listes de lecture accessibles</p>
          {playlists.length === 0 && <p className="text-sm text-slate-500">Aucune liste pour l&apos;instant : le profil y aura accès dès qu&apos;une liste sera ajoutée.</p>}
          <div className="space-y-1">
            {playlists.map((pl) => (
              <label key={pl.id} className="flex items-center gap-2 text-sm">
                <input type="checkbox" name="playlist_ids" value={pl.id} defaultChecked={profile ? profile.playlist_ids.includes(pl.id) : true} className="h-4 w-4" />
                {pl.name}
              </label>
            ))}
          </div>
        </div>
        {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
        <div className="flex items-center justify-between gap-2">
          {profile && canDelete ? (
            <button type="submit" formAction={deleteProfileAction} className="btn-danger !py-1 text-xs" onClick={(e) => { if (!confirm(`Supprimer le profil « ${profile.name} » et son historique ?`)) e.preventDefault(); }}>
              Supprimer
            </button>
          ) : <span />}
          <div className="flex gap-2">
            <button type="button" className="btn-secondary" onClick={onClose} disabled={pending}>Annuler</button>
            <button type="submit" className="btn-primary" disabled={pending}>{pending ? "Enregistrement…" : "Enregistrer"}</button>
          </div>
        </div>
      </form>
    </div>
  );
}
