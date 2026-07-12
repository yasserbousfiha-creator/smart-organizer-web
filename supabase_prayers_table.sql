-- شغل هاد السكريبت مرة وحدة فـ Supabase Dashboard -> SQL Editor
-- باش يتخلق الجدول اللي كيخزن حالة صلوات عبدالرحمن اليومية.

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

-- الميزة كتستعمل قفل برمز سري داخل التطبيق (ماشي تسجيل دخول حقيقي عبر
-- Supabase)، فخاص الجدول يقبل قراءة وكتابة عبر الـ anon key. هادشي كافي
-- لاستخدام عائلي بسيط، ولكن لاحظ: أي حد عندو الـ anon key ديال التطبيق
-- (موجود فالكود، قابل للاكتشاف) يقدر نظريا يقرا/يبدل هاد الجدول مباشرة
-- من برا التطبيق، بحال باقي الجداول اللي كتخدم بنفس الطريقة فهاد المشروع.
create policy "public read/write for prayers"
  on public.prayers
  for all
  using (true)
  with check (true);
