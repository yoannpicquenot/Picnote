import '../../utils/dates.dart';

/// How often a Pense-bête reminder comes back.
enum MemoRepeat { never, daily, weekly, monthly }

/// A task of the household's Pense-bête: one list per household, always
/// there, for reminders that come once or again and again. Everyone in the
/// household may change or delete any of them.
///
/// It is for one member ([forId]), for both ([forBoth]), or for no one in
/// particular (both null/false, which concerns everyone). The reminder is
/// a day and an hour on the phone's clock ([remindOn] at [remindHour]),
/// both null when there is none.
class MemoTask {
  const MemoTask({
    required this.id,
    required this.title,
    this.forId,
    this.forBoth = false,
    this.remindOn,
    this.remindHour,
    this.repeat = MemoRepeat.never,
    this.done = false,
    this.doneAt,
    this.authorId,
  });

  final String id;
  final String title;
  final String? forId;
  final bool forBoth;
  final DateTime? remindOn;
  final int? remindHour;
  final MemoRepeat repeat;
  final bool done;
  final DateTime? doneAt;
  final String? authorId;

  bool get hasReminder => remindOn != null && remindHour != null;

  /// For [memberId], for both, or for no one in particular.
  bool concerns(String memberId) => forBoth || forId == null || forId == memberId;

  /// The day it shows on: a missed reminder slides to today, as on lists.
  DateTime? get day => remindOn == null ? null : effectiveDay(remindOn!);

  /// Checked before today, and not coming back: archived at midnight, as
  /// list items are.
  bool get isStale =>
      done && repeat == MemoRepeat.never && doneAt != null && doneAt!.isBefore(dateOnly(DateTime.now()));

  /// Checking stamps [doneAt], unchecking clears it. [forId] and [remindOn]
  /// take a function, so that they can be set to null.
  MemoTask copyWith({
    String? title,
    String? Function()? forId,
    bool? forBoth,
    DateTime? Function()? remindOn,
    int? Function()? remindHour,
    MemoRepeat? repeat,
    bool? done,
  }) {
    final checked = done ?? this.done;
    return MemoTask(
      id: id,
      title: title ?? this.title,
      forId: forId != null ? forId() : this.forId,
      forBoth: forBoth ?? this.forBoth,
      remindOn: remindOn != null ? remindOn() : this.remindOn,
      remindHour: remindHour != null ? remindHour() : this.remindHour,
      repeat: repeat ?? this.repeat,
      done: checked,
      doneAt: !checked
          ? null
          : this.done
          ? doneAt
          : DateTime.now(),
      authorId: authorId,
    );
  }
}

/// The hours a reminder can ring at.
const memoHours = [8, 9, 12, 18, 20];

/// What is left to do: in all, for [meId], and for [partnerId]. A task for
/// both counts for each of them.
({int open, int mine, int theirs}) countMemos(Iterable<MemoTask> tasks, String meId, String? partnerId) {
  final open = tasks.where((t) => !t.done);
  return (
    open: open.length,
    mine: open.where((t) => t.forBoth || t.forId == meId).length,
    theirs: partnerId == null ? 0 : open.where((t) => t.forBoth || t.forId == partnerId).length,
  );
}
