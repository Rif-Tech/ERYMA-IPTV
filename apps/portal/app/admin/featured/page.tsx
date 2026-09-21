import Link from "next/link";
import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import { deleteFeaturedAction, moveFeaturedAction, toggleFeaturedAction } from "./actions";
import { CustomBannerForm, TmdbSearchForm } from "./featured-forms";

type FeaturedRow = {
  id: string;
  kind: "movie" | "tv" | "custom";
  tmdb_id: number | null;
  title: string;
  subtitle: string | null;
  year: number | null;
  poster_url: string | null;
  backdrop_url: string | null;
  link_kind: string | null;
  link_query: string | null;
  require_match: boolean;
  enabled: boolean;
  position: number;
  event_at: string | null;
  event_end_at: string | null;
};

const kindLabel: Record<FeaturedRow["kind"], string> = { movie: "Film", tv: "Série", custom: "Bannière" };
const linkLabel: Record<string, string> = { channel: "Chaîne", movie: "Film", series: "Série", url: "URL" };
const fmt = new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium", timeStyle: "short", timeZone: "Europe/Paris" });

function eventState(row: FeaturedRow, now: number): "upcoming" | "live" | "over" | null {
  if (!row.event_at) return null;
  const start = Date.parse(row.event_at);
  const end = row.event_end_at ? Date.parse(row.event_end_at) : start + 3 * 3600_000;
  if (now > end) return "over";
  if (now >= start - 15 * 60_000) return "live";
  return "upcoming";
}

// Server component: the clock is read once per request, outside the render body.
async function currentTime(): Promise<number> {
  return Date.now();
}

export default async function FeaturedPage() {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");

  const { data, error } = await supabase.from("featured_items").select("*").order("position", { ascending: true });
  if (error) throw new Error(error.message);
  const items = (data ?? []) as FeaturedRow[];
  const now = await currentTime();

  return (
    <div className="space-y-6">
      <Link href="/admin" className="text-sm text-blue-400 hover:underline">← Appareils</Link>
      <div>
        <h1 className="text-2xl font-semibold">À la une</h1>
        <p className="text-sm text-slate-400">
          Contenu du carrousel d&apos;accueil pour les utilisateurs en mode « Sélection de l&apos;équipe » (choix par défaut). L&apos;ordre ci-dessous est l&apos;ordre d&apos;affichage.
        </p>
      </div>

      <div className="overflow-x-auto rounded-lg border border-slate-800">
        <table className="w-full text-sm">
          <thead className="bg-slate-900 text-left text-xs uppercase text-slate-400">
            <tr>
              <th className="px-3 py-2">#</th>
              <th className="px-3 py-2">Visuel</th>
              <th className="px-3 py-2">Titre</th>
              <th className="px-3 py-2">Type</th>
              <th className="px-3 py-2">Cible</th>
              <th className="px-3 py-2">Statut</th>
              <th className="px-3 py-2 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.length === 0 && (
              <tr>
                <td colSpan={7} className="px-3 py-6 text-center text-slate-500">Aucun élément. Ajoutez un film/série TMDB ou une bannière ci-dessous.</td>
              </tr>
            )}
            {items.map((it, i) => (
              <tr key={it.id} className={`border-t border-slate-800 ${it.enabled ? "" : "opacity-50"}`}>
                <td className="px-3 py-2 text-slate-500">{i + 1}</td>
                <td className="px-3 py-2">
                  {it.backdrop_url || it.poster_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={it.backdrop_url ?? it.poster_url ?? ""} alt="" className="h-12 w-20 rounded object-cover" />
                  ) : (
                    <div className="h-12 w-20 rounded bg-slate-800" />
                  )}
                </td>
                <td className="px-3 py-2">
                  <p className="font-medium">{it.title}{it.year ? <span className="text-slate-500"> ({it.year})</span> : null}</p>
                  {it.subtitle && <p className="text-xs text-slate-400">{it.subtitle}</p>}
                  {it.tmdb_id && <p className="text-xs text-slate-500">TMDB #{it.tmdb_id}</p>}
                  {it.event_at && (
                    <p className="mt-1 text-xs">
                      <span className="text-slate-400">📅 {fmt.format(new Date(it.event_at))}</span>
                      {eventState(it, now) === "live" && <span className="ml-2 badge border-red-800 text-red-300">● En direct</span>}
                      {eventState(it, now) === "over" && <span className="ml-2 badge">Terminé (masqué)</span>}
                    </p>
                  )}
                </td>
                <td className="px-3 py-2">{kindLabel[it.kind]}</td>
                <td className="px-3 py-2 text-xs text-slate-400">
                  {it.kind === "custom"
                    ? it.link_kind
                      ? `${linkLabel[it.link_kind] ?? it.link_kind} : ${it.link_query}`
                      : "—"
                    : "Playlist de l'utilisateur"}
                  {it.require_match && <span className="ml-2 badge">si dispo</span>}
                </td>
                <td className="px-3 py-2">
                  <form action={toggleFeaturedAction}>
                    <input type="hidden" name="id" value={it.id} />
                    <input type="hidden" name="enabled" value={it.enabled ? "false" : "true"} />
                    <button className={`badge ${it.enabled ? "border-emerald-800 text-emerald-300" : ""}`}>{it.enabled ? "Actif" : "Désactivé"}</button>
                  </form>
                </td>
                <td className="px-3 py-2">
                  <div className="flex justify-end gap-1">
                    <form action={moveFeaturedAction}>
                      <input type="hidden" name="id" value={it.id} />
                      <input type="hidden" name="dir" value="up" />
                      <button className="btn-secondary !px-2 !py-1" disabled={i === 0} aria-label="Monter">↑</button>
                    </form>
                    <form action={moveFeaturedAction}>
                      <input type="hidden" name="id" value={it.id} />
                      <input type="hidden" name="dir" value="down" />
                      <button className="btn-secondary !px-2 !py-1" disabled={i === items.length - 1} aria-label="Descendre">↓</button>
                    </form>
                    <form action={deleteFeaturedAction}>
                      <input type="hidden" name="id" value={it.id} />
                      <button className="btn-danger !px-2 !py-1">Supprimer</button>
                    </form>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <TmdbSearchForm />
      <CustomBannerForm />
    </div>
  );
}
