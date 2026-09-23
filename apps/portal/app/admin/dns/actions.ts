"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { requireAdmin } from "@/lib/supabase";
import type { ActionState } from "@/lib/types";

async function admin() {
  const ctx = await requireAdmin();
  if (!ctx.isAdmin) redirect("/admin/login");
  return ctx.supabase;
}

async function nextPosition(supabase: Awaited<ReturnType<typeof admin>>): Promise<number> {
  const { data } = await supabase.from("dns_servers").select("position").order("position", { ascending: false }).limit(1);
  return ((data?.[0]?.position as number | undefined) ?? -1) + 1;
}

/** Comma/space/newline separated list of IPv4 or IPv6 literals. */
function parseAddresses(raw: FormDataEntryValue | null, { v6 }: { v6: boolean }): string[] | { error: string } {
  const parts = String(raw ?? "")
    .split(/[\s,]+/)
    .map((s) => s.trim())
    .filter(Boolean);
  const ipv4 = /^\d{1,3}(\.\d{1,3}){3}$/;
  const ipv6 = /^[0-9a-f:]+$/i;
  for (const p of parts) {
    if (v6 ? !ipv6.test(p) : !ipv4.test(p)) return { error: `Adresse ${v6 ? "IPv6" : "IPv4"} invalide : ${p}` };
  }
  return parts;
}

function optionalUrl(v: FormDataEntryValue | null): string | null | { error: string } {
  const s = String(v ?? "").trim();
  if (!s) return null;
  if (!/^https:\/\//i.test(s)) return { error: "L'URL DNS-over-HTTPS doit commencer par https://." };
  return s;
}

type DnsFields = {
  name: string;
  provider: string | null;
  ipv4: string[];
  ipv6: string[];
  doh_url: string | null;
  dot_host: string | null;
  notes: string | null;
};

function parseDnsFields(form: FormData): DnsFields | { error: string } {
  const name = String(form.get("name") ?? "").trim();
  if (!name) return { error: "Le nom est obligatoire." };
  const ipv4 = parseAddresses(form.get("ipv4"), { v6: false });
  if ("error" in ipv4) return ipv4;
  const ipv6 = parseAddresses(form.get("ipv6"), { v6: true });
  if ("error" in ipv6) return ipv6;
  if (ipv4.length === 0 && ipv6.length === 0) return { error: "Indiquez au moins une adresse IPv4 ou IPv6." };
  const doh = optionalUrl(form.get("doh_url"));
  if (doh && typeof doh === "object") return doh;
  return {
    name,
    provider: String(form.get("provider") ?? "").trim() || null,
    ipv4,
    ipv6,
    doh_url: doh,
    dot_host: String(form.get("dot_host") ?? "").trim() || null,
    notes: String(form.get("notes") ?? "").trim() || null,
  };
}

export async function addDnsServerAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await admin();
  const fields = parseDnsFields(form);
  if ("error" in fields) return fields;
  const { error } = await supabase.from("dns_servers").insert({ ...fields, position: await nextPosition(supabase) });
  if (error) return { error: error.message };
  revalidatePath("/admin/dns");
  return { ok: true };
}

export async function updateDnsServerAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await admin();
  const id = String(form.get("id") ?? "");
  if (!/^[0-9a-f-]{36}$/i.test(id)) return { error: "Identifiant invalide." };
  const fields = parseDnsFields(form);
  if ("error" in fields) return fields;
  const { error } = await supabase
    .from("dns_servers")
    .update({ ...fields, updated_at: new Date().toISOString() })
    .eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/admin/dns");
  return { ok: true };
}

export async function toggleDnsServerAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const { error } = await supabase
    .from("dns_servers")
    .update({ enabled: form.get("enabled") === "true", updated_at: new Date().toISOString() })
    .eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/admin/dns");
}

export async function setDefaultDnsServerAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const id = String(form.get("id"));
  // The partial unique index only allows one `is_default = true` row; clear the others first.
  const { error: clearError } = await supabase.from("dns_servers").update({ is_default: false }).eq("is_default", true);
  if (clearError) throw new Error(clearError.message);
  const { error } = await supabase.from("dns_servers").update({ is_default: true, enabled: true }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/admin/dns");
}

export async function deleteDnsServerAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const { error } = await supabase.from("dns_servers").delete().eq("id", String(form.get("id")));
  if (error) throw new Error(error.message);
  revalidatePath("/admin/dns");
}

export async function moveDnsServerAction(form: FormData): Promise<void> {
  const supabase = await admin();
  const id = String(form.get("id"));
  const dir = String(form.get("dir")) === "up" ? -1 : 1;
  const { data, error } = await supabase.from("dns_servers").select("id, position").order("position", { ascending: true });
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as { id: string; position: number }[];
  const i = rows.findIndex((r) => r.id === id);
  const j = i + dir;
  if (i < 0 || j < 0 || j >= rows.length) return;
  const order = rows.map((r) => r.id);
  [order[i], order[j]] = [order[j], order[i]];
  for (const [pos, rowId] of order.entries()) {
    const { error: e } = await supabase.from("dns_servers").update({ position: pos }).eq("id", rowId);
    if (e) throw new Error(e.message);
  }
  revalidatePath("/admin/dns");
}
