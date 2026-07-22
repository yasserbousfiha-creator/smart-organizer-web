alter table public.prayers
  add column if not exists quran_page integer,
  add column if not exists quran_done boolean not null default false,
  add column if not exists quran_points integer not null default 0,
  add column if not exists sabah_done boolean not null default false,
  add column if not exists sabah_points integer not null default 0,
  add column if not exists masaa_done boolean not null default false,
  add column if not exists masaa_points integer not null default 0;
