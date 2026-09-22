import { redirect } from "next/navigation";
import { requireUser } from "@/lib/supabase";
import { deleteDeviceAction, renameDeviceAction, revokeDeviceAction } from "./actions";
import { type AccountStatus, fmtDateTime } from "./layout";

type Device = {
  id: string;
  name: string | null;
  device_type: string;
  platform: string | null;
  manufacturer: string | null;
  model: string | null;
  os: string | null;
  os_version: string | null;
  app_version: string | null;
  status: "active" | "revoked";
  last_seen_at: string;
  created_at: string;
  mac: string | null;
};

const typeLabel: Record<string, string> = { tv: "Téléviseur", tablet: "Tablette", mobile: "Téléphone" };

export default async function DevicesPage({ searchParams }: PageProps<"/account">) {
  const { supabase, user } = await requireUser();
  if (!user) redirect("/login?next=/account");
  const justPaired = (await searchParams).paired === "1";
  const [{ data: devices, error }, { data: overview }] = await Promise.all([
    supabase.from("devices").select("id, name, device_type, platform, manufacturer, model, os, os_version, app_version, status, last_seen_at, created_at, mac").eq("account_id", user.id).order("last_seen_at", { ascending: false }),
    supabase.from("accounts_overview").select("status").eq("id", user.id).maybeSingle(),
  ]);
  if (error) throw new Error(error.message);
  const list = (devices ?? []) as Device[];
  const active = list.filter((d) => d.status === "active").length;
  const max = (overview?.status as AccountStatus | undefined)?.max_devices ?? 0;

  return (
    <div className="space-y-4">
      {justPaired && (
        <div className="notice-success">
          <span className="text-lg">✓</span>
          <div>
            <p className="font-medium">Appareil connecté</p>
            <p className="text-sm opacity-80">Votre écran charge vos profils et vos listes de lecture.</p>
          </div>
        </div>
      )}
      <p className="text-sm text-white/60">
        {active} appareil{active > 1 ? "s" : ""} connecté{active > 1 ? "s" : ""} sur {max}. Un appareil déconnecté ne peut plus accéder à vos listes tant qu&apos;il n&apos;est pas reconnecté.
      </p>
      {list.length === 0 && (
        <div className="card text-sm text-slate-300">
          Aucun appareil pour l&apos;instant. Ouvrez l&apos;application sur votre téléviseur ou téléphone, puis scannez le QR code ou saisissez le code affiché dans « Ajouter un appareil ».
        </div>
      )}
      <ul className="grid gap-3 md:grid-cols-2">
        {list.map((d) => (
          <li key={d.id} className={`card space-y-3 ${d.status === "revoked" ? "opacity-60" : ""}`}>
            <form action={renameDeviceAction} className="flex items-center gap-2">
              <input type="hidden" name="id" value={d.id} />
              <input name="name" className="input flex-1 font-medium" defaultValue={d.name ?? ""} placeholder={`${typeLabel[d.device_type] ?? d.device_type} sans nom`} maxLength={60} />
              <button className="btn-secondary !px-3 !py-2 text-xs">Renommer</button>
            </form>
            <dl className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-slate-400">
              <dt>Type</dt><dd className="text-slate-200">{typeLabel[d.device_type] ?? d.device_type}{d.manufacturer || d.model ? ` · ${[d.manufacturer, d.model].filter(Boolean).join(" ")}` : ""}</dd>
              <dt>Plateforme</dt><dd className="text-slate-200">{[d.os ?? d.platform, d.os_version].filter(Boolean).join(" ") || "—"}</dd>
              <dt>Application</dt><dd className="text-slate-200">{d.app_version ?? "—"}</dd>
              <dt>Dernière activité</dt><dd className="text-slate-200">{fmtDateTime.format(new Date(d.last_seen_at))}</dd>
              <dt>Statut</dt>
              <dd>{d.status === "active" ? <span className="badge border border-emerald-800 text-emerald-300">Connecté</span> : <span className="badge border border-slate-700 text-slate-400">Déconnecté</span>}</dd>
            </dl>
            <div className="flex justify-end gap-2">
              {d.status === "active" && (
                <form action={revokeDeviceAction}>
                  <input type="hidden" name="id" value={d.id} />
                  <button className="btn-secondary !py-1 text-xs">Déconnecter</button>
                </form>
              )}
              <form action={deleteDeviceAction}>
                <input type="hidden" name="id" value={d.id} />
                <button className="btn-danger !py-1 text-xs">Supprimer</button>
              </form>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
