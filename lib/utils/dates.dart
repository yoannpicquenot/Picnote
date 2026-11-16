/// Calendar-day helpers. Picnote only deals in days, never instants.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime today() => dateOnly(DateTime.now());

DateTime inDays(int n) {
  final t = today();
  return DateTime(t.year, t.month, t.day + n);
}

int daysFromToday(DateTime d) => dateOnly(d).difference(today()).inDays;

/// A missed day or reminder slides to today: no "late!".
DateTime effectiveDay(DateTime d) => daysFromToday(d) < 0 ? today() : dateOnly(d);

/// Next [weekday] (DateTime.monday…sunday) strictly after today.
DateTime nextWeekday(int weekday) {
  final t = today();
  final n = (weekday - t.weekday + 7) % 7;
  return DateTime(t.year, t.month, t.day + (n == 0 ? 7 : n));
}
