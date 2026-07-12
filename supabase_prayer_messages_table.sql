-- شغل هاد السكريبت مرة وحدة فـ Supabase Dashboard -> SQL Editor
-- جدول الرسائل اللي عبدالرحمن كيوجهها لباه. الرسائل كتتمسح أوتوماتيكيا
-- (من جوج التطبيق نفسو، ملي تتفتح الصفحة بعد 5 صباحا) بلا ما تحتاج أي
-- إعداد إضافي فـ Supabase.

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
