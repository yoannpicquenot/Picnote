import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/domain/models/task_list.dart';

void main() {
  test('the apple takes the sun’s place in the picker; lists wearing the sun keep it', () {
    expect(ListIcon.pickable, contains(ListIcon.apple));
    expect(ListIcon.pickable, isNot(contains(ListIcon.sun)));
    expect(ListIcon.values.asNameMap()['sun'], ListIcon.sun);
  });
}
