"use server";

import { redirect } from "next/navigation";
import { headers } from "next/headers";
import { createSupabaseServer } from "@/lib/supabase";
import type { ActionState } from "@/lib/types";

/** Only relative paths are accepted as post-login destinations (no open redirect). */
function safeNext(raw: unknown): string {
  const s = String(raw ?? "");
  return s.startsWith("/") && !s.startsWith("//") ? s : "/account";
}

async function siteUrl(): Promise<string> {
  const h = await headers();
  const proto = h.get("x-forwarded-proto") ?? "http";
  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";
  return `${proto}://${host}`;
}

export async function loginAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const supabase = await createSupabaseServer();
  const { error } = await supabase.auth.signInWithPassword({
    email: String(form.get("email") ?? "").trim(),
    password: String(form.get("password") ?? ""),
  });
  if (error) {
    return { error: /confirm/i.test(error.message) ? "Confirmez votre adresse e-mail avant de vous connecter." : "E-mail ou mot de passe incorrect." };
  }
  redirect(safeNext(form.get("next")));
}

export async function signupAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const email = String(form.get("email") ?? "").trim();
  const password = String(form.get("password") ?? "");
  if (password.length < 8) return { error: "Le mot de passe doit contenir au moins 8 caractères." };
  if (password !== String(form.get("confirm") ?? "")) return { error: "Les mots de passe ne correspondent pas." };
  const next = safeNext(form.get("next"));
  const supabase = await createSupabaseServer();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { emailRedirectTo: `${await siteUrl()}/auth/callback?next=${encodeURIComponent(next)}` },
  });
  if (error) return { error: error.message };
  // With e-mail confirmation disabled a session is returned straight away.
  if (data.session) redirect(next);
  return { ok: true };
}

export async function logoutAction(): Promise<void> {
  const supabase = await createSupabaseServer();
  await supabase.auth.signOut();
  redirect("/login");
}

export async function forgotPasswordAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const email = String(form.get("email") ?? "").trim();
  if (!email) return { error: "Indiquez votre adresse e-mail." };
  const supabase = await createSupabaseServer();
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${await siteUrl()}/auth/callback?next=${encodeURIComponent("/reset-password")}`,
  });
  if (error) return { error: error.message };
  return { ok: true };
}

export async function resetPasswordAction(_prev: ActionState, form: FormData): Promise<ActionState> {
  const password = String(form.get("password") ?? "");
  if (password.length < 8) return { error: "Le mot de passe doit contenir au moins 8 caractères." };
  if (password !== String(form.get("confirm") ?? "")) return { error: "Les mots de passe ne correspondent pas." };
  const supabase = await createSupabaseServer();
  const { error } = await supabase.auth.updateUser({ password });
  if (error) return { error: error.message };
  redirect("/account");
}
