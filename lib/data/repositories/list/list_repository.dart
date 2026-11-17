import 'package:flutter/foundation.dart';

import '../../../domain/models/task.dart';
import '../../../domain/models/task_list.dart';
import '../../../utils/result.dart';

/// What a deletion removed, so it can be put back ("Undo").
class DeletedList {
  const DeletedList({required this.list, required this.index, required this.tasks});

  final TaskList list;
  final int index;
  final List<Task> tasks;
}

class DeletedTask {
  const DeletedTask({required this.task, required this.index});

  final Task task;
  final int index;
}

/// Source of truth for the household's lists and their tasks, shared across
/// features. [lists] and [tasks] are what was last loaded.
///
/// Tasks checked before today ([Task.isStale]) are archived on load, and
/// the app asks again at midnight and when it comes back to the foreground.
abstract class ListRepository extends ChangeNotifier {
  List<TaskList> get lists;

  List<Task> get tasks;

  /// Lists visible to the current user: their personal lists and the
  /// household's shared lists.
  Future<Result<void>> load();

  Future<Result<TaskList>> createList(TaskList draft);

  Future<Result<void>> updateList(TaskList list);

  Future<Result<DeletedList>> deleteList(String id);

  Future<Result<void>> restoreList(DeletedList deleted);

  /// Joining a household keeps everything, as personal.
  Future<Result<void>> makeAllPersonal();

  Future<Result<Task>> addTask(String listId, String title, {required String byId});

  Future<Result<void>> updateTask(Task task);

  Future<Result<DeletedTask>> deleteTask(String id);

  Future<Result<void>> restoreTask(DeletedTask deleted);

  /// Reorders the unchecked tasks of [listId] to match [openTaskIds].
  Future<Result<void>> reorderOpenTasks(String listId, List<String> openTaskIds);

  /// Archives the tasks checked before today: they leave [tasks] but stay
  /// stored.
  Future<Result<void>> archiveStaleTasks();

  /// Puts the pinned lists in the order of [ids] on home. Each list changed
  /// is saved, and shows in its new place at once.
  Future<void> reorderPinned(List<String> ids) async {
    final byId = {for (final l in lists) l.id: l};
    await Future.wait([
      for (final (i, id) in ids.indexed)
        if (byId[id] case final l? when l.pinOrder != i) updateList(l.copyWith(pinOrder: () => i)),
    ]);
  }
}
