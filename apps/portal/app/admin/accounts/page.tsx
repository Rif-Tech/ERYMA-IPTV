import Link from "next/link";
import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import { type AccountOverview, SubscriptionBadge } from "./shared";

export default async function AccountsPage({ searchParams }: PageProps<"/admin/accounts">) {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");
  const params = await searchParams;
  const q = (Array.isArray(params.q) ? params.q[0] : params.q ?? "").trim().replace(/[^\w@.+-]/g, "");

  let query = supabase.from("accounts_overview").select("*").order("created_at", { ascending: false }).limit(200);
  if (q) query = query.ilike("email", `%${q}%`);
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  const accounts = (data ?? []) as AccountOverview[];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Comptes ({accounts.length})</h1>
        <Link href="/admin" className="btn-secondary">Appareils</Link>
      </div>
      <form className="flex gap-2">
        <input name="q" className="input" placeholder="Rechercher un e-mail…" defaultValue={q} />
        <button className="btn-primary">Rechercher</button>
      </form>
      <div className="overflow-x-auto rounded-lg border border-slate-800">
        <table className="w-full text-sm">
          <thead className="bg-slate-900 text-left text-xs uppercase text-slate-400">
            <tr>
              <th className="px-3 py-2">E-mail</th>
              <th className="px-3 py-2">Abonnement</th>
              <th className="px-3 py-2">Expire</th>
              <th className="px-3 py-2">Appareils</th>
              <th className="px-3 py-2">Listes</th>
              <th className="px-3 py-2">Profils</th>
              <th className="px-3 py-2">Créé le</th>
            </tr>
          </thead>
          <tbody>
            {accounts.map((a) => (
              <tr key={a.id} className="border-t border-slate-800 hover:bg-slate-900/60">
                <td className="px-3 py-2">
                  <Link href={`/admin/accounts/${a.id}`} className="text-blue-400 hover:underline">{a.email ?? a.id}</Link>
                  {a.role === "admin" && <span className="badge ml-2 border border-blue-800 text-blue-300">admin</span>}
                </td>
                <td className="px-3 py-2"><SubscriptionBadge s={a.status} /></td>
                <td className="px-3 py-2 text-slate-400">{a.status.expires_at ? new Date(a.status.expires_at).toLocaleDateString("fr-FR") : a.status.trial_ends_at ? `essai → ${new Date(a.status.trial_ends_at).toLocaleDateString("fr-FR")}` : "—"}</td>
                <td className="px-3 py-2">{a.device_count} / {a.status.max_devices}</td>
                <td className="px-3 py-2">{a.playlist_count} / {a.status.max_playlists}</td>
                <td className="px-3 py-2">{a.profile_count} / {a.status.max_profiles}</td>
                <td className="px-3 py-2 text-slate-400">{new Date(a.created_at).toLocaleDateString("fr-FR")}</td>
              </tr>
            ))}
            {accounts.length === 0 && <tr><td colSpan={7} className="px-3 py-6 text-center text-slate-500">Aucun compte.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
