export type DnsServerRow = {
  id: string;
  name: string;
  provider: string | null;
  ipv4: string[];
  ipv6: string[];
  doh_url: string | null;
  dot_host: string | null;
  enabled: boolean;
  is_default: boolean;
  position: number;
  notes: string | null;
};
