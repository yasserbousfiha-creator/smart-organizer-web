create table if not exists public.prayers (
  id uuid primary key default gen_random_uuid(),
  prayer_date date not null unique,
  fajr boolean not null default false,
  dhuhr boolean not null default false,
  asr boolean not null default false,
  maghrib boolean not null default false,
  isha boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.prayers enable row level security;

create policy "public read/write for prayers"
  on public.prayers
  for all
  using (true)
  with check (true);
