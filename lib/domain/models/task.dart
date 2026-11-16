import '../../utils/dates.dart';

/// One item of a [TaskList]. [byId] is the member who last changed it.
class Task {
  const Task({
    required this.id,
    required this.listId,
    required this.title,
    this.done = false,
    this.doneAt,
    this.byId,
    this.today = false,
  });

  final String id;
  final String listId;
  final String title;
  final bool done;

  /// When it was checked, null while unchecked.
  final DateTime? doneAt;
  final String? byId;

  /// Pinned to today even when its list has no day.
  final bool today;

  /// Checked before today: archived at midnight, so each day starts clean.
  bool get isStale => done && doneAt != null && doneAt!.isBefore(dateOnly(DateTime.now()));

  /// Checking stamps [doneAt], unchecking clears it.
  Task copyWith({String? title, bool? done, String? byId}) {
    final checked = done ?? this.done;
    return Task(
      id: id,
      listId: listId,
      title: title ?? this.title,
      done: checked,
      doneAt: !checked
          ? null
          : this.done
          ? doneAt
          : DateTime.now(),
      byId: byId ?? this.byId,
      today: today,
    );
  }
}
