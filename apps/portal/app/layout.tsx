import type { Metadata } from "next";
import Link from "next/link";
import { createSupabaseServer, currentUser } from "@/lib/supabase";
import "./globals.css";

export const metadata: Metadata = {
  title: "MultIPTV — Portail",
  description: "Gérez votre compte, vos appareils et vos listes de lecture MultIPTV.",
};

export default async function RootLayout({ children }: LayoutProps<"/">) {
  const supabase = await createSupabaseServer();
  const user = await currentUser(supabase);
  return (
    <html lang="fr" className="h-full antialiased">
      <body className="min-h-full flex flex-col text-white">
        <header className="sticky top-0 z-40 border-b border-white/10 bg-black/40 backdrop-blur-xl">
          <nav className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
            <Link href="/" className="flex items-center gap-2.5 font-semibold tracking-tight">
              <span className="inline-flex h-7 w-7 items-center justify-center rounded-lg bg-gradient-to-br from-[#6fb2ff] to-[#0a84ff] text-black shadow-[0_6px_20px_rgba(10,132,255,0.45)]" aria-hidden>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z" /></svg>
              </span>
              MultIPTV
            </Link>
            <div className="flex items-center gap-2 text-sm">
              <Link href="/activate" className="btn-secondary !px-3.5 !py-1.5">Ajouter un appareil</Link>
              {user ? (
                <Link href="/account" className="btn-primary !px-3.5 !py-1.5">Mon compte</Link>
              ) : (
                <>
                  <Link href="/login" className="tab">Connexion</Link>
                  <Link href="/signup" className="btn-primary !px-3.5 !py-1.5">Créer un compte</Link>
                </>
              )}
            </div>
          </nav>
        </header>
        <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-8">{children}</main>
        <footer className="py-6 text-center text-xs text-white/35">
          MultIPTV est un lecteur multimédia générique : il ne fournit ni contenu ni playlist.
        </footer>
      </body>
    </html>
  );
}
