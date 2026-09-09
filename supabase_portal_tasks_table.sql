create table if not exists public.portal_tasks (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null,
  title text not null,
  details text,
  status text not null default 'قيد الانتظار',
  created_by text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.portal_tasks enable row level security;

drop policy if exists "public read/write for portal_tasks" on public.portal_tasks;
create policy "public read/write for portal_tasks"
  on public.portal_tasks
  for all
  using (true)
  with check (true);
