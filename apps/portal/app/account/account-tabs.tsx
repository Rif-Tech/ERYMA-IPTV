"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const tabs = [
  { href: "/account", label: "Appareils" },
  { href: "/account/profiles", label: "Profils" },
  { href: "/account/playlists", label: "Listes de lecture" },
  { href: "/activate", label: "Ajouter un appareil" },
];

/** tvOS-style segmented control; the active segment follows the current route. */
export function AccountTabs() {
  const pathname = usePathname();
  return (
    <nav className="segmented" aria-label="Sections du compte">
      {tabs.map((t) => {
        const active = t.href === "/account" ? pathname === "/account" : pathname.startsWith(t.href);
        return (
          <Link key={t.href} href={t.href} className={`tab ${active ? "tab-active" : ""}`} aria-current={active ? "page" : undefined}>
            {t.label}
          </Link>
        );
      })}
    </nav>
  );
}
