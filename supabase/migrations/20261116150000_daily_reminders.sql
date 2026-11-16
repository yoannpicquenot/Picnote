-- Every 3 hours from 9:00 to 21:00, phone time, a reminder of what is left
-- to do today and tomorrow, as the home screen shows it. Nothing left,
-- no reminder. Sent by the notify function (see supabase/functions/notify).

alter table public.profiles add column notify_daily_reminders boolean not null default true;

-- The phone's offset from UTC, sent each time the app starts, so "9:00"
-- and "today" are the phone's. Existing phones are in Paris (winter time).
alter table public.device_tokens add column utc_offset_minutes integer not null default 60;

drop function public.register_device(text, text, text);

create function public.register_device(
  device_token text,
  device_platform text,
  device_locale text,
  device_utc_offset integer default 60
) returns void
language sql security definer set search_path = '' as $$
  insert into public.device_tokens (token, user_id, platform, locale, utc_offset_minutes)
  values (device_token, auth.uid(), device_platform, device_locale, device_utc_offset)
  on conflict (token) do update
  set user_id = auth.uid(), platform = excluded.platform, locale = excluded.locale,
    utc_offset_minutes = excluded.utc_offset_minutes, updated_at = now();
$$;

revoke execute on function public.register_device(text, text, text, integer) from public, anon;
grant execute on function public.register_device(text, text, text, integer) to authenticated;

-- The hours a reminder goes out, phone time.
create function public.reminder_hours() returns integer[]
language sql immutable as $$ select '{9,12,15,18,21}'::integer[] $$;

-- The phones whose hour it is, with the unchecked tasks of their person
-- for today (pinned to today, or in a list whose day is today or already
-- past) and tomorrow. Phones with nothing to do are left out.
create function public.due_reminders() returns table (token text, locale text, today text[], tomorrow text[])
language sql stable security definer set search_path = '' as $$
  with phones as (
    select d.token, d.locale, d.user_id, m.household_id,
      ((now() at time zone 'utc') + make_interval(mins => d.utc_offset_minutes)) as local_now
    from public.device_tokens d
    join public.profiles p on p.id = d.user_id
    left join public.household_members m on m.user_id = d.user_id
    where p.notify_enabled and p.notify_daily_reminders
  ),
  due as (
    select *, local_now::date as day from phones
    where extract(hour from local_now)::integer = any (public.reminder_hours())
  ),
  tasks as (
    select due.token, due.locale, t.title, l.day as list_day, t.today as pinned, due.day, t.position, l.created_at
    from due
    join public.lists l on (l.household_id is null and l.owner_id = due.user_id) or l.household_id = due.household_id
    join public.tasks t on t.list_id = l.id and not t.done and t.archived_at is null
    where t.today or l.day <= due.day + 1
  )
  select token, locale,
    coalesce(array_agg(title order by created_at, position) filter (where pinned or list_day <= day), '{}'),
    coalesce(array_agg(title order by created_at, position) filter (where not pinned and list_day = day + 1), '{}')
  from tasks
  group by token, locale;
$$;

revoke execute on function public.due_reminders() from public, anon, authenticated;
grant execute on function public.due_reminders() to service_role;

-- On the hour: the function sends to the phones whose hour it is.
select cron.schedule(
  'daily-reminders',
  '0 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/notify',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{"kind": "reminders"}'::jsonb
  );
  $$
);
