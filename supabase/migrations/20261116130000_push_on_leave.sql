-- Push notifications go out as soon as the person leaves the list or note
-- they changed (or puts the app away), not only after a minute of quiet.

-- Set by the app when its user leaves a list or note.
alter table public.activity add column released boolean not null default false;

-- The user is done with a list or note: what they changed in it is sent now.
create function public.release_activity(item uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.activity set released = true
  where actor_id = auth.uid() and notified_at is null and (list_id = item or note_id = item);
  if found then
    perform net.http_post(
      url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/notify',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := '{}'::jsonb
    );
  end if;
end $$;

revoke execute on function public.release_activity(uuid) from public, anon;
grant execute on function public.release_activity(uuid) to authenticated;

-- Editing a note again after it was sent starts a new burst.
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
    update activity set at = now(), released = released and notified_at is null, notified_at = null
    where id = last.id;
  else
    insert into activity (note_id, actor_id, verb) values (new.id, auth.uid(), 'edit');
  end if;
  return null;
end $$;

-- Due when released, or after a minute of quiet as before (the app was
-- killed, or the phone lost its connection).
create or replace function public.claim_activity_notifications() returns table (
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
    having max(a.at) < now() - interval '1 minute' or bool_or(a.released)
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

select cron.unschedule('notify-activity');
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
    where notified_at is null and (released or at < now() - interval '1 minute')
  );
  $$
);
