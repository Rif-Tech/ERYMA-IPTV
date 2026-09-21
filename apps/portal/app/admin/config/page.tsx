import Link from "next/link";
import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/supabase";
import { ConfigForm, type AppConfigValues } from "./config-form";

export default async function ConfigPage() {
  const { supabase, isAdmin } = await requireAdmin();
  if (!isAdmin) redirect("/admin/login");

  const { data } = await supabase.from("app_config").select("key, value");
  const cfg: Record<string, unknown> = {};
  for (const row of data ?? []) cfg[row.key] = row.value;
  const str = (v: unknown) => (v === null || v === undefined ? "" : String(v));

  const values: AppConfigValues = {
    app_status: str(cfg.app_status) || "ok",
    message: str(cfg.message),
    min_version: str(cfg.min_version),
    latest_version: str(cfg.latest_version),
    apk_link: str(cfg.apk_link),
    trial_days: Number(cfg.trial_days ?? 7),
  };

  return (
    <div className="space-y-6">
      <Link href="/admin" className="text-sm text-blue-400 hover:underline">← Appareils</Link>
      <h1 className="text-2xl font-semibold">Configuration de l&apos;application</h1>
      <ConfigForm values={values} />
    </div>
  );
}
