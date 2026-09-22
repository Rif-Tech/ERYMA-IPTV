import type { NextConfig } from "next";

// Hosts allowed to POST Server Actions (LAN / Tailscale); extend with PORTAL_ALLOWED_ORIGINS="a,b".
const allowedOrigins = [
  "100.88.208.52:3000",
  "localhost:3000",
  "127.0.0.1:3000",
  "*.ts.net",
  ...(process.env.PORTAL_ALLOWED_ORIGINS ?? "").split(",").map((s) => s.trim()).filter(Boolean),
];

const nextConfig: NextConfig = {
  agentRules: false,
  // Dev server reachable from other machines on the LAN / Tailscale.
  allowedDevOrigins: ["100.88.208.52", "localhost", "127.0.0.1"],
  experimental: {
    serverActions: { allowedOrigins },
  },
};

export default nextConfig;
