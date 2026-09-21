import Link from "next/link";

export default function HomePage() {
  return (
    <div className="grid gap-8 md:grid-cols-2 md:items-center">
      <div className="space-y-5">
        <h1 className="text-4xl font-bold tracking-tight">Gérez vos playlists depuis le web</h1>
        <p className="text-slate-300">
          Connectez-vous avec l&apos;adresse MAC et la clé affichées dans l&apos;application MultIPTV
          (écran « Aucune playlist » ou Réglages), puis ajoutez vos sources M3U ou Xtream Codes.
          L&apos;application les récupère au prochain lancement ou via « Rafraîchir ».
        </p>
        <div className="flex gap-3">
          <Link href="/manage-playlists/login" className="btn-primary">Gérer mes playlists</Link>
        </div>
      </div>
      <ol className="card space-y-3 text-sm text-slate-300">
        <li><span className="font-semibold text-white">1.</span> Installez MultIPTV sur votre téléphone, tablette ou Android TV.</li>
        <li><span className="font-semibold text-white">2.</span> Notez l&apos;adresse MAC et la clé appareil (ou scannez le QR code).</li>
        <li><span className="font-semibold text-white">3.</span> Ajoutez ici vos playlists ; elles sont synchronisées automatiquement.</li>
        <li><span className="font-semibold text-white">4.</span> Un essai gratuit est ouvert à l&apos;enregistrement ; l&apos;activation se fait par l&apos;administrateur.</li>
      </ol>
    </div>
  );
}
