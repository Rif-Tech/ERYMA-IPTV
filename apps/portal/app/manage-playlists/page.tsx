import { redirect } from "next/navigation";
import { api, ApiError } from "@/lib/api";
import { clearPortalToken, getPortalToken } from "@/lib/session";
import { StatusBadge } from "@/components/status-badge";
import { logoutAction } from "./actions";
import { PlaylistList } from "./playlist-list";

export default async function ManagePlaylistsPage() {
  const token = await getPortalToken();
  if (!token) redirect("/manage-playlists/login");

  let data;
  try {
    data = await api.playlists(token);
  } catch (e) {
    if (e instanceof ApiError && e.status === 401) {
      await clearPortalToken();
      redirect("/manage-playlists/login");
    }
    throw e;
  }

  const { device, status, playlists } = data;
  return (
    <div className="space-y-6">
      <div className="card flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-xs uppercase tracking-wide text-slate-400">Appareil</p>
          <p className="font-mono text-lg">{device.mac}</p>
          <p className="text-xs text-slate-500">
            {device.device_type}
            {device.platform ? ` · ${device.platform}` : ""}
            {device.app_version ? ` · v${device.app_version}` : ""}
            {device.last_seen_at ? ` · vu le ${new Date(device.last_seen_at).toLocaleString("fr-FR")}` : ""}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <StatusBadge status={status} />
          <form action={logoutAction}>
            <button className="btn-secondary">Déconnexion</button>
          </form>
        </div>
      </div>

      {status.expired && (
        <p className="rounded-md border border-red-900 bg-red-950/60 px-4 py-3 text-sm text-red-100">
          L&apos;appareil n&apos;est plus actif : les playlists restent modifiables ici mais ne seront pas chargées par l&apos;application
          tant que l&apos;activation n&apos;a pas été renouvelée par l&apos;administrateur.
        </p>
      )}

      <PlaylistList playlists={playlists} />
    </div>
  );
}
