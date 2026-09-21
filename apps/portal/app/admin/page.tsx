import Link from "next/link";
import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import { StatusBadge } from "@/components/status-badge";
import type { DeviceStatus } from "@/lib/api";
import { adminLogoutAction } from "./actions";

type DeviceRow = {
  id: string;
  mac: string;
  device_key: string;
  device_type: string;
  platform: string | null;
  app_version: string | null;
  last_seen_at: string;
  created_at: string;
  status: DeviceStatus;
  playlist_count: number;
};

export default async function AdminPage({ searchParams }: PageProps<"/admin">) {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");

  const params = await searchParams;
  const q = (Array.isArray(params.q) ? params.q[0] : params.q ?? "").trim();
  const filter = Array.isArray(params.f) ? params.f[0] : params.f;

  let query = supabase.from("devices_with_status").select("*").order("last_seen_at", { ascending: false }).limit(200);
  if (q) query = query.ilike("mac", `%${q.replace(/-/g, ":").toUpperCase()}%`);
  const { data, error } = await query;
  if (error) throw new Error(error.message);

  let devices = (data ?? []) as DeviceRow[];
  if (filter === "trial") devices = devices.filter((d) => d.status.is_trial);
  if (filter === "active") devices = devices.filter((d) => d.status.activated);
  if (filter === "expired") devices = devices.filter((d) => d.status.expired);

  const counts = {
    total: (data ?? []).length,
    trial: (data as DeviceRow[] | null)?.filter((d) => d.status.is_trial).length ?? 0,
    active: (data as DeviceRow[] | null)?.filter((d) => d.status.activated).length ?? 0,
    expired: (data as DeviceRow[] | null)?.filter((d) => d.status.expired).length ?? 0,
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Appareils</h1>
        <div className="flex gap-2">
          <Link href="/admin/config" className="btn-secondary">Configuration de l&apos;app</Link>
          <form action={adminLogoutAction}><button className="btn-secondary">Déconnexion</button></form>
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-4">
        {(
          [
            ["", "Total", counts.total],
            ["trial", "En essai", counts.trial],
            ["active", "Activés", counts.active],
            ["expired", "Expirés", counts.expired],
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
              <th className="px-3 py-2">MAC</th>
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
                <td className="px-3 py-2 font-mono"><Link href={`/admin/devices/${d.id}`} className="text-blue-400 hover:underline">{d.mac}</Link></td>
                <td className="px-3 py-2">{d.device_type}{d.platform ? ` / ${d.platform}` : ""}</td>
                <td className="px-3 py-2">{d.app_version ?? "—"}</td>
                <td className="px-3 py-2">{d.playlist_count}</td>
                <td className="px-3 py-2"><StatusBadge status={d.status} /></td>
                <td className="px-3 py-2 text-slate-400">{new Date(d.last_seen_at).toLocaleString("fr-FR")}</td>
              </tr>
            ))}
            {devices.length === 0 && (
              <tr><td colSpan={6} className="px-3 py-6 text-center text-slate-500">Aucun appareil.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
