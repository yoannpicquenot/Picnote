-- Joining another household from the app ("Join a household" in the
-- avatars' menu), while alone in one's own. All at once, so that nothing
-- moves if anything fails (a wrong code, a full household): the shared lists
-- and notes of the old household come along as personal (otherwise they
-- would go with it, since nobody is left), then the old household is left
-- (its pending invitation with it) and the new one joined.
create function public.switch_household(invite_code text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  old_hid uuid := public.my_household();
  new_hid uuid;
begin
  if me is null then raise exception 'Not signed in' using errcode = '42501'; end if;
  select household_id into new_hid from public.invites
  where code = upper(invite_code) and sent_at > now() - interval '7 days';
  if new_hid is null or new_hid = old_hid then raise exception 'Invalid invite' using errcode = 'P0003'; end if;
  perform 1 from public.households where id = new_hid for update;
  if (select count(*) from public.household_members where household_id = new_hid) >= 2 then
    raise exception 'Household full' using errcode = 'P0002';
  end if;
  if old_hid is not null then
    -- With a housemate, the shared lists and notes stay with them: leave first.
    if (select count(*) from public.household_members where household_id = old_hid) > 1 then
      raise exception 'Not alone in the household' using errcode = 'P0001';
    end if;
    update public.lists set is_shared = false where household_id = old_hid;
    -- Notes become personal for their author only (see place_shared_note):
    -- this user becomes the author first.
    update public.notes set author_id = me where household_id = old_hid;
    update public.notes set is_shared = false where household_id = old_hid;
    perform public.drop_member(me);
  end if;
  insert into public.household_members (user_id, household_id) values (me, new_hid);
  delete from public.invites where household_id = new_hid;
end $$;
