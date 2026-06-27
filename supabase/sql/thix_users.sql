-- THIX ID — Users profile table
-- Run this in Supabase Dashboard → SQL Editor.
-- IMPORTANT:
-- - Supabase Auth already provides `auth.users` (system table).
-- - This file creates `public.users` as your app-level user profile table.
--   It links 1:1 with `auth.users` via `id`.

begin;

-- If you didn't run thix_market.sql yet, pgcrypto is still safe to enable.
create extension if not exists "pgcrypto";

-- updated_at helper (created in thix_market.sql as well). Kept here for standalone usage.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================================
-- public.users (app-level profile)
-- Fields mapped to your Sign Up form:
-- - name
-- - email
-- - country
-- - birth_date
-- ============================================================================

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  country text,
  birth_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Forward-compatible alters (safe to re-run)
alter table public.users add column if not exists name text;
alter table public.users add column if not exists email text;
alter table public.users add column if not exists country text;
alter table public.users add column if not exists birth_date date;
alter table public.users add column if not exists created_at timestamptz not null default now();
alter table public.users add column if not exists updated_at timestamptz not null default now();

create unique index if not exists idx_public_users_email_unique on public.users (lower(email));

drop trigger if exists trg_public_users_updated_at on public.users;
create trigger trg_public_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

-- ============================================================================
-- Row Level Security (RLS)
-- - Users can read/update their own row
-- - Users can insert only for themselves
-- ============================================================================

alter table public.users enable row level security;

drop policy if exists "users_select_own" on public.users;
create policy "users_select_own"
on public.users
for select
using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own"
on public.users
for insert
with check (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own"
on public.users
for update
using (auth.uid() = id)
with check (auth.uid() = id);

commit;
