import Link from "next/link";
import { createSupabaseServer } from "@/lib/supabase";

export default async function HomePage() {
  const supabase = await createSupabaseServer();
  const { data: { user } } = await supabase.auth.getUser();
  return (
    <div className="grid gap-8 md:grid-cols-2 md:items-center">
      <div className="space-y-5">
        <h1 className="text-4xl font-bold tracking-tight">Un compte, tous vos écrans</h1>
        <p className="text-slate-300">
          Créez un compte MultIPTV, ajoutez vos listes de lecture M3U ou Xtream Codes, puis connectez votre téléviseur,
          votre tablette ou votre téléphone en scannant un QR code. Chaque profil garde son historique et sa reprise de lecture.
        </p>
        <div className="flex flex-wrap gap-3">
          {user ? (
            <>
              <Link href="/account" className="btn-primary">Mon compte</Link>
              <Link href="/activate" className="btn-secondary">Ajouter un appareil</Link>
            </>
          ) : (
            <>
              <Link href="/signup" className="btn-primary">Créer un compte</Link>
              <Link href="/login" className="btn-secondary">Connexion</Link>
            </>
          )}
        </div>
        <p className="text-xs text-slate-500">
          Ancien appareil identifié par adresse MAC ? <Link href="/manage-playlists/login" className="underline">Gérer ses playlists</Link>{" "}
          ou reliez-le à votre compte depuis l&apos;écran d&apos;appairage de l&apos;application.
        </p>
      </div>
      <ol className="card space-y-3 text-sm text-slate-300">
        <li><span className="font-semibold text-white">1.</span> Créez votre compte et ajoutez vos listes de lecture dans « Mon compte ».</li>
        <li><span className="font-semibold text-white">2.</span> Installez MultIPTV sur vos appareils : un QR code et un code court s&apos;affichent au premier lancement.</li>
        <li><span className="font-semibold text-white">3.</span> Scannez le QR code (ou saisissez le code) : l&apos;appareil est relié à votre compte.</li>
        <li><span className="font-semibold text-white">4.</span> Choisissez un profil et une liste sur l&apos;appareil ; l&apos;essai gratuit démarre automatiquement, l&apos;activation se fait par l&apos;administrateur.</li>
      </ol>
    </div>
  );
}
