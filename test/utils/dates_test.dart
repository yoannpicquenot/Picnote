import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/utils/dates.dart';

void main() {
  test('a missed day slides to today', () {
    expect(effectiveDay(inDays(-4)), today());
    expect(effectiveDay(inDays(3)), inDays(3));
  });

  test('next weekday is always in the future', () {
    for (final weekday in [DateTime.monday, DateTime.saturday]) {
      final d = nextWeekday(weekday);
      expect(d.weekday, weekday);
      expect(daysFromToday(d), inInclusiveRange(1, 7));
    }
  });
}
