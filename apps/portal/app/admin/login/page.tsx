"use client";

import { useActionState } from "react";
import { adminLoginAction } from "../actions";
import type { ActionState } from "../../manage-playlists/actions";

export default function AdminLoginPage() {
  const [state, action, pending] = useActionState<ActionState, FormData>(adminLoginAction, {});
  return (
    <form action={action} className="card mx-auto max-w-md space-y-4">
      <h1 className="text-2xl font-semibold">Administration</h1>
      <div>
        <label className="label" htmlFor="email">E-mail</label>
        <input id="email" name="email" type="email" className="input" required autoFocus />
      </div>
      <div>
        <label className="label" htmlFor="password">Mot de passe</label>
        <input id="password" name="password" type="password" className="input" required />
      </div>
      {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
      <button type="submit" className="btn-primary w-full" disabled={pending}>{pending ? "Connexion…" : "Se connecter"}</button>
    </form>
  );
}
