-- Migration: make RLS policies resilient when tables are missing.
-- Fixes: ERROR 42P01 relation "public.users" does not exist
--
-- Root cause:
--   Some environments attempt to (re)create RLS policies for public.users
--   even when the table hasn't been created yet (or was dropped in another step).
--
-- Strategy:
--   1) Ensure the critical table public.users exists (CREATE TABLE IF NOT EXISTS)
--   2) Enable RLS only when tables exist (ALTER TABLE IF EXISTS)
--   3) Create policies only if (a) table exists and (b) policy does not exist.

begin;

create extension if not exists "pgcrypto";

-- Ensure public.users exists (minimal schema compatible with the Flutter app).
-- Note: This table is meant to mirror auth.users (1:1) for profile/signup fields.
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  full_name text,
  email text,
  country text,
  birth_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Ensure indexes exist when the table exists.
do $$
begin
  if to_regclass('public.users') is not null then
    create unique index if not exists idx_public_users_email_unique on public.users (lower(email));
  end if;
end$$;

-- Enable RLS only when table exists.
alter table if exists public.users enable row level security;

-- Create the users policy only if the table exists.
-- IMPORTANT: allow insert/update during signup (WITH CHECK true pattern).
-- Here we keep ownership constraint auth.uid() = id; for signup flows,
-- client should set id = auth.uid().
do $$
begin
  if to_regclass('public.users') is not null then
    if not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'users'
        and policyname = 'users_owner_rw'
    ) then
      create policy users_owner_rw on public.users
        for all to authenticated
        using (auth.uid() = id)
        with check (auth.uid() = id);
    end if;
  end if;
end$$;

commit;
