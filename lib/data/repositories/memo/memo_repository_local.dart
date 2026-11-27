import '../../../domain/models/memo_task.dart';
import '../../../utils/result.dart';
import 'memo_repository.dart';

/// In-memory Pense-bête, for the demo and tests.
class MemoRepositoryLocal extends MemoRepository {
  MemoRepositoryLocal({List<MemoTask> tasks = const []}) : _tasks = [...tasks];

  final List<MemoTask> _tasks;
  int _nextId = 0;

  @override
  List<MemoTask> get tasks => List.unmodifiable(_tasks);

  @override
  Future<Result<void>> load() => archiveStaleTasks();

  @override
  Future<Result<void>> archiveStaleTasks() async {
    final before = _tasks.length;
    _tasks.removeWhere((t) => t.isStale);
    if (_tasks.length != before) notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<MemoTask>> addTask(MemoTask draft, {required String authorId}) async {
    final task = MemoTask(
      id: 'm${DateTime.now().microsecondsSinceEpoch}-${_nextId++}',
      title: draft.title,
      forId: draft.forId,
      forBoth: draft.forBoth,
      remindOn: draft.remindOn,
      remindHour: draft.remindHour,
      repeat: draft.repeat,
      authorId: authorId,
    );
    _tasks.add(task);
    notifyListeners();
    return Result.ok(task);
  }

  @override
  Future<Result<void>> updateTask(MemoTask task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return Result.error(Exception('Unknown task ${task.id}'));
    _tasks[i] = task;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<DeletedMemo>> deleteTask(String id) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return Result.error(Exception('Unknown task $id'));
    final deleted = DeletedMemo(task: _tasks.removeAt(i), index: i);
    notifyListeners();
    return Result.ok(deleted);
  }

  @override
  Future<Result<void>> restoreTask(DeletedMemo deleted) async {
    _tasks.insert(deleted.index.clamp(0, _tasks.length), deleted.task);
    notifyListeners();
    return const Result.ok(null);
  }
}
