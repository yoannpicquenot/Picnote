-- The invitation goes out by email (through Brevo, from the invite-email
-- function) each time it is sent or sent again: a trigger on invites calls
-- the function, which claims the invite before mailing it, so each send or
-- resend gives one email, however often the function is called.

-- Set when the email for the latest send went out; older than sent_at (or
-- null) while one is due.
alter table public.invites add column emailed_at timestamptz;

-- Everything the email needs, once per send. Marks it as emailed.
create function public.claim_invite_email(hid uuid)
returns table (email text, code text, inviter_name text, inviter_email text, household_name text, locale text)
language sql security definer set search_path = '' as $$
  with claimed as (
    update public.invites i set emailed_at = now()
    where i.household_id = hid and (i.emailed_at is null or i.emailed_at < i.sent_at)
    returning i.*
  )
  select c.email, c.code, coalesce(p.name, ''), coalesce(p.email, ''), h.name,
    coalesce(
      (select d.locale from public.device_tokens d where d.user_id = c.invited_by order by d.updated_at desc limit 1),
      'fr'
    )
  from claimed c
  join public.households h on h.id = c.household_id
  left join public.profiles p on p.id = c.invited_by;
$$;

revoke execute on function public.claim_invite_email(uuid) from public, anon, authenticated;
grant execute on function public.claim_invite_email(uuid) to service_role;

-- Security definer to read the project address from the vault.
create function public.email_invite() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/invite-email',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object('household_id', new.household_id)
  );
  return new;
end $$;

revoke execute on function public.email_invite() from public, anon, authenticated;

create trigger email_invite
  after insert or update of email, code, sent_at on public.invites
  for each row execute function public.email_invite();
