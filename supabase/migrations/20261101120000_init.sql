-- Picnote schema: profiles, households of up to 2 members, invite codes,
-- lists + tasks, notes. Personal rows belong to their owner; shared rows
-- belong to a household (household_id is set) and every member sees them.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text not null default '',
  name text not null default '',
  color bigint not null default 4289682492, -- 0xFFAF5C3C
  notify_enabled boolean not null default true,
  notify_default_time text not null default '9:00',
  notify_partner_activity boolean not null default true,
  deletion_requested_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

-- One household per person, two people per household (enforced in join).
create table public.household_members (
  user_id uuid primary key references public.profiles on delete cascade,
  household_id uuid not null references public.households on delete cascade,
  joined_at timestamptz not null default now()
);
create index on public.household_members (household_id);

-- At most one pending invitation per household, valid for 7 days.
create table public.invites (
  household_id uuid primary key references public.households on delete cascade,
  email text not null,
  code text not null unique,
  invited_by uuid references public.profiles on delete set null,
  sent_at timestamptz not null default now(),
  resent boolean not null default false
);

create table public.lists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid default auth.uid() references public.profiles on delete set null,
  household_id uuid references public.households on delete cascade,
  is_shared boolean not null default false,
  name text not null,
  color text not null default 'rose',
  icon text not null default 'heart',
  day date,
  reminder_date date,
  reminder_time text,
  created_at timestamptz not null default now()
);
create index on public.lists (owner_id);
create index on public.lists (household_id);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.lists on delete cascade,
  title text not null,
  done boolean not null default false,
  by_id uuid references public.profiles on delete set null,
  today boolean not null default false,
  position double precision not null default 0,
  created_at timestamptz not null default now()
);
create index on public.tasks (list_id);

create table public.notes (
  id uuid primary key default gen_random_uuid(),
  author_id uuid default auth.uid() references public.profiles on delete set null,
  household_id uuid references public.households on delete cascade,
  is_shared boolean not null default false,
  title text not null default '',
  blocks jsonb not null default '[]',
  reminder_date date,
  reminder_time text,
  edited_by uuid references public.profiles on delete set null,
  edited_at timestamptz not null default now()
);
create index on public.notes (author_id);
create index on public.notes (household_id);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- The caller's household. Security definer so policies on household_members
-- can use it without recursing.
create function public.my_household() returns uuid
language sql stable security definer set search_path = '' as $$
  select household_id from public.household_members where user_id = auth.uid()
$$;

-- A profile row for every new auth user.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, email) values (new.id, coalesce(new.email, ''));
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- Sharing moves a row into the caller's household. Making a list personal
-- again gives it to whoever did it; only the author can do so for a note.
create function public.place_shared_list() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.is_shared then
    new.household_id := coalesce(new.household_id, public.my_household());
    if new.household_id is null then
      raise exception 'Not in a household' using errcode = 'P0001';
    end if;
  else
    if tg_op = 'UPDATE' then
      if old.is_shared then
        new.owner_id := auth.uid();
      end if;
    end if;
    new.household_id := null;
  end if;
  return new;
end $$;

create function public.place_shared_note() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.is_shared then
    new.household_id := coalesce(new.household_id, public.my_household());
    if new.household_id is null then
      raise exception 'Not in a household' using errcode = 'P0001';
    end if;
  else
    if tg_op = 'UPDATE' then
      if old.is_shared and old.author_id is not null and old.author_id <> auth.uid() then
        raise exception 'Only the author can make this note personal' using errcode = '42501';
      end if;
    end if;
    new.household_id := null;
  end if;
  return new;
end $$;

create trigger place_shared before insert or update on public.lists
for each row execute function public.place_shared_list();
create trigger place_shared before insert or update on public.notes
for each row execute function public.place_shared_note();

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.invites enable row level security;
alter table public.lists enable row level security;
alter table public.tasks enable row level security;
alter table public.notes enable row level security;

create policy "own or housemate profile" on public.profiles for select to authenticated
  using (id = auth.uid() or id in (select user_id from public.household_members where household_id = public.my_household()));
create policy "update own profile" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy "my household" on public.households for select to authenticated
  using (id = public.my_household());
create policy "rename my household" on public.households for update to authenticated
  using (id = public.my_household()) with check (id = public.my_household());

create policy "my household members" on public.household_members for select to authenticated
  using (household_id = public.my_household());

create policy "my household invite" on public.invites for select to authenticated
  using (household_id = public.my_household());

create policy "visible lists" on public.lists for all to authenticated
  using ((household_id is null and owner_id = auth.uid()) or household_id = public.my_household())
  with check ((household_id is null and owner_id = auth.uid()) or household_id = public.my_household());

-- The subquery runs under the lists policy, so a task is visible exactly
-- when its list is.
create policy "tasks of visible lists" on public.tasks for all to authenticated
  using (exists (select 1 from public.lists l where l.id = tasks.list_id))
  with check (exists (select 1 from public.lists l where l.id = tasks.list_id));

create policy "visible notes" on public.notes for select to authenticated
  using ((household_id is null and author_id = auth.uid()) or household_id = public.my_household());
create policy "create notes" on public.notes for insert to authenticated
  with check (author_id = auth.uid() and (household_id is null or household_id = public.my_household()));
create policy "edit visible notes" on public.notes for update to authenticated
  using ((household_id is null and author_id = auth.uid()) or household_id = public.my_household())
  with check ((household_id is null and author_id = auth.uid()) or household_id = public.my_household());
-- Only the author deletes a shared note (or anyone, once the author left).
create policy "author deletes notes" on public.notes for delete to authenticated
  using (
    (household_id is null and author_id = auth.uid())
    or (household_id = public.my_household() and (author_id = auth.uid() or author_id is null))
  );

