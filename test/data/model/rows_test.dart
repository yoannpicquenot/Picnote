import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/model/rows.dart';
import 'package:picnote/domain/models/activity.dart';
import 'package:picnote/domain/models/note.dart';
import 'package:picnote/domain/models/reminder.dart';
import 'package:picnote/domain/models/task.dart';
import 'package:picnote/domain/models/task_list.dart';

void main() {
  test('a list survives a round trip through its row', () {
    final list = TaskList(
      id: 'l1',
      name: 'Courses',
      color: ListColor.mustard,
      icon: ListIcon.shoppingCart,
      isShared: true,
      pinned: true,
      day: DateTime(2026, 11, 3),
      reminder: Reminder(date: DateTime(2026, 11, 2), time: '9:00'),
    );
    final row = listToRow(list);
    expect(row['day'], '2026-11-03');
    expect(row['reminder_date'], '2026-11-02');

    final back = listFromRow(row);
    expect(back.color, ListColor.mustard);
    expect(back.icon, ListIcon.shoppingCart);
    expect(back.pinned, isTrue);
    expect(back.day, DateTime(2026, 11, 3));
    expect(back.reminder, list.reminder);
  });

  test('an activity row tells a list from a note', () {
    final onList = activityFromRow({
      'list_id': 'l1',
      'note_id': null,
      'actor_id': 'me',
      'verb': 'check',
      'item': 'Lait',
      'at': '2026-11-02T08:00:00Z',
    });
    expect(onList.isNote, isFalse);
    expect(onList.itemId, 'l1');
    expect(onList.verb, ActivityVerb.check);
    expect(onList.item, 'Lait');

    final onNote = activityFromRow({
      'list_id': null,
      'note_id': 'n1',
      'actor_id': null,
      'verb': 'edit',
      'at': '2026-11-02T08:00:00Z',
    });
    expect(onNote.isNote, isTrue);
    expect(onNote.actorId, '');
    expect(onNote.item, isNull);
  });

  test('a note keeps its blocks, and a missing author reads as empty', () {
    final note = Note(
      id: 'n1',
      authorId: 'a',
      editedById: 'a',
      editedAt: DateTime(2026, 11, 1, 10, 30),
      title: 'Canada',
      blocks: const [NoteBlock(id: 'b1', type: NoteBlockType.todo, text: 'Passeports', done: true)],
    );
    final back = noteFromRow({...noteToRow(note), 'author_id': null});
    expect(back.authorId, '');
    expect(back.editedAt, note.editedAt);
    expect(back.reminder, isNull);
    expect(back.blocks.single.type, NoteBlockType.todo);
    expect(back.blocks.single.done, isTrue);
    expect(back.blocks.single.styles, isEmpty);
  });

  test('a block keeps its bold / italic / underline', () {
    const styles = [StyleRange(0, 4, InlineStyle.bold), StyleRange(2, 9, InlineStyle.underline)];
    final note = Note(
      id: 'n1',
      authorId: 'a',
      editedById: 'a',
      editedAt: DateTime(2026, 11, 1),
      blocks: const [NoteBlock(id: 'b1', text: 'Très important', styles: styles)],
    );
    expect(noteFromRow({...noteToRow(note), 'author_id': 'a'}).blocks.single.styles, styles);
  });

  test('a task keeps when it was checked', () {
    final task = Task(id: 't1', listId: 'l1', title: 'Pain', done: true, doneAt: DateTime(2026, 11, 14, 18, 5));
    expect(taskFromRow({...taskToRow(task, position: 1), 'today': false}).doneAt, task.doneAt);
  });
}
