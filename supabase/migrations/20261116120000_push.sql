-- Push notifications: when someone creates or changes a shared list or note,
-- the other members of the household get one notification, a minute after
-- that person stopped (see supabase/functions/notify).

-- ---------------------------------------------------------------------------
-- Devices
-- ---------------------------------------------------------------------------

-- A phone's Firebase token. A token belongs to whoever last signed in on
-- that phone, so it is only written through register_device. A token
-- Firebase no longer knows is dropped by the notify function.
create table public.device_tokens (
  token text primary key,
  user_id uuid not null references public.profiles on delete cascade,
  platform text not null default 'android',
  -- The app's language, for the wording of the notification.
  locale text not null default 'fr',
  updated_at timestamptz not null default now()
);
create index on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

create function public.register_device(device_token text, device_platform text, device_locale text) returns void
language sql security definer set search_path = '' as $$
  insert into public.device_tokens (token, user_id, platform, locale)
  values (device_token, auth.uid(), device_platform, device_locale)
  on conflict (token) do update
  set user_id = auth.uid(), platform = excluded.platform, locale = excluded.locale, updated_at = now();
$$;

revoke execute on function public.register_device(text, text, text) from public, anon;
grant execute on function public.register_device(text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Pending notifications
-- ---------------------------------------------------------------------------

alter table public.activity add column notified_at timestamptz;

-- What happened before this migration is not news.
update public.activity set notified_at = now();

create index on public.activity (at) where notified_at is null;

-- A note's edits in a row still make a single entry, but moving it to the
-- latest time makes it news again.
create or replace function public.log_note() returns trigger
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
    update activity set at = now(), notified_at = null where id = last.id;
  else
    insert into activity (note_id, actor_id, verb) values (new.id, auth.uid(), 'edit');
  end if;
  return null;
end $$;

-- Takes what one person did to one list or note, once they have left it
-- alone for a minute, and marks it as sent. One row per such burst, with
-- the devices of the housemates who want to hear about it. Personal lists
-- and notes have nobody to tell.
create function public.claim_activity_notifications() returns table (
  actor_name text,
  list_id uuid,
  note_id uuid,
  title text,
  created boolean,
  added text[],
  checked integer,
  unchecked integer,
  edited integer,
  deleted integer,
  devices jsonb
)
language sql security definer set search_path = '' as $$
  with due as (
    select a.actor_id, a.list_id, a.note_id
    from public.activity a
    where a.notified_at is null
    group by a.actor_id, a.list_id, a.note_id
    having max(a.at) < now() - interval '1 minute'
  ),
  claimed as (
    update public.activity a set notified_at = now()
    from due
    where a.notified_at is null
      and a.actor_id is not distinct from due.actor_id
      and a.list_id is not distinct from due.list_id
      and a.note_id is not distinct from due.note_id
    returning a.*
  ),
  bursts as (
    select
      c.actor_id,
      c.list_id,
      c.note_id,
      bool_or(c.verb = 'create') as created,
      array_agg(c.item order by c.at) filter (where c.verb = 'add') as added,
      count(*) filter (where c.verb = 'check')::integer as checked,
      count(*) filter (where c.verb = 'uncheck')::integer as unchecked,
      count(*) filter (where c.verb = 'edit')::integer as edited,
      count(*) filter (where c.verb = 'del')::integer as deleted
    from claimed c
    where c.actor_id is not null
    group by c.actor_id, c.list_id, c.note_id
  )
  select
    p.name,
    b.list_id,
    b.note_id,
    coalesce(l.name, n.title),
    b.created,
    coalesce(b.added, '{}'),
    b.checked,
    b.unchecked,
    b.edited,
    b.deleted,
    (
      select coalesce(jsonb_agg(jsonb_build_object('token', d.token, 'locale', d.locale)), '[]')
      from public.household_members m
      join public.profiles r on r.id = m.user_id
      join public.device_tokens d on d.user_id = m.user_id
      where m.household_id = coalesce(l.household_id, n.household_id)
        and m.user_id <> b.actor_id
        and r.notify_enabled
        and r.notify_partner_activity
    )
  from bursts b
  join public.profiles p on p.id = b.actor_id
  left join public.lists l on l.id = b.list_id
  left join public.notes n on n.id = b.note_id
  where coalesce(l.household_id, n.household_id) is not null;
$$;

-- Only the notify function, with the service role, calls it.
revoke execute on function public.claim_activity_notifications() from public, anon, authenticated;
grant execute on function public.claim_activity_notifications() to service_role;

create function public.forget_device(device_token text) returns void
language sql security definer set search_path = '' as $$
  delete from public.device_tokens where token = device_token;
$$;

revoke execute on function public.forget_device(text) from public, anon, authenticated;
grant execute on function public.forget_device(text) to service_role;

-- ---------------------------------------------------------------------------
-- Every minute
-- ---------------------------------------------------------------------------

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- Calls the notify function, only when something waits. Its address is
-- read from the vault, set once per project:
--   select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
select cron.schedule(
  'notify-activity',
  '* * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/notify',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  )
  where exists (
    select 1 from public.activity
    where notified_at is null and at < now() - interval '1 minute'
  );
  $$
);
