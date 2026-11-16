import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/domain/models/task_list.dart';
import 'package:picnote/ui/all_lists/view_models/all_lists_viewmodel.dart';

import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  group('AllListsViewModel', () {
    AllListsViewModel build(FakeListRepository lists) => AllListsViewModel(
      listRepository: lists,
      householdRepository: FakeHouseholdRepository(household: kDuo),
    );

    test('splits pinned lists from the others', () {
      final vm = build(FakeListRepository(lists: manyLists(5, pinned: 2)));

      expect(vm.pinned.map((l) => l.id), ['l0', 'l1']);
      expect(vm.others.map((l) => l.id), ['l2', 'l3', 'l4']);
      expect(vm.homeFull, isFalse);
    });

    test('pins and unpins', () async {
      final lists = FakeListRepository(lists: manyLists(3, pinned: 1));
      final vm = build(lists);

      await vm.setPinned(vm.others.first, true);
      expect(vm.pinned.map((l) => l.id), ['l0', 'l1']);

      await vm.setPinned(vm.pinned.first, false);
      expect(vm.pinned.map((l) => l.id), ['l1']);
    });

    test('pins no more than home holds', () async {
      final vm = build(FakeListRepository(lists: manyLists(6, pinned: maxPinnedLists)));
      expect(vm.homeFull, isTrue);

      await vm.setPinned(vm.others.first, true);
      expect(vm.pinned, hasLength(maxPinnedLists));
    });
  });

  test('a new list is not pinned: that is done from its menu', () async {
    final lists = FakeListRepository(lists: manyLists(1, pinned: 1));
    final created = await lists.createList(const TaskList(id: '', name: 'Deux'));
    expect(lists.lists.firstWhere((l) => l.name == 'Deux').pinned, isFalse);
    expect(created, isNotNull);
  });
}
