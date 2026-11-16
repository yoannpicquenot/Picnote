import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/domain/models/note.dart';
import 'package:picnote/utils/inline_styles.dart';

void main() {
  const bold = InlineStyle.bold;
  const italic = InlineStyle.italic;

  List<StyleRange> afterTyping(List<StyleRange> styles, String from, String to) =>
      rangesOf(shiftMasks(masksOf(styles, from.length), from, to));

  test('ranges survive a round trip through masks', () {
    const styles = [StyleRange(0, 3, bold), StyleRange(2, 5, italic)];
    expect(rangesOf(masksOf(styles, 6)), styles);
  });

  test('typing right after a bold word keeps going in bold', () {
    expect(afterTyping(const [StyleRange(0, 3, bold)], 'Bon voyage', 'Bonne voyage'), const [StyleRange(0, 5, bold)]);
  });

  test('typing right before a bold word does not', () {
    expect(afterTyping(const [StyleRange(4, 8, bold)], 'Tes amis', 'Tes vrais amis'), const [StyleRange(10, 14, bold)]);
  });

  test('deleting inside a range shrinks it, deleting all of it drops it', () {
    expect(afterTyping(const [StyleRange(0, 5, bold)], 'Hello world', 'Helo world'), const [StyleRange(0, 4, bold)]);
    expect(afterTyping(const [StyleRange(0, 5, bold)], 'Hello world', ' world'), isEmpty);
  });

  test('a toggle adds a style to the selection, and takes it off when all of it has it', () {
    final masks = masksOf(const [StyleRange(0, 2, bold)], 6);
    final on = toggleStyle(masks, 0, 4, bold);
    expect(rangesOf(on), const [StyleRange(0, 4, bold)]);
    expect(rangesOf(toggleStyle(on, 1, 3, bold)), const [StyleRange(0, 1, bold), StyleRange(3, 4, bold)]);
  });
}
