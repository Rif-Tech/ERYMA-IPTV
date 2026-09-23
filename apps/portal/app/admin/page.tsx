import Link from "next/link";
import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import { adminLogoutAction } from "./actions";

type DeviceRow = {
  id: string;
  device_type: string;
  platform: string | null;
  app_version: string | null;
  last_seen_at: string;
  created_at: string;
  status: "active" | "revoked";
  name: string | null;
  account_id: string | null;
  account_email: string | null;
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
    const safe = q.replace(/[^\w@.+-]/g, "");
    if (safe) query = query.or(`account_email.ilike.%${safe}%,name.ilike.%${safe}%,model.ilike.%${safe}%`);
  }
  const { data, error } = await query;
  if (error) throw new Error(error.message);

  const all = (data ?? []) as DeviceRow[];
  let devices = all;
  if (filter === "active") devices = all.filter((d) => d.account_id && d.status === "active");
  if (filter === "revoked") devices = all.filter((d) => d.account_id && d.status !== "active");
  if (filter === "pending") devices = all.filter((d) => !d.account_id);

  const counts = {
    total: all.length,
    active: all.filter((d) => d.account_id && d.status === "active").length,
    revoked: all.filter((d) => d.account_id && d.status !== "active").length,
    pending: all.filter((d) => !d.account_id).length,
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Appareils</h1>
        <div className="flex gap-2">
          <Link href="/admin/accounts" className="btn-secondary">Comptes</Link>
          <Link href="/admin/featured" className="btn-secondary">À la une</Link>
          <Link href="/admin/dns" className="btn-secondary">DNS</Link>
          <Link href="/admin/config" className="btn-secondary">Configuration de l&apos;app</Link>
          <form action={adminLogoutAction}><button className="btn-secondary">Déconnexion</button></form>
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-4">
        {(
          [
            ["", "Total", counts.total],
            ["active", "Connectés", counts.active],
            ["revoked", "Déconnectés", counts.revoked],
            ["pending", "En attente d'appairage", counts.pending],
          ] as const
        ).map(([f, label, n]) => (
          <Link key={label} href={f ? `/admin?f=${f}` : "/admin"} className={`card ${filter === f || (!filter && !f) ? "border-blue-700" : ""}`}>
            <p className="text-xs uppercase text-slate-400">{label}</p>
            <p className="text-2xl font-semibold">{n}</p>
          </Link>
        ))}
      </div>

      <form className="flex gap-2">
        <input name="q" className="input" placeholder="Rechercher un compte, un nom ou un modèle…" defaultValue={q} />
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
              <th className="px-3 py-2">Statut</th>
              <th className="px-3 py-2">Dernière activité</th>
            </tr>
          </thead>
          <tbody>
            {devices.map((d) => (
              <tr key={d.id} className="border-t border-slate-800 hover:bg-slate-900/60">
                <td className="px-3 py-2">
                  <Link href={`/admin/devices/${d.id}`} className="text-blue-400 hover:underline">{d.name ?? d.id.slice(0, 8)}</Link>
                </td>
                <td className="px-3 py-2 text-xs">
                  {d.account_id ? (
                    <Link href={`/admin/accounts/${d.account_id}`} className="hover:underline">{d.account_email ?? d.account_id.slice(0, 8)}</Link>
                  ) : (
                    <span className="text-slate-500">non appairé</span>
                  )}
                </td>
                <td className="px-3 py-2">{d.device_type}{d.platform ? ` / ${d.platform}` : ""}</td>
                <td className="px-3 py-2">{d.app_version ?? "—"}</td>
                <td className="px-3 py-2">
                  {d.account_id && d.status === "active" ? (
                    <span className="badge border border-emerald-800 text-emerald-300">Connecté</span>
                  ) : (
                    <span className="badge border border-slate-700 text-slate-400">{d.account_id ? "Déconnecté" : "En attente"}</span>
                  )}
                </td>
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
