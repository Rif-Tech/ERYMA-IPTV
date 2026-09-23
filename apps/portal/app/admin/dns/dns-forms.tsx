"use client";

import { useActionState, useEffect, useState } from "react";
import type { ActionState } from "@/lib/types";
import { addDnsServerAction, updateDnsServerAction } from "./actions";
import type { DnsServerRow } from "./types";

/** Shared fields for creating and editing a DNS preset; `item` pre-fills the inputs. */
function DnsFields({ idPrefix, item }: { idPrefix: string; item?: DnsServerRow }) {
  const id = (name: string) => `${idPrefix}-${name}`;
  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <div>
        <label className="label" htmlFor={id("name")}>Nom</label>
        <input id={id("name")} name="name" className="input" required defaultValue={item?.name ?? ""} placeholder="Cloudflare" />
      </div>
      <div>
        <label className="label" htmlFor={id("provider")}>Fournisseur</label>
        <input id={id("provider")} name="provider" className="input" defaultValue={item?.provider ?? ""} placeholder="Cloudflare, Inc." />
      </div>
      <div>
        <label className="label" htmlFor={id("ipv4")}>Adresses IPv4</label>
        <input id={id("ipv4")} name="ipv4" className="input" defaultValue={item?.ipv4?.join(", ") ?? ""} placeholder="1.1.1.1, 1.0.0.1" />
      </div>
      <div>
        <label className="label" htmlFor={id("ipv6")}>Adresses IPv6</label>
        <input id={id("ipv6")} name="ipv6" className="input" defaultValue={item?.ipv6?.join(", ") ?? ""} placeholder="2606:4700:4700::1111" />
      </div>
      <div>
        <label className="label" htmlFor={id("doh_url")}>URL DNS-over-HTTPS</label>
        <input id={id("doh_url")} name="doh_url" className="input" defaultValue={item?.doh_url ?? ""} placeholder="https://1.1.1.1/dns-query" />
      </div>
      <div>
        <label className="label" htmlFor={id("dot_host")}>Nom d&apos;hôte DNS-over-TLS</label>
        <input id={id("dot_host")} name="dot_host" className="input" defaultValue={item?.dot_host ?? ""} placeholder="cloudflare-dns.com" />
      </div>
      <div className="sm:col-span-2">
        <label className="label" htmlFor={id("notes")}>Notes (visibles en admin seulement)</label>
        <input id={id("notes")} name="notes" className="input" defaultValue={item?.notes ?? ""} />
      </div>
    </div>
  );
}

export function AddDnsServerForm() {
  const [state, action, pending] = useActionState<ActionState, FormData>(addDnsServerAction, {});
  return (
    <form action={action} className="card space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Ajouter un serveur DNS</h2>
        <p className="text-sm text-slate-400">
          Proposé aux utilisateurs dans Réglages → Réseau / DNS pour contourner les restrictions DNS d&apos;un opérateur.
        </p>
      </div>
      <DnsFields idPrefix="add" />
      {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
      {state.ok && <p className="rounded-md border border-emerald-900 bg-emerald-950/60 px-3 py-2 text-sm text-emerald-200">Serveur ajouté.</p>}
      <button className="btn-primary" disabled={pending}>{pending ? "Ajout…" : "Ajouter"}</button>
    </form>
  );
}

export function EditDnsServerButton({ item }: { item: DnsServerRow }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button type="button" className="btn-secondary !px-2 !py-1" onClick={() => setOpen(true)}>Modifier</button>
      {open && <EditDnsServerDialog item={item} onClose={() => setOpen(false)} />}
    </>
  );
}

function EditDnsServerDialog({ item, onClose }: { item: DnsServerRow; onClose: () => void }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(updateDnsServerAction, {});
  useEffect(() => {
    if (state.ok) onClose();
  }, [state.ok, onClose]);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);
  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/70 p-4 sm:p-8" onClick={onClose} role="presentation">
      <form
        action={action}
        onClick={(e) => e.stopPropagation()}
        className="card w-full max-w-2xl space-y-4"
        role="dialog"
        aria-modal="true"
        aria-labelledby={`edit-dns-${item.id}-title`}
      >
        <input type="hidden" name="id" value={item.id} />
        <div className="flex items-start justify-between gap-4">
          <h2 id={`edit-dns-${item.id}-title`} className="text-lg font-semibold">Modifier « {item.name} »</h2>
          <button type="button" className="btn-secondary !px-2 !py-1" onClick={onClose} aria-label="Fermer">✕</button>
        </div>
        <DnsFields idPrefix={`edit-${item.id}`} item={item} />
        {state.error && <p className="rounded-md border border-red-900 bg-red-950/60 px-3 py-2 text-sm text-red-200">{state.error}</p>}
        <div className="flex justify-end gap-2">
          <button type="button" className="btn-secondary" onClick={onClose} disabled={pending}>Annuler</button>
          <button className="btn-primary" disabled={pending}>{pending ? "Enregistrement…" : "Enregistrer"}</button>
        </div>
      </form>
    </div>
  );
}
