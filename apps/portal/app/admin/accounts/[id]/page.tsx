import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import type { Playlist } from "@/lib/api";
import { revokeAllDevicesAction, updateSubscriptionAction } from "../actions";
import { type AccountOverview, SubscriptionBadge } from "../shared";

type DeviceRow = { id: string; name: string | null; mac: string | null; device_type: string; model: string | null; status: string; last_seen_at: string };
type ProfileRow = { id: string; name: string; is_kids: boolean };

export default async function AccountDetailPage({ params }: PageProps<"/admin/accounts/[id]">) {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");
  const { id } = await params;

  const [{ data: account }, { data: devices }, { data: playlists }, { data: profiles }, { data: plans }] = await Promise.all([
    supabase.from("accounts_overview").select("*").eq("id", id).maybeSingle(),
    supabase.from("devices").select("id, name, mac, device_type, model, status, last_seen_at").eq("account_id", id).order("last_seen_at", { ascending: false }),
    supabase.from("playlists").select("*").eq("account_id", id).order("position"),
    supabase.from("viewer_profiles").select("id, name, is_kids").eq("account_id", id).order("position"),
    supabase.from("plans").select("id, name").order("id"),
  ]);
  if (!account) notFound();
  const a = account as AccountOverview;
  const expires = a.expires_at ? String(a.expires_at).slice(0, 10) : "";

  return (
    <div className="space-y-6">
      <Link href="/admin/accounts" className="text-sm text-blue-400 hover:underline">← Comptes</Link>

      <div className="card space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-2xl">{a.email ?? a.id}</p>
            <p className="text-xs text-slate-500">Créé le {new Date(a.created_at).toLocaleString("fr-FR")} · {a.id}</p>
          </div>
          <SubscriptionBadge s={a.status} />
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <form action={updateSubscriptionAction} className="space-y-2 rounded-md border border-slate-800 p-4">
            <input type="hidden" name="account_id" value={a.id} />
            <p className="font-medium">Abonnement</p>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="label" htmlFor="plan_id">Formule</label>
                <select id="plan_id" name="plan_id" className="input" defaultValue={a.plan_id ?? "trial"}>
                  {(plans ?? []).map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>
              <div>
                <label className="label" htmlFor="status">Statut</label>
                <select id="status" name="status" className="input" defaultValue={a.subscription_status ?? "trial"}>
                  <option value="trial">Essai</option>
                  <option value="active">Actif</option>
                  <option value="expired">Expiré</option>
                  <option value="cancelled">Annulé</option>
                </select>
              </div>
            </div>
            <div>
              <label className="label" htmlFor="expires_at">Expiration (vide = illimité)</label>
              <input id="expires_at" name="expires_at" type="date" className="input" defaultValue={expires} />
            </div>
            <div>
              <label className="label" htmlFor="note">Note interne</label>
              <input id="note" name="note" className="input" defaultValue={a.note ?? ""} maxLength={500} />
            </div>
            <button className="btn-primary">Enregistrer</button>
          </form>

          <div className="space-y-3 rounded-md border border-slate-800 p-4 text-sm">
            <p className="font-medium">Limites de la formule</p>
            <dl className="grid grid-cols-2 gap-1 text-slate-300">
              <dt className="text-slate-400">Appareils</dt><dd>{a.device_count} / {a.status.max_devices}</dd>
              <dt className="text-slate-400">Listes</dt><dd>{a.playlist_count} / {a.status.max_playlists}</dd>
              <dt className="text-slate-400">Profils</dt><dd>{a.profile_count} / {a.status.max_profiles}</dd>
              <dt className="text-slate-400">Fin d&apos;essai</dt><dd>{a.status.trial_ends_at ? new Date(a.status.trial_ends_at).toLocaleDateString("fr-FR") : "—"}</dd>
            </dl>
            <form action={revokeAllDevicesAction}>
              <input type="hidden" name="account_id" value={a.id} />
              <button className="btn-danger" disabled={(devices ?? []).every((d) => d.status !== "active")}>Déconnecter tous les appareils</button>
            </form>
          </div>
        </div>
      </div>

      <section className="space-y-2">
        <h2 className="text-xl font-semibold">Appareils ({devices?.length ?? 0})</h2>
        {(devices as DeviceRow[] | null)?.map((d) => (
          <div key={d.id} className="card flex flex-wrap items-center justify-between gap-2 text-sm">
            <Link href={`/admin/devices/${d.id}`} className="text-blue-400 hover:underline">{d.name ?? d.mac ?? d.id.slice(0, 8)}</Link>
            <span className="text-slate-400">{d.device_type}{d.model ? ` · ${d.model}` : ""} · {d.status === "active" ? "connecté" : "déconnecté"} · {new Date(d.last_seen_at).toLocaleString("fr-FR")}</span>
          </div>
        ))}
        {(devices?.length ?? 0) === 0 && <p className="text-slate-500">Aucun appareil.</p>}
      </section>

      <section className="space-y-2">
        <h2 className="text-xl font-semibold">Profils ({profiles?.length ?? 0})</h2>
        <div className="flex flex-wrap gap-2">
          {(profiles as ProfileRow[] | null)?.map((p) => (
            <span key={p.id} className="badge border border-slate-700 text-slate-200">{p.name}{p.is_kids ? " · enfant" : ""}</span>
          ))}
        </div>
      </section>

      <section className="space-y-2">
        <h2 className="text-xl font-semibold">Listes de lecture ({playlists?.length ?? 0})</h2>
        {(playlists as Playlist[] | null)?.map((p) => (
          <div key={p.id} className="card text-sm">
            <p className="font-medium"><span className={`badge mr-2 ${p.type === "xtream" ? "bg-violet-900 text-violet-100" : "bg-emerald-900 text-emerald-100"}`}>{p.type}</span>{p.name}</p>
            <p className="truncate font-mono text-xs text-slate-400">{p.url}{p.username ? ` · ${p.username}` : ""}</p>
          </div>
        ))}
        {(playlists?.length ?? 0) === 0 && <p className="text-slate-500">Aucune liste.</p>}
      </section>
    </div>
  );
}
