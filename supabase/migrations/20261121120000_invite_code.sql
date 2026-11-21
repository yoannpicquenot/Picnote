-- An invitation can also be given by hand, as a code, with no email: the
-- inviter shares it themselves (onboarding step "By code"). Such an invite
-- has an empty email and never goes out by mail.

-- Codes no longer use Q: the app's code field never accepted it (see
-- CodeBoxes.inviteAlphabet), so a code with a Q could not be typed in.
create or replace function public.new_invite_code() returns text
language plpgsql set search_path = '' as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPRSTUVWXYZ23456789';
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

-- The household's invite code: the pending one if there is one, otherwise a
-- new invite without an email.
create function public.create_invite_code() returns text
language plpgsql security definer set search_path = '' as $$
declare
  hid uuid := public.my_household();
  existing text;
  new_code text;
begin
  if hid is null then raise exception 'Not in a household' using errcode = 'P0001'; end if;
  if (select count(*) from public.household_members where household_id = hid) >= 2 then
    raise exception 'Household full' using errcode = 'P0002';
  end if;
  -- An older code with a Q can't be typed in: a new one replaces it.
  select code into existing from public.invites
  where household_id = hid and sent_at > now() - interval '7 days' and position('Q' in code) = 0;
  if existing is not null then return existing; end if;
  new_code := public.new_invite_code();
  insert into public.invites (household_id, email, code, invited_by)
  values (hid, '', new_code, auth.uid())
  on conflict (household_id) do update
    set email = '', code = excluded.code, invited_by = excluded.invited_by,
        sent_at = now(), resent = false, emailed_at = null;
  return new_code;
end $$;

-- Sending by email keeps a code that is still valid, so a code already given
-- by hand keeps working.
create or replace function public.send_invite(invite_email text) returns text
language plpgsql security definer set search_path = '' as $$
declare
  hid uuid := public.my_household();
  new_code text;
begin
  if hid is null then raise exception 'Not in a household' using errcode = 'P0001'; end if;
  if (select count(*) from public.household_members where household_id = hid) >= 2 then
    raise exception 'Household full' using errcode = 'P0002';
  end if;
  -- An older code with a Q can't be typed in: a new one replaces it.
  select code into new_code from public.invites
  where household_id = hid and sent_at > now() - interval '7 days' and position('Q' in code) = 0;
  if new_code is null then new_code := public.new_invite_code(); end if;
  insert into public.invites (household_id, email, code, invited_by)
  values (hid, invite_email, new_code, auth.uid())
  on conflict (household_id) do update
    set email = excluded.email, code = excluded.code, invited_by = excluded.invited_by,
        sent_at = now(), resent = false;
  return new_code;
end $$;

-- Only invites with an address are mailed.
drop trigger email_invite on public.invites;
create trigger email_invite
  after insert or update of email, code, sent_at on public.invites
  for each row when (new.email <> '') execute function public.email_invite();
