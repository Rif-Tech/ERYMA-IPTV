import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";

export const metadata: Metadata = {
  title: "MultIPTV — Portail",
  description: "Gérez les playlists de votre appareil MultIPTV.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="fr" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-slate-950 text-slate-100">
        <header className="border-b border-slate-800">
          <nav className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
            <Link href="/" className="flex items-center gap-2 font-semibold">
              <span className="inline-block h-6 w-6 rounded bg-blue-600" aria-hidden />
              MultIPTV
            </Link>
            <div className="flex gap-4 text-sm text-slate-300">
              <Link href="/manage-playlists" className="hover:text-white">Mes playlists</Link>
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
