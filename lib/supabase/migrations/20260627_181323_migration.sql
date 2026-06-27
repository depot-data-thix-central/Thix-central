-- THIX baseline schema (safe to apply on existing Supabase instance)
-- Includes profiles, public.users (signup form), and market tables.

begin;

-- Extensions
create extension if not exists "pgcrypto";

-- Helper to maintain updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =============================================================================
-- Profiles (public user surface linked to auth.users)
-- =============================================================================

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  thix_id text,
  country text,
  birth_date date,
  email_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists thix_id text;
alter table public.profiles add column if not exists country text;
alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists email_verified boolean not null default false;

create unique index if not exists idx_profiles_thix_id_unique on public.profiles (thix_id);

-- THIX ID generation (kept forward compatible)
create or replace function public._thix_random_block(len int)
returns text
language plpgsql
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  out_text text := '';
  i int;
  idx int;
begin
  for i in 1..len loop
    idx := 1 + floor(random() * length(alphabet))::int;
    out_text := out_text || substr(alphabet, idx, 1);
  end loop;
  return out_text;
end;
$$;

create or replace function public.generate_thix_id()
returns text
language plpgsql
as $$
declare
  candidate text;
begin
  loop
    candidate := 'THIX-' || public._thix_random_block(4) || '-' || public._thix_random_block(4) || '-' || public._thix_random_block(4);
    exit when not exists(select 1 from public.profiles p where p.thix_id = candidate);
  end loop;
  return candidate;
end;
$$;

create or replace function public.set_profile_thix_id()
returns trigger
language plpgsql
as $$
begin
  if new.thix_id is null or new.thix_id = '' then
    new.thix_id := public.generate_thix_id();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_thix_id on public.profiles;
create trigger trg_profiles_thix_id
before insert on public.profiles
for each row execute function public.set_profile_thix_id();

create or replace function public.prevent_thix_id_update()
returns trigger
language plpgsql
as $$
begin
  if new.thix_id is distinct from old.thix_id then
    raise exception 'thix_id is immutable';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_thix_id_immutable on public.profiles;
create trigger trg_profiles_thix_id_immutable
before update on public.profiles
for each row execute function public.prevent_thix_id_update();

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "profiles_read_all" on public.profiles;
create policy "profiles_read_all" on public.profiles for select using (true);

