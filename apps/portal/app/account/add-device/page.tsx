import { redirect } from "next/navigation";

/** Same flow as /activate, kept under the account tabs for discoverability. */
export default function AddDevicePage() {
  redirect("/activate");
}
