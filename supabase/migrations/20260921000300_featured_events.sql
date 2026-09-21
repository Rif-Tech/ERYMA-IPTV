-- Scheduled events on featured banners (e.g. a football match on a channel).

alter table public.featured_items
  add column if not exists event_at timestamptz,
  add column if not exists event_end_at timestamptz;

comment on column public.featured_items.event_at is 'Start of the event; the app shows a LIVE badge from 15 minutes before.';
comment on column public.featured_items.event_end_at is 'End of the event; defaults to event_at + 3 hours when null. Hidden afterwards.';
