import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../../../domain/models/note.dart';
import '../../../utils/inline_styles.dart';

/// A note's blocks are stored as they always were; the editor works on one
/// Quill document, one line per block, so a selection can span lines.

const _inline = {InlineStyle.bold: 'bold', InlineStyle.italic: 'italic', InlineStyle.underline: 'underline'};

/// The document for [blocks]. A link block is a line that is all link.
Delta blocksToDelta(List<NoteBlock> blocks) {
  final delta = Delta();
  for (final b in blocks) {
    final masks = masksOf(b.styles, b.text.length);
    var start = 0;
    for (var i = 1; i <= b.text.length; i++) {
      if (i == b.text.length || masks[i] != masks[start]) {
        final attrs = <String, dynamic>{
          for (final MapEntry(key: style, value: name) in _inline.entries)
            if (masks[start] & (1 << style.index) != 0) name: true,
          if (b.type == NoteBlockType.link) 'link': b.text,
        };
        delta.insert(b.text.substring(start, i), attrs.isEmpty ? null : attrs);
        start = i;
      }
    }
    delta.insert('\n', switch (b.type) {
      NoteBlockType.heading => {'header': 1},
      NoteBlockType.bullet => {'list': 'bullet'},
      NoteBlockType.todo => {'list': b.done ? 'checked' : 'unchecked'},
      NoteBlockType.text || NoteBlockType.link => null,
    });
  }
  if (blocks.isEmpty) delta.insert('\n');
  return delta;
}

/// The blocks of [delta]. Line i keeps the id of [previous] block i, so
/// that blocks are not all renamed on each keystroke.
List<NoteBlock> deltaToBlocks(Delta delta, List<NoteBlock> previous, String Function() newId) {
  final blocks = <NoteBlock>[];
  final text = StringBuffer();
  final masks = <int>[];
  var allLink = true;

  void endLine(Map<String, dynamic>? attrs) {
    final i = blocks.length;
    final line = text.toString();
    final type = switch (attrs) {
      {'header': _} => NoteBlockType.heading,
      {'list': 'bullet'} => NoteBlockType.bullet,
      {'list': 'checked' || 'unchecked'} => NoteBlockType.todo,
      _ when line.isNotEmpty && allLink => NoteBlockType.link,
      _ => NoteBlockType.text,
    };
    blocks.add(
      NoteBlock(
        id: i < previous.length ? previous[i].id : newId(),
        type: type,
        text: line,
        done: attrs?['list'] == 'checked',
        styles: rangesOf(masks),
      ),
    );
    text.clear();
    masks.clear();
    allLink = true;
  }

  for (final op in delta.toList()) {
    final data = op.data;
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
        text.write(part);
        masks.addAll(List.filled(part.length, mask));
        allLink &= link;
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
    if (x.styles.length != y.styles.length) return false;
    for (var k = 0; k < x.styles.length; k++) {
      if (x.styles[k] != y.styles[k]) return false;
    }
  }
  return true;
}

/// The block-level attribute a "/" menu pick gives the current line.
List<Attribute<dynamic>> lineAttributes(NoteBlockType type) => switch (type) {
  NoteBlockType.heading => [Attribute.clone(Attribute.list, null), Attribute.h1],
  NoteBlockType.bullet => [Attribute.clone(Attribute.header, null), Attribute.ul],
  NoteBlockType.todo => [Attribute.clone(Attribute.header, null), Attribute.unchecked],
  NoteBlockType.text ||
  NoteBlockType.link => [Attribute.clone(Attribute.header, null), Attribute.clone(Attribute.list, null)],
};
