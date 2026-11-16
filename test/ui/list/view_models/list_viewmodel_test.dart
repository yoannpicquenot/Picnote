import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/activity/activity_repository_local.dart';
import 'package:picnote/data/repositories/live/live_repository.dart';
import 'package:picnote/data/repositories/settings/settings_repository.dart';
import 'package:picnote/domain/models/live.dart';
import 'package:picnote/domain/models/task.dart';
import 'package:picnote/ui/core/ui/mascot_data.dart';
import 'package:picnote/ui/list/view_models/list_viewmodel.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  group('ListViewModel', () {
    late FakeListRepository lists;

    ListViewModel build({String listId = 'shared'}) => ListViewModel(
      listId: listId,
      listRepository: lists,
      authRepository: FakeAuthRepository(),
      householdRepository: FakeHouseholdRepository(household: kDuo),
      settingsRepository: SettingsRepositoryLocal(),
      activityRepository: ActivityRepositoryLocal(),
      liveRepository: LiveRepositoryLocal(),
    );

    setUp(() => lists = FakeListRepository(lists: [kSharedList, kPersonalList], tasks: kSharedTasks));

    test('splits open and done tasks', () {
      final vm = build();

      expect(vm.openTasks.map((t) => t.title), ['Tomates', 'Café', 'Lait']);
      expect(vm.doneTasks.map((t) => t.title), ['Pain', 'Huile']);
    });

    test('the mascot cheers up as tasks get checked', () {
      lists = FakeListRepository(lists: [kSharedList], tasks: tasksFor('shared', open: 4));
      final vm = build();
      expect(vm.mood, MascotMood.cheerful);

      lists = FakeListRepository(lists: [kSharedList], tasks: tasksFor('shared', open: 1, done: 3));
      expect(build().mood, MascotMood.wink);

      lists = FakeListRepository(lists: [kSharedList], tasks: tasksFor('shared', done: 2));
      expect(build().mood, MascotMood.love);
    });

    test('adds tasks signed by me', () async {
      final vm = build(listId: 'personal');
      await vm.addTask('Livre');

      expect(vm.openTasks.single.title, 'Livre');
      expect(vm.openTasks.single.byId, 'me');
    });

    test('new tasks go at the end, in the order they were added', () async {
      final vm = build(listId: 'personal');
      for (final title in ['Un', 'Deux', 'Trois']) {
        await vm.addTask(title);
      }

      expect(vm.openTasks.map((t) => t.title), ['Un', 'Deux', 'Trois']);
    });

    test('checking stamps the time, unchecking clears it', () async {
      final vm = build();
      await vm.toggle(vm.openTasks.first);
      final checked = vm.doneTasks.firstWhere((t) => t.title == 'Tomates');
      expect(checked.doneAt, isNotNull);
      expect(checked.isStale, isFalse);

      await vm.toggle(checked);
      expect(vm.openTasks.firstWhere((t) => t.title == 'Tomates').doneAt, isNull);
    });

    test('tasks checked before today are archived, today\'s stay', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      lists = FakeListRepository(
        lists: [kSharedList],
        tasks: [
          Task(id: 'a', listId: 'shared', title: 'Hier', done: true, doneAt: yesterday),
          Task(id: 'b', listId: 'shared', title: 'Aujourd\'hui', done: true, doneAt: DateTime.now()),
          const Task(id: 'c', listId: 'shared', title: 'À faire'),
        ],
      );
      await lists.archiveStaleTasks();
      final vm = build();

      expect(vm.doneTasks.map((t) => t.title), ['Aujourd\'hui']);
      expect(vm.openTasks.map((t) => t.title), ['À faire']);
    });

    test('reorders open tasks only', () async {
      final vm = build();
      await vm.reorder(0, 2);

      expect(vm.openTasks.map((t) => t.title), ['Café', 'Lait', 'Tomates']);
      expect(vm.doneTasks.map((t) => t.title), ['Pain', 'Huile']);
    });

    test('toggles sharing', () async {
      final vm = build(listId: 'personal');
      await vm.toggleShared();

      expect(vm.list?.isShared, isTrue);
    });

    test('deleting the list removes its tasks, and undo brings both back', () async {
      final vm = build();
      final deleted = await vm.deleteList();

      expect(lists.lists.map((l) => l.id), ['personal']);
      expect(lists.tasks, isEmpty);

      await vm.restoreList(deleted!);
      expect(lists.lists.map((l) => l.id), ['shared', 'personal']);
      expect(lists.tasks, hasLength(5));
    });

    test('leaving tells the housemates at once, only after a change', () async {
      final activity = ActivityRepositoryLocal();
      final vm = ListViewModel(
        listId: 'shared',
        listRepository: lists,
        authRepository: FakeAuthRepository(),
        householdRepository: FakeHouseholdRepository(household: kDuo),
        settingsRepository: SettingsRepositoryLocal(),
        activityRepository: activity,
        liveRepository: LiveRepositoryLocal(),
      );

      await vm.release();
      expect(activity.released, isEmpty);

      await vm.toggle(vm.openTasks.first);
      await vm.release();
      await vm.release();
      expect(activity.released, ['shared']);
    });

    test('the item typed goes to the housemate on a shared list only, and theirs shows', () {
      final live = LiveRepositoryLocal();
      addTearDown(live.dispose);
      ListViewModel open(String id) => ListViewModel(
        listId: id,
        listRepository: lists,
        authRepository: FakeAuthRepository(),
        householdRepository: FakeHouseholdRepository(household: kDuo),
        settingsRepository: SettingsRepositoryLocal(),
        activityRepository: ActivityRepositoryLocal(),
        liveRepository: live,
      );

      open('personal').typing('Secret');
      expect(live.sent, isEmpty);
      final vm = open('shared')..typing('Lai');
      expect((live.sent.single as LiveDraft).text, 'Lai');

      live.receiveDraft('shared', const LiveDraft(userId: 'yoann', text: 'Pai'));
      expect((vm.draft?.text, vm.drafter?.name), ('Pai', 'Yoann'));
    });
  });
}
