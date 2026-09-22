"use client";

import Link from "next/link";
import { useActionState } from "react";
import type { ActionState } from "../manage-playlists/actions";
import { confirmDeviceAction, type PairingPreview } from "../pairing/actions";

const typeLabel: Record<string, string> = { tv: "Téléviseur", tablet: "Tablette", mobile: "Téléphone" };

function describe(d: PairingPreview["device"]): string {
  if (!d) return "Appareil";
  const parts = [typeLabel[d.device_type] ?? d.device_type, [d.manufacturer, d.model].filter(Boolean).join(" ")].filter(Boolean);
  return parts.join(" · ");
}

/** Step 1: type the code (when no token came from a QR). Step 2: confirm the described device.
 *  On success the action redirects (to the playlist form when the account has none). */
export function ActivateForm({ token, code, preview, previewError }: { token?: string; code?: string; preview?: PairingPreview; previewError?: string }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(confirmDeviceAction, {});

  if (!preview) {
    // Plain GET: the server looks the code up and re-renders with the device description.
    return (
      <form method="get" action="/activate" className="card mx-auto max-w-md space-y-4">
        <h1 className="text-2xl font-semibold">Connecter un appareil</h1>
        <p className="text-sm text-white/70">Saisissez le code affiché sur l&apos;écran de votre téléviseur ou de votre appareil.</p>
        <div>
          <label className="label" htmlFor="code">Code</label>
          <input
            id="code"
            name="code"
            className="input text-center font-mono text-2xl uppercase tracking-[0.4em]"
            defaultValue={code ?? ""}
            maxLength={7}
            autoComplete="one-time-code"
            autoFocus
            required
          />
        </div>
        {previewError && <p className="notice-error">{previewError}</p>}
        <button type="submit" className="btn-primary w-full">Continuer</button>
      </form>
    );
  }

  return (
    <form action={action} className="card mx-auto max-w-md space-y-4">
      {token && <input type="hidden" name="token" value={token} />}
      {code && <input type="hidden" name="code" value={code} />}
      <h1 className="text-2xl font-semibold">Connecter un appareil</h1>
      <div className="rounded-xl border border-white/10 bg-white/[0.05] p-4">
        <p className="text-xs uppercase tracking-wide text-white/50">Appareil détecté</p>
        <p className="text-lg font-medium">{describe(preview.device)}</p>
        {code && <p className="font-mono text-sm text-white/60">Code {code}</p>}
      </div>
      <div>
        <label className="label" htmlFor="name">Nom de l&apos;appareil (optionnel)</label>
        <input id="name" name="name" className="input" placeholder="TV Salon" maxLength={60} defaultValue={preview.device?.name ?? ""} />
      </div>
      <p className="text-sm text-white/70">Connecter cet appareil à votre compte ? Il aura accès à vos listes de lecture et à vos profils.</p>
      {state.error && <p className="notice-error">{state.error}</p>}
      {state.error?.includes("maximal") && <Link href="/account" className="btn-secondary w-full">Gérer mes appareils</Link>}
      <button type="submit" className="btn-primary w-full" disabled={pending}>{pending ? "Connexion…" : "Connecter cet appareil"}</button>
    </form>
  );
}
