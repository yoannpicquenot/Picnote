import '../domain/models/note.dart';

/// Inline styles as one bit mask per character (bit = [InlineStyle.index]):
/// easy to edit, turned back into [StyleRange]s to be stored.
List<int> masksOf(List<StyleRange> ranges, int length) {
  final masks = List.filled(length, 0);
  for (final r in ranges) {
    for (var i = r.start.clamp(0, length); i < r.end.clamp(0, length); i++) {
      masks[i] |= 1 << r.style.index;
    }
  }
  return masks;
}

/// The fewest ranges for [masks], per style in order.
List<StyleRange> rangesOf(List<int> masks) => [
  for (final style in InlineStyle.values) ..._runs(masks, 1 << style.index, style),
];

Iterable<StyleRange> _runs(List<int> masks, int bit, InlineStyle style) sync* {
  int? start;
  for (var i = 0; i <= masks.length; i++) {
    final on = i < masks.length && masks[i] & bit != 0;
    if (on && start == null) start = i;
    if (!on && start != null) {
      yield StyleRange(start, i, style);
      start = null;
    }
  }
}

/// Follows [oldText] becoming [newText]: untouched characters keep their
/// style, typed ones take the style of the character before them (typing
/// on after a bold word stays bold), or of the first replaced one.
List<int> shiftMasks(List<int> masks, String oldText, String newText) {
  final max = oldText.length < newText.length ? oldText.length : newText.length;
  var p = 0;
  while (p < max && oldText.codeUnitAt(p) == newText.codeUnitAt(p)) {
    p++;
  }
  var s = 0;
  while (s < max - p && oldText.codeUnitAt(oldText.length - 1 - s) == newText.codeUnitAt(newText.length - 1 - s)) {
    s++;
  }
  final removed = oldText.length - p - s;
  final inserted = newText.length - p - s;
  final typed = removed > 0
      ? masks[p]
      : p > 0
      ? masks[p - 1]
      : 0;
  return [...masks.sublist(0, p), for (var i = 0; i < inserted; i++) typed, ...masks.sublist(masks.length - s)];
}

/// Whether every character from [start] to [end] has [style].
bool hasStyle(List<int> masks, int start, int end, InlineStyle style) {
  if (start >= end) return false;
  for (var i = start; i < end; i++) {
    if (masks[i] & (1 << style.index) == 0) return false;
  }
  return true;
}

/// Removes [style] from [start]..[end] if all of it has it, adds it
/// otherwise, like any text editor.
List<int> toggleStyle(List<int> masks, int start, int end, InlineStyle style) {
  final bit = 1 << style.index;
  final on = !hasStyle(masks, start, end, style);
  return [
    for (var i = 0; i < masks.length; i++)
      i < start || i >= end
          ? masks[i]
          : on
          ? masks[i] | bit
          : masks[i] & ~bit,
  ];
}
