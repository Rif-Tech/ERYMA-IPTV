import Link from "next/link";
import { redirect } from "next/navigation";
import { requireUser } from "@/lib/supabase";
import { PlaylistForm } from "../account/playlists/playlist-form";
import { addPlaylistByCodeAction, normalizeCode, previewPairing } from "../pairing/actions";

/** Playlist pairing: the TV shows a code/QR, the user fills in the provider details here. */
export default async function AddPlaylistPage({ searchParams }: PageProps<"/add-playlist">) {
  const params = await searchParams;
  const token = typeof params.token === "string" ? params.token : undefined;
  const rawCode = typeof params.code === "string" ? params.code : undefined;
  const done = params.done === "1";
  const { user } = await requireUser();
  if (!user) {
    const here = token ? `/add-playlist?token=${encodeURIComponent(token)}` : rawCode ? `/add-playlist?code=${encodeURIComponent(rawCode)}` : "/add-playlist";
    redirect(`/login?next=${encodeURIComponent(here)}`);
  }
  const code = rawCode ? await normalizeCode(rawCode) : undefined;
  const { preview, error } = token || code?.length === 6 ? await previewPairing({ token, code }) : {};

  if (done) {
    return (
      <div className="card mx-auto max-w-md space-y-3">
        <h1 className="text-2xl font-semibold">Liste de lecture ajoutée</h1>
        <p className="text-sm text-slate-300">Votre appareil la charge maintenant. Elle est aussi disponible dans « Mon compte » pour vos autres appareils.</p>
        <Link href="/account/playlists" className="btn-primary">Mes listes de lecture</Link>
      </div>
    );
  }

  if (!preview || preview.kind !== "playlist") {
    return (
      <form method="get" action="/add-playlist" className="card mx-auto max-w-md space-y-4">
        <h1 className="text-2xl font-semibold">Ajouter une liste de lecture</h1>
        <p className="text-sm text-slate-300">Sur votre appareil, ouvrez « Ajouter une liste de lecture » et saisissez le code affiché.</p>
        <div>
          <label className="label" htmlFor="code">Code</label>
          <input id="code" name="code" className="input text-center font-mono text-2xl uppercase tracking-[0.4em]" defaultValue={code ?? ""} maxLength={7} autoFocus required />
        </div>
        {(error || (preview && preview.kind !== "playlist")) && (
          <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{error ?? "Ce code sert à connecter un appareil, pas à ajouter une liste."}</p>
        )}
        <button type="submit" className="btn-primary w-full">Continuer</button>
        <p className="text-xs text-slate-500">Sans appareil sous la main ? Vous pouvez aussi ajouter une liste depuis <Link href="/account/playlists" className="underline">Mon compte</Link>.</p>
      </form>
    );
  }

  return (
    <div className="card mx-auto max-w-2xl space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Ajouter une liste de lecture</h1>
        <p className="text-sm text-slate-400">Cette application est un lecteur IPTV : renseignez la source fournie par votre fournisseur. La liste appartiendra à votre compte et sera visible par tous vos profils.</p>
      </div>
      <PlaylistForm action={addPlaylistByCodeAction.bind(null, { token, code })} submitLabel="Ajouter la liste" redirectTo="/add-playlist?done=1" />
    </div>
  );
}
