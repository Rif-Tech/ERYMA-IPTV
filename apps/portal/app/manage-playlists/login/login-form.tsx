"use client";

import { useActionState } from "react";
import { loginAction, type ActionState } from "../actions";

export function LoginForm({ mac, deviceKey }: { mac: string; deviceKey: string }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(loginAction, {});
  return (
    <form action={action} className="card mx-auto max-w-md space-y-4">
      <h1 className="text-2xl font-semibold">Connexion appareil</h1>
      <p className="text-sm text-slate-400">
        L&apos;adresse MAC et la clé sont affichées dans l&apos;application (écran « Aucune playlist » ou Réglages).
      </p>
      <div>
        <label className="label" htmlFor="mac">Adresse MAC</label>
        <input id="mac" name="mac" className="input font-mono uppercase" placeholder="02:AB:CD:12:34:56" defaultValue={mac} required autoFocus />
      </div>
      <div>
        <label className="label" htmlFor="key">Clé appareil</label>
        <input id="key" name="key" className="input font-mono uppercase" placeholder="ABC123" defaultValue={deviceKey} required maxLength={12} />
      </div>
      {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
      <button type="submit" className="btn-primary w-full" disabled={pending}>
        {pending ? "Connexion…" : "Se connecter"}
      </button>
    </form>
  );
}
