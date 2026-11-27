import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/invite_prompt/invite_prompt_repository.dart';
import 'package:picnote/data/repositories/memo/memo_repository_local.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/domain/models/household.dart';
import 'package:picnote/domain/models/task.dart';
import 'package:picnote/domain/models/task_list.dart';
import 'package:picnote/ui/home/view_models/home_viewmodel.dart';
import 'package:picnote/utils/dates.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  HomeViewModel build(FakeListRepository lists, {Household household = kDuo, InvitePromptRepository? invitePrompt}) =>
      HomeViewModel(
        listRepository: lists,
        authRepository: FakeAuthRepository(),
        householdRepository: FakeHouseholdRepository(household: household),
        noteRepository: NoteRepositoryLocal(),
        invitePromptRepository: invitePrompt ?? InvitePromptRepositoryLocal(),
        memoRepository: MemoRepositoryLocal(),
      );

  group('HomeViewModel', () {
    test('offers to invite someone while alone, until put away', () async {
      final prompt = InvitePromptRepositoryLocal();
      final viewModel = build(FakeListRepository(), household: kSolo, invitePrompt: prompt);
      expect(viewModel.showInviteCard, isTrue);

      await viewModel.dismissInviteCard();
      expect(viewModel.showInviteCard, isFalse);

      // A new sign-in brings it back.
      await prompt.reset();
      expect(viewModel.showInviteCard, isTrue);
    });

    test('no invite card with a partner, the pending invitation instead of it', () {
      expect(build(FakeListRepository()).showInviteCard, isFalse);
      const pending = Household(
        name: 'Maison',
        members: [kMe],
        invite: Invite(email: 'yoann@picnote.cc', code: 'K7H2M9'),
      );
      final viewModel = build(FakeListRepository(), household: pending);
      expect(viewModel.showInviteCard, isFalse);
      expect(viewModel.pendingInvite?.email, 'yoann@picnote.cc');
    });

    test('a code given by hand is no invitation: the card stays', () {
      const byCode = Household(
        name: 'Maison',
        members: [kMe],
        invite: Invite(email: '', code: 'K7H2M9'),
      );
      final viewModel = build(FakeListRepository(), household: byCode);
      expect(viewModel.showInviteCard, isTrue);
      expect(viewModel.pendingInvite, isNull);
    });

    test('loads lists', () async {
      final viewModel = build(FakeListRepository(lists: [kSharedList, kPersonalList]));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.load.completed, isTrue);
      expect(viewModel.visibleLists, [kSharedList, kPersonalList]);
    });

    test('shows the pinned lists only', () async {
      final viewModel = build(FakeListRepository(lists: manyLists(6, pinned: 2)));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.visibleLists.map((l) => l.id), ['l0', 'l1']);
      expect(viewModel.listCount, 6);
    });

    test('shows at most 4 lists', () async {
      final viewModel = build(FakeListRepository(lists: manyLists(6, pinned: 6)));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.visibleLists, hasLength(maxPinnedLists));
    });

    test('exposes load errors', () async {
      final viewModel = build(FakeListRepository(failing: true));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.load.error, isTrue);
    });

    test('counts what is left in a list', () {
      final viewModel = build(FakeListRepository(lists: [kSharedList], tasks: kSharedTasks));

      final stats = viewModel.stats(kSharedList);
      expect(stats.total, 5);
      expect(stats.open, 3);
    });

    test('puts tasks of lists due today or tomorrow in their section', () {
      final viewModel = build(
        FakeListRepository(
          lists: [
            TaskList(id: 'a', name: 'A', day: inDays(0)),
            TaskList(id: 'b', name: 'B', day: inDays(1)),
            // A missed day slides to today.
            TaskList(id: 'c', name: 'C', day: inDays(-3)),
            const TaskList(id: 'd', name: 'D'),
          ],
          tasks: const [
            Task(id: '1', listId: 'a', title: 'a'),
            Task(id: '2', listId: 'b', title: 'b'),
            Task(id: '3', listId: 'c', title: 'c'),
            Task(id: '4', listId: 'd', title: 'd'),
            Task(id: '5', listId: 'd', title: 'pinned', today: true),
          ],
        ),
      );

      expect(viewModel.today.map((t) => t.id), ['1', '3', '5']);
      expect(viewModel.tomorrow.map((t) => t.id), ['2']);
    });

    test('lists unchecked tasks first, then checked ones, each in its own order', () {
      final viewModel = build(
        FakeListRepository(
          lists: [TaskList(id: 'a', name: 'A', day: inDays(0))],
          tasks: const [
            Task(id: '1', listId: 'a', title: '1', done: true),
            Task(id: '2', listId: 'a', title: '2'),
            Task(id: '3', listId: 'a', title: '3', done: true),
            Task(id: '4', listId: 'a', title: '4'),
          ],
        ),
      );

      expect(viewModel.today.map((t) => t.id), ['2', '4', '1', '3']);
    });

    test('shows who else changed a task, never yourself', () {
      final viewModel = build(FakeListRepository(lists: [kSharedList], tasks: kSharedTasks));

      expect(viewModel.authorOf(kSharedTasks[0])?.name, 'Yoann');
      expect(viewModel.authorOf(kSharedTasks[1].copyWith(byId: 'me')), isNull);
    });
  });
}
