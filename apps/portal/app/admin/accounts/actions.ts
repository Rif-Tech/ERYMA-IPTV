"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { requireAdmin } from "@/lib/supabase";

const PLANS = new Set(["trial", "standard"]);
const STATUSES = new Set(["trial", "active", "expired", "cancelled"]);

async function admin() {
  const ctx = await requireAdmin();
  if (!ctx.isAdmin) redirect("/admin/login");
  return ctx.supabase;
}

/** Admin-only: set plan, status and expiry for an account's subscription. */
export async function updateSubscriptionAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const accountId = String(form.get("account_id"));
  const plan = String(form.get("plan_id") ?? "");
  const status = String(form.get("status") ?? "");
  const expires = String(form.get("expires_at") ?? "").trim();
  if (!PLANS.has(plan) || !STATUSES.has(status)) throw new Error("Plan ou statut invalide.");
  const patch = {
    account_id: accountId,
    plan_id: plan,
    status,
    expires_at: expires ? new Date(`${expires}T23:59:59`).toISOString() : null,
    note: String(form.get("note") ?? "").slice(0, 500) || null,
  };
  const { error } = await supabase.from("subscriptions").upsert(patch, { onConflict: "account_id" });
  if (error) throw new Error(error.message);
  revalidatePath(`/admin/accounts/${accountId}`);
  revalidatePath("/admin/accounts");
}

/** Admin-only: revoke every device of an account (forces re-pairing). */
export async function revokeAllDevicesAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const accountId = String(form.get("account_id"));
  const { error } = await supabase
    .from("devices")
    .update({ status: "revoked", revoked_at: new Date().toISOString(), secret_hash: null })
    .eq("account_id", accountId);
  if (error) throw new Error(error.message);
  revalidatePath(`/admin/accounts/${accountId}`);
}
