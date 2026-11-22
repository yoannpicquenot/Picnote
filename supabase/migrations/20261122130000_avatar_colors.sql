-- New avatar palette (PnColors.avatars): mustard, old rose and cocoa are
-- lighter. Whoever wore the old ones moves to their new shade, so they still
-- match a color of the picker. Terra and sage don't change.
update public.profiles set color = case color
  when 4286206994 then 4291596820 -- 0xFF7A5412 -> 0xFFCC9214, mustard
  when 4287377982 then 4287906900 -- 0xFF8C323E -> 0xFF944454, old rose
  when 4284366380 then 4285024828 -- 0xFF5E3E2C -> 0xFF684A3C, cocoa
  else color
end
where color in (4286206994, 4287377982, 4284366380);
