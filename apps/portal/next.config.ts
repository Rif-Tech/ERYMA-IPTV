import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  agentRules: false,
  // Dev server reachable from other machines on the LAN / Tailscale.
  allowedDevOrigins: ["100.88.208.52", "localhost", "127.0.0.1"],
};

export default nextConfig;
