-- Migration: align Supabase schema with current Flutter app models.
-- Safe for fresh DBs: uses IF NOT EXISTS guards and avoids drops.

 --------------------------
 -- Helper: updated_at trigger
 --------------------------
 CREATE EXTENSION IF NOT EXISTS "pgcrypto";

 CREATE OR REPLACE FUNCTION public.set_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--------------------------
-- Table: public.profiles
--------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  country TEXT,
  birth_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

--------------------------
-- Table: public.users (signup form data)
--------------------------
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  country TEXT,
  birth_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_lower_unique ON public.users (LOWER(email));

DROP TRIGGER IF EXISTS trg_users_updated_at ON public.users;
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

--------------------------
-- Table: public.market_products
--------------------------
CREATE TABLE IF NOT EXISTS public.market_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  price_cents INTEGER NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'XOF',
  stock INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_market_products_updated_at ON public.market_products;
CREATE TRIGGER trg_market_products_updated_at
BEFORE UPDATE ON public.market_products
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

--------------------------
-- Table: public.market_product_media
--------------------------
CREATE TABLE IF NOT EXISTS public.market_product_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES public.market_products (id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_market_product_media_product_id ON public.market_product_media (product_id);
CREATE INDEX IF NOT EXISTS idx_market_product_media_sort ON public.market_product_media (product_id, sort_order);

--------------------------
-- Table: public.market_cart_items
--------------------------
CREATE TABLE IF NOT EXISTS public.market_cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.market_products (id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_market_cart_items_user ON public.market_cart_items (user_id);
CREATE INDEX IF NOT EXISTS idx_market_cart_items_product ON public.market_cart_items (product_id);

DROP TRIGGER IF EXISTS trg_market_cart_items_updated_at ON public.market_cart_items;
CREATE TRIGGER trg_market_cart_items_updated_at
BEFORE UPDATE ON public.market_cart_items
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

--------------------------
-- Table: public.market_orders
--------------------------
CREATE TABLE IF NOT EXISTS public.market_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',
  currency TEXT NOT NULL DEFAULT 'XOF',
  subtotal_cents INTEGER NOT NULL DEFAULT 0,
  shipping_cents INTEGER NOT NULL DEFAULT 0,
  total_cents INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_market_orders_buyer ON public.market_orders (buyer_id);
CREATE INDEX IF NOT EXISTS idx_market_orders_created ON public.market_orders (created_at DESC);

DROP TRIGGER IF EXISTS trg_market_orders_updated_at ON public.market_orders;
CREATE TRIGGER trg_market_orders_updated_at
BEFORE UPDATE ON public.market_orders
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

--------------------------
-- Table: public.market_order_items
--------------------------
CREATE TABLE IF NOT EXISTS public.market_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.market_orders (id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.market_products (id) ON DELETE SET NULL,
  seller_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  unit_price_cents INTEGER NOT NULL DEFAULT 0,
  quantity INTEGER NOT NULL DEFAULT 1,
  line_total_cents INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_market_order_items_order ON public.market_order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_market_order_items_seller ON public.market_order_items (seller_id);

--------------------------
-- Row Level Security
--------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_product_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_order_items ENABLE ROW LEVEL SECURITY;

-- profiles: owner can read/write
CREATE POLICY IF NOT EXISTS profiles_owner_rw ON public.profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- users table: allow insert/update even during signup; owner read/write
CREATE POLICY IF NOT EXISTS users_owner_rw ON public.users
  FOR ALL TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- market_products: everyone can read active products; sellers manage their own
CREATE POLICY IF NOT EXISTS market_products_select_active ON public.market_products
  FOR SELECT TO authenticated
  USING (is_active = TRUE);

CREATE POLICY IF NOT EXISTS market_products_seller_rw ON public.market_products
  FOR ALL TO authenticated
  USING (auth.uid() = seller_id)
  WITH CHECK (auth.uid() = seller_id);

-- market_product_media: readable to all; seller manages
CREATE POLICY IF NOT EXISTS market_product_media_select ON public.market_product_media
  FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY IF NOT EXISTS market_product_media_seller_rw ON public.market_product_media
  FOR ALL TO authenticated
  USING (auth.uid() = (SELECT seller_id FROM public.market_products mp WHERE mp.id = product_id))
  WITH CHECK (auth.uid() = (SELECT seller_id FROM public.market_products mp WHERE mp.id = product_id));

-- cart items: owner only
CREATE POLICY IF NOT EXISTS market_cart_items_owner_rw ON public.market_cart_items
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- orders: buyer only
CREATE POLICY IF NOT EXISTS market_orders_buyer_rw ON public.market_orders
  FOR ALL TO authenticated
  USING (auth.uid() = buyer_id)
  WITH CHECK (auth.uid() = buyer_id);

-- order items: visible to buyer and seller; insert limited to buyer
CREATE POLICY IF NOT EXISTS market_order_items_select_buyer_or_seller ON public.market_order_items
  FOR SELECT TO authenticated
  USING (auth.uid() = seller_id OR auth.uid() = (SELECT buyer_id FROM public.market_orders o WHERE o.id = order_id));

CREATE POLICY IF NOT EXISTS market_order_items_insert_buyer ON public.market_order_items
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = (SELECT buyer_id FROM public.market_orders o WHERE o.id = order_id));

CREATE POLICY IF NOT EXISTS market_order_items_delete_buyer ON public.market_order_items
  FOR DELETE TO authenticated
  USING (auth.uid() = (SELECT buyer_id FROM public.market_orders o WHERE o.id = order_id));
