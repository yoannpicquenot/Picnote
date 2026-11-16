-- Live typing: what someone types in a list or note goes, keystroke by
-- keystroke, to their housemates over the private realtime channel
-- `live:<household id>`. Only that household's members may join it, to
-- listen or to send. Nothing is stored.

create policy "housemates hear live typing" on realtime.messages for select to authenticated
  using (realtime.messages.extension = 'broadcast' and realtime.topic() = 'live:' || public.my_household()::text);

create policy "housemates send live typing" on realtime.messages for insert to authenticated
  with check (realtime.messages.extension = 'broadcast' and realtime.topic() = 'live:' || public.my_household()::text);
