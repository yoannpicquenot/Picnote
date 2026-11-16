import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/activity/activity_repository_local.dart';
import 'package:picnote/data/repositories/live/live_repository.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/data/repositories/settings/settings_repository.dart';
import 'package:picnote/domain/models/live.dart';
import 'package:picnote/domain/models/note.dart';
import 'package:picnote/ui/note/view_models/note_viewmodel.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  group('NoteViewModel', () {
    late NoteRepositoryLocal notes;

    Note note({String author = 'me', bool shared = false, List<NoteBlock>? blocks}) => Note(
      id: 'n',
      title: 'Canada',
      authorId: author,
      editedById: author,
      editedAt: DateTime(2026, 1, 1),
      isShared: shared,
      blocks: blocks ?? const [NoteBlock(id: 'b1', text: 'Montréal')],
    );

    late ActivityRepositoryLocal activity;
    late LiveRepositoryLocal live;

    NoteViewModel build() => NoteViewModel(
      noteId: 'n',
      noteRepository: notes,
      authRepository: FakeAuthRepository(),
      householdRepository: FakeHouseholdRepository(household: kDuo),
      settingsRepository: SettingsRepositoryLocal(),
      activityRepository: activity = ActivityRepositoryLocal(),
      liveRepository: live = LiveRepositoryLocal(),
    );

    test('edits are signed by me', () async {
      notes = NoteRepositoryLocal(notes: [note(author: 'yoann', shared: true)]);
      final vm = build();
      await vm.setTitle('Voyage au Canada');

      expect(vm.note?.title, 'Voyage au Canada');
      expect(vm.note?.editedById, 'me');
      expect(vm.editedByMe, isTrue);
    });

    test('only the author can make a shared note personal or delete it', () {
      notes = NoteRepositoryLocal(notes: [note(author: 'yoann', shared: true)]);
      expect(build().canUnshareOrDelete, isFalse);

      notes = NoteRepositoryLocal(notes: [note(author: 'yoann')]);
      expect(build().canUnshareOrDelete, isTrue);
    });

    test('saves the body the editor has, signed by me', () async {
      notes = NoteRepositoryLocal(notes: [note()]);
      final vm = build();

      await vm.setBlocks([
        const NoteBlock(id: 'b1', text: 'Valise'),
        NoteBlock(id: vm.newBlockId(), type: NoteBlockType.todo, text: 'Passeports'),
      ]);
      expect(vm.note?.blocks.map((b) => b.type), [NoteBlockType.text, NoteBlockType.todo]);
      expect(vm.note?.blocks.map((b) => b.id).toSet(), hasLength(2));
      expect(vm.editedByMe, isTrue);
    });

    test('closing an empty note discards it', () async {
      notes = NoteRepositoryLocal(
        notes: [
          note(blocks: const [NoteBlock(id: 'b1')]).copyWith(title: ''),
        ],
      );
      await build().close();

      expect(notes.notes, isEmpty);
    });

    test('closing a note with content keeps it', () async {
      notes = NoteRepositoryLocal(notes: [note()]);
      await build().close();

      expect(notes.notes, hasLength(1));
    });

    test('closing an edited note tells the housemates at once', () async {
      notes = NoteRepositoryLocal(notes: [note()]);
      final untouched = build();
      await untouched.close();
      expect(activity.released, isEmpty);

      final edited = build();
      await edited.setTitle('Bergen');
      await edited.close();
      expect(activity.released, ['n']);
    });

    test('a shared note is sent as it is typed, a personal one never', () async {
      notes = NoteRepositoryLocal(notes: [note()]);
      await build().setTitle('Perso');
      expect(live.sent, isEmpty);

      notes = NoteRepositoryLocal(notes: [note(shared: true)]);
      final vm = build();
      await vm.setBlocks(const [NoteBlock(id: 'b1', text: 'Bergen')], cursor: 6);
      final sent = live.sent.single as LiveNote;
      expect((sent.title, sent.blocks.single.text, sent.cursor), ('Canada', 'Bergen', 6));
    });

    test('shows the housemate typing', () {
      notes = NoteRepositoryLocal(notes: [note(shared: true)]);
      final vm = build();
      expect(vm.typist, isNull);

      live.receiveNote('n', const LiveNote(userId: 'yoann', title: 'Canada', blocks: [], cursor: 0));
      expect(vm.typist?.name, 'Yoann');
      expect(vm.live?.title, 'Canada');
      live.dispose();
    });
  });
}
