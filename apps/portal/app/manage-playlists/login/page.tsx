import { redirect } from "next/navigation";
import { getPortalToken } from "@/lib/session";
import { LoginForm } from "./login-form";

export default async function LoginPage({ searchParams }: PageProps<"/manage-playlists/login">) {
  if (await getPortalToken()) redirect("/manage-playlists");
  const params = await searchParams;
  const first = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? "";
  return <LoginForm mac={first(params.mac)} deviceKey={first(params.key)} />;
}
