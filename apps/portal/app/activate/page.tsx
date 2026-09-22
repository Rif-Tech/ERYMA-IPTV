import { redirect } from "next/navigation";
import { requireUser } from "@/lib/supabase";
import { normalizeCode, previewPairing } from "../pairing/actions";
import { ActivateForm } from "./activate-form";

/** Device pairing: `?token=` from the QR code, or `?code=` typed by the user. */
export default async function ActivatePage({ searchParams }: PageProps<"/activate">) {
  const params = await searchParams;
  const token = typeof params.token === "string" ? params.token : undefined;
  const rawCode = typeof params.code === "string" ? params.code : undefined;
  const { user } = await requireUser();
  if (!user) {
    const here = token ? `/activate?token=${encodeURIComponent(token)}` : rawCode ? `/activate?code=${encodeURIComponent(rawCode)}` : "/activate";
    redirect(`/login?next=${encodeURIComponent(here)}`);
  }
  const code = rawCode ? await normalizeCode(rawCode) : undefined;
  const { preview, error } = token || code?.length === 6 ? await previewPairing({ token, code }) : {};
  return <ActivateForm token={token} code={code} preview={preview} previewError={error} />;
}
