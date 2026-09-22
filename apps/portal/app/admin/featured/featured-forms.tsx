"use client";

import { useActionState, useEffect, useState, useTransition, type FormEvent } from "react";
import type { ActionState } from "../../manage-playlists/actions";
import { addCustomFeaturedAction, addTmdbFeaturedAction, searchTmdbAction, updateFeaturedAction, type TmdbResult } from "./actions";
import type { FeaturedRow } from "./types";

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
  return (
    <form action={action} className="card space-y-4" onSubmit={stampTimezone}>
      <input type="hidden" name="tz_offset" defaultValue="0" />
      <div>
        <h2 className="text-lg font-semibold">Bannière personnalisée</h2>
        <p className="text-sm text-slate-400">Événement sportif, promotion, message… avec une image et, si besoin, un lien vers une chaîne, un film, une série ou une URL.</p>
      </div>
      <BannerFields idPrefix="new" allowLink />
      {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
      {state.ok && <p className="rounded-md border border-emerald-900 bg-emerald-950/60 px-3 py-2 text-sm text-emerald-200">Bannière ajoutée.</p>}
      <button className="btn-primary" disabled={pending}>{pending ? "Ajout…" : "Ajouter la bannière"}</button>
    </form>
  );
}

/** Opens a modal editor for an existing featured item. */
export function EditFeaturedButton({ item }: { item: FeaturedRow }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button type="button" className="btn-secondary !px-2 !py-1" onClick={() => setOpen(true)}>Modifier</button>
      {open && <EditFeaturedDialog item={item} onClose={() => setOpen(false)} />}
    </>
  );
}

function EditFeaturedDialog({ item, onClose }: { item: FeaturedRow; onClose: () => void }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(updateFeaturedAction, {});
  const isCustom = item.kind === "custom";
  useEffect(() => {
    if (state.ok) onClose();
  }, [state.ok, onClose]);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);
  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/70 p-4 sm:p-8" onClick={onClose} role="presentation">
      <form
        action={action}
        onSubmit={stampTimezone}
        onClick={(e) => e.stopPropagation()}
        className="card w-full max-w-2xl space-y-4"
        role="dialog"
        aria-modal="true"
        aria-labelledby={`edit-${item.id}-title`}
      >
        <input type="hidden" name="id" value={item.id} />
        <input type="hidden" name="tz_offset" defaultValue="0" />
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 id={`edit-${item.id}-title`} className="text-lg font-semibold">Modifier « {item.title} »</h2>
            <p className="text-sm text-slate-400">
              {isCustom ? "Bannière personnalisée." : `${item.kind === "movie" ? "Film" : "Série"} TMDB #${item.tmdb_id} — la correspondance avec la playlist de l'utilisateur se fait sur le titre et l'année.`}
            </p>
          </div>
          <button type="button" className="btn-secondary !px-2 !py-1" onClick={onClose} aria-label="Fermer">✕</button>
        </div>
        <BannerFields idPrefix={`edit-${item.id}`} allowLink={isCustom} item={item} />
        {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
        <div className="flex justify-end gap-2">
          <button type="button" className="btn-secondary" onClick={onClose} disabled={pending}>Annuler</button>
          <button className="btn-primary" disabled={pending}>{pending ? "Enregistrement…" : "Enregistrer"}</button>
        </div>
      </form>
    </div>
  );
}

// datetime-local has no zone: attach the browser offset right before the server action runs.
function stampTimezone(e: FormEvent<HTMLFormElement>) {
  const tz = e.currentTarget.elements.namedItem("tz_offset") as HTMLInputElement | null;
  if (tz) tz.value = String(new Date().getTimezoneOffset());
}

