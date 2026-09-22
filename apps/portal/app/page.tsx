import Link from "next/link";
import { createSupabaseServer, currentUser } from "@/lib/supabase";

export default async function HomePage() {
  const supabase = await createSupabaseServer();
  const user = await currentUser(supabase);
  return (
    <div className="space-y-12">
      <section className="card-strong relative overflow-hidden px-6 py-12 text-center sm:px-12 sm:py-16">
        <div className="pointer-events-none absolute -top-32 left-1/2 h-72 w-[42rem] -translate-x-1/2 rounded-full bg-[#0a84ff]/25 blur-3xl" aria-hidden />
        <div className="relative space-y-6">
          <p className="badge mx-auto">Un compte · tous vos écrans</p>
          <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">Vos listes de lecture,<br />sur votre télé en un scan.</h1>
          <p className="mx-auto max-w-2xl text-base text-white/70 sm:text-lg">
            Créez un compte, ajoutez vos sources M3U ou Xtream Codes, puis connectez votre téléviseur, tablette ou téléphone
            en scannant un QR code. Chaque profil garde son historique et sa reprise de lecture.
          </p>
          <div className="flex flex-wrap justify-center gap-3 pt-2">
            {user ? (
              <>
                <Link href="/account" className="btn-primary !px-6 !py-3 text-base">Mon compte</Link>
                <Link href="/activate" className="btn-secondary !px-6 !py-3 text-base">Ajouter un appareil</Link>
              </>
            ) : (
              <>
                <Link href="/signup" className="btn-primary !px-6 !py-3 text-base">Créer un compte</Link>
                <Link href="/login" className="btn-secondary !px-6 !py-3 text-base">Connexion</Link>
              </>
            )}
          </div>
        </div>
      </section>

      <section className="grid gap-4 md:grid-cols-3">
        {[
          { n: "1", title: "Créez votre compte", text: "Ajoutez vos listes de lecture dans « Mon compte » : elles suivent votre compte, pas un appareil." },
          { n: "2", title: "Scannez le QR code", text: "Installez MultIPTV sur vos appareils : un QR code et un code court s'affichent au premier lancement." },
          { n: "3", title: "Regardez", text: "Choisissez un profil ; l'essai gratuit démarre aussitôt, l'activation se fait par l'administrateur." },
        ].map((s) => (
          <div key={s.n} className="card space-y-2">
            <span className="inline-flex h-9 w-9 items-center justify-center rounded-full bg-white text-sm font-bold text-black">{s.n}</span>
            <h2 className="text-lg font-semibold">{s.title}</h2>
            <p className="text-sm text-white/65">{s.text}</p>
          </div>
        ))}
      </section>

      <p className="text-center text-xs text-white/40">
        Ancien appareil identifié par adresse MAC ? <Link href="/manage-playlists/login" className="underline hover:text-white">Gérer ses playlists</Link>{" "}
        ou reliez-le à votre compte depuis l&apos;écran d&apos;appairage de l&apos;application.
      </p>
    </div>
  );
}
