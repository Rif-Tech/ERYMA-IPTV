import { cookies } from "next/headers";

export const PORTAL_COOKIE = "multiptv_portal";

export async function getPortalToken(): Promise<string | null> {
  const store = await cookies();
  return store.get(PORTAL_COOKIE)?.value ?? null;
}

export async function setPortalToken(token: string): Promise<void> {
  const store = await cookies();
  store.set(PORTAL_COOKIE, token, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24,
  });
}

export async function clearPortalToken(): Promise<void> {
  const store = await cookies();
  store.delete(PORTAL_COOKIE);
}
