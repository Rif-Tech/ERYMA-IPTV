"use client";

import { useActionState } from "react";
import { saveConfigAction } from "../actions";
import type { ActionState } from "../../manage-playlists/actions";

export type AppConfigValues = {
  app_status: string;
  message: string;
  min_version: string;
  latest_version: string;
  apk_link: string;
  trial_days: number;
};

export function ConfigForm({ values }: { values: AppConfigValues }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(saveConfigAction, {});
  return (
    <form action={action} className="card space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label className="label" htmlFor="app_status">Statut du service</label>
          <select id="app_status" name="app_status" className="input" defaultValue={values.app_status}>
            <option value="ok">OK</option>
            <option value="maintenance">Maintenance (bloque l&apos;app)</option>
          </select>
        </div>
        <div>
          <label className="label" htmlFor="trial_days">Durée de l&apos;essai (jours)</label>
          <input id="trial_days" name="trial_days" type="number" min={0} className="input" defaultValue={values.trial_days} />
        </div>
        <div>
          <label className="label" htmlFor="min_version">Version minimale requise</label>
          <input id="min_version" name="min_version" className="input font-mono" defaultValue={values.min_version} placeholder="1.0.0" />
        </div>
        <div>
          <label className="label" htmlFor="latest_version">Dernière version</label>
          <input id="latest_version" name="latest_version" className="input font-mono" defaultValue={values.latest_version} placeholder="1.0.0" />
        </div>
      </div>
      <div>
        <label className="label" htmlFor="apk_link">Lien de téléchargement (APK / store)</label>
        <input id="apk_link" name="apk_link" className="input" defaultValue={values.apk_link} placeholder="https://…" />
      </div>
      <div>
        <label className="label" htmlFor="message">Message affiché (maintenance)</label>
        <textarea id="message" name="message" className="input" rows={3} defaultValue={values.message} />
      </div>
      {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
      {state.ok && <p className="rounded-md border border-emerald-900 bg-emerald-950/60 px-3 py-2 text-sm text-emerald-200">Configuration enregistrée.</p>}
      <button className="btn-primary" disabled={pending}>{pending ? "Enregistrement…" : "Enregistrer"}</button>
    </form>
  );
}
