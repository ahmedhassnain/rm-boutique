-- =====================================================================
-- R&M Boutique: demo conversations for the chat            OWNER: Ahmed
-- Run AFTER chat.sql and seed.sql, in the Supabase SQL editor.
--
-- Fills the Inbox with two realistic conversations so the chat can be tried
-- straight away:
--   * customer@rm-boutique.test (Maheen)  <->  the boutique
--   * rider@rm-boutique.test (Ahmad)      <->  the boutique
-- A customer message and a rider message are left UNREAD on purpose, so the
-- Inbox shows its badges and unread counts.
-- Safe to run twice: a person who already has messages is skipped.
-- =====================================================================

do $$
declare
  v_admin    uuid := (select id from public.profiles where email = 'admin@rm-boutique.test');
  v_customer uuid := (select id from public.profiles where email = 'customer@rm-boutique.test');
  v_rider    uuid := (select id from public.profiles where email = 'rider@rm-boutique.test');
begin
  if v_admin is null then
    raise exception 'Run seed.sql first: the admin account was not found';
  end if;

  if v_customer is not null
     and not exists (select 1 from public.messages where member_id = v_customer) then
    insert into public.messages
      (member_id, sender_id, from_admin, body, tag, read_at, created_at)
    values
      (v_customer, v_customer, false,
       'Hi! Do you have the Tatreez Evening Dress in size M?',
       'browsing', now() - interval '3 hours', now() - interval '3 hours 10 minutes'),
      (v_customer, v_admin, true,
       'Hello Maheen! Yes, the olive Tatreez dress is in stock in S, M and L.',
       null, now() - interval '2 hours 40 minutes', now() - interval '3 hours'),
      (v_customer, v_customer, false,
       'Lovely, I would like the M. I will place the order in the app now.',
       'ready_to_order', now() - interval '2 hours 30 minutes', now() - interval '2 hours 35 minutes'),
      (v_customer, v_customer, false,
       'Can it be delivered by Saturday?',
       'ready_to_order', null, now() - interval '12 minutes');
  end if;

  if v_rider is not null
     and not exists (select 1 from public.messages where member_id = v_rider) then
    insert into public.messages
      (member_id, sender_id, from_admin, body, tag, read_at, created_at)
    values
      (v_rider, v_rider, false,
       'Good morning, I am at the boutique for the pickup.',
       null, now() - interval '5 hours', now() - interval '5 hours 5 minutes'),
      (v_rider, v_admin, true,
       'Good morning Ahmad. The order is packed and waiting by the door.',
       null, now() - interval '4 hours 50 minutes', now() - interval '5 hours'),
      (v_rider, v_rider, false,
       'Got it. The customer pin looks far from the address, can you confirm?',
       null, null, now() - interval '35 minutes');
  end if;
end $$;
