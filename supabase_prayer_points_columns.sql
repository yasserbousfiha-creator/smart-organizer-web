alter table public.prayers
  add column if not exists fajr_points integer not null default 0,
  add column if not exists dhuhr_points integer not null default 0,
  add column if not exists asr_points integer not null default 0,
  add column if not exists maghrib_points integer not null default 0,
  add column if not exists isha_points integer not null default 0;

create table if not exists public.prayer_settings (
  id integer primary key default 1,
  reward_choice text,
  current_challenge_start date not null default current_date,
  constraint prayer_settings_singleton check (id = 1)
);

insert into public.prayer_settings (id, current_challenge_start)
values (1, current_date)
on conflict (id) do nothing;

alter table public.prayer_settings enable row level security;

create policy "public read/write for prayer_settings"
  on public.prayer_settings
  for all
  using (true)
  with check (true);

create table if not exists public.prayer_challenges (
  id uuid primary key default gen_random_uuid(),
  start_date date not null,
  end_date date not null,
  total_points integer not null default 0,
  reward_reached boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.prayer_challenges enable row level security;

create policy "public read/write for prayer_challenges"
  on public.prayer_challenges
  for all
  using (true)
  with check (true);
