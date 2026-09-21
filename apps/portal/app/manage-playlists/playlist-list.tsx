"use client";

import { useState, useTransition } from "react";
import type { Playlist } from "@/lib/api";
import {
  createPlaylistAction,
  deletePlaylistAction,
  movePlaylistAction,
  revealPlaylistAction,
  updatePlaylistAction,
  type ActionState,
} from "./actions";
import { PlaylistForm } from "./playlist-form";

type Unlocked = { playlist: Playlist; pin: string };

export function PlaylistList({ playlists }: { playlists: Playlist[] }) {
  const [editing, setEditing] = useState<Unlocked | null>(null);
  const [adding, setAdding] = useState(playlists.length === 0);
  const [pinPrompt, setPinPrompt] = useState<{ id: string; mode: "edit" | "delete" } | null>(null);
  const [pinValue, setPinValue] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const doDelete = (id: string, pin?: string) =>
    startTransition(async () => {
      const form = new FormData();
      form.set("id", id);
      if (pin) form.set("pin", pin);
      const res: ActionState = await deletePlaylistAction({}, form);
      if (res.error) setError(res.error);
      else setPinPrompt(null);
    });

  const startEdit = (p: Playlist) => {
    setError(null);
    if (p.locked) {
      setPinValue("");
      setPinPrompt({ id: p.id, mode: "edit" });
    } else {
      setEditing({ playlist: p, pin: "" });
    }
  };

  const startDelete = (p: Playlist) => {
    setError(null);
    if (!confirm(`Supprimer « ${p.name} » ?`)) return;
    if (p.locked) {
      setPinValue("");
      setPinPrompt({ id: p.id, mode: "delete" });
    } else {
      doDelete(p.id);
    }
  };

  const submitPin = () =>
    startTransition(async () => {
      if (!pinPrompt) return;
      if (pinPrompt.mode === "delete") {
        doDelete(pinPrompt.id, pinValue);
        return;
      }
      const res = await revealPlaylistAction(pinPrompt.id, pinValue);
      if (res.error || !res.playlist) {
        setError(res.error ?? "Erreur inattendue.");
        return;
      }
      setEditing({ playlist: res.playlist, pin: pinValue });
      setPinPrompt(null);
    });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold">Playlists ({playlists.length})</h2>
        <button className="btn-primary" onClick={() => setAdding((v) => !v)}>{adding ? "Fermer" : "Ajouter une playlist"}</button>
      </div>

      {adding && (
        <div className="card">
          <h3 className="mb-4 font-medium">Nouvelle playlist</h3>
          <PlaylistForm action={createPlaylistAction} submitLabel="Ajouter" onDone={() => setAdding(false)} />
        </div>
      )}

      {playlists.length === 0 && !adding && <p className="text-slate-400">Aucune playlist pour cet appareil.</p>}
      {error && !pinPrompt && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{error}</p>}

      <ul className="space-y-3">
        {playlists.map((p, i) => (
          <li key={p.id} className="card">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="min-w-0">
                <div className="flex items-center gap-2">
                  <span className={`badge ${p.type === "xtream" ? "bg-violet-900 text-violet-100" : "bg-emerald-900 text-emerald-100"}`}>
                    {p.type === "xtream" ? "Xtream" : "M3U"}
                  </span>
                  <h3 className="truncate font-medium">{p.name}</h3>
                  {p.is_protected && <span className="badge bg-amber-900 text-amber-100">PIN</span>}
                </div>
                <p className="mt-1 truncate font-mono text-xs text-slate-400">{p.url}</p>
                {p.type === "xtream" && p.username && <p className="text-xs text-slate-500">Identifiant : {p.username}</p>}
                {p.locked && <p className="text-xs text-slate-500">Informations protégées par code PIN.</p>}
                {p.expires_at && <p className="text-xs text-slate-500">Expire le {new Date(p.expires_at).toLocaleDateString("fr-FR")}</p>}
              </div>
              <div className="flex flex-wrap gap-2">
                <form action={movePlaylistAction}>
                  <input type="hidden" name="id" value={p.id} />
                  <input type="hidden" name="direction" value="up" />
                  <button className="btn-secondary px-2" disabled={i === 0} title="Monter">↑</button>
                </form>
                <form action={movePlaylistAction}>
                  <input type="hidden" name="id" value={p.id} />
                  <input type="hidden" name="direction" value="down" />
                  <button className="btn-secondary px-2" disabled={i === playlists.length - 1} title="Descendre">↓</button>
                </form>
                <button className="btn-secondary" onClick={() => (editing?.playlist.id === p.id ? setEditing(null) : startEdit(p))}>
                  {editing?.playlist.id === p.id ? "Annuler" : "Modifier"}
                </button>
                <button className="btn-danger" onClick={() => startDelete(p)} disabled={pending}>Supprimer</button>
              </div>
            </div>

            {pinPrompt?.id === p.id && (
              <form
                className="mt-4 flex flex-wrap items-end gap-3 border-t border-slate-800 pt-4"
                onSubmit={(e) => {
                  e.preventDefault();
                  submitPin();
                }}
              >
                <div>
                  <label className="label" htmlFor={`pin-${p.id}`}>
                    Code PIN requis pour {pinPrompt.mode === "delete" ? "supprimer" : "modifier"}
                  </label>
                  <input
                    id={`pin-${p.id}`}
                    className="input w-40 font-mono"
                    type="password"
                    inputMode="numeric"
                    autoFocus
                    value={pinValue}
                    onChange={(e) => setPinValue(e.target.value)}
                    required
                  />
                </div>
                <button className="btn-primary" disabled={pending}>{pending ? "Vérification…" : "Valider"}</button>
                <button type="button" className="btn-secondary" onClick={() => setPinPrompt(null)}>Annuler</button>
                {error && <p className="w-full text-sm text-red-300">{error}</p>}
              </form>
            )}

            {editing?.playlist.id === p.id && (
              <div className="mt-4 border-t border-slate-800 pt-4">
                <PlaylistForm
                  action={updatePlaylistAction}
                  playlist={editing.playlist}
                  unlockPin={editing.pin || undefined}
                  submitLabel="Enregistrer"
                  onDone={() => setEditing(null)}
                />
              </div>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
