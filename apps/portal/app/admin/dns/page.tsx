import Link from "next/link";
import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import { deleteDnsServerAction, moveDnsServerAction, setDefaultDnsServerAction, toggleDnsServerAction } from "./actions";
import { AddDnsServerForm, EditDnsServerButton } from "./dns-forms";
import type { DnsServerRow } from "./types";

export default async function DnsServersPage() {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");

  const { data, error } = await supabase.from("dns_servers").select("*").order("position", { ascending: true });
  if (error) throw new Error(error.message);
  const items = (data ?? []) as DnsServerRow[];

  return (
    <div className="space-y-6">
      <Link href="/admin" className="text-sm text-blue-400 hover:underline">← Appareils</Link>
      <div>
        <h1 className="text-2xl font-semibold">Serveurs DNS</h1>
        <p className="text-sm text-slate-400">
          Diffusés à l&apos;application via <code>/app-info</code> ; l&apos;utilisateur choisit un DNS pour charger sa liste de
          lecture et ses flux sans configurer son appareil ou sa box.
        </p>
      </div>

      <div className="overflow-x-auto rounded-lg border border-slate-800">
        <table className="w-full text-sm">
          <thead className="bg-slate-900 text-left text-xs uppercase text-slate-400">
            <tr>
              <th className="px-3 py-2">#</th>
              <th className="px-3 py-2">Nom</th>
              <th className="px-3 py-2">Adresses</th>
              <th className="px-3 py-2">DoH / DoT</th>
              <th className="px-3 py-2">Défaut</th>
              <th className="px-3 py-2">Statut</th>
              <th className="px-3 py-2 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.length === 0 && (
              <tr>
                <td colSpan={7} className="px-3 py-6 text-center text-slate-500">Aucun serveur DNS configuré.</td>
              </tr>
            )}
            {items.map((it, i) => (
              <tr key={it.id} className={`border-t border-slate-800 ${it.enabled ? "" : "opacity-50"}`}>
                <td className="px-3 py-2 text-slate-500">{i + 1}</td>
                <td className="px-3 py-2">
                  <p className="font-medium">{it.name}</p>
                  {it.provider && <p className="text-xs text-slate-400">{it.provider}</p>}
                </td>
                <td className="px-3 py-2 text-xs text-slate-400">
                  {it.ipv4.length > 0 && <p>IPv4 : {it.ipv4.join(", ")}</p>}
                  {it.ipv6.length > 0 && <p>IPv6 : {it.ipv6.join(", ")}</p>}
                </td>
                <td className="px-3 py-2 text-xs text-slate-400">
                  {it.doh_url && <p>DoH : {it.doh_url}</p>}
                  {it.dot_host && <p>DoT : {it.dot_host}</p>}
                </td>
                <td className="px-3 py-2">
                  {it.is_default ? (
                    <span className="badge border-emerald-800 text-emerald-300">Défaut</span>
                  ) : (
                    <form action={setDefaultDnsServerAction}>
                      <input type="hidden" name="id" value={it.id} />
                      <button className="btn-secondary !px-2 !py-1">Définir</button>
                    </form>
                  )}
                </td>
                <td className="px-3 py-2">
                  <form action={toggleDnsServerAction}>
                    <input type="hidden" name="id" value={it.id} />
                    <input type="hidden" name="enabled" value={it.enabled ? "false" : "true"} />
                    <button className={`badge ${it.enabled ? "border-emerald-800 text-emerald-300" : ""}`}>{it.enabled ? "Actif" : "Désactivé"}</button>
                  </form>
                </td>
                <td className="px-3 py-2">
                  <div className="flex justify-end gap-1">
                    <EditDnsServerButton item={it} />
                    <form action={moveDnsServerAction}>
                      <input type="hidden" name="id" value={it.id} />
                      <input type="hidden" name="dir" value="up" />
                      <button className="btn-secondary !px-2 !py-1" disabled={i === 0} aria-label="Monter">↑</button>
                    </form>
                    <form action={moveDnsServerAction}>
                      <input type="hidden" name="id" value={it.id} />
                      <input type="hidden" name="dir" value="down" />
                      <button className="btn-secondary !px-2 !py-1" disabled={i === items.length - 1} aria-label="Descendre">↓</button>
                    </form>
                    <form action={deleteDnsServerAction}>
                      <input type="hidden" name="id" value={it.id} />
                      <button className="btn-danger !px-2 !py-1" disabled={it.is_default}>Supprimer</button>
                    </form>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <AddDnsServerForm />
    </div>
  );
}
