import 'package:flutter/material.dart';

/// The colored shape behind a list: its card on home, the header of its
/// page. The page fades in over the card (no hero: the morph looked odd).
class ListBackdrop extends StatelessWidget {
  const ListBackdrop({super.key, required this.listId, required this.color, required this.radius});

  final String listId;
  final Color color;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) => _Shape(color: color, radius: radius);
}

/// The shape behind a note: its card on the notes grid, the whole page of
/// the open note.
class NoteBackdrop extends StatelessWidget {
  const NoteBackdrop({super.key, required this.noteId, required this.color, this.radius = BorderRadius.zero});

  final String noteId;
  final Color color;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) => _Shape(color: color, radius: radius);
}

/// A list's name, on its card and at the top of its page.
class ListTitle extends StatelessWidget {
  const ListTitle({super.key, required this.listId, required this.text, required this.style, this.maxLines});

  final String listId;
  final String text;
  final TextStyle style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: style, maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis);
}

class _Shape extends StatelessWidget {
  const _Shape({required this.color, required this.radius});

  final Color color;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, borderRadius: radius),
  );
}
