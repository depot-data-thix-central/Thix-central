-- Repair migration: make sure public.social_connections has the expected columns.
-- This fixes remote environments where the table existed with a different column name
-- (so CREATE TABLE IF NOT EXISTS didn't apply the intended schema, and index creation failed).

begin;

do $$
begin
  -- If addressee_id is missing but a legacy column exists, rename it to addressee_id.
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'social_connections'
      and column_name = 'addressee_id'
  ) then
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'social_connections'
        and column_name = 'addressee_user_id'
    ) then
      alter table public.social_connections rename column addressee_user_id to addressee_id;
    elsif exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'social_connections'
        and column_name = 'addressee'
    ) then
      alter table public.social_connections rename column addressee to addressee_id;
    elsif exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'social_connections'
        and column_name = 'recipient_id'
    ) then
      alter table public.social_connections rename column recipient_id to addressee_id;
    elsif exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'social_connections'
        and column_name = 'target_user_id'
    ) then
      alter table public.social_connections rename column target_user_id to addressee_id;
    else
      -- As a last resort, add the column (nullable). We don't set NOT NULL here because
      -- existing rows would fail without a backfill.
      alter table public.social_connections add column if not exists addressee_id uuid;
    end if;
  end if;
end $$;

-- Ensure the index exists only if the column exists.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'social_connections'
      and column_name = 'addressee_id'
  ) then
    create index if not exists idx_social_connections_addressee
      on public.social_connections(addressee_id);
  end if;
end $$;

commit;
