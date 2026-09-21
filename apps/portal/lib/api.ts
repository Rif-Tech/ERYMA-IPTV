// Server-side client for the MultIPTV Edge Functions.

export interface DeviceStatus {
  registered: boolean;
  activated: boolean;
  is_trial: boolean;
  expired: boolean;
  trial_ends_at: string | null;
  expires_at: string | null;
}

export interface PortalDevice {
  mac: string;
  device_type: string;
  platform?: string | null;
  app_version?: string | null;
  created_at: string;
  last_seen_at?: string;
}

export interface Playlist {
  id: string;
  name: string;
  type: "m3u" | "xtream";
  url: string;
  username: string | null;
  password: string | null;
  epg_url: string | null;
  is_protected: boolean;
  pin_code: string | null;
  expires_at: string | null;
  position: number;
  created_at: string;
  updated_at: string;
  /** True when credentials were masked by the server (PIN required to reveal). */
  locked?: boolean;
}

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

function functionsUrl(): string {
  const explicit = process.env.SUPABASE_FUNCTIONS_URL;
  if (explicit) return explicit.replace(/\/$/, "");
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "http://127.0.0.1:54321";
  return `${base.replace(/\/$/, "")}/functions/v1`;
}

async function call<T>(path: string, init: RequestInit & { token?: string } = {}): Promise<T> {
  const { token, ...rest } = init;
  const headers: Record<string, string> = { "Content-Type": "application/json", ...(rest.headers as Record<string, string>) };
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (anon) headers.apikey = anon;
  if (token) headers["x-portal-token"] = token;
  const res = await fetch(`${functionsUrl()}${path}`, { ...rest, headers, cache: "no-store" });
  const text = await res.text();
  const data = text ? JSON.parse(text) : {};
  if (!res.ok) throw new ApiError(res.status, data.error ?? res.statusText);
  return data as T;
}

export const api = {
  portalLogin: (mac: string, deviceKey: string) =>
    call<{ token: string; status: DeviceStatus; device: PortalDevice }>("/portal-login", {
      method: "POST",
      body: JSON.stringify({ mac, device_key: deviceKey }),
    }),

  playlists: (token: string) =>
    call<{ status: DeviceStatus; device: PortalDevice; playlists: Playlist[] }>("/portal-playlists", { token }),

  revealPlaylist: (token: string, id: string, pin: string) =>
    call<{ playlist: Playlist }>(`/portal-playlists?id=${encodeURIComponent(id)}&pin=${encodeURIComponent(pin)}`, { token }),

  createPlaylist: (token: string, input: Partial<Playlist>) =>
    call<{ playlist: Playlist }>("/portal-playlists", { method: "POST", token, body: JSON.stringify(input) }),

  updatePlaylist: (token: string, id: string, input: Partial<Playlist>, pin?: string) =>
    call<{ playlist: Playlist }>("/portal-playlists", { method: "PUT", token, body: JSON.stringify({ id, pin, ...input }) }),

  reorderPlaylists: (token: string, order: string[]) =>
    call<{ ok: true }>("/portal-playlists", { method: "PATCH", token, body: JSON.stringify({ order }) }),

  deletePlaylist: (token: string, id: string, pin?: string) =>
    call<{ ok: true }>("/portal-playlists", { method: "DELETE", token, body: JSON.stringify({ id, pin }) }),
};

export function normalizeMac(raw: string): string {
  const hex = raw.replace(/[^0-9a-fA-F]/g, "").toUpperCase();
  if (hex.length !== 12) return raw.trim().toUpperCase();
  return hex.match(/.{2}/g)!.join(":");
}