-- ---------------------------------------------------------------------------
-- Household functions (called with supabase.rpc)
-- ---------------------------------------------------------------------------

create function public.create_household(household_name text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  new_id uuid;
begin
  if auth.uid() is null then raise exception 'Not signed in' using errcode = '42501'; end if;
  if public.my_household() is not null then raise exception 'Already in a household' using errcode = 'P0001'; end if;
  insert into public.households (name) values (household_name) returning id into new_id;
  insert into public.household_members (user_id, household_id) values (auth.uid(), new_id);
  return new_id;
end $$;

-- 6 characters, no 0/O/1/I to avoid misreading.
create function public.new_invite_code() returns text
language plpgsql set search_path = '' as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  candidate text;
begin
  loop
    candidate := '';
    for i in 1..6 loop
      candidate := candidate || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.invites where code = candidate);
  end loop;
  return candidate;
end $$;

-- Creates (or replaces) the household's invitation and returns its code.
create function public.send_invite(invite_email text) returns text
language plpgsql security definer set search_path = '' as $$
declare
  hid uuid := public.my_household();
  new_code text;
begin
  if hid is null then raise exception 'Not in a household' using errcode = 'P0001'; end if;
  if (select count(*) from public.household_members where household_id = hid) >= 2 then
    raise exception 'Household full' using errcode = 'P0002';
  end if;
  new_code := public.new_invite_code();
  insert into public.invites (household_id, email, code, invited_by)
  values (hid, invite_email, new_code, auth.uid())
  on conflict (household_id) do update
    set email = excluded.email, code = excluded.code, invited_by = excluded.invited_by,
        sent_at = now(), resent = false;
  return new_code;
end $$;

-- Restarts the 7 days.
create function public.resend_invite() returns void
language sql security definer set search_path = '' as $$
  update public.invites set sent_at = now(), resent = true where household_id = public.my_household()
$$;

create function public.cancel_invite() returns void
language sql security definer set search_path = '' as $$
  delete from public.invites where household_id = public.my_household()
$$;

-- What an invite code reveals before joining: {name, members: [{id, name, color}]},
-- or null when the code is unknown or expired.
create function public.look_up_invite(invite_code text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'name', h.name,
    'members', coalesce((
      select jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'color', p.color) order by m.joined_at)
      from public.household_members m join public.profiles p on p.id = m.user_id
      where m.household_id = h.id
    ), '[]'::jsonb)
  )
  from public.invites i join public.households h on h.id = i.household_id
  where i.code = upper(invite_code) and i.sent_at > now() - interval '7 days'
$$;

create function public.join_household(invite_code text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  hid uuid;
begin
  if auth.uid() is null then raise exception 'Not signed in' using errcode = '42501'; end if;
  if public.my_household() is not null then raise exception 'Already in a household' using errcode = 'P0001'; end if;
  select household_id into hid from public.invites
  where code = upper(invite_code) and sent_at > now() - interval '7 days';
  if hid is null then raise exception 'Invalid invite' using errcode = 'P0003'; end if;
  perform 1 from public.households where id = hid for update;
  if (select count(*) from public.household_members where household_id = hid) >= 2 then
    raise exception 'Household full' using errcode = 'P0002';
  end if;
  insert into public.household_members (user_id, household_id) values (auth.uid(), hid);
  delete from public.invites where household_id = hid;
end $$;

-- Takes [member] out of their household. Shared lists and notes stay with
-- the household; when nobody is left, the household and its content go.
create function public.drop_member(member uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  hid uuid;
begin
  select household_id into hid from public.household_members where user_id = member;
  if hid is null then return; end if;
  delete from public.household_members where user_id = member;
  update public.notes set author_id = null where household_id = hid and author_id = member;
  if not exists (select 1 from public.household_members where household_id = hid) then
    delete from public.households where id = hid;
  end if;
end $$;
revoke execute on function public.drop_member(uuid) from public, anon, authenticated;

create function public.leave_household() returns void
language sql security definer set search_path = '' as $$
  select public.drop_member(auth.uid())
$$;

create function public.remove_member(member uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if member = auth.uid() or public.my_household() is null
     or not exists (select 1 from public.household_members where user_id = member and household_id = public.my_household()) then
    raise exception 'Not a housemate' using errcode = '42501';
  end if;
  perform public.drop_member(member);
end $$;

-- ---------------------------------------------------------------------------
-- Account deletion: 15 days to change your mind, then a daily job erases it.
-- ---------------------------------------------------------------------------

create function public.request_account_deletion() returns timestamptz
language sql security definer set search_path = '' as $$
  update public.profiles set deletion_requested_at = now() where id = auth.uid()
  returning deletion_requested_at + interval '15 days'
$$;

create function public.cancel_account_deletion() returns void
language sql security definer set search_path = '' as $$
  update public.profiles set deletion_requested_at = null where id = auth.uid()
$$;

create function public.purge_deleted_accounts() returns void
language plpgsql security definer set search_path = '' as $$
declare
  doomed uuid;
begin
  for doomed in
    select id from public.profiles where deletion_requested_at < now() - interval '15 days'
  loop
    perform public.drop_member(doomed);
    delete from public.lists where owner_id = doomed and household_id is null;
    delete from public.notes where author_id = doomed and household_id is null;
    delete from auth.users where id = doomed;
  end loop;
end $$;
revoke execute on function public.purge_deleted_accounts() from public, anon, authenticated;

create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('purge-deleted-accounts', '17 3 * * *', 'select public.purge_deleted_accounts()');

-- ---------------------------------------------------------------------------
-- Live sync
-- ---------------------------------------------------------------------------

alter publication supabase_realtime add table
  public.profiles, public.households, public.household_members, public.invites,
  public.lists, public.tasks, public.notes;
