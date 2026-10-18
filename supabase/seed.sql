-- =====================================================================
-- R&M Boutique: test data                          OWNER: Ahmed
-- Run AFTER schema.sql and policies.sql.
--
-- STEP 1  In the Supabase dashboard go to Authentication -> Users -> Add user
--         and create three users (tick "Auto Confirm User"):
--           admin@rm-boutique.test     / Test1234!
--           customer@rm-boutique.test  / Test1234!
--           rider@rm-boutique.test     / Test1234!
-- STEP 2  Run this file. It promotes the admin and the rider and adds products.
-- =====================================================================

update public.profiles set role = 'admin',  full_name = 'Ahmed Hassnain'
 where email = 'admin@rm-boutique.test';
update public.profiles set role = 'rider',  full_name = 'Ahmad M.D Mousa'
 where email = 'rider@rm-boutique.test';
update public.profiles set full_name = 'Maheen Zubair'
 where email = 'customer@rm-boutique.test';

with p as (
  insert into public.products (name, description, category, price) values
    ('Tatreez Evening Dress',  'Hand-embroidered cross-stitch panel on a deep olive dress.', 'Dresses', 389.00),
    ('Terracotta Thobe',       'Classic thobe with traditional chest embroidery.',            'Dresses', 450.00),
    ('Sand Linen Abaya',       'Light linen abaya with a stitched hem.',                      'Abayas',  279.00),
    ('Ivory Embroidered Shawl','Soft shawl with a tatreez border.',                           'Accessories', 120.00),
    ('Olive Everyday Dress',   'Relaxed midi dress, easy to wear and wash.',                  'Dresses', 215.00),
    ('Cross-Stitch Clutch',    'Small clutch with a hand-stitched medallion.',                'Accessories', 95.00)
  returning id, name
)
insert into public.product_variants (product_id, size, colour, stock)
select p.id, v.size, v.colour, v.stock
  from p
  join (values
    ('Tatreez Evening Dress','S','Olive',3), ('Tatreez Evening Dress','M','Olive',4), ('Tatreez Evening Dress','L','Olive',1),
    ('Terracotta Thobe','M','Terracotta',2),  ('Terracotta Thobe','L','Terracotta',2),
    ('Sand Linen Abaya','M','Sand',5),        ('Sand Linen Abaya','L','Sand',3),
    ('Ivory Embroidered Shawl','One size','Ivory',8),
    ('Olive Everyday Dress','S','Olive',4),   ('Olive Everyday Dress','M','Olive',4),
    ('Cross-Stitch Clutch','One size','Terracotta',6)
  ) as v(pname, size, colour, stock) on v.pname = p.name;
