import { redirect } from "next/navigation";
import { requireUser } from "@/lib/supabase";
import { AuthForm } from "../auth-form";

/** Reached through the recovery link (session established by /auth/callback). */
export default async function ResetPasswordPage() {
  const { user } = await requireUser();
  if (!user) redirect("/forgot-password");
  return <AuthForm mode="reset" />;
}
