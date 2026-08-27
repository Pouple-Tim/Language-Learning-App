create table if not exists public.decks (
  id text primary key,
  content jsonb not null
);

alter table public.decks enable row level security;

create policy "Public read access" on public.decks
  for select
  to anon
  using (true);

-- Minimal anonymous usage logging (no accounts, no PII: anon_device_id is a
-- random UUID generated on-device, see AnalyticsService). Insert-only for
-- the anon key -- no select/update/delete policy exists for anon, so RLS
-- denies those by default. This must stay insert-only: the anon key is
-- public (embedded client-side, public repo), so a read policy here would
-- let anyone read every user's events.
create table if not exists public.app_events (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  event_name text not null,
  event_props jsonb not null default '{}'::jsonb,
  anon_device_id uuid not null,
  app_version text
);

alter table public.app_events enable row level security;

create policy "Anonymous insert only" on public.app_events
  for insert
  to anon
  with check (true);
