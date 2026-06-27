begin;

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.thix_events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid references auth.users(id) on delete set null,
  title text not null,
  summary text not null default '',
  description text not null default '',
  category text not null,
  city text not null,
  venue text not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  price_cents integer not null default 0 check (price_cents >= 0),
  currency text not null default 'XOF',
  cover_image_url text not null,
  gallery_urls text[] not null default '{}',
  tags text[] not null default '{}',
  badge_label text,
  organizer_name text not null default 'THIX Events Studio',
  organizer_verified boolean not null default true,
  is_featured boolean not null default false,
  is_recommended boolean not null default false,
  is_trending boolean not null default false,
  is_published boolean not null default true,
  seats_total integer not null default 0 check (seats_total >= 0),
  seats_remaining integer not null default 0 check (seats_remaining >= 0 and seats_remaining <= seats_total),
  attendees_count integer not null default 0 check (attendees_count >= 0),
  rating numeric(3,2) not null default 0 check (rating >= 0 and rating <= 5),
  review_count integer not null default 0 check (review_count >= 0),
  favorites_count integer not null default 0 check (favorites_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_thix_events_public_listing
  on public.thix_events (is_published, starts_at asc);
create index if not exists idx_thix_events_category
  on public.thix_events (category, starts_at asc);
create index if not exists idx_thix_events_tags
  on public.thix_events using gin (tags);

alter table public.thix_events enable row level security;

drop trigger if exists trg_thix_events_updated_at on public.thix_events;
create trigger trg_thix_events_updated_at
before update on public.thix_events
for each row execute function public.set_updated_at();

drop policy if exists "thix_events_read_published" on public.thix_events;
create policy "thix_events_read_published"
on public.thix_events
for select using (is_published = true);

drop policy if exists "thix_events_insert_own" on public.thix_events;
create policy "thix_events_insert_own"
on public.thix_events
for insert with check (organizer_id is null or auth.uid() = organizer_id);

drop policy if exists "thix_events_update_own" on public.thix_events;
create policy "thix_events_update_own"
on public.thix_events
for update using (organizer_id is null or auth.uid() = organizer_id)
with check (organizer_id is null or auth.uid() = organizer_id);

create table if not exists public.thix_event_favorites (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.thix_events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (event_id, user_id)
);

create index if not exists idx_thix_event_favorites_user
  on public.thix_event_favorites (user_id, created_at desc);

alter table public.thix_event_favorites enable row level security;

drop policy if exists "thix_event_favorites_read_own" on public.thix_event_favorites;
create policy "thix_event_favorites_read_own"
on public.thix_event_favorites
for select using (auth.uid() = user_id);

drop policy if exists "thix_event_favorites_insert_own" on public.thix_event_favorites;
create policy "thix_event_favorites_insert_own"
on public.thix_event_favorites
for insert with check (auth.uid() = user_id);

drop policy if exists "thix_event_favorites_delete_own" on public.thix_event_favorites;
create policy "thix_event_favorites_delete_own"
on public.thix_event_favorites
for delete using (auth.uid() = user_id);

create table if not exists public.thix_event_bookings (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.thix_events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  event_title text not null,
  event_date timestamptz not null,
  event_venue text not null,
  cover_image_url text not null,
  quantity integer not null check (quantity > 0),
  total_price_cents integer not null check (total_price_cents >= 0),
  currency text not null default 'XOF',
  status text not null default 'confirmed' check (status in ('confirmed', 'pending_sync', 'cancelled')),
  ticket_code text not null,
  qr_payload text not null,
  attendee_name text,
  attendee_email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_thix_event_bookings_user
  on public.thix_event_bookings (user_id, created_at desc);

alter table public.thix_event_bookings enable row level security;

drop trigger if exists trg_thix_event_bookings_updated_at on public.thix_event_bookings;
create trigger trg_thix_event_bookings_updated_at
before update on public.thix_event_bookings
for each row execute function public.set_updated_at();

drop policy if exists "thix_event_bookings_read_own" on public.thix_event_bookings;
create policy "thix_event_bookings_read_own"
on public.thix_event_bookings
for select using (auth.uid() = user_id);

drop policy if exists "thix_event_bookings_insert_own" on public.thix_event_bookings;
create policy "thix_event_bookings_insert_own"
on public.thix_event_bookings
for insert with check (auth.uid() = user_id);

create or replace function public.reserve_thix_event(
  p_event_id uuid,
  p_quantity integer default 1,
  p_attendee_name text default null,
  p_attendee_email text default null
)
returns public.thix_event_bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event public.thix_events%rowtype;
  v_booking public.thix_event_bookings%rowtype;
  v_user_id uuid := auth.uid();
  v_quantity integer := greatest(coalesce(p_quantity, 1), 1);
  v_ticket_code text := 'THX-' || to_char(now(), 'YYYYMM') || '-' || lpad((floor(random() * 9999) + 1)::int::text, 4, '0');
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select * into v_event
  from public.thix_events
  where id = p_event_id and is_published = true
  for update;

  if not found then
    raise exception 'Event not found';
  end if;

  if v_event.seats_total > 0 and v_event.seats_remaining < v_quantity then
    raise exception 'Not enough seats remaining';
  end if;

  update public.thix_events
  set seats_remaining = case when seats_total > 0 then greatest(seats_remaining - v_quantity, 0) else seats_remaining end,
      attendees_count = attendees_count + v_quantity,
      updated_at = now()
  where id = v_event.id;

  insert into public.thix_event_bookings (
    event_id,
    user_id,
    event_title,
    event_date,
    event_venue,
    cover_image_url,
    quantity,
    total_price_cents,
    currency,
    status,
    ticket_code,
    qr_payload,
    attendee_name,
    attendee_email
  )
  values (
    v_event.id,
    v_user_id,
    v_event.title,
    v_event.starts_at,
    v_event.venue,
    v_event.cover_image_url,
    v_quantity,
    v_event.price_cents * v_quantity,
    v_event.currency,
    'confirmed',
    v_ticket_code,
    'thix-event:' || v_event.id::text || ':' || v_ticket_code,
    p_attendee_name,
    p_attendee_email
  )
  returning * into v_booking;

  return v_booking;
end;
$$;

grant execute on function public.reserve_thix_event(uuid, integer, text, text) to authenticated;

commit;
