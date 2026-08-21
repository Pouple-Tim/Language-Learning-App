create table if not exists public.decks (
  id text primary key,
  content jsonb not null
);

alter table public.decks enable row level security;

create policy "Public read access" on public.decks
  for select
  to anon
  using (true);
