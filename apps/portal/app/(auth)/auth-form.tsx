"use client";

import Link from "next/link";
import { useActionState } from "react";
import type { ActionState } from "../manage-playlists/actions";
import { forgotPasswordAction, loginAction, resetPasswordAction, signupAction } from "./actions";

type Mode = "login" | "signup" | "forgot" | "reset";

const copy: Record<Mode, { title: string; submit: string; pending: string }> = {
  login: { title: "Connexion", submit: "Se connecter", pending: "Connexion…" },
  signup: { title: "Créer un compte", submit: "Créer mon compte", pending: "Création…" },
  forgot: { title: "Mot de passe oublié", submit: "Envoyer le lien", pending: "Envoi…" },
  reset: { title: "Nouveau mot de passe", submit: "Enregistrer", pending: "Enregistrement…" },
};

const actions = { login: loginAction, signup: signupAction, forgot: forgotPasswordAction, reset: resetPasswordAction };

/** One form for every e-mail/password step; `next` survives the login → signup → login loop. */
export function AuthForm({ mode, next }: { mode: Mode; next?: string }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(actions[mode], {});
  const q = next ? `?next=${encodeURIComponent(next)}` : "";
  const c = copy[mode];

  if (state.ok && mode === "signup") {
    return (
      <div className="card mx-auto max-w-md space-y-3">
        <h1 className="text-2xl font-semibold">Vérifiez votre boîte mail</h1>
        <p className="text-sm text-slate-300">Un lien de confirmation vient d&apos;être envoyé. Ouvrez-le pour activer votre compte, puis revenez ici.</p>
        <Link href={`/login${q}`} className="btn-secondary">Retour à la connexion</Link>
      </div>
    );
  }
  if (state.ok && mode === "forgot") {
    return (
      <div className="card mx-auto max-w-md space-y-3">
        <h1 className="text-2xl font-semibold">E-mail envoyé</h1>
        <p className="text-sm text-slate-300">Si un compte existe pour cette adresse, un lien de réinitialisation vous attend dans votre boîte mail.</p>
        <Link href="/login" className="btn-secondary">Retour à la connexion</Link>
      </div>
    );
  }

  return (
    <form action={action} className="card mx-auto max-w-md space-y-4">
      {next && <input type="hidden" name="next" value={next} />}
      <h1 className="text-2xl font-semibold">{c.title}</h1>
      {mode !== "reset" && (
        <div>
          <label className="label" htmlFor="email">E-mail</label>
          <input id="email" name="email" type="email" className="input" required autoFocus autoComplete="email" />
        </div>
      )}
      {mode !== "forgot" && (
        <div>
          <label className="label" htmlFor="password">{mode === "reset" ? "Nouveau mot de passe" : "Mot de passe"}</label>
          <input
            id="password"
            name="password"
            type="password"
            className="input"
            required
            minLength={mode === "login" ? undefined : 8}
            autoComplete={mode === "login" ? "current-password" : "new-password"}
          />
        </div>
      )}
      {(mode === "signup" || mode === "reset") && (
        <div>
          <label className="label" htmlFor="confirm">Confirmer le mot de passe</label>
          <input id="confirm" name="confirm" type="password" className="input" required minLength={8} autoComplete="new-password" />
        </div>
      )}
      {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
      <button type="submit" className="btn-primary w-full" disabled={pending}>{pending ? c.pending : c.submit}</button>
      <div className="flex flex-wrap justify-between gap-2 text-sm text-slate-400">
        {mode === "login" && (
          <>
            <Link href={`/signup${q}`} className="hover:text-white">Créer un compte</Link>
            <Link href="/forgot-password" className="hover:text-white">Mot de passe oublié ?</Link>
          </>
        )}
        {mode === "signup" && <Link href={`/login${q}`} className="hover:text-white">J&apos;ai déjà un compte</Link>}
        {mode === "forgot" && <Link href="/login" className="hover:text-white">Retour à la connexion</Link>}
      </div>
    </form>
  );
}
