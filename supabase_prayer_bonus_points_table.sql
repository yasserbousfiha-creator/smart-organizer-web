create table if not exists public.prayer_bonus_points (
  id uuid primary key default gen_random_uuid(),
  bonus_date date not null default current_date,
  amount integer not null,
  note text,
  created_at timestamptz not null default now()
);

alter table public.prayer_bonus_points enable row level security;

create policy "public read/write for prayer_bonus_points"
  on public.prayer_bonus_points
  for all
  using (true)
  with check (true);
