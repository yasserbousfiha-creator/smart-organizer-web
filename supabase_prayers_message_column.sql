-- شغل هاد السكريبت مرة وحدة فـ Supabase Dashboard -> SQL Editor
-- باش يتزاد عمود الرسالة اللي عبدالرحمن كيوجهها لباه، فوق الجدول
-- `prayers` اللي تخلق قبل (supabase_prayers_table.sql).

alter table public.prayers
  add column if not exists message text not null default '';
