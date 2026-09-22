import Link from "next/link";
import { redirect } from "next/navigation";
import { requireUser } from "@/lib/supabase";
import { logoutAction } from "../(auth)/actions";

export type AccountStatus = {
  plan: string;
  plan_name: string;
  max_devices: number;
  max_profiles: number;
  max_playlists: number;
  activated: boolean;
  is_trial: boolean;
  expired: boolean;
  trial_ends_at: string | null;
  expires_at: string | null;
};

const tabs = [
  { href: "/account", label: "Appareils" },
  { href: "/account/profiles", label: "Profils" },
  { href: "/account/playlists", label: "Listes de lecture" },
  { href: "/account/add-device", label: "Ajouter un appareil" },
];

export const fmtDate = new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium", timeZone: "Europe/Paris" });
export const fmtDateTime = new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium", timeStyle: "short", timeZone: "Europe/Paris" });

export function statusLine(s: AccountStatus): { text: string; tone: string } {
  if (s.expired) return { text: "Abonnement expiré", tone: "border-red-800 text-red-300" };
  if (s.activated) return { text: s.expires_at ? `${s.plan_name} · jusqu'au ${fmtDate.format(new Date(s.expires_at))}` : `${s.plan_name} · sans expiration`, tone: "border-emerald-800 text-emerald-300" };
  return { text: s.trial_ends_at ? `Essai gratuit · jusqu'au ${fmtDate.format(new Date(s.trial_ends_at))}` : "Essai gratuit", tone: "border-amber-800 text-amber-300" };
}

export default async function AccountLayout({ children }: LayoutProps<"/account">) {
  const { supabase, user } = await requireUser();
  if (!user) redirect("/login?next=/account");
  const { data } = await supabase.from("accounts_overview").select("status").eq("id", user.id).maybeSingle();
  const status = data?.status as AccountStatus | undefined;
  const line = status ? statusLine(status) : null;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Mon compte</h1>
          <p className="text-sm text-slate-400">{user.email}</p>
        </div>
        <div className="flex items-center gap-3">
          {line && <span className={`badge border ${line.tone}`}>{line.text}</span>}
          <form action={logoutAction}>
            <button className="btn-secondary !py-1 text-xs">Déconnexion</button>
          </form>
        </div>
      </div>
      <nav className="flex flex-wrap gap-2 border-b border-slate-800 pb-3 text-sm">
        {tabs.map((t) => (
          <Link key={t.href} href={t.href} className="rounded-md px-3 py-1.5 text-slate-300 hover:bg-slate-900 hover:text-white">
            {t.label}
          </Link>
        ))}
      </nav>
      {children}
    </div>
  );
}
