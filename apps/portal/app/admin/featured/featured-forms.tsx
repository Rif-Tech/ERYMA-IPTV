"use client";

import { useActionState, useState, useTransition } from "react";
import type { ActionState } from "../../manage-playlists/actions";
import { addCustomFeaturedAction, addTmdbFeaturedAction, searchTmdbAction, type TmdbResult } from "./actions";

export function TmdbSearchForm() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<TmdbResult[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [pending, start] = useTransition();
  const [adding, startAdd] = useTransition();

  function search() {
    start(async () => {
      setError(null);
      const res = await searchTmdbAction(query);
      if (res.error) setError(res.error);
      setResults(res.results ?? []);
    });
  }

  function add(item: TmdbResult) {
    const fd = new FormData();
    fd.set("payload", JSON.stringify(item));
    startAdd(async () => {
      await addTmdbFeaturedAction(fd);
      setResults((r) => r.filter((x) => x.tmdb_id !== item.tmdb_id || x.kind !== item.kind));
    });
  }

  return (
    <div className="card space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Ajouter depuis TMDB</h2>
        <p className="text-sm text-slate-400">
          Le film ou la série ne s&apos;affiche chez un utilisateur que s&apos;il figure dans l&apos;une de ses listes de lecture
          (correspondance par titre et année). Affiche et fond proviennent de TMDB.
        </p>
      </div>
      <div className="flex gap-2">
        <input
          className="input flex-1"
          placeholder="Titre du film ou de la série…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              search();
            }
          }}
        />
        <button type="button" className="btn-primary" onClick={search} disabled={pending || query.trim().length < 2}>
          {pending ? "Recherche…" : "Rechercher"}
        </button>
      </div>
      {error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{error}</p>}
      {results.length > 0 && (
        <ul className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {results.map((r) => (
            <li key={`${r.kind}-${r.tmdb_id}`} className="flex gap-3 rounded-lg border border-slate-800 bg-slate-900/60 p-3">
              {r.poster_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={r.poster_url} alt="" className="h-24 w-16 flex-none rounded object-cover" />
              ) : (
                <div className="h-24 w-16 flex-none rounded bg-slate-800" />
              )}
              <div className="min-w-0 flex-1">
                <p className="truncate font-medium">{r.title}</p>
                <p className="text-xs text-slate-400">
                  {r.kind === "movie" ? "Film" : "Série"}
                  {r.year ? ` · ${r.year}` : ""}
                  {r.rating ? ` · ★ ${r.rating.toFixed(1)}` : ""} · TMDB #{r.tmdb_id}
                </p>
                <p className="mt-1 line-clamp-2 text-xs text-slate-500">{r.overview}</p>
                <button type="button" className="btn-secondary mt-2 !py-1 text-xs" onClick={() => add(r)} disabled={adding}>
                  Ajouter à la une
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export function CustomBannerForm() {
  const [state, action, pending] = useActionState<ActionState, FormData>(addCustomFeaturedAction, {});
  const [linkKind, setLinkKind] = useState("");
  const [hasEvent, setHasEvent] = useState(false);
  return (
    <form
      action={action}
      className="card space-y-4"
      // datetime-local has no zone: attach the browser offset right before the server action runs.
      onSubmit={(e) => {
        const tz = e.currentTarget.elements.namedItem("tz_offset") as HTMLInputElement | null;
        if (tz) tz.value = String(new Date().getTimezoneOffset());
      }}
    >
      <input type="hidden" name="tz_offset" defaultValue="0" />
      <div>
        <h2 className="text-lg font-semibold">Bannière personnalisée</h2>
        <p className="text-sm text-slate-400">Événement sportif, promotion, message… avec une image et, si besoin, un lien vers une chaîne, un film, une série ou une URL.</p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label className="label" htmlFor="title">Titre</label>
          <input id="title" name="title" className="input" required placeholder="Ligue 1 · PSG – OM" />
        </div>
        <div>
          <label className="label" htmlFor="subtitle">Sous-titre</label>
          <input id="subtitle" name="subtitle" className="input" placeholder="Dimanche 20h45" />
        </div>
        <div className="sm:col-span-2">
          <label className="label" htmlFor="backdrop_url">Image large (URL, 16:9 recommandé)</label>
          <input id="backdrop_url" name="backdrop_url" className="input" placeholder="https://…/banner.jpg" />
        </div>
        <div className="sm:col-span-2">
          <label className="label" htmlFor="poster_url">Affiche (URL, optionnel)</label>
          <input id="poster_url" name="poster_url" className="input" placeholder="https://…/poster.jpg" />
        </div>
        <div className="sm:col-span-2">
          <label className="label" htmlFor="overview">Description</label>
          <textarea id="overview" name="overview" className="input" rows={2} />
        </div>
        <div>
          <label className="label" htmlFor="link_kind">Action du bouton</label>
          <select id="link_kind" name="link_kind" className="input" value={linkKind} onChange={(e) => setLinkKind(e.target.value)}>
            <option value="">Aucune (visuel seul)</option>
            <option value="channel">Lancer une chaîne (par nom)</option>
            <option value="movie">Lancer un film (par titre)</option>
            <option value="series">Ouvrir une série (par titre)</option>
            <option value="url">Ouvrir une URL</option>
          </select>
        </div>
        <div>
          <label className="label" htmlFor="link_query">{linkKind === "url" ? "URL" : "Nom / titre recherché"}</label>
          <input id="link_query" name="link_query" className="input" disabled={!linkKind} placeholder={linkKind === "url" ? "https://…" : "beIN Sports 1"} />
        </div>
      </div>
      <div className="space-y-3 rounded-lg border border-slate-800 p-3">
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" className="h-4 w-4" checked={hasEvent} onChange={(e) => setHasEvent(e.target.checked)} />
          Événement programmé (match, direct…)
        </label>
        {hasEvent && (
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className="label" htmlFor="event_at">Début</label>
              <input id="event_at" name="event_at" type="datetime-local" className="input" required />
            </div>
            <div>
              <label className="label" htmlFor="event_end_at">Fin (optionnel, sinon début + 3 h)</label>
              <input id="event_end_at" name="event_end_at" type="datetime-local" className="input" />
            </div>
            <p className="text-xs text-slate-400 sm:col-span-2">
              La date s&apos;affiche sur la bannière ; un badge « Maintenant » (point rouge clignotant) apparaît 15 minutes avant le début. La bannière disparaît après la fin.
            </p>
          </div>
        )}
      </div>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="require_match" defaultChecked className="h-4 w-4" />
        Masquer la bannière si l&apos;utilisateur n&apos;a pas la chaîne / le contenu ciblé
      </label>
      {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
      {state.ok && <p className="rounded-md border border-emerald-900 bg-emerald-950/60 px-3 py-2 text-sm text-emerald-200">Bannière ajoutée.</p>}
      <button className="btn-primary" disabled={pending}>{pending ? "Ajout…" : "Ajouter la bannière"}</button>
    </form>
  );
}
