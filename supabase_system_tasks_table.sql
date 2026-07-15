create table if not exists public.system_tasks (
  id uuid primary key default gen_random_uuid(),
  task_date date not null,
  title text not null,
  sort_order int not null default 0,
  is_custom boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.system_tasks add column if not exists kind text not null default 'simple';
alter table public.system_tasks add column if not exists done boolean not null default false;
alter table public.system_tasks add column if not exists progress numeric not null default 0;
alter table public.system_tasks add column if not exists target numeric;
alter table public.system_tasks add column if not exists unit text;
alter table public.system_tasks add column if not exists step numeric;
alter table public.system_tasks add column if not exists sub_status jsonb;

alter table public.system_tasks enable row level security;

drop policy if exists "public read/write for system_tasks" on public.system_tasks;
create policy "public read/write for system_tasks"
  on public.system_tasks
  for all
  using (true)
  with check (true);
