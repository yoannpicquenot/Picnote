import 'note.dart';

/// A note as a housemate is typing it, before it is saved.
class LiveNote {
  const LiveNote({required this.userId, required this.title, required this.blocks, required this.cursor});

  final String userId;
  final String title;
  final List<NoteBlock> blocks;

  /// Where their cursor is in the body, as an offset in the editor's text;
  /// null while they type the title.
  final int? cursor;
}

/// The item a housemate is typing into a list, before it is added.
class LiveDraft {
  const LiveDraft({required this.userId, required this.text});

  final String userId;
  final String text;
}
