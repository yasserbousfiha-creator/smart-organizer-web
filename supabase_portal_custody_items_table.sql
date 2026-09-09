create table if not exists public.portal_custody_items (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null,
  equipment_name text not null,
  notes text,
  status text not null default 'بانتظار الاستلام',
  created_by text,
  created_at timestamptz not null default now(),
  received_at timestamptz
);

alter table public.portal_custody_items enable row level security;

drop policy if exists "public read/write for portal_custody_items" on public.portal_custody_items;
create policy "public read/write for portal_custody_items"
  on public.portal_custody_items
  for all
  using (true)
  with check (true);
