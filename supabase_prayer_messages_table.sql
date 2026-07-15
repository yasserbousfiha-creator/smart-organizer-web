create table if not exists public.prayer_messages (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  created_at timestamptz not null default now()
);

alter table public.prayer_messages enable row level security;

create policy "public read/write for prayer_messages"
  on public.prayer_messages
  for all
  using (true)
  with check (true);