/** ISO timestamp → value accepted by `<input type="datetime-local">` in the browser's zone. */
function toLocalInput(iso: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** Shared fields for creating a banner and editing any item; `item` pre-fills the inputs. */
function BannerFields({ idPrefix, allowLink, item }: { idPrefix: string; allowLink: boolean; item?: FeaturedRow }) {
  const [linkKind, setLinkKind] = useState(item?.link_kind ?? "");
  const [hasEvent, setHasEvent] = useState(Boolean(item?.event_at));
  const id = (name: string) => `${idPrefix}-${name}`;
  return (
    <>
      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label className="label" htmlFor={id("title")}>Titre</label>
          <input id={id("title")} name="title" className="input" required defaultValue={item?.title ?? ""} placeholder="Ligue 1 · PSG – OM" />
        </div>
        <div>
          <label className="label" htmlFor={id("subtitle")}>Sous-titre</label>
          <input id={id("subtitle")} name="subtitle" className="input" defaultValue={item?.subtitle ?? ""} placeholder="Dimanche 20h45" />
        </div>
        {item && (
          <div>
            <label className="label" htmlFor={id("year")}>Année</label>
            <input id={id("year")} name="year" type="number" min={1800} max={2200} className="input" defaultValue={item.year ?? ""} />
          </div>
        )}
        <div className="sm:col-span-2">
          <label className="label" htmlFor={id("backdrop_url")}>Image large (URL, 16:9 recommandé)</label>
          <input id={id("backdrop_url")} name="backdrop_url" className="input" defaultValue={item?.backdrop_url ?? ""} placeholder="https://…/banner.jpg" />
        </div>
        <div className="sm:col-span-2">
          <label className="label" htmlFor={id("poster_url")}>Affiche (URL, optionnel)</label>
          <input id={id("poster_url")} name="poster_url" className="input" defaultValue={item?.poster_url ?? ""} placeholder="https://…/poster.jpg" />
        </div>
        <div className="sm:col-span-2">
          <label className="label" htmlFor={id("overview")}>Description</label>
          <textarea id={id("overview")} name="overview" className="input" rows={2} defaultValue={item?.overview ?? ""} />
        </div>
        {allowLink && (
          <>
            <div>
              <label className="label" htmlFor={id("link_kind")}>Action du bouton</label>
              <select id={id("link_kind")} name="link_kind" className="input" value={linkKind} onChange={(e) => setLinkKind(e.target.value)}>
                <option value="">Aucune (visuel seul)</option>
                <option value="channel">Lancer une chaîne (par nom)</option>
                <option value="movie">Lancer un film (par titre)</option>
                <option value="series">Ouvrir une série (par titre)</option>
                <option value="url">Ouvrir une URL</option>
              </select>
            </div>
            <div>
              <label className="label" htmlFor={id("link_query")}>{linkKind === "url" ? "URL" : "Nom / titre recherché"}</label>
              <input
                id={id("link_query")}
                name="link_query"
                className="input"
                disabled={!linkKind}
                defaultValue={item?.link_query ?? ""}
                placeholder={linkKind === "url" ? "https://…" : "beIN Sports 1"}
              />
            </div>
          </>
        )}
      </div>
      <div className="space-y-3 rounded-lg border border-slate-800 p-3">
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" className="h-4 w-4" checked={hasEvent} onChange={(e) => setHasEvent(e.target.checked)} />
          Événement programmé (match, direct…)
        </label>
        {hasEvent && (
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className="label" htmlFor={id("event_at")}>Début</label>
              <input id={id("event_at")} name="event_at" type="datetime-local" className="input" required defaultValue={toLocalInput(item?.event_at ?? null)} />
            </div>
            <div>
              <label className="label" htmlFor={id("event_end_at")}>Fin (optionnel, sinon début + 3 h)</label>
              <input id={id("event_end_at")} name="event_end_at" type="datetime-local" className="input" defaultValue={toLocalInput(item?.event_end_at ?? null)} />
            </div>
            <p className="text-xs text-slate-400 sm:col-span-2">
              La date s&apos;affiche sur la bannière ; un badge « Maintenant » (point rouge clignotant) apparaît 15 minutes avant le début. La bannière disparaît après la fin.
            </p>
          </div>
        )}
      </div>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="require_match" defaultChecked={item?.require_match ?? true} className="h-4 w-4" />
        Masquer si l&apos;utilisateur n&apos;a pas la chaîne / le contenu ciblé dans ses playlists
      </label>
    </>
  );
}
