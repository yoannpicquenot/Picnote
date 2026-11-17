import '../../../domain/models/note.dart';
import '../../../utils/inline_styles.dart';

/// Copying from a note puts Markdown on the clipboard, which other apps
/// understand; pasting reads it back. Underline has no Markdown of its
/// own, so it goes as `<u>…</u>`.

///
/// Blocks are separated by a blank line, as Markdown wants paragraphs, except
/// list items that follow each other. Each empty line of the note adds one
/// more blank line, so it comes back on paste.
String blocksToMarkdown(List<NoteBlock> blocks) {
  bool isEmpty(NoteBlock b) => b.type == NoteBlockType.text && b.text.isEmpty;
  bool isList(NoteBlock b) => b.type == NoteBlockType.bullet || b.type == NoteBlockType.todo;
  final first = blocks.indexWhere((b) => !isEmpty(b));
  if (first < 0) return '';
  final last = blocks.lastIndexWhere((b) => !isEmpty(b));
  final out = StringBuffer();
  NoteBlock? prev;
  var empties = 0;
  for (final b in blocks.sublist(first, last + 1)) {
    if (isEmpty(b)) {
      empties++;
      continue;
    }
    if (prev != null) {
      out.write(isList(prev) && isList(b) && empties == 0 ? '\n' : '\n\n');
      out.write('\n' * empties);
    }
    final text = _inlineMarkdown(b);
    out.write(switch (b.type) {
      NoteBlockType.heading => '${'#' * b.level.clamp(1, NoteBlock.maxLevel)} $text',
      NoteBlockType.bullet => '- $text',
      NoteBlockType.todo => '- [${b.done ? 'x' : ' '}] $text',
      NoteBlockType.link => b.text,
      NoteBlockType.table => _tableMarkdown(b.cells),
      NoteBlockType.text => text,
    });
    prev = b;
    empties = 0;
  }
  return out.toString();
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

final _quote = RegExp(r'^\s*>\s?(.*)$');
final _divider = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
final _fence = RegExp(r'^\s*(```|~~~)');
final _image = RegExp(r'^!\[[^\]]*\]\((\S+?)\)$');
// Notion's callouts and toggles come wrapped in these.
final _htmlTag = RegExp(r'^\s*</?(aside|details|summary|div|p|br)\b[^>]*/?>\s*$', caseSensitive: false);

/// The blocks in [markdown], with ids from [newId].
///
/// One blank line only separates blocks, as in Markdown; each further one
/// is an empty line of the note.
List<NoteBlock> markdownToBlocks(String markdown, String Function() newId) {
  final lines = markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final blocks = <NoteBlock>[];
  var blanks = 0;
  // Blank lines around a skipped line (divider, fence, HTML tag) count once.
  var carried = 0;
  void skip() {
    carried = blanks > carried ? blanks : carried;
    blanks = 0;
  }

  var inCode = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_fence.hasMatch(line)) {
      inCode = !inCode;
      skip();
      continue;
    }
    if (inCode) {
      blocks.add(NoteBlock(id: newId(), text: line));
      continue;
    }
    if (line.trim().isEmpty) {
      blanks++;
      continue;
    }
    if (_divider.hasMatch(line) || _htmlTag.hasMatch(line)) {
      skip();
      continue;
    }
    if (blocks.isNotEmpty) {
      final gap = blanks > carried ? blanks : carried;
      for (var k = 1; k < gap; k++) {
        blocks.add(NoteBlock(id: newId()));
      }
    }
    blanks = 0;
    carried = 0;
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
    blocks.add(_lineBlock(line, newId));
  }
  return blocks;
}

NoteBlock _lineBlock(String line, String Function() newId) {
  // A quote has no block of its own: its content stays.
  if (_quote.firstMatch(line) case final m?) return _lineBlock(m[1]!, newId);
  if (_heading.firstMatch(line.trimLeft()) case final m?) {
    final (text, styles) = _parseInline(m[2]!);
    final level = m[1]!.length.clamp(1, NoteBlock.maxLevel);
    return NoteBlock(id: newId(), type: NoteBlockType.heading, text: text, styles: styles, level: level);
  }
  if (_todo.firstMatch(line) case final m?) {
    final (text, styles) = _parseInline(m[2]!);
    return NoteBlock(id: newId(), type: NoteBlockType.todo, text: text, styles: styles, done: m[1] != ' ');
  }
  if (_bullet.firstMatch(line) case final m?) {
    final (text, styles) = _parseInline(m[1]!);
    return NoteBlock(id: newId(), type: NoteBlockType.bullet, text: text, styles: styles);
  }
  final trimmed = line.trim();
  if (_mdLink.firstMatch(trimmed) ?? _image.firstMatch(trimmed) case final m?) {
    return NoteBlock(id: newId(), type: NoteBlockType.link, text: m[m.groupCount]!);
  }
  if (_url.hasMatch(trimmed)) return NoteBlock(id: newId(), type: NoteBlockType.link, text: trimmed);
  final (text, styles) = _parseInline(trimmed);
  return NoteBlock(id: newId(), text: text, styles: styles);
}

List<String> _cells(String row) {
  var r = row.trim();
  if (r.startsWith('|')) r = r.substring(1);
  if (r.endsWith('|') && !r.endsWith(r'\|')) r = r.substring(0, r.length - 1);
  // Cells hold plain text: "**Mer. 10**" keeps only its words.
  return [for (final c in r.split(RegExp(r'(?<!\\)\|'))) _parseInline(c.trim().replaceAll(r'\|', '|')).$1];
}

/// `**bold**`, `*italic*` or `_italic_`, `<u>underline</u>`, and links
/// (their text stays). Strikethrough and `code`, which notes do not have,
/// keep their text too, and `\*` is a plain `*`.
final _token = RegExp(
  r'\*\*(.+?)\*\*|__(.+?)__|<u>(.+?)</u>|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?!\*)|(?<!\w)_(?!\s)(.+?)(?<!\s)_(?!\w)|\[([^\]]+)\]\([^)\s]+\)'
  r'|~~(.+?)~~|`([^`]+)`|\\([\\`*_{}\[\]()#+\-.!|~>])',
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
    at = m.end;
    // Code and escaped characters are taken as they are.
    if ((m[8] ?? m[9]) case final literal?) {
      plain(literal, mask);
      continue;
    }
    final (inner, style) = switch (m) {
      _ when m[1] != null => (m[1]!, InlineStyle.bold),
      _ when m[2] != null => (m[2]!, InlineStyle.bold),
      _ when m[3] != null => (m[3]!, InlineStyle.underline),
      _ when m[4] != null => (m[4]!, InlineStyle.italic),
      _ when m[5] != null => (m[5]!, InlineStyle.italic),
      _ when m[6] != null => (m[6]!, null),
      _ => (m[7]!, null),
    };
    final (innerText, innerStyles) = _parseInline(inner, style == null ? mask : mask | (1 << style.index));
    final innerMasks = masksOf(innerStyles, innerText.length);
    text.write(innerText);
    masks.addAll(innerMasks);
  }
  plain(source.substring(at), mask);
  return (text.toString(), rangesOf(masks));
}
