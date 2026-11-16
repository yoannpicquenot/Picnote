import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/push/push_repository_supabase.dart';

void main() {
  test('a notification opens its list or note, nothing else', () {
    expect(PushRepositorySupabase.routeOf({'route': '/notes/3f2a-9c'}), '/notes/3f2a-9c');
    expect(PushRepositorySupabase.routeOf({'route': '/lists/abc'}), '/lists/abc');
    expect(PushRepositorySupabase.routeOf({'route': '/settings/account'}), isNull);
    expect(PushRepositorySupabase.routeOf({'route': '/notes/1/../../settings'}), isNull);
    expect(PushRepositorySupabase.routeOf({}), isNull);
    expect(PushRepositorySupabase.routeOf(null), isNull);
  });
}
