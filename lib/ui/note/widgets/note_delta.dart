import 'dart:convert';
import 'dart:ui';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../../../domain/models/note.dart';
import '../../../utils/inline_styles.dart';
import '../../core/themes/colors.dart';

/// A note's blocks are stored as they always were; the editor works on one
/// Quill document, one line per block, so a selection can span lines.

const _inline = {InlineStyle.bold: 'bold', InlineStyle.italic: 'italic', InlineStyle.underline: 'underline'};

/// The embed a table is, alone on its line.
const tableEmbed = 'table';

/// A heading's color, as the editor draws it.
Color headingColor(HeadingColor c) => switch (c) {
  HeadingColor.terra => PnColors.terra,
  HeadingColor.sage => ListTheme.sage.fg,
  HeadingColor.mustard => ListTheme.mustard.fg,
  HeadingColor.rose => ListTheme.rose.fg,
  HeadingColor.cocoa => ListTheme.cocoa.fg,
  HeadingColor.grey => PnColors.muted,
  HeadingColor.ink => PnColors.ink,
};

/// The value of Quill's inline color attribute for [c]: none for the
/// default terracotta, which the heading styles already have.
String? headingColorValue(HeadingColor c) {
  if (c == HeadingColor.terra) return null;
  final rgb = headingColor(c).toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

HeadingColor _headingColorOf(Object? value) {
  for (final c in HeadingColor.values) {
    if (value != null && headingColorValue(c) == value.toString().toUpperCase()) return c;
  }
  return HeadingColor.terra;
}

/// The document for [blocks]. A link block is a line that is all link.
Delta blocksToDelta(List<NoteBlock> blocks) {
  final delta = Delta();
  for (final b in blocks) {
    if (b.type == NoteBlockType.table) {
      delta
        ..insert({tableEmbed: jsonEncode(b.cells)})
        ..insert('\n');
      continue;
    }
    final masks = masksOf(b.styles, b.text.length);
    final color = b.type == NoteBlockType.heading ? headingColorValue(b.color) : null;
    var start = 0;
    for (var i = 1; i <= b.text.length; i++) {
      if (i == b.text.length || masks[i] != masks[start]) {
        final attrs = <String, dynamic>{
          for (final MapEntry(key: style, value: name) in _inline.entries)
            if (masks[start] & (1 << style.index) != 0) name: true,
          if (b.type == NoteBlockType.link) 'link': b.text,
          'color': ?color,
        };
        delta.insert(b.text.substring(start, i), attrs.isEmpty ? null : attrs);
        start = i;
      }
    }
    delta.insert('\n', switch (b.type) {
      NoteBlockType.heading => {'header': b.level.clamp(1, NoteBlock.maxLevel)},
      NoteBlockType.bullet => {'list': 'bullet'},
      NoteBlockType.todo => {'list': b.done ? 'checked' : 'unchecked'},
      NoteBlockType.text || NoteBlockType.link || NoteBlockType.table => null,
    });
  }
  if (blocks.isEmpty) delta.insert('\n');
  return delta;
}

/// The rows of a table embed's data.
List<List<String>> tableCells(Object? data) {
  try {
    final rows = (data is String ? jsonDecode(data) : data) as List;
    return [
      for (final row in rows.cast<List>()) [for (final c in row) c?.toString() ?? ''],
    ];
  } on Object {
    return const [];
  }
}

/// The blocks of [delta]. Line i keeps the id of [previous] block i, so
/// that blocks are not all renamed on each keystroke.
List<NoteBlock> deltaToBlocks(Delta delta, List<NoteBlock> previous, String Function() newId) {
  final blocks = <NoteBlock>[];
  final text = StringBuffer();
  final masks = <int>[];
  var allLink = true;
  Object? color;

  /// The newline closing a table's line closes nothing more.
  var afterTable = false;

  String idAt(int i) => i < previous.length ? previous[i].id : newId();

  void endLine(Map<String, dynamic>? attrs) {
    if (afterTable) {
      afterTable = false;
      return;
    }
    final i = blocks.length;
    final line = text.toString();
    final type = switch (attrs) {
      {'header': _} => NoteBlockType.heading,
      {'list': 'bullet'} => NoteBlockType.bullet,
      {'list': 'checked' || 'unchecked'} => NoteBlockType.todo,
      _ when line.isNotEmpty && allLink => NoteBlockType.link,
      _ => NoteBlockType.text,
    };
    final level = attrs?['header'];
    blocks.add(
      NoteBlock(
        id: idAt(i),
        type: type,
        text: line,
        done: attrs?['list'] == 'checked',
        styles: rangesOf(masks),
        level: level is int ? level.clamp(1, NoteBlock.maxLevel) : 1,
        color: type == NoteBlockType.heading ? _headingColorOf(color) : HeadingColor.terra,
      ),
    );
    text.clear();
    masks.clear();
    allLink = true;
    color = null;
  }

  for (final op in delta.toList()) {
    final data = op.data;
    if (data is Map) {
      if (data.containsKey(tableEmbed)) {
        // Whatever was typed before it on the same line ends there.
        if (text.isNotEmpty) endLine(null);
        blocks.add(NoteBlock(id: idAt(blocks.length), type: NoteBlockType.table, cells: tableCells(data[tableEmbed])));
        afterTable = true;
      }
      continue;
    }
    if (data is! String) continue;
    final attrs = op.attributes;
    var mask = 0;
    for (final MapEntry(key: style, value: name) in _inline.entries) {
      if (attrs?[name] == true) mask |= 1 << style.index;
    }
    final link = attrs?.containsKey('link') ?? false;
    final parts = data.split('\n');
    for (var k = 0; k < parts.length; k++) {
      final part = parts[k];
      if (part.isNotEmpty) {
        afterTable = false;
        text.write(part);
        masks.addAll(List.filled(part.length, mask));
        allLink &= link;
        color ??= attrs?['color'];
      }
      if (k < parts.length - 1) endLine(attrs);
    }
  }
  return blocks;
}

/// Same content, ids aside.
bool sameBlocks(List<NoteBlock> a, List<NoteBlock> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.type != y.type || x.text != y.text || (x.type == NoteBlockType.todo && x.done != y.done)) return false;
    if (x.type == NoteBlockType.heading && (x.level != y.level || x.color != y.color)) return false;
    if (x.type == NoteBlockType.table && jsonEncode(x.cells) != jsonEncode(y.cells)) return false;
    if (x.styles.length != y.styles.length) return false;
    for (var k = 0; k < x.styles.length; k++) {
      if (x.styles[k] != y.styles[k]) return false;
    }
  }
  return true;
}

/// The block-level attribute a "/" menu pick gives the current line.
List<Attribute<dynamic>> lineAttributes(NoteBlockType type, {int level = 1}) => switch (type) {
  NoteBlockType.heading => [Attribute.clone(Attribute.list, null), HeaderAttribute(level: level)],
  NoteBlockType.bullet => [Attribute.clone(Attribute.header, null), Attribute.ul],
  NoteBlockType.todo => [Attribute.clone(Attribute.header, null), Attribute.unchecked],
  NoteBlockType.text ||
  NoteBlockType.link ||
  NoteBlockType.table => [Attribute.clone(Attribute.header, null), Attribute.clone(Attribute.list, null)],
};
