import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/list/list_repository.dart';
import 'package:picnote/data/repositories/note/note_repository.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/data/repositories/settings/settings_repository.dart';
import 'package:picnote/domain/models/note.dart';
import 'package:picnote/domain/models/task_list.dart';
import 'package:picnote/ui/shell/view_models/shell_viewmodel.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  group('ShellViewModel tells what the housemate creates', () {
    late FakeListRepository lists;
    late NoteRepositoryLocal notes;
    late ShellViewModel vm;
    late List<Creation> told;

    setUp(() {
      lists = FakeListRepository(
        lists: [TaskList(id: 'old', name: 'Old', ownerId: 'yoann', createdAt: DateTime.now())],
      );
      notes = NoteRepositoryLocal();
      vm = ShellViewModel(
        authRepository: FakeAuthRepository(),
        householdRepository: FakeHouseholdRepository(household: kDuo),
        listRepository: lists,
        noteRepository: notes,
        settingsRepository: SettingsRepositoryLocal(),
      );
      told = [];
      vm.partnerCreated.listen(told.add);
    });

    Future<void> arrive(TaskList list) => lists.restoreList(DeletedList(list: list, index: 0, tasks: const []));

    Note note(String id, {String author = 'yoann', String title = ''}) =>
        Note(id: id, authorId: author, editedById: author, editedAt: DateTime.now(), title: title, isShared: true);

    test('a new list, by them only, and only once', () async {
      await arrive(TaskList(id: 'l1', name: 'Courses', ownerId: 'yoann', createdAt: DateTime.now()));
      await arrive(TaskList(id: 'l2', name: 'Mine', ownerId: 'me', createdAt: DateTime.now()));
      // An old list newly shared with me is not a creation.
      await arrive(TaskList(id: 'l3', name: 'Vieille', ownerId: 'yoann', createdAt: DateTime(2026)));
      await lists.updateList(lists.lists.firstWhere((l) => l.id == 'l1').copyWith(name: 'Courses du soir'));
      await Future<void>.delayed(Duration.zero);

      expect(told.map((c) => (c.author.name, c.name, c.isNote)), [('Yoann', 'Courses', false)]);
    });

    test('a new note, once it has a title or text', () async {
      await notes.restoreNote(DeletedNote(note: note('n1'), index: 0));
      await notes.restoreNote(
        DeletedNote(
          note: note('n2', author: 'me', title: 'Moi'),
          index: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(told, isEmpty);

      await notes.updateNote(note('n1', title: 'Trip to Bergen'));
      await notes.updateNote(note('n1', title: 'Trip to Bergen 2'));
      await Future<void>.delayed(Duration.zero);
      expect(told.map((c) => (c.name, c.id, c.isNote)), [('Trip to Bergen', 'n1', true)]);
    });

    test('a change to a list, by them: once per burst', () async {
      // Shared long ago: no news on arrival.
      await arrive(TaskList(id: 'l7', name: 'Courses', ownerId: 'yoann', createdAt: DateTime(2026)));
      await lists.addTask('l7', 'Mien', byId: 'me');
      await lists.addTask('l7', 'Lait', byId: 'yoann');
      await lists.addTask('l7', 'Pain', byId: 'yoann');
      await Future<void>.delayed(Duration.zero);
      expect(told.map((c) => (c.author.name, c.name, c.isNote, c.edited)), [('Yoann', 'Courses', false, true)]);
    });

    test('a change to a note, by them only', () async {
      final at = DateTime.now().subtract(const Duration(hours: 1));
      Note old(String by, DateTime editedAt) =>
          Note(id: 'n9', authorId: 'yoann', editedById: by, editedAt: editedAt, title: 'Voyage', isShared: true);
      await notes.restoreNote(DeletedNote(note: old('yoann', at), index: 0));
      await notes.updateNote(old('me', at.add(const Duration(minutes: 1))));
      await Future<void>.delayed(Duration.zero);
      expect(told, isEmpty);

      await notes.updateNote(old('yoann', DateTime.now()));
      await Future<void>.delayed(Duration.zero);
      expect(told.map((c) => (c.name, c.isNote, c.edited)), [('Voyage', true, true)]);
    });
  });
}
