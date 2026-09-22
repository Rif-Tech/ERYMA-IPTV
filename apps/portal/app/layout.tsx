import type { Metadata } from "next";
import Link from "next/link";
import { createSupabaseServer } from "@/lib/supabase";
import "./globals.css";

export const metadata: Metadata = {
  title: "MultIPTV — Portail",
  description: "Gérez votre compte, vos appareils et vos listes de lecture MultIPTV.",
};

export default async function RootLayout({ children }: LayoutProps<"/">) {
  const supabase = await createSupabaseServer();
  const { data: { user } } = await supabase.auth.getUser();
  return (
    <html lang="fr" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-slate-950 text-slate-100">
        <header className="border-b border-slate-800">
          <nav className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
            <Link href="/" className="flex items-center gap-2 font-semibold">
              <span className="inline-block h-6 w-6 rounded bg-blue-600" aria-hidden />
              MultIPTV
            </Link>
            <div className="flex items-center gap-4 text-sm text-slate-300">
              <Link href="/activate" className="hover:text-white">Ajouter un appareil</Link>
              {user ? (
                <Link href="/account" className="hover:text-white">Mon compte</Link>
              ) : (
                <>
                  <Link href="/login" className="hover:text-white">Connexion</Link>
                  <Link href="/signup" className="btn-primary !px-3 !py-1.5">Créer un compte</Link>
                </>
              )}
            </div>
          </nav>
        </header>
        <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-8">{children}</main>
        <footer className="border-t border-slate-800 py-4 text-center text-xs text-slate-500">
          MultIPTV est un lecteur multimédia générique : il ne fournit ni contenu ni playlist.
        </footer>
      </body>
    </html>
  );
}
