-- Pinned lists (home shows up to 4) and the activity log behind "Latest
-- changes" and the "who's here" panel.

-- ---------------------------------------------------------------------------
-- Pins
-- ---------------------------------------------------------------------------

alter table public.lists add column pinned boolean not null default false;

-- Existing lists: each owner's 4 newest are pinned, as home showed them.
update public.lists set pinned = true
where id in (
  select id from (
    select id, row_number() over (partition by owner_id order by created_at desc) as n
    from public.lists
  ) ranked
  where n <= 4
);

-- ---------------------------------------------------------------------------
-- Activity
-- ---------------------------------------------------------------------------

-- Written by triggers only, so both apps log the same way.
create table public.activity (
  id bigint generated always as identity primary key,
  list_id uuid references public.lists on delete cascade,
  note_id uuid references public.notes on delete cascade,
  actor_id uuid references public.profiles on delete set null,
  verb text not null check (verb in ('create', 'add', 'check', 'uncheck', 'edit', 'del')),
  -- The task's title, when the change is about a task.
  item text,
  at timestamptz not null default now(),
  check ((list_id is null) <> (note_id is null))
);

create index on public.activity (list_id, at desc);
create index on public.activity (note_id, at desc);
create index on public.activity (actor_id, at desc);

alter table public.activity enable row level security;

-- The subqueries run under the lists and notes policies: an entry is
-- visible exactly when its list or note is.
create policy "activity of visible items" on public.activity for select to authenticated
  using (
    (list_id is not null and exists (select 1 from public.lists l where l.id = activity.list_id))
    or (note_id is not null and exists (select 1 from public.notes n where n.id = activity.note_id))
  );

create function public.log_list() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  -- A list put back by "Undo" keeps its old creation date: not a new one.
  if auth.uid() is not null and new.created_at > now() - interval '1 minute' then
    insert into activity (list_id, actor_id, verb) values (new.id, auth.uid(), 'create');
  end if;
  return null;
end $$;

create function public.log_task() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return null; end if;
  if tg_op = 'INSERT' then
    insert into activity (list_id, actor_id, verb, item) values (new.list_id, auth.uid(), 'add', new.title);
  elsif tg_op = 'UPDATE' then
    if new.done <> old.done then
      insert into activity (list_id, actor_id, verb, item)
      values (new.list_id, auth.uid(), case when new.done then 'check' else 'uncheck' end, new.title);
    elsif new.title <> old.title then
      insert into activity (list_id, actor_id, verb, item) values (new.list_id, auth.uid(), 'edit', new.title);
    end if;
  -- Not when the whole list is being deleted.
  elsif exists (select 1 from lists where id = old.list_id) then
    insert into activity (list_id, actor_id, verb, item) values (old.list_id, auth.uid(), 'del', old.title);
  end if;
  return null;
end $$;

-- A note saves as it is typed: one person's edits in a row make a single
-- entry, moved to the latest time.
create function public.log_note() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  last activity;
begin
  if auth.uid() is null then return null; end if;
  if tg_op = 'INSERT' then
    insert into activity (note_id, actor_id, verb) values (new.id, auth.uid(), 'create');
    return null;
  end if;
  if new.title is not distinct from old.title and new.blocks is not distinct from old.blocks then
    return null;
  end if;
  select * into last from activity where note_id = new.id order by at desc limit 1;
  if last.id is not null and last.verb = 'edit' and last.actor_id = auth.uid() then
    update activity set at = now() where id = last.id;
  else
    insert into activity (note_id, actor_id, verb) values (new.id, auth.uid(), 'edit');
  end if;
  return null;
end $$;

create trigger log_activity after insert on public.lists
for each row execute function public.log_list();
create trigger log_activity after insert or update or delete on public.tasks
for each row execute function public.log_task();
create trigger log_activity after insert or update on public.notes
for each row execute function public.log_note();
