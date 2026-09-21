import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import { StatusBadge } from "@/components/status-badge";
import type { DeviceStatus, Playlist } from "@/lib/api";
import { deleteDeviceAction, deletePlaylistAdminAction, extendTrialAction, saveNoteAction, setActivationAction } from "../../actions";

export default async function DevicePage({ params }: PageProps<"/admin/devices/[id]">) {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");
  const { id } = await params;

  const [{ data: device }, { data: playlists }] = await Promise.all([
    supabase.from("devices_with_status").select("*").eq("id", id).maybeSingle(),
    supabase.from("playlists").select("*").eq("device_id", id).order("position"),
  ]);
  if (!device) notFound();
  const status = device.status as DeviceStatus;
  const expires = device.expires_at ? String(device.expires_at).slice(0, 10) : "";

  return (
    <div className="space-y-6">
      <Link href="/admin" className="text-sm text-blue-400 hover:underline">← Appareils</Link>

      <div className="card space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="font-mono text-2xl">{device.mac}</p>
            <p className="text-sm text-slate-400">
              Clé : <span className="font-mono">{device.device_key}</span> · {device.device_type}
              {device.platform ? ` / ${device.platform}` : ""} · v{device.app_version ?? "?"}
            </p>
            <p className="text-xs text-slate-500">
              Enregistré le {new Date(device.created_at).toLocaleString("fr-FR")} · dernière activité {new Date(device.last_seen_at).toLocaleString("fr-FR")}
            </p>
          </div>
          <StatusBadge status={status} />
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <form action={setActivationAction} className="space-y-2 rounded-md border border-slate-800 p-4">
            <input type="hidden" name="id" value={device.id} />
            <input type="hidden" name="mode" value="activate" />
            <p className="font-medium">Activer l&apos;appareil</p>
            <div>
              <label className="label" htmlFor="expires_at">Expiration (vide = illimité)</label>
              <input id="expires_at" name="expires_at" type="date" className="input" defaultValue={expires} />
            </div>
            <button className="btn-primary">{device.activated ? "Mettre à jour l'activation" : "Activer"}</button>
          </form>

          <div className="space-y-2 rounded-md border border-slate-800 p-4">
            <p className="font-medium">Autres actions</p>
            <div className="flex flex-wrap gap-2">
              <form action={setActivationAction}>
                <input type="hidden" name="id" value={device.id} />
                <input type="hidden" name="mode" value="deactivate" />
                <button className="btn-secondary" disabled={!device.activated}>Désactiver</button>
              </form>
              <form action={extendTrialAction}>
                <input type="hidden" name="id" value={device.id} />
                <button className="btn-secondary">Relancer l&apos;essai</button>
              </form>
              <form action={deleteDeviceAction}>
                <input type="hidden" name="id" value={device.id} />
                <button className="btn-danger">Supprimer l&apos;appareil</button>
              </form>
            </div>
            <form action={saveNoteAction} className="flex gap-2 pt-2">
              <input type="hidden" name="id" value={device.id} />
              <input name="note" className="input" placeholder="Note interne" defaultValue={device.note ?? ""} maxLength={500} />
              <button className="btn-secondary">OK</button>
            </form>
          </div>
        </div>
      </div>

      <div className="space-y-3">
        <h2 className="text-xl font-semibold">Playlists ({playlists?.length ?? 0})</h2>
        {(playlists as Playlist[] | null)?.map((p) => (
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
        {(playlists?.length ?? 0) === 0 && <p className="text-slate-500">Aucune playlist.</p>}
      </div>
    </div>
  );
}
