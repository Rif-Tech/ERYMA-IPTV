// Shared types for server actions and playlist rows.

/** Result shape returned by every form server action (used with `useActionState`). */
export type ActionState = { error?: string; ok?: boolean };

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
