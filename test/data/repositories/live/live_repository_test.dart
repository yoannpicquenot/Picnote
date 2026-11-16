import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/live/live_repository.dart';
import 'package:picnote/domain/models/live.dart';
import 'package:picnote/domain/models/note.dart';

void main() {
  test('what a housemate types goes once they stop for a while', () async {
    final live = LiveRepositoryLocal(quiet: const Duration(milliseconds: 300));
    addTearDown(live.dispose);
    live.receiveNote(
      'n',
      const LiveNote(
        userId: 'yoann',
        title: 'Bergen',
        blocks: [NoteBlock(id: 'b')],
        cursor: 3,
      ),
    );
    live.receiveDraft('l', const LiveDraft(userId: 'yoann', text: 'Lai'));
    expect(live.note('n')?.title, 'Bergen');
    expect(live.draft('l')?.text, 'Lai');

    await Future<void>.delayed(const Duration(milliseconds: 200));
    live.receiveDraft('l', const LiveDraft(userId: 'yoann', text: 'Lait'));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(live.note('n'), isNull);
    expect(live.draft('l')?.text, 'Lait');

    // Added (or cleared): no draft any more.
    live.receiveDraft('l', const LiveDraft(userId: 'yoann', text: ''));
    expect(live.draft('l'), isNull);
  });
}
