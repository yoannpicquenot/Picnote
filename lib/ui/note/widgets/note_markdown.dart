import '../../../domain/models/note.dart';
import '../../../utils/inline_styles.dart';

/// Copying from a note puts Markdown on the clipboard, which other apps
/// understand; pasting reads it back. Underline has no Markdown of its
/// own, so it goes as `<u>…</u>`.

String blocksToMarkdown(List<NoteBlock> blocks) {
  final lines = <String>[];
  for (final b in blocks) {
    final text = _inlineMarkdown(b);
    lines.add(switch (b.type) {
      NoteBlockType.heading => '${'#' * b.level.clamp(1, NoteBlock.maxLevel)} $text',
      NoteBlockType.bullet => '- $text',
      NoteBlockType.todo => '- [${b.done ? 'x' : ' '}] $text',
      NoteBlockType.link => b.text,
      NoteBlockType.table => _tableMarkdown(b.cells),
      NoteBlockType.text => text,
    });
  }
  return lines.join('\n');
}

const _marks = {InlineStyle.bold: ('**', '**'), InlineStyle.italic: ('*', '*'), InlineStyle.underline: ('<u>', '</u>')};

String _inlineMarkdown(NoteBlock b) {
  if (b.styles.isEmpty) return b.text;
  final masks = masksOf(b.styles, b.text.length);
  final out = StringBuffer();
  var start = 0;
  for (var i = 1; i <= b.text.length; i++) {
    if (i < b.text.length && masks[i] == masks[start]) continue;
    final run = b.text.substring(start, i);
    final on = [
      for (final style in InlineStyle.values)
        if (masks[start] & (1 << style.index) != 0) style,
    ];
    // Markers hug the text: "**word** " rather than "**word **".
    final core = run.trim();
    if (on.isEmpty || core.isEmpty) {
      out.write(run);
    } else {
      final lead = run.substring(0, run.indexOf(core));
      out
        ..write(lead)
        ..writeAll(on.map((s) => _marks[s]!.$1))
        ..write(core)
        ..writeAll(on.reversed.map((s) => _marks[s]!.$2))
        ..write(run.substring(lead.length + core.length));
    }
    start = i;
  }
  return out.toString();
}

String _tableMarkdown(List<List<String>> cells) {
  if (cells.isEmpty) return '';
  String row(List<String> r) => '| ${r.map((c) => c.replaceAll('|', r'\|').replaceAll('\n', ' ')).join(' | ')} |';
  return [
    row(cells.first),
    row([for (final _ in cells.first) '---']),
    for (final r in cells.skip(1)) row(r),
  ].join('\n');
}

final _heading = RegExp(r'^(#{1,6})\s+(.*)$');
final _todo = RegExp(r'^\s*[-*+]\s+\[([ xX])\]\s?(.*)$');
final _bullet = RegExp(r'^\s*[-*+•]\s+(.*)$');
final _url = RegExp(r'^(https?://|www\.)\S+$');
final _mdLink = RegExp(r'^\[([^\]]*)\]\((\S+)\)$');
final _tableRow = RegExp(r'^\s*\|.*\|\s*$');
final _tableRule = RegExp(r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$');

/// The blocks in [markdown], with ids from [newId].
List<NoteBlock> markdownToBlocks(String markdown, String Function() newId) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final blocks = <NoteBlock>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    // A table: a header row, the "---" rule, then its rows.
    if (_tableRow.hasMatch(line) && i + 1 < lines.length && _tableRule.hasMatch(lines[i + 1])) {
      final rows = [_cells(line)];
      i += 2;
      while (i < lines.length && _tableRow.hasMatch(lines[i])) {
        rows.add(_cells(lines[i]));
        i++;
      }
      i--;
      final width = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
      blocks.add(
        NoteBlock(
          id: newId(),
          type: NoteBlockType.table,
          cells: [
            for (final r in rows) [...r, for (var k = r.length; k < width; k++) ''],
          ],
        ),
      );
      continue;
    }
    if (_heading.firstMatch(line) case final m?) {
      final (text, styles) = _parseInline(m[2]!);
      final level = m[1]!.length.clamp(1, NoteBlock.maxLevel);
      blocks.add(NoteBlock(id: newId(), type: NoteBlockType.heading, text: text, styles: styles, level: level));
    } else if (_todo.firstMatch(line) case final m?) {
      final (text, styles) = _parseInline(m[2]!);
      blocks.add(NoteBlock(id: newId(), type: NoteBlockType.todo, text: text, styles: styles, done: m[1] != ' '));
    } else if (_bullet.firstMatch(line) case final m?) {
      final (text, styles) = _parseInline(m[1]!);
      blocks.add(NoteBlock(id: newId(), type: NoteBlockType.bullet, text: text, styles: styles));
    } else if (_mdLink.firstMatch(line.trim()) case final m?) {
      blocks.add(NoteBlock(id: newId(), type: NoteBlockType.link, text: m[2]!));
    } else if (_url.hasMatch(line.trim())) {
      blocks.add(NoteBlock(id: newId(), type: NoteBlockType.link, text: line.trim()));
    } else {
      final (text, styles) = _parseInline(line);
      blocks.add(NoteBlock(id: newId(), text: text, styles: styles));
    }
  }
  return blocks;
}

List<String> _cells(String row) {
  var r = row.trim();
  if (r.startsWith('|')) r = r.substring(1);
  if (r.endsWith('|') && !r.endsWith(r'\|')) r = r.substring(0, r.length - 1);
  return [for (final c in r.split(RegExp(r'(?<!\\)\|'))) c.trim().replaceAll(r'\|', '|')];
}

/// `**bold**`, `*italic*` or `_italic_`, `<u>underline</u>`, and links
/// (their text stays).
final _token = RegExp(
  r'\*\*(.+?)\*\*|__(.+?)__|<u>(.+?)</u>|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?!\*)|(?<!\w)_(?!\s)(.+?)(?<!\s)_(?!\w)|\[([^\]]+)\]\([^)\s]+\)',
);

(String, List<StyleRange>) _parseInline(String source, [int mask = 0]) {
  final text = StringBuffer();
  final masks = <int>[];
  void plain(String s, int m) {
    text.write(s);
    masks.addAll(List.filled(s.length, m));
  }

  var at = 0;
  for (final m in _token.allMatches(source)) {
    plain(source.substring(at, m.start), mask);
    final (inner, style) = switch (m) {
      _ when m[1] != null => (m[1]!, InlineStyle.bold),
      _ when m[2] != null => (m[2]!, InlineStyle.bold),
      _ when m[3] != null => (m[3]!, InlineStyle.underline),
      _ when m[4] != null => (m[4]!, InlineStyle.italic),
      _ when m[5] != null => (m[5]!, InlineStyle.italic),
      _ => (m[6]!, null),
    };
    final (innerText, innerStyles) = _parseInline(inner, style == null ? mask : mask | (1 << style.index));
    final innerMasks = masksOf(innerStyles, innerText.length);
    text.write(innerText);
    masks.addAll(innerMasks);
    at = m.end;
  }
  plain(source.substring(at), mask);
  return (text.toString(), rangesOf(masks));
}
