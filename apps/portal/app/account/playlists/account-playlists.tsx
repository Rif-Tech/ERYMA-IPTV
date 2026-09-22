"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import type { Playlist } from "@/lib/api";
import { PlaylistForm } from "../../manage-playlists/playlist-form";
import { createPlaylistAction, deletePlaylistAction, movePlaylistAction, updatePlaylistAction } from "../actions";

const fmt = new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium", timeZone: "Europe/Paris" });

export function AccountPlaylists({ playlists, canAdd, initialAdd = false }: { playlists: Playlist[]; canAdd: boolean; initialAdd?: boolean }) {
  const router = useRouter();
  const [editing, setEditing] = useState<Playlist | null>(null);
  const [adding, setAdding] = useState(initialAdd);
  // Drops `?add=1&paired=1` once the form has served its purpose.
  const closeAdd = () => {
    setAdding(false);
    router.replace("/account/playlists");
  };

  return (
    <div className="space-y-4">
      {playlists.length === 0 && (
        <div className="card space-y-2 text-sm text-slate-300">
          <p className="font-medium text-slate-100">Aucune liste de lecture configurée</p>
          <p>Cette application est un lecteur IPTV : elle ne fournit pas de contenu. Ajoutez la source fournie par votre fournisseur (URL M3U ou compte Xtream Codes) pour commencer.</p>
        </div>
      )}
      <ul className="space-y-2">
        {playlists.map((p, i) => (
          <li key={p.id} className="card flex flex-wrap items-center gap-3">
            <div className="min-w-0 flex-1">
              <p className="font-medium">
                {p.name}
                <span className="badge ml-2 border border-slate-700 text-slate-300">{p.type === "xtream" ? "Xtream" : "M3U"}</span>
                {p.is_protected && <span className="badge ml-1 border border-slate-700 text-slate-300">PIN</span>}
              </p>
              <p className="truncate text-xs text-slate-400">
                {p.url}
                {p.expires_at ? ` · expire le ${fmt.format(new Date(p.expires_at))}` : ""}
              </p>
            </div>
            <div className="flex gap-1">
              <form action={movePlaylistAction}>
                <input type="hidden" name="id" value={p.id} />
                <input type="hidden" name="dir" value="up" />
                <button className="btn-secondary !px-2 !py-1" disabled={i === 0} aria-label="Monter">↑</button>
              </form>
              <form action={movePlaylistAction}>
                <input type="hidden" name="id" value={p.id} />
                <input type="hidden" name="dir" value="down" />
                <button className="btn-secondary !px-2 !py-1" disabled={i === playlists.length - 1} aria-label="Descendre">↓</button>
              </form>
              <button type="button" className="btn-secondary !px-2 !py-1" onClick={() => setEditing(p)}>Modifier</button>
              <form action={deletePlaylistAction} onSubmit={(e) => { if (!confirm(`Supprimer « ${p.name} » ? L'historique associé sur vos appareils sera perdu.`)) e.preventDefault(); }}>
                <input type="hidden" name="id" value={p.id} />
                <button className="btn-danger !px-2 !py-1">Supprimer</button>
              </form>
            </div>
          </li>
        ))}
      </ul>
      {canAdd && !adding && <button type="button" className="btn-primary" onClick={() => setAdding(true)}>Ajouter une liste de lecture</button>}
      {adding && (
        <div className="card space-y-3">
          <h2 className="text-lg font-semibold">Nouvelle liste de lecture</h2>
          <PlaylistForm action={createPlaylistAction} submitLabel="Ajouter" onDone={closeAdd} />
          <button type="button" className="btn-secondary" onClick={closeAdd}>Annuler</button>
        </div>
      )}
      {editing && (
        <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/70 p-4 sm:p-8" onClick={() => setEditing(null)} role="presentation">
          <div className="card w-full max-w-2xl space-y-3" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
            <h2 className="text-lg font-semibold">Modifier « {editing.name} »</h2>
            <PlaylistForm action={updatePlaylistAction} playlist={editing} submitLabel="Enregistrer" onDone={() => setEditing(null)} />
            <button type="button" className="btn-secondary" onClick={() => setEditing(null)}>Annuler</button>
          </div>
        </div>
      )}
    </div>
  );
}
