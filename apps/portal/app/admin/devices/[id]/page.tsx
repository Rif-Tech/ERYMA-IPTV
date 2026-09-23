import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import type { Playlist } from "@/lib/types";
import { deleteDeviceAction, deletePlaylistAdminAction, saveNoteAction } from "../../actions";

export default async function DevicePage({ params }: PageProps<"/admin/devices/[id]">) {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");
  const { id } = await params;

  const { data: device } = await supabase.from("devices_with_status").select("*").eq("id", id).maybeSingle();
  if (!device) notFound();
  const paired = Boolean(device.account_id);
  const playlists = paired
    ? ((await supabase.from("playlists").select("*").eq("account_id", device.account_id).order("position")).data ?? []) as Playlist[]
    : [];

  return (
    <div className="space-y-6">
      <Link href="/admin" className="text-sm text-blue-400 hover:underline">← Appareils</Link>

      <div className="card space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-2xl">{device.name ?? device.id}</p>
            <p className="text-sm text-slate-400">
              {device.device_type}
              {device.platform ? ` / ${device.platform}` : ""} · v{device.app_version ?? "?"}
              {device.manufacturer || device.model ? ` · ${[device.manufacturer, device.model].filter(Boolean).join(" ")}` : ""}
              {device.os ? ` · ${device.os} ${device.os_version ?? ""}` : ""}
            </p>
            <p className="font-mono text-xs text-slate-500">Identifiant : {device.device_uuid ?? device.id}</p>
            {paired ? (
              <p className="text-sm text-slate-300">
                Compte : <Link href={`/admin/accounts/${device.account_id}`} className="text-blue-400 hover:underline">{device.account_email ?? device.account_id}</Link>
                {" · "}
                {device.status === "active" ? <span className="text-emerald-300">connecté</span> : <span className="text-slate-400">déconnecté</span>}
              </p>
            ) : (
              <p className="text-sm text-slate-400">Pas encore appairé à un compte.</p>
            )}
            <p className="text-xs text-slate-500">
              Enregistré le {new Date(device.created_at).toLocaleString("fr-FR")} · dernière activité {new Date(device.last_seen_at).toLocaleString("fr-FR")}
            </p>
          </div>
          {paired && device.status === "active" ? (
            <span className="badge border border-emerald-800 text-emerald-300">Connecté</span>
          ) : (
            <span className="badge border border-slate-700 text-slate-400">{paired ? "Déconnecté" : "En attente"}</span>
          )}
        </div>

        <div className="space-y-3 rounded-md border border-slate-800 p-4 text-sm text-slate-300">
          <p>L&apos;abonnement, les listes et les profils se gèrent au niveau du compte.</p>
          <div className="flex flex-wrap gap-2">
            <form action={saveNoteAction} className="flex flex-1 gap-2">
              <input type="hidden" name="id" value={device.id} />
              <input name="note" className="input" placeholder="Note interne" defaultValue={device.note ?? ""} maxLength={500} />
              <button className="btn-secondary">OK</button>
            </form>
            <form action={deleteDeviceAction}>
              <input type="hidden" name="id" value={device.id} />
              <button className="btn-danger">Supprimer l&apos;appareil</button>
            </form>
          </div>
        </div>
      </div>

      {paired && (
        <div className="space-y-3">
          <h2 className="text-xl font-semibold">Playlists du compte ({playlists.length})</h2>
          {playlists.map((p) => (
            <div key={p.id} className="card flex flex-wrap items-center justify-between gap-3">
              <div className="min-w-0">
                <p className="font-medium">
                  <span className={`badge mr-2 ${p.type === "xtream" ? "bg-violet-900 text-violet-100" : "bg-emerald-900 text-emerald-100"}`}>{p.type}</span>
                  {p.name}
                </p>
                <p className="truncate font-mono text-xs text-slate-400">{p.url}{p.username ? ` · ${p.username}` : ""}</p>
              </div>
              <form action={deletePlaylistAdminAction}>
                <input type="hidden" name="id" value={p.id} />
                <input type="hidden" name="device_id" value={device.id} />
                <button className="btn-danger">Supprimer</button>
              </form>
            </div>
          ))}
          {playlists.length === 0 && <p className="text-slate-500">Aucune playlist.</p>}
        </div>
      )}
    </div>
  );
}
