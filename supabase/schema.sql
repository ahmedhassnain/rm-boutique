-- =====================================================================
-- R&M Boutique: database schema                    OWNER: Ahmed
-- Run order in the Supabase SQL editor: schema.sql -> policies.sql -> seed.sql
-- This file is the CONTRACT. Dart mirrors it in lib/shared/models.
-- =====================================================================

-- ---------- Types ----------------------------------------------------
create type public.user_role as enum ('admin', 'customer', 'rider');

-- The agreed order flow. Same five values as lib/shared/order_status.dart.
create type public.order_status as enum
  ('confirmed', 'paid', 'packed', 'dispatched', 'delivered');

-- ---------- Profiles (one row per auth user) -------------------------
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text,
  full_name   text not null default '',
  phone       text,
  role        public.user_role not null default 'customer',
  created_at  timestamptz not null default now()
);

-- Every new sign-up becomes a CUSTOMER. Admin and rider roles are granted
-- by hand in seed.sql, so nobody can sign up as admin from the app.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, phone)
  values (new.id, new.email,
          coalesce(new.raw_user_meta_data ->> 'full_name', ''),
          new.raw_user_meta_data ->> 'phone');
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Role of the signed-in user. Used by every policy and trigger below.
create function public.app_role() returns public.user_role
language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

-- ---------- Catalogue -------------------------------------------------
create table public.products (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  description  text not null default '',
  category     text not null default 'Dresses',
  price        numeric(10, 2) not null check (price >= 0),
  image_path   text,                       -- path inside bucket product-images
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

-- One row per size/colour. Stock lives here, so shop, chat and app all
-- read the same number (fixes the double-selling problem from the interviews).
create table public.product_variants (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references public.products (id) on delete cascade,
  size        text not null,
  colour      text not null,
  stock       integer not null default 0 check (stock >= 0),
  low_stock_at integer not null default 2,
  unique (product_id, size, colour)
);

-- ---------- Orders ----------------------------------------------------
create table public.orders (
  id               uuid primary key default gen_random_uuid(),
  customer_id      uuid not null references public.profiles (id),
  rider_id         uuid references public.profiles (id),
  status           public.order_status not null default 'confirmed',
  delivery_address text not null,
  address_lat      double precision,
  address_lng      double precision,
  needed_by        date,                   -- for the "date is near" flag
  notes            text,
  total            numeric(10, 2) not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table public.order_items (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders (id) on delete cascade,
  variant_id  uuid not null references public.product_variants (id),
  quantity    integer not null check (quantity > 0),
  unit_price  numeric(10, 2) not null
);

-- Payment screenshot uploaded by the customer, verified by the admin.
create table public.payments (
  id              uuid primary key default gen_random_uuid(),
  order_id        uuid not null unique references public.orders (id) on delete cascade,
  screenshot_path text not null,           -- path inside bucket payment-proofs
  amount          numeric(10, 2),
  verified        boolean not null default false,
  flagged         boolean not null default false,   -- admin marks a mismatch
  verified_by     uuid references public.profiles (id),
  verified_at     timestamptz,
  created_at      timestamptz not null default now()
);

-- Proof of delivery uploaded by the rider.
create table public.deliveries (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null unique references public.orders (id) on delete cascade,
  rider_id      uuid not null references public.profiles (id),
  photo_path    text not null,             -- path inside bucket delivery-photos
  notes         text,
  delivered_at  timestamptz not null default now()
);

create index on public.orders (customer_id);
create index on public.orders (rider_id);
create index on public.orders (status);
create index on public.order_items (order_id);

-- ---------- Placing an order (the ONLY way a customer creates one) ----
-- p_items = [{"variant_id": "...", "quantity": 2}, ...]
-- Prices come from the products table, never from the app, and stock is
-- reduced in the same transaction, so two customers cannot buy the last piece.
create function public.place_order(
  p_address text, p_lat double precision, p_lng double precision,
  p_needed_by date, p_notes text, p_items jsonb
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_order uuid;
  v_item  jsonb;
  v_var   record;
  v_qty   integer;
  v_total numeric(10, 2) := 0;
begin
  if auth.uid() is null or public.app_role() <> 'customer' then
    raise exception 'Only customers can place orders';
  end if;
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'An order needs at least one item';
  end if;

  -- Pass 1: lock the variants, check stock and work out the total.
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item ->> 'quantity')::integer;
    if v_qty is null or v_qty <= 0 then
      raise exception 'Invalid quantity';
    end if;
    select v.stock, p.price, p.is_active
      into v_var
      from product_variants v join products p on p.id = v.product_id
     where v.id = (v_item ->> 'variant_id')::uuid
       for update of v;
    if not found or not v_var.is_active then
      raise exception 'Item not available';
    end if;
    if v_var.stock < v_qty then
      raise exception 'Not enough stock for one of the items';
    end if;
    v_total := v_total + v_var.price * v_qty;
  end loop;

  insert into orders (customer_id, delivery_address, address_lat, address_lng,
                      needed_by, notes, total)
  values (auth.uid(), p_address, p_lat, p_lng, p_needed_by, p_notes, v_total)
  returning id into v_order;

  -- Pass 2: reduce stock and write the order lines (prices from the database).
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item ->> 'quantity')::integer;
    insert into order_items (order_id, variant_id, quantity, unit_price)
    select v_order, v.id, v_qty, p.price
      from product_variants v join products p on p.id = v.product_id
     where v.id = (v_item ->> 'variant_id')::uuid;
    update product_variants set stock = stock - v_qty
     where id = (v_item ->> 'variant_id')::uuid;
  end loop;

  return v_order;
end $$;

-- ---------- Guard the status flow in the database ---------------------
-- Even if someone's app code is wrong, these rules cannot be broken.
--   admin : confirmed -> paid (payment must be verified) -> packed
--           -> dispatched (rider must be assigned)
--   rider : dispatched -> delivered (only their own order, with a photo)
--   customer: cannot change an order at all
create function public.guard_order_update() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role public.user_role := public.app_role();
begin
  new.updated_at := now();

  if v_role = 'admin' then
    if new.status is distinct from old.status then
      if not ((old.status, new.status) in (
          ('confirmed','paid'), ('paid','packed'), ('packed','dispatched'))) then
        raise exception 'Admin cannot move an order from % to %', old.status, new.status;
      end if;
      if new.status = 'paid' and not exists (
          select 1 from payments where order_id = old.id and verified) then
        raise exception 'Verify the payment before marking the order as paid';
      end if;
      if new.status = 'dispatched' and new.rider_id is null then
        raise exception 'Assign a rider before dispatching';
      end if;
    end if;
    return new;
  elsif v_role = 'rider' then
    if old.rider_id is distinct from auth.uid() then
      raise exception 'This order is not assigned to you';
    end if;
    if new.rider_id is distinct from old.rider_id
       or new.customer_id is distinct from old.customer_id
       or new.total is distinct from old.total
       or new.delivery_address is distinct from old.delivery_address then
      raise exception 'Riders can only mark an order as delivered';
    end if;
    if not (old.status = 'dispatched' and new.status = 'delivered') then
      raise exception 'Riders can only move dispatched -> delivered';
    end if;
    if not exists (select 1 from deliveries where order_id = old.id) then
      raise exception 'Upload the delivery photo first';
    end if;
    return new;
  end if;
  raise exception 'You are not allowed to change orders';
end $$;

create trigger orders_guard
  before update on public.orders
  for each row execute function public.guard_order_update();
