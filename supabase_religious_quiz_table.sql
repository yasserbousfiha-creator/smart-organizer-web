create table if not exists public.religious_quiz_days (
  id uuid primary key default gen_random_uuid(),
  quiz_date date not null unique,
  question_ids integer[] not null,
  answers jsonb not null default '{}'::jsonb,
  points integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.religious_quiz_days enable row level security;

create policy "public read/write for religious_quiz_days"
  on public.religious_quiz_days
  for all
  using (true)
  with check (true);
