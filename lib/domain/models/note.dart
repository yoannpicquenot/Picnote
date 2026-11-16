import 'reminder.dart';

/// Kinds of block, picked by typing "/" in an empty line.
enum NoteBlockType { text, heading, bullet, todo, link, table }

/// What a heading can be colored in: terracotta by default, the list
/// colors, grey, black.
enum HeadingColor { terra, sage, mustard, rose, cocoa, grey, ink }

/// Inline formatting, from the toolbar above the keyboard.
enum InlineStyle { bold, italic, underline }

/// [style] applies to the characters from [start] (included) to [end]
/// (excluded) of a block's text.
class StyleRange {
  const StyleRange(this.start, this.end, this.style);

  final int start;
  final int end;
  final InlineStyle style;

  @override
  bool operator ==(Object other) =>
      other is StyleRange && other.start == start && other.end == end && other.style == style;

  @override
  int get hashCode => Object.hash(start, end, style);
}

class NoteBlock {
  const NoteBlock({
    required this.id,
    this.type = NoteBlockType.text,
    this.text = '',
    this.done = false,
    this.styles = const [],
    this.level = 1,
    this.color = HeadingColor.terra,
    this.cells = const [],
  });

  static const maxLevel = 4;

  final String id;
  final NoteBlockType type;
  final String text;
  final bool done;
  final List<StyleRange> styles;

  /// A heading's size, 1 (largest) to [maxLevel].
  final int level;

  /// A heading's color.
  final HeadingColor color;

  /// A table's rows, each a list of cells (all rows the same length).
  final List<List<String>> cells;

  NoteBlock copyWith({
    NoteBlockType? type,
    String? text,
    bool? done,
    List<StyleRange>? styles,
    int? level,
    HeadingColor? color,
    List<List<String>>? cells,
  }) => NoteBlock(
    id: id,
    type: type ?? this.type,
    text: text ?? this.text,
    done: done ?? this.done,
    styles: styles ?? this.styles,
    level: level ?? this.level,
    color: color ?? this.color,
    cells: cells ?? this.cells,
  );
}

/// A free-form note. Only its author can make a shared note personal again
/// or delete it.
class Note {
  const Note({
    required this.id,
    required this.authorId,
    required this.editedById,
    required this.editedAt,
    this.title = '',
    this.isShared = false,
    this.reminder,
    this.blocks = const [],
  });

  final String id;
  final String title;
  final String authorId;
  final String editedById;
  final DateTime editedAt;
  final bool isShared;
  final Reminder? reminder;
  final List<NoteBlock> blocks;

  bool get isBlank => title.trim().isEmpty && blocks.every((b) => b.text.trim().isEmpty);

  /// First line worth previewing on the notes grid.
  String? get snippet {
    for (final b in blocks) {
      if (b.type == NoteBlockType.text && b.text.trim().isNotEmpty) return b.text;
    }
    for (final b in blocks) {
      if (b.text.trim().isNotEmpty) return b.text;
    }
    return null;
  }

  Note copyWith({
    String? title,
    String? editedById,
    DateTime? editedAt,
    bool? isShared,
    Reminder? Function()? reminder,
    List<NoteBlock>? blocks,
  }) => Note(
    id: id,
    authorId: authorId,
    title: title ?? this.title,
    editedById: editedById ?? this.editedById,
    editedAt: editedAt ?? this.editedAt,
    isShared: isShared ?? this.isShared,
    reminder: reminder != null ? reminder() : this.reminder,
    blocks: blocks ?? this.blocks,
  );
}
