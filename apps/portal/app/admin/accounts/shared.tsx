export type AccountStatusJson = {
  plan: string;
  plan_name: string;
  max_devices: number;
  max_profiles: number;
  max_playlists: number;
  activated: boolean;
  is_trial: boolean;
  expired: boolean;
  trial_ends_at: string | null;
  expires_at: string | null;
};

export type AccountOverview = {
  id: string;
  created_at: string;
  email: string | null;
  role: string | null;
  plan_id: string | null;
  subscription_status: string | null;
  expires_at: string | null;
  note: string | null;
  status: AccountStatusJson;
  device_count: number;
  playlist_count: number;
  profile_count: number;
};

export function SubscriptionBadge({ s }: { s: AccountStatusJson }) {
  if (s.expired) return <span className="badge border border-red-900 text-red-300">Expiré</span>;
  if (s.is_trial) return <span className="badge border border-amber-800 text-amber-300">Essai</span>;
  if (s.activated) return <span className="badge border border-emerald-800 text-emerald-300">{s.plan_name}</span>;
  return <span className="badge border border-slate-700 text-slate-300">Inactif</span>;
}
