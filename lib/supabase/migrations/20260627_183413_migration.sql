-- Patch migration: fix policy creation syntax (CREATE POLICY lacks IF NOT EXISTS).
-- This re-applies all policies using DO blocks so it succeeds even if they already exist.

--------------------------
-- Ensure RLS is enabled
--------------------------
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.market_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.market_product_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.market_cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.market_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.market_order_items ENABLE ROW LEVEL SECURITY;

--------------------------
-- Policies (idempotent via pg_policies check)
--------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_owner_rw'
  ) THEN
    CREATE POLICY profiles_owner_rw ON public.profiles
      FOR ALL TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_owner_rw'
  ) THEN
    CREATE POLICY users_owner_rw ON public.users
      FOR ALL TO authenticated
      USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_products' AND policyname = 'market_products_select_active'
  ) THEN
    CREATE POLICY market_products_select_active ON public.market_products
      FOR SELECT TO authenticated
      USING (is_active = TRUE);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_products' AND policyname = 'market_products_seller_rw'
  ) THEN
    CREATE POLICY market_products_seller_rw ON public.market_products
      FOR ALL TO authenticated
      USING (auth.uid() = seller_id)
      WITH CHECK (auth.uid() = seller_id);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_product_media' AND policyname = 'market_product_media_select'
  ) THEN
    CREATE POLICY market_product_media_select ON public.market_product_media
      FOR SELECT TO authenticated USING (TRUE);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_product_media' AND policyname = 'market_product_media_seller_rw'
  ) THEN
    CREATE POLICY market_product_media_seller_rw ON public.market_product_media
      FOR ALL TO authenticated
      USING (auth.uid() = (SELECT seller_id FROM public.market_products mp WHERE mp.id = product_id))
      WITH CHECK (auth.uid() = (SELECT seller_id FROM public.market_products mp WHERE mp.id = product_id));
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_cart_items' AND policyname = 'market_cart_items_owner_rw'
  ) THEN
    CREATE POLICY market_cart_items_owner_rw ON public.market_cart_items
      FOR ALL TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_orders' AND policyname = 'market_orders_buyer_rw'
  ) THEN
    CREATE POLICY market_orders_buyer_rw ON public.market_orders
      FOR ALL TO authenticated
      USING (auth.uid() = buyer_id)
      WITH CHECK (auth.uid() = buyer_id);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_order_items' AND policyname = 'market_order_items_select_buyer_or_seller'
  ) THEN
    CREATE POLICY market_order_items_select_buyer_or_seller ON public.market_order_items
      FOR SELECT TO authenticated
      USING (auth.uid() = seller_id OR auth.uid() = (SELECT buyer_id FROM public.market_orders o WHERE o.id = order_id));
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_order_items' AND policyname = 'market_order_items_insert_buyer'
  ) THEN
    CREATE POLICY market_order_items_insert_buyer ON public.market_order_items
      FOR INSERT TO authenticated
      WITH CHECK (auth.uid() = (SELECT buyer_id FROM public.market_orders o WHERE o.id = order_id));
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'market_order_items' AND policyname = 'market_order_items_delete_buyer'
  ) THEN
    CREATE POLICY market_order_items_delete_buyer ON public.market_order_items
      FOR DELETE TO authenticated
      USING (auth.uid() = (SELECT buyer_id FROM public.market_orders o WHERE o.id = order_id));
  END IF;
END$$;