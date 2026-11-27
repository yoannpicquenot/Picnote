-- The Pense-bête: one list per household, always there, for reminders that
-- come once or again and again. Each task is for one member (for_id), for
-- both (for_both), or for no one in particular (both unset: everyone).
-- Every member may change or delete any task.
--
-- The reminder is a day and an hour on the phone's clock (remind_on at
-- remind_hour). The notify function, called every 5 minutes, sends it to
-- whoever it is for, then moves a repeating one to its next time.

create table public.memo_tasks (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households on delete cascade,
  title text not null,
  for_id uuid references public.profiles on delete set null,
  for_both boolean not null default false,
  remind_on date,
  remind_hour smallint check (remind_hour between 0 and 23),
  repeat text not null default 'never' check (repeat in ('never', 'daily', 'weekly', 'monthly')),
  done boolean not null default false,
  done_at timestamptz,
  author_id uuid references public.profiles on delete set null,
  position double precision not null default 0,
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  -- The day whose reminder was sent, so it goes out once.
  notified_on date
);
create index on public.memo_tasks (household_id);

-- New tasks go to the caller's household.
create function public.place_memo_task() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.household_id := public.my_household();
  if new.household_id is null then
    raise exception 'Not in a household' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger place_memo_task before insert on public.memo_tasks
for each row execute function public.place_memo_task();

alter table public.memo_tasks enable row level security;

create policy "my household memo tasks" on public.memo_tasks for all to authenticated
  using (household_id = public.my_household())
  with check (household_id = public.my_household());

alter publication supabase_realtime add table public.memo_tasks;

-- ---------------------------------------------------------------------------
-- Reminders
-- ---------------------------------------------------------------------------

-- The reminders whose time has come, each with the phones to send it to.
-- Claimed: a one-off is marked sent; a repeating one is unchecked and moved
-- to its next time, so it comes back. "Now" is the household's phone time
-- (the latest registered phone of a member), Paris by default.
create function public.claim_memo_reminders()
returns table (task_id uuid, title text, author_name text, repeat text, remind_on date, devices jsonb)
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare
  t public.memo_tasks;
  local_now timestamp;
  next_on date;
  n integer;
begin
  for t in
    select * from public.memo_tasks m
    where m.archived_at is null
      and m.remind_on is not null
      and m.remind_hour is not null
      and m.notified_on is distinct from m.remind_on
      -- Phones are at most 14 h ahead of UTC.
      and m.remind_on <= (now() at time zone 'utc')::date + 1
    for update skip locked
  loop
    select (now() at time zone 'utc') + make_interval(mins => coalesce((
      select d.utc_offset_minutes
      from public.household_members hm
      join public.device_tokens d on d.user_id = hm.user_id
      where hm.household_id = t.household_id
      order by d.updated_at desc
      limit 1
    ), 60))
    into local_now;

    continue when t.remind_on + make_interval(hours => t.remind_hour) > local_now;

    -- Sent unless a one-off is already done.
    if t.repeat <> 'never' or not t.done then
      task_id := t.id;
      title := t.title;
      repeat := t.repeat;
      remind_on := t.remind_on;
      select p.name into author_name from public.profiles p where p.id = t.author_id;
      select coalesce(jsonb_agg(jsonb_build_object('token', d.token, 'locale', d.locale)), '[]')
      into devices
      from public.household_members hm
      join public.profiles r on r.id = hm.user_id
      join public.device_tokens d on d.user_id = hm.user_id
      where hm.household_id = t.household_id
        and r.notify_enabled
        and (t.for_both or t.for_id is null or t.for_id = hm.user_id);
      return next;
    end if;

    if t.repeat = 'never' then
      update public.memo_tasks set notified_on = t.remind_on where id = t.id;
    else
      -- From the first day each time, so the 31st stays the 31st (or the
      -- month's last day).
      n := 1;
      loop
        next_on := (t.remind_on + case t.repeat
          when 'daily' then make_interval(days => n)
          when 'weekly' then make_interval(weeks => n)
          else make_interval(months => n)
        end)::date;
        exit when next_on + make_interval(hours => t.remind_hour) > local_now;
        n := n + 1;
      end loop;
      update public.memo_tasks
      set remind_on = next_on, done = false, done_at = null, notified_on = null
      where id = t.id;
    end if;
  end loop;
end $$;

revoke execute on function public.claim_memo_reminders() from public, anon, authenticated;
grant execute on function public.claim_memo_reminders() to service_role;

-- Every 5 minutes, only when a reminder may be due.
select cron.schedule(
  'memo-reminders',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/notify',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{"kind": "memos"}'::jsonb
  )
  where exists (
    select 1 from public.memo_tasks
    where archived_at is null and remind_on is not null and remind_hour is not null
      and notified_on is distinct from remind_on
      and remind_on <= (now() at time zone 'utc')::date + 1
  );
  $$
);
