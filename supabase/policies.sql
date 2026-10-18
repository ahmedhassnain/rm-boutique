-- =====================================================================
-- R&M Boutique: Row Level Security, storage and realtime   OWNER: Ahmed
-- Run AFTER schema.sql.
--   customer : sees own orders, browses the catalogue, uploads payment proof
--   rider    : sees only orders assigned to them, uploads delivery photo
--   admin    : sees and manages everything
-- =====================================================================

alter table public.profiles         enable row level security;
alter table public.products         enable row level security;
alter table public.product_variants enable row level security;
alter table public.orders           enable row level security;
alter table public.order_items      enable row level security;
alter table public.payments         enable row level security;
alter table public.deliveries       enable row level security;

-- ---------- profiles --------------------------------------------------
create policy "read own profile" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "admin reads all profiles" on public.profiles
  for select to authenticated using (public.app_role() = 'admin');
-- A customer or rider sees the name/phone of the other side of THEIR order.
create policy "read people on my orders" on public.profiles
  for select to authenticated using (
    exists (select 1 from public.orders o
             where (o.customer_id = auth.uid() and o.rider_id = profiles.id)
                or (o.rider_id = auth.uid() and o.customer_id = profiles.id)));
-- Users may edit their name and phone, but never their role.
create policy "update own profile" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
revoke update on public.profiles from authenticated;
grant  update (full_name, phone) on public.profiles to authenticated;

-- ---------- catalogue -------------------------------------------------
create policy "anyone signed in reads products" on public.products
  for select to authenticated using (is_active or public.app_role() = 'admin');
create policy "admin manages products" on public.products
  for all to authenticated
  using (public.app_role() = 'admin') with check (public.app_role() = 'admin');

create policy "anyone signed in reads variants" on public.product_variants
  for select to authenticated using (true);
create policy "admin manages variants" on public.product_variants
  for all to authenticated
  using (public.app_role() = 'admin') with check (public.app_role() = 'admin');

-- ---------- orders ----------------------------------------------------
-- No insert policy: customers create orders only through place_order().
create policy "customer reads own orders" on public.orders
  for select to authenticated using (customer_id = auth.uid());
create policy "rider reads assigned orders" on public.orders
  for select to authenticated using (rider_id = auth.uid());
create policy "admin reads all orders" on public.orders
  for select to authenticated using (public.app_role() = 'admin');
create policy "admin updates orders" on public.orders
  for update to authenticated
  using (public.app_role() = 'admin') with check (public.app_role() = 'admin');
create policy "rider updates assigned orders" on public.orders
  for update to authenticated
  using (rider_id = auth.uid() and public.app_role() = 'rider')
  with check (rider_id = auth.uid());
-- (guard_order_update() in schema.sql decides WHICH changes are allowed)

-- ---------- order_items ----------------------------------------------
create policy "read items of visible orders" on public.order_items
  for select to authenticated using (
    exists (select 1 from public.orders o where o.id = order_items.order_id));
-- the select policies on orders already limit who can see which order

-- ---------- payments --------------------------------------------------
create policy "customer reads own payment" on public.payments
  for select to authenticated using (
    exists (select 1 from public.orders o
             where o.id = payments.order_id and o.customer_id = auth.uid()));
create policy "admin reads payments" on public.payments
  for select to authenticated using (public.app_role() = 'admin');
create policy "customer uploads payment for own confirmed order" on public.payments
  for insert to authenticated with check (
    verified = false and flagged = false
    and exists (select 1 from public.orders o
                 where o.id = payments.order_id and o.customer_id = auth.uid()
                   and o.status = 'confirmed'));
create policy "customer replaces own unverified payment" on public.payments
  for update to authenticated
  using (not verified and exists (select 1 from public.orders o
          where o.id = payments.order_id and o.customer_id = auth.uid()))
  with check (verified = false and flagged = false);
create policy "admin verifies payments" on public.payments
  for update to authenticated
  using (public.app_role() = 'admin') with check (public.app_role() = 'admin');

-- ---------- deliveries ------------------------------------------------
create policy "admin reads deliveries" on public.deliveries
  for select to authenticated using (public.app_role() = 'admin');
create policy "rider reads own deliveries" on public.deliveries
  for select to authenticated using (rider_id = auth.uid());
create policy "customer reads delivery of own order" on public.deliveries
  for select to authenticated using (
    exists (select 1 from public.orders o
             where o.id = deliveries.order_id and o.customer_id = auth.uid()));
create policy "rider records delivery of assigned order" on public.deliveries
  for insert to authenticated with check (
    rider_id = auth.uid()
    and exists (select 1 from public.orders o
                 where o.id = deliveries.order_id and o.rider_id = auth.uid()
                   and o.status = 'dispatched'));

-- ---------- storage buckets ------------------------------------------
-- File paths are  <order_id>/<anything>.jpg  in the two private buckets.
insert into storage.buckets (id, name, public) values
  ('product-images', 'product-images', true),
  ('payment-proofs', 'payment-proofs', false),
  ('delivery-photos', 'delivery-photos', false)
on conflict (id) do nothing;

create policy "product images are public to read" on storage.objects
  for select using (bucket_id = 'product-images');
create policy "admin writes product images" on storage.objects
  for all to authenticated
  using (bucket_id = 'product-images' and public.app_role() = 'admin')
  with check (bucket_id = 'product-images' and public.app_role() = 'admin');

create policy "customer uploads payment proof" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'payment-proofs' and exists (
      select 1 from public.orders o
       where o.id::text = (storage.foldername(name))[1] and o.customer_id = auth.uid()));
create policy "customer replaces payment proof" on storage.objects
  for update to authenticated using (
    bucket_id = 'payment-proofs' and exists (
      select 1 from public.orders o
       where o.id::text = (storage.foldername(name))[1] and o.customer_id = auth.uid()));
create policy "read payment proof (owner or admin)" on storage.objects
  for select to authenticated using (
    bucket_id = 'payment-proofs' and (
      public.app_role() = 'admin' or exists (
        select 1 from public.orders o
         where o.id::text = (storage.foldername(name))[1] and o.customer_id = auth.uid())));

create policy "rider uploads delivery photo" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'delivery-photos' and exists (
      select 1 from public.orders o
       where o.id::text = (storage.foldername(name))[1] and o.rider_id = auth.uid()));
create policy "read delivery photo (rider, customer or admin)" on storage.objects
  for select to authenticated using (
    bucket_id = 'delivery-photos' and (
      public.app_role() = 'admin' or exists (
        select 1 from public.orders o
         where o.id::text = (storage.foldername(name))[1]
           and (o.customer_id = auth.uid() or o.rider_id = auth.uid()))));

-- ---------- function permissions -------------------------------------
revoke execute on function public.place_order(text, double precision, double precision, date, text, jsonb) from public, anon;
grant  execute on function public.place_order(text, double precision, double precision, date, text, jsonb) to authenticated;

-- ---------- realtime (live order updates) ----------------------------
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.payments;
alter publication supabase_realtime add table public.product_variants;
