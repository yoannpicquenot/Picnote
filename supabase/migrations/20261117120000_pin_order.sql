-- The order of the pinned lists on home, which the user can rearrange.
-- Smallest first; null for lists never arranged, which come first.

alter table public.lists add column pin_order integer;

-- Existing pins keep the order home showed them in: newest first.
update public.lists set pin_order = ranked.n
from (
  select id, row_number() over (partition by owner_id order by created_at desc) - 1 as n
  from public.lists
  where pinned
) ranked
where lists.id = ranked.id;
