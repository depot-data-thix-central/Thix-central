-- Dreamflow migration: THIX Profile (dashboard) module

begin;

-- =============================================================================
-- Enums
-- =============================================================================

do $$ begin
  create type public.document_status as enum ('pending','verified','rejected');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.transaction_status as enum ('pending','success','failed','refunded');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.transaction_type as enum ('activation','document_upload');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.skill_level as enum ('beginner','intermediate','advanced','expert');
exception when duplicate_object then null;
end $$;

-- =============================================================================
-- Profile details (civil info + visibility + activation)
-- =============================================================================

create table if not exists public.profile_details (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  bio text,
  phone text,
  address text,
  city text,
  nationality text,
  marital_status text,
  birth_place text,
  father_name text,
  mother_name text,
  thix_account_status text not null default 'THIX-PENDING',
  public_bio boolean not null default true,
  public_experiences boolean not null default true,
  public_education boolean not null default true,
  public_skills boolean not null default true,
  public_languages boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_details_updated_at on public.profile_details;
create trigger trg_profile_details_updated_at before update on public.profile_details
for each row execute function public.set_updated_at();

alter table public.profile_details enable row level security;

drop policy if exists "profile_details_select_own" on public.profile_details;
create policy "profile_details_select_own" on public.profile_details
for select using (auth.uid() = user_id);

drop policy if exists "profile_details_insert_own" on public.profile_details;
create policy "profile_details_insert_own" on public.profile_details
for insert with check (auth.uid() = user_id);

drop policy if exists "profile_details_update_own" on public.profile_details;
create policy "profile_details_update_own" on public.profile_details
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =============================================================================
-- Emergency contacts
-- =============================================================================

create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text not null,
  relationship text,
  city text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_emergency_contacts_updated_at on public.emergency_contacts;
create trigger trg_emergency_contacts_updated_at before update on public.emergency_contacts
for each row execute function public.set_updated_at();

create index if not exists idx_emergency_contacts_user on public.emergency_contacts (user_id, created_at desc);

alter table public.emergency_contacts enable row level security;

drop policy if exists "emergency_contacts_read_own" on public.emergency_contacts;
create policy "emergency_contacts_read_own" on public.emergency_contacts
for select using (auth.uid() = user_id);

drop policy if exists "emergency_contacts_write_own" on public.emergency_contacts;
create policy "emergency_contacts_write_own" on public.emergency_contacts
for insert with check (auth.uid() = user_id);

drop policy if exists "emergency_contacts_update_own" on public.emergency_contacts;
create policy "emergency_contacts_update_own" on public.emergency_contacts
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "emergency_contacts_delete_own" on public.emergency_contacts;
create policy "emergency_contacts_delete_own" on public.emergency_contacts
for delete using (auth.uid() = user_id);

-- =============================================================================
-- Experiences, education, skills, languages
-- =============================================================================

create table if not exists public.profile_experiences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  organization text,
  sector text,
  city text,
  start_date date,
  end_date date,
  missions text,
  attachments jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_experiences_updated_at on public.profile_experiences;
create trigger trg_profile_experiences_updated_at before update on public.profile_experiences
for each row execute function public.set_updated_at();

create index if not exists idx_profile_experiences_user on public.profile_experiences (user_id, start_date desc nulls last, created_at desc);

alter table public.profile_experiences enable row level security;
drop policy if exists "profile_experiences_read_own" on public.profile_experiences;
create policy "profile_experiences_read_own" on public.profile_experiences for select using (auth.uid() = user_id);
drop policy if exists "profile_experiences_write_own" on public.profile_experiences;
create policy "profile_experiences_write_own" on public.profile_experiences for insert with check (auth.uid() = user_id);
drop policy if exists "profile_experiences_update_own" on public.profile_experiences;
create policy "profile_experiences_update_own" on public.profile_experiences for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "profile_experiences_delete_own" on public.profile_experiences;
create policy "profile_experiences_delete_own" on public.profile_experiences for delete using (auth.uid() = user_id);

create table if not exists public.profile_education (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  institution text not null,
  degree text,
  level text,
  start_year int,
  end_year int,
  description text,
  attachments jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_education_updated_at on public.profile_education;
create trigger trg_profile_education_updated_at before update on public.profile_education
for each row execute function public.set_updated_at();

create index if not exists idx_profile_education_user on public.profile_education (user_id, end_year desc nulls last, created_at desc);

alter table public.profile_education enable row level security;
drop policy if exists "profile_education_read_own" on public.profile_education;
create policy "profile_education_read_own" on public.profile_education for select using (auth.uid() = user_id);
drop policy if exists "profile_education_write_own" on public.profile_education;
create policy "profile_education_write_own" on public.profile_education for insert with check (auth.uid() = user_id);
drop policy if exists "profile_education_update_own" on public.profile_education;
create policy "profile_education_update_own" on public.profile_education for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "profile_education_delete_own" on public.profile_education;
create policy "profile_education_delete_own" on public.profile_education for delete using (auth.uid() = user_id);

create table if not exists public.profile_skills (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  level public.skill_level not null default 'beginner',
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_skills_updated_at on public.profile_skills;
create trigger trg_profile_skills_updated_at before update on public.profile_skills
for each row execute function public.set_updated_at();

create index if not exists idx_profile_skills_user on public.profile_skills (user_id, created_at desc);
alter table public.profile_skills enable row level security;
drop policy if exists "profile_skills_read_own" on public.profile_skills;
create policy "profile_skills_read_own" on public.profile_skills for select using (auth.uid() = user_id);
drop policy if exists "profile_skills_write_own" on public.profile_skills;
create policy "profile_skills_write_own" on public.profile_skills for insert with check (auth.uid() = user_id);
drop policy if exists "profile_skills_update_own" on public.profile_skills;
create policy "profile_skills_update_own" on public.profile_skills for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "profile_skills_delete_own" on public.profile_skills;
create policy "profile_skills_delete_own" on public.profile_skills for delete using (auth.uid() = user_id);

create table if not exists public.profile_languages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  level text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_languages_updated_at on public.profile_languages;
create trigger trg_profile_languages_updated_at before update on public.profile_languages
for each row execute function public.set_updated_at();

create index if not exists idx_profile_languages_user on public.profile_languages (user_id, created_at desc);
alter table public.profile_languages enable row level security;
drop policy if exists "profile_languages_read_own" on public.profile_languages;
create policy "profile_languages_read_own" on public.profile_languages for select using (auth.uid() = user_id);
drop policy if exists "profile_languages_write_own" on public.profile_languages;
create policy "profile_languages_write_own" on public.profile_languages for insert with check (auth.uid() = user_id);
drop policy if exists "profile_languages_update_own" on public.profile_languages;
create policy "profile_languages_update_own" on public.profile_languages for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "profile_languages_delete_own" on public.profile_languages;
create policy "profile_languages_delete_own" on public.profile_languages for delete using (auth.uid() = user_id);

-- =============================================================================
-- Documents (metadata)
-- =============================================================================

create table if not exists public.profile_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  doc_type text not null,
  label text,
  file_url text,
  status public.document_status not null default 'pending',
  kyc_pack jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_documents_updated_at on public.profile_documents;
create trigger trg_profile_documents_updated_at before update on public.profile_documents
for each row execute function public.set_updated_at();

create index if not exists idx_profile_documents_user on public.profile_documents (user_id, created_at desc);

alter table public.profile_documents enable row level security;
drop policy if exists "profile_documents_read_own" on public.profile_documents;
create policy "profile_documents_read_own" on public.profile_documents for select using (auth.uid() = user_id);
drop policy if exists "profile_documents_write_own" on public.profile_documents;
create policy "profile_documents_write_own" on public.profile_documents for insert with check (auth.uid() = user_id);
drop policy if exists "profile_documents_update_own" on public.profile_documents;
create policy "profile_documents_update_own" on public.profile_documents for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "profile_documents_delete_own" on public.profile_documents;
create policy "profile_documents_delete_own" on public.profile_documents for delete using (auth.uid() = user_id);

-- =============================================================================
-- Transactions (simulated) + receipts
-- =============================================================================

create table if not exists public.profile_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  txn_type public.transaction_type not null,
  amount_usd numeric(10,2) not null,
  method text not null default 'SIMULATED',
  status public.transaction_status not null default 'success',
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_transactions_updated_at on public.profile_transactions;
create trigger trg_profile_transactions_updated_at before update on public.profile_transactions
for each row execute function public.set_updated_at();

create index if not exists idx_profile_transactions_user on public.profile_transactions (user_id, created_at desc);

alter table public.profile_transactions enable row level security;
drop policy if exists "profile_transactions_read_own" on public.profile_transactions;
create policy "profile_transactions_read_own" on public.profile_transactions for select using (auth.uid() = user_id);
drop policy if exists "profile_transactions_write_own" on public.profile_transactions;
create policy "profile_transactions_write_own" on public.profile_transactions for insert with check (auth.uid() = user_id);

-- =============================================================================
-- Security settings + activity log
-- =============================================================================

create table if not exists public.profile_security_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  biometrics_enabled boolean not null default false,
  two_fa_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_security_settings_updated_at on public.profile_security_settings;
create trigger trg_profile_security_settings_updated_at before update on public.profile_security_settings
for each row execute function public.set_updated_at();

alter table public.profile_security_settings enable row level security;
drop policy if exists "profile_security_settings_read_own" on public.profile_security_settings;
create policy "profile_security_settings_read_own" on public.profile_security_settings for select using (auth.uid() = user_id);
drop policy if exists "profile_security_settings_write_own" on public.profile_security_settings;
create policy "profile_security_settings_write_own" on public.profile_security_settings for insert with check (auth.uid() = user_id);
drop policy if exists "profile_security_settings_update_own" on public.profile_security_settings;
create policy "profile_security_settings_update_own" on public.profile_security_settings for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.profile_security_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null,
  details jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profile_security_events_updated_at on public.profile_security_events;
create trigger trg_profile_security_events_updated_at before update on public.profile_security_events
for each row execute function public.set_updated_at();

create index if not exists idx_profile_security_events_user on public.profile_security_events (user_id, created_at desc);

alter table public.profile_security_events enable row level security;
drop policy if exists "profile_security_events_read_own" on public.profile_security_events;
create policy "profile_security_events_read_own" on public.profile_security_events for select using (auth.uid() = user_id);
drop policy if exists "profile_security_events_write_own" on public.profile_security_events;
create policy "profile_security_events_write_own" on public.profile_security_events for insert with check (auth.uid() = user_id);

commit;
