"use client";

import { useRouter } from "next/navigation";
import { useActionState, useState } from "react";
import type { ActionState, Playlist } from "@/lib/types";

type Props = {
  action: (prev: ActionState, form: FormData) => Promise<ActionState>;
  playlist?: Playlist;
  /** PIN already verified for this edit session (protected playlists). */
  unlockPin?: string;
  submitLabel: string;
  onDone?: () => void;
  /** Navigate here after a successful submit. */
  redirectTo?: string;
};

/** Shared create/edit form for M3U and Xtream playlists. */
export function PlaylistForm({ action, playlist, unlockPin, submitLabel, onDone, redirectTo }: Props) {
  const router = useRouter();
  const [state, formAction, pending] = useActionState<ActionState, FormData>(
    async (prev, form) => {
      const result = await action(prev, form);
      if (result.ok) {
        onDone?.();
        if (redirectTo) router.push(redirectTo);
      }
      return result;
    },
    {},
  );
  const [type, setType] = useState<"m3u" | "xtream">(playlist?.type ?? "xtream");
  const [isProtected, setProtected] = useState(playlist?.is_protected ?? false);
  const expires = playlist?.expires_at ? playlist.expires_at.slice(0, 10) : "";

  return (
    <form action={formAction} className="space-y-4" key={playlist?.id ?? "new"}>
      {playlist && <input type="hidden" name="id" value={playlist.id} />}
      {unlockPin && <input type="hidden" name="unlock_pin" value={unlockPin} />}
      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label className="label" htmlFor="name">Nom</label>
          <input id="name" name="name" className="input" defaultValue={playlist?.name} required maxLength={120} />
        </div>
        <div>
          <label className="label" htmlFor="type">Type</label>
          <select id="type" name="type" className="input" value={type} onChange={(e) => setType(e.target.value as "m3u" | "xtream")}>
            <option value="xtream">Xtream Codes</option>
            <option value="m3u">M3U / M3U8</option>
          </select>
        </div>
      </div>
      <div>
        <label className="label" htmlFor="url">{type === "xtream" ? "URL du serveur" : "URL de la playlist M3U"}</label>
        <input id="url" name="url" className="input" defaultValue={playlist?.url} placeholder={type === "xtream" ? "http://serveur:8080" : "http://…/playlist.m3u"} required />
      </div>
      {type === "xtream" ? (
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label className="label" htmlFor="username">Identifiant</label>
            <input id="username" name="username" className="input" defaultValue={playlist?.username ?? ""} required />
          </div>
          <div>
            <label className="label" htmlFor="password">Mot de passe</label>
            <input id="password" name="password" className="input" type="text" defaultValue={playlist?.password ?? ""} required />
          </div>
        </div>
      ) : (
        <div>
          <label className="label" htmlFor="epg_url">URL EPG (XMLTV, optionnel)</label>
          <input id="epg_url" name="epg_url" className="input" defaultValue={playlist?.epg_url ?? ""} placeholder="http://…/guide.xml.gz" />
        </div>
      )}
      <div className="grid gap-4 sm:grid-cols-3">
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" name="is_protected" checked={isProtected} onChange={(e) => setProtected(e.target.checked)} />
          Protéger par un code PIN
        </label>
        {isProtected && (
          <div>
            <label className="label" htmlFor="pin_code">Code PIN (4 à 8 chiffres)</label>
            <input id="pin_code" name="pin_code" className="input font-mono" inputMode="numeric" pattern="\d{4,8}" defaultValue={playlist?.pin_code ?? ""} required />
          </div>
        )}
        <div>
          <label className="label" htmlFor="expires_at">Expiration (optionnel)</label>
          <input id="expires_at" name="expires_at" className="input" type="date" defaultValue={expires} />
        </div>
      </div>
      {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
      <button type="submit" className="btn-primary" disabled={pending}>{pending ? "Enregistrement…" : submitLabel}</button>
    </form>
  );
}
