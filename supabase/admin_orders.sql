-- =====================================================================
-- R&M Boutique: orders typed in by the admin ("Add order")   OWNER: Ahmed
-- Run AFTER schema.sql and policies.sql. Safe to run twice.
--
-- place_order() only accepts customers. This adds the same thing for the
-- admin: an order for a registered customer who ordered by Instagram,
-- WhatsApp or in the shop. Prices and stock work exactly as for a customer
-- order: prices come from the products table and stock is reduced in the
-- same transaction. The order starts as "confirmed", like any other, and
-- follows the same flow afterwards.
-- =====================================================================

create or replace function public.admin_place_order(
  p_customer uuid,
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
  if auth.uid() is null or public.app_role() <> 'admin' then
    raise exception 'Only the admin can add an order for a customer';
  end if;
  if not exists (select 1 from profiles where id = p_customer and role = 'customer') then
    raise exception 'Choose a registered customer';
  end if;
  if p_address is null or btrim(p_address) = '' then
    raise exception 'A delivery address is needed';
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
  values (p_customer, btrim(p_address), p_lat, p_lng, p_needed_by, p_notes, v_total)
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

revoke all on function public.admin_place_order(uuid, text, double precision, double precision, date, text, jsonb) from public;
grant execute on function public.admin_place_order(uuid, text, double precision, double precision, date, text, jsonb) to authenticated;

-- The admin also needs to see which customers exist (names for the picker).
-- policies.sql already has "admin reads all profiles".
