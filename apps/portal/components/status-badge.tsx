import type { DeviceStatus } from "@/lib/api";

export function StatusBadge({ status }: { status: DeviceStatus }) {
  const fmt = (d: string | null) => (d ? new Date(d).toLocaleDateString("fr-FR") : null);
  if (status.expired) {
    return (
      <span className="badge bg-red-900 text-red-100">
        {status.activated || status.expires_at ? `Activation expirée le ${fmt(status.expires_at)}` : "Essai terminé — activation requise"}
      </span>
    );
  }
  if (status.activated) {
    return <span className="badge bg-emerald-900 text-emerald-100">{status.expires_at ? `Activé jusqu'au ${fmt(status.expires_at)}` : "Activé, sans expiration"}</span>;
  }
  return <span className="badge bg-amber-900 text-amber-100">Essai gratuit jusqu&apos;au {fmt(status.trial_ends_at)}</span>;
}
