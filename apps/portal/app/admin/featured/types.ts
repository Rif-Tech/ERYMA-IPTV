export type FeaturedRow = {
  id: string;
  kind: "movie" | "tv" | "custom";
  tmdb_id: number | null;
  title: string;
  subtitle: string | null;
  overview: string | null;
  year: number | null;
  poster_url: string | null;
  backdrop_url: string | null;
  link_kind: string | null;
  link_query: string | null;
  require_match: boolean;
  enabled: boolean;
  position: number;
  event_at: string | null;
  event_end_at: string | null;
};
