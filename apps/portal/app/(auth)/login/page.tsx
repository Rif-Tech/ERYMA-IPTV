import { redirect } from "next/navigation";
import { requireUser } from "@/lib/supabase";
import { AuthForm } from "../auth-form";

export default async function LoginPage({ searchParams }: PageProps<"/login">) {
  const params = await searchParams;
  const next = typeof params.next === "string" ? params.next : undefined;
  const { user } = await requireUser();
  if (user) redirect(next && next.startsWith("/") ? next : "/account");
  return <AuthForm mode="login" next={next} />;
}
