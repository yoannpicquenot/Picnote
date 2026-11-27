import 'package:flutter/foundation.dart';

import '../../../domain/models/memo_task.dart';
import '../../../utils/result.dart';

/// What a deletion removed, so "Undo" puts it back where it was.
class DeletedMemo {
  const DeletedMemo({required this.task, required this.index});

  final MemoTask task;
  final int index;
}

/// Source of truth for the household's Pense-bête. [tasks] are in their
/// order on screen, the latest added last.
///
/// One-off tasks checked before today ([MemoTask.isStale]) are archived on
/// load, at midnight and when the app comes back, as list items are.
abstract class MemoRepository extends ChangeNotifier {
  List<MemoTask> get tasks;

  Future<Result<void>> load();

  /// [draft]'s id is ignored; [authorId] added it.
  Future<Result<MemoTask>> addTask(MemoTask draft, {required String authorId});

  Future<Result<void>> updateTask(MemoTask task);

  Future<Result<DeletedMemo>> deleteTask(String id);

  Future<Result<void>> restoreTask(DeletedMemo deleted);

  Future<Result<void>> archiveStaleTasks();
}
