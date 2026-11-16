-- Checked tasks are archived at the first minute of the next day (the app
-- does it, at the user's local midnight), so a list starts every day with
-- only what is left to do. Archived rows stay stored.

alter table public.tasks add column done_at timestamptz;
alter table public.tasks add column archived_at timestamptz;

-- Already checked: archived at the coming midnight.
update public.tasks set done_at = now() where done;

create index on public.tasks (list_id) where archived_at is null;
