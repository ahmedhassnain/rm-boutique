-- =====================================================================
-- R&M Boutique: chat between the boutique and its customers and riders
-- OWNER: Ahmed.  Run AFTER schema.sql and policies.sql. Safe to run twice,
-- and safe to run on top of the first version of this file (it renames the
-- old "customer_id" column and replaces the old policies and function).
--
-- One conversation per person. Every message belongs to that person
-- (member_id: a customer or a rider) and is written either by them or by
-- the admin (from_admin). A customer's message can carry a tag ("browsing"
-- or "ready_to_order") that the admin sees in the Inbox.
-- =====================================================================

create table if not exists public.messages (
  id          uuid primary key default gen_random_uuid(),
  member_id   uuid not null references public.profiles (id) on delete cascade,
  sender_id   uuid not null default auth.uid() references public.profiles (id),
  from_admin  boolean not null default false,
  body        text not null check (char_length(btrim(body)) between 1 and 1000),
  tag         text check (tag in ('browsing', 'ready_to_order')),
  read_at     timestamptz,                 -- set when the other side opens the chat
  created_at  timestamptz not null default now()
);

-- Upgrade from the first version (customers only).
do $$
begin
  if exists (select 1 from information_schema.columns
              where table_schema = 'public' and table_name = 'messages'
                and column_name = 'customer_id') then
    alter table public.messages rename column customer_id to member_id;
  end if;
end $$;

drop index if exists public.messages_customer_created_idx;
create index if not exists messages_member_created_idx
  on public.messages (member_id, created_at);

alter table public.messages enable row level security;

-- Read: a customer or rider sees only their own conversation; the admin sees all.
drop policy if exists "read own conversation or admin" on public.messages;
create policy "read own conversation or admin" on public.messages
  for select to authenticated
  using (member_id = auth.uid() or public.app_role() = 'admin');

-- Write: a customer or rider writes into their own conversation, as themselves.
drop policy if exists "customer sends message" on public.messages;
drop policy if exists "member sends message" on public.messages;
create policy "member sends message" on public.messages
  for insert to authenticated
  with check (
    public.app_role() in ('customer', 'rider')
    and member_id = auth.uid()
    and sender_id = auth.uid()
    and from_admin = false
    and (tag is null or public.app_role() = 'customer')
  );

-- Write: the admin replies into anyone's conversation, as admin.
drop policy if exists "admin sends message" on public.messages;
create policy "admin sends message" on public.messages
  for insert to authenticated
  with check (
    public.app_role() = 'admin'
    and sender_id = auth.uid()
    and from_admin = true
  );

-- No update or delete policy: messages cannot be edited or removed.
-- "Seen" marks go through this function, which can only set read_at on the
-- messages the OTHER side wrote.
drop function if exists public.mark_thread_read(uuid);
create function public.mark_thread_read(p_member uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if public.app_role() = 'admin' then
    update public.messages set read_at = now()
     where member_id = p_member and not from_admin and read_at is null;
  elsif auth.uid() = p_member then
    update public.messages set read_at = now()
     where member_id = p_member and from_admin and read_at is null;
  end if;
end $$;

grant execute on function public.mark_thread_read(uuid) to authenticated;

-- The admin needs names and roles in the Inbox; policies.sql already lets the
-- admin read every profile ("admin reads all profiles").

-- Live updates: new messages appear without refreshing.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public' and tablename = 'messages') then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
