import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/domain/models/note.dart';
import 'package:picnote/ui/note/widgets/note_delta.dart';

void main() {
  var next = 0;
  String newId() => 'new${next++}';

  const blocks = [
    NoteBlock(id: 'b1', text: 'Valise à faire', styles: [StyleRange(0, 6, InlineStyle.bold)]),
    NoteBlock(id: 'b2', type: NoteBlockType.heading, text: 'Lieux'),
    NoteBlock(id: 'b3', type: NoteBlockType.bullet, text: 'Montréal', styles: [StyleRange(2, 5, InlineStyle.italic)]),
    NoteBlock(id: 'b4', type: NoteBlockType.todo, text: 'Passeports', done: true),
    NoteBlock(id: 'b5', type: NoteBlockType.todo, text: 'Adaptateur'),
    NoteBlock(id: 'b6', type: NoteBlockType.link, text: 'airbnb.com/rooms/1'),
    NoteBlock(id: 'b7'),
  ];

  test('every kind of block survives a trip through the editor', () {
    final back = deltaToBlocks(blocksToDelta(blocks), blocks, newId);
    expect(sameBlocks(back, blocks), isTrue);
    expect(back.map((b) => b.id), blocks.map((b) => b.id));
  });

  test('and through a Quill document, as the editor holds it', () {
    final doc = Document.fromDelta(blocksToDelta(blocks));
    expect(sameBlocks(deltaToBlocks(doc.toDelta(), blocks, newId), blocks), isTrue);
  });

  test('a new line gets a new id, the others keep theirs', () {
    final doc = Document.fromDelta(blocksToDelta(blocks.take(2).toList()));
    doc.insert(doc.length - 1, '\nEncore');
    final back = deltaToBlocks(doc.toDelta(), blocks.take(2).toList(), newId);
    expect(back.map((b) => b.id), ['b1', 'b2', startsWith('new')]);
    expect(back.last.text, 'Encore');
  });

  test('an empty note is one empty line', () {
    expect(sameBlocks(deltaToBlocks(blocksToDelta(const []), const [], newId), const [NoteBlock(id: 'x')]), isTrue);
  });
}