drop policy if exists "profiles_upsert_own" on public.profiles;
create policy "profiles_upsert_own" on public.profiles for insert with check (auth.uid() = user_id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =============================================================================
-- public.users (signup form: name/email/country/birth_date)
-- =============================================================================

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  country text,
  birth_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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

alter table public.users enable row level security;

drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users for select using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own" on public.users for insert with check (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own" on public.users for update using (auth.uid() = id) with check (auth.uid() = id);

-- =============================================================================
-- Market tables (products, media, cart, orders)
-- =============================================================================

create table if not exists public.market_products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  price_cents integer not null check (price_cents >= 0),
  currency text not null default 'XOF',
  stock integer not null default 0 check (stock >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_market_products_updated_at on public.market_products;
create trigger trg_market_products_updated_at before update on public.market_products for each row execute function public.set_updated_at();

create index if not exists idx_market_products_active_created on public.market_products (is_active, created_at desc);

alter table public.market_products enable row level security;

drop policy if exists "products_read_active" on public.market_products;
create policy "products_read_active" on public.market_products for select using (is_active = true);

drop policy if exists "products_insert_own" on public.market_products;
create policy "products_insert_own" on public.market_products for insert with check (auth.uid() = seller_id);

drop policy if exists "products_update_own" on public.market_products;
create policy "products_update_own" on public.market_products for update using (auth.uid() = seller_id) with check (auth.uid() = seller_id);

create table if not exists public.market_product_media (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.market_products(id) on delete cascade,
  url text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_market_product_media_updated_at on public.market_product_media;
create trigger trg_market_product_media_updated_at before update on public.market_product_media for each row execute function public.set_updated_at();

create index if not exists idx_market_product_media_product on public.market_product_media (product_id, sort_order asc);

alter table public.market_product_media enable row level security;

drop policy if exists "product_media_read_active_products" on public.market_product_media;
create policy "product_media_read_active_products" on public.market_product_media for select using (
  exists(select 1 from public.market_products p where p.id = product_id and p.is_active = true)
);

drop policy if exists "product_media_insert_owner" on public.market_product_media;
create policy "product_media_insert_owner" on public.market_product_media for insert with check (
  exists(select 1 from public.market_products p where p.id = product_id and p.seller_id = auth.uid())
);

drop policy if exists "product_media_update_owner" on public.market_product_media;
create policy "product_media_update_owner" on public.market_product_media for update using (
  exists(select 1 from public.market_products p where p.id = product_id and p.seller_id = auth.uid())
)
with check (
  exists(select 1 from public.market_products p where p.id = product_id and p.seller_id = auth.uid())
);

drop policy if exists "product_media_delete_owner" on public.market_product_media;
create policy "product_media_delete_owner" on public.market_product_media for delete using (
  exists(select 1 from public.market_products p where p.id = product_id and p.seller_id = auth.uid())
);

create table if not exists public.market_cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.market_products(id) on delete cascade,
  quantity integer not null check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, product_id)
);

drop trigger if exists trg_market_cart_items_updated_at on public.market_cart_items;
create trigger trg_market_cart_items_updated_at before update on public.market_cart_items for each row execute function public.set_updated_at();

create index if not exists idx_market_cart_items_user on public.market_cart_items (user_id, updated_at desc);

alter table public.market_cart_items enable row level security;

drop policy if exists "cart_read_own" on public.market_cart_items;
create policy "cart_read_own" on public.market_cart_items for select using (auth.uid() = user_id);

drop policy if exists "cart_insert_own" on public.market_cart_items;
create policy "cart_insert_own" on public.market_cart_items for insert with check (auth.uid() = user_id);

drop policy if exists "cart_update_own" on public.market_cart_items;
create policy "cart_update_own" on public.market_cart_items for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "cart_delete_own" on public.market_cart_items;
create policy "cart_delete_own" on public.market_cart_items for delete using (auth.uid() = user_id);

create table if not exists public.market_orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','confirmed','shipped','delivered','cancelled')),
  currency text not null default 'XOF',
  subtotal_cents integer not null default 0 check (subtotal_cents >= 0),
  shipping_cents integer not null default 0 check (shipping_cents >= 0),
  total_cents integer not null default 0 check (total_cents >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_market_orders_updated_at on public.market_orders;
create trigger trg_market_orders_updated_at before update on public.market_orders for each row execute function public.set_updated_at();

create index if not exists idx_market_orders_buyer_created on public.market_orders (buyer_id, created_at desc);

alter table public.market_orders enable row level security;

drop policy if exists "orders_read_own" on public.market_orders;
create policy "orders_read_own" on public.market_orders for select using (auth.uid() = buyer_id);

drop policy if exists "orders_insert_own" on public.market_orders;
create policy "orders_insert_own" on public.market_orders for insert with check (auth.uid() = buyer_id);

drop policy if exists "orders_update_own" on public.market_orders;
create policy "orders_update_own" on public.market_orders for update using (auth.uid() = buyer_id) with check (auth.uid() = buyer_id);

create table if not exists public.market_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.market_orders(id) on delete cascade,
  product_id uuid not null references public.market_products(id),
  seller_id uuid not null references auth.users(id),
  title text not null,
  unit_price_cents integer not null,
  quantity integer not null check (quantity > 0),
  line_total_cents integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_market_order_items_updated_at on public.market_order_items;
create trigger trg_market_order_items_updated_at before update on public.market_order_items for each row execute function public.set_updated_at();

create index if not exists idx_market_order_items_order on public.market_order_items (order_id);

alter table public.market_order_items enable row level security;

drop policy if exists "order_items_read_own_order" on public.market_order_items;
create policy "order_items_read_own_order" on public.market_order_items for select using (
  exists(select 1 from public.market_orders o where o.id = order_id and o.buyer_id = auth.uid())
);

drop policy if exists "order_items_insert_own_order" on public.market_order_items;
create policy "order_items_insert_own_order" on public.market_order_items for insert with check (
  exists(select 1 from public.market_orders o where o.id = order_id and o.buyer_id = auth.uid())
);

commit;