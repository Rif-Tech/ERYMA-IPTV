import Link from "next/link";
import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import { StatusBadge } from "@/components/status-badge";
import type { DeviceStatus } from "@/lib/api";
import { adminLogoutAction } from "./actions";

type DeviceRow = {
  id: string;
  mac: string | null;
  device_key: string | null;
  device_type: string;
  platform: string | null;
  app_version: string | null;
  last_seen_at: string;
  created_at: string;
  status_legacy: DeviceStatus;
  status: "active" | "revoked";
  name: string | null;
  account_id: string | null;
  account_email: string | null;
  playlist_count: number;
};

export default async function AdminPage({ searchParams }: PageProps<"/admin">) {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");

  const params = await searchParams;
  const q = (Array.isArray(params.q) ? params.q[0] : params.q ?? "").trim();
  const filter = Array.isArray(params.f) ? params.f[0] : params.f;

  let query = supabase.from("devices_with_status").select("*").order("last_seen_at", { ascending: false }).limit(200);
  if (q) {
    // Restrict to a safe charset: the value is embedded in a PostgREST `or` filter expression.
    const safe = q.replace(/[^\w@.:+-]/g, "");
    const mac = safe.replace(/-/g, ":").toUpperCase();
    if (safe) query = query.or(`mac.ilike.%${mac}%,account_email.ilike.%${safe}%,name.ilike.%${safe}%`);
  }
  const { data, error } = await query;
  if (error) throw new Error(error.message);

  let devices = (data ?? []) as DeviceRow[];
  // Account-paired devices follow their account's subscription; the legacy status only applies to MAC/key devices.
  const isLegacy = (d: DeviceRow) => !d.account_id;
  if (filter === "trial") devices = devices.filter((d) => isLegacy(d) && d.status_legacy.is_trial);
  if (filter === "active") devices = devices.filter((d) => isLegacy(d) && d.status_legacy.activated);
  if (filter === "expired") devices = devices.filter((d) => isLegacy(d) && d.status_legacy.expired);
  if (filter === "account") devices = devices.filter((d) => !isLegacy(d));

  const all = (data ?? []) as DeviceRow[];
  const counts = {
    total: all.length,
    account: all.filter((d) => !isLegacy(d)).length,
    trial: all.filter((d) => isLegacy(d) && d.status_legacy.is_trial).length,
    active: all.filter((d) => isLegacy(d) && d.status_legacy.activated).length,
    expired: all.filter((d) => isLegacy(d) && d.status_legacy.expired).length,
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Appareils</h1>
        <div className="flex gap-2">
          <Link href="/admin/accounts" className="btn-secondary">Comptes</Link>
          <Link href="/admin/featured" className="btn-secondary">À la une</Link>
          <Link href="/admin/config" className="btn-secondary">Configuration de l&apos;app</Link>
          <form action={adminLogoutAction}><button className="btn-secondary">Déconnexion</button></form>
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-5">
        {(
          [
            ["", "Total", counts.total],
            ["account", "Liés à un compte", counts.account],
            ["trial", "Legacy · essai", counts.trial],
            ["active", "Legacy · activés", counts.active],
            ["expired", "Legacy · expirés", counts.expired],
          ] as const
        ).map(([f, label, n]) => (
          <Link key={label} href={f ? `/admin?f=${f}` : "/admin"} className={`card ${filter === f || (!filter && !f) ? "border-blue-700" : ""}`}>
            <p className="text-xs uppercase text-slate-400">{label}</p>
            <p className="text-2xl font-semibold">{n}</p>
          </Link>
        ))}
      </div>

      <form className="flex gap-2">
        <input name="q" className="input font-mono" placeholder="Rechercher une adresse MAC…" defaultValue={q} />
        <button className="btn-primary">Rechercher</button>
      </form>

      <div className="overflow-x-auto rounded-lg border border-slate-800">
        <table className="w-full text-sm">
          <thead className="bg-slate-900 text-left text-xs uppercase text-slate-400">
            <tr>
              <th className="px-3 py-2">Appareil</th>
              <th className="px-3 py-2">Compte</th>
              <th className="px-3 py-2">Type</th>
              <th className="px-3 py-2">Version</th>
              <th className="px-3 py-2">Playlists</th>
              <th className="px-3 py-2">Statut</th>
              <th className="px-3 py-2">Dernière activité</th>
            </tr>
          </thead>
          <tbody>
            {devices.map((d) => (
              <tr key={d.id} className="border-t border-slate-800 hover:bg-slate-900/60">
                <td className="px-3 py-2 font-mono">
                  <Link href={`/admin/devices/${d.id}`} className="text-blue-400 hover:underline">{d.name ?? d.mac ?? d.id.slice(0, 8)}</Link>
                  {d.name && d.mac && <span className="ml-2 text-xs text-slate-500">{d.mac}</span>}
                </td>
                <td className="px-3 py-2 text-xs">{d.account_email ?? <span className="text-slate-500">legacy</span>}</td>
                <td className="px-3 py-2">{d.device_type}{d.platform ? ` / ${d.platform}` : ""}</td>
                <td className="px-3 py-2">{d.app_version ?? "—"}</td>
                <td className="px-3 py-2">{d.playlist_count}</td>
                <td className="px-3 py-2">
                  {isLegacy(d) ? <StatusBadge status={d.status_legacy} /> : d.status === "active" ? <span className="badge border border-emerald-800 text-emerald-300">Connecté</span> : <span className="badge border border-slate-700 text-slate-400">Déconnecté</span>}
                </td>
                <td className="px-3 py-2 text-slate-400">{new Date(d.last_seen_at).toLocaleString("fr-FR")}</td>
              </tr>
            ))}
            {devices.length === 0 && (
              <tr><td colSpan={7} className="px-3 py-6 text-center text-slate-500">Aucun appareil.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
