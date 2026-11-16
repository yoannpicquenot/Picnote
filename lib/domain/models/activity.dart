/// What someone did to a list or a note.
enum ActivityVerb { create, add, check, uncheck, edit, del }

/// One change to a list or a note, for "Latest changes" and the "who's
/// here" panel.
class Activity {
  const Activity({
    required this.isNote,
    required this.itemId,
    required this.actorId,
    required this.verb,
    required this.at,
    this.item,
  });

  /// About a note, else about a list.
  final bool isNote;

  /// The list's or note's id.
  final String itemId;
  final String actorId;
  final ActivityVerb verb;

  /// The task's title, when the change is about a task.
  final String? item;
  final DateTime at;
}
