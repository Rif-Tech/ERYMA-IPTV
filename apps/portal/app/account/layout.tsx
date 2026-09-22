import { redirect } from "next/navigation";
import { requireUser } from "@/lib/supabase";
import { logoutAction } from "../(auth)/actions";
import { AccountTabs } from "./account-tabs";

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

export const fmtDate = new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium", timeZone: "Europe/Paris" });
export const fmtDateTime = new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium", timeStyle: "short", timeZone: "Europe/Paris" });

export function statusLine(s: AccountStatus): { text: string; tone: string } {
  if (s.expired) return { text: "Abonnement expiré", tone: "!bg-red-500/15 !text-red-200 !ring-red-400/30" };
  if (s.activated) return { text: s.expires_at ? `${s.plan_name} · jusqu'au ${fmtDate.format(new Date(s.expires_at))}` : `${s.plan_name} · sans expiration`, tone: "!bg-emerald-500/15 !text-emerald-200 !ring-emerald-400/30" };
  return { text: s.trial_ends_at ? `Essai gratuit · jusqu'au ${fmtDate.format(new Date(s.trial_ends_at))}` : "Essai gratuit", tone: "!bg-amber-500/15 !text-amber-200 !ring-amber-400/30" };
}

export default async function AccountLayout({ children }: LayoutProps<"/account">) {
  const { supabase, user } = await requireUser();
  if (!user) redirect("/login?next=/account");
  const { data } = await supabase.from("accounts_overview").select("status").eq("id", user.id).maybeSingle();
  const status = data?.status as AccountStatus | undefined;
  const line = status ? statusLine(status) : null;
  const initial = (user.email ?? "?").trim().charAt(0).toUpperCase();

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <span className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-[#6fb2ff] to-[#0a84ff] text-xl font-bold text-black shadow-[0_10px_30px_rgba(10,132,255,0.35)]" aria-hidden>
            {initial}
          </span>
          <div>
            <h1 className="page-title">Mon compte</h1>
            <p className="text-sm muted">{user.email}</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          {line && <span className={`badge ${line.tone}`}>{line.text}</span>}
          <form action={logoutAction}>
            <button className="btn-secondary !px-3.5 !py-1.5 text-xs">Déconnexion</button>
          </form>
        </div>
      </div>
      <AccountTabs />
      {children}
    </div>
  );
}
