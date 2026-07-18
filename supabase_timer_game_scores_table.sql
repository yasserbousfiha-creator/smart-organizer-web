create table if not exists public.timer_game_scores (
  id uuid primary key default gen_random_uuid(),
  player_name text not null,
  target_ms integer not null,
  elapsed_ms integer not null,
  diff_ms integer not null,
  created_at timestamptz not null default now()
);

alter table public.timer_game_scores enable row level security;

create policy "public read/write for timer_game_scores"
  on public.timer_game_scores
  for all
  using (true)
  with check (true);
