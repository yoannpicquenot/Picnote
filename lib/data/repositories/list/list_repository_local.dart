import '../../../domain/models/task.dart';
import '../../../domain/models/task_list.dart';
import '../../../utils/result.dart';
import 'list_repository.dart';

/// In-memory implementation used until the Supabase repository exists.
class ListRepositoryLocal extends ListRepository {
  ListRepositoryLocal({List<TaskList> lists = const [], List<Task> tasks = const []})
    : _lists = [...lists],
      _tasks = [...tasks];

  final List<TaskList> _lists;
  final List<Task> _tasks;
  int _nextId = 0;

  String _id(String prefix) => '$prefix${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  @override
  List<TaskList> get lists => List.unmodifiable(_lists);

  @override
  List<Task> get tasks => List.unmodifiable(_tasks);

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
  Future<Result<TaskList>> createList(TaskList draft) async {
    final list = TaskList(
      id: _id('l'),
      name: draft.name,
      color: draft.color,
      icon: draft.icon,
      isShared: draft.isShared,
      // Pinned to home while there is room.
      pinned: _lists.where((l) => l.pinned).length < maxPinnedLists,
      day: draft.day,
      reminder: draft.reminder,
    );
    _lists.insert(0, list);
    notifyListeners();
    return Result.ok(list);
  }

  @override
  Future<Result<void>> updateList(TaskList list) async {
    final i = _lists.indexWhere((l) => l.id == list.id);
    if (i < 0) return Result.error(Exception('Unknown list ${list.id}'));
    _lists[i] = list;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<DeletedList>> deleteList(String id) async {
    final i = _lists.indexWhere((l) => l.id == id);
    if (i < 0) return Result.error(Exception('Unknown list $id'));
    final deleted = DeletedList(
      list: _lists.removeAt(i),
      index: i,
      tasks: _tasks.where((t) => t.listId == id).toList(),
    );
    _tasks.removeWhere((t) => t.listId == id);
    notifyListeners();
    return Result.ok(deleted);
  }

  @override
  Future<Result<void>> restoreList(DeletedList deleted) async {
    _lists.insert(deleted.index.clamp(0, _lists.length), deleted.list);
    _tasks.addAll(deleted.tasks);
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> makeAllPersonal() async {
    for (var i = 0; i < _lists.length; i++) {
      _lists[i] = _lists[i].copyWith(isShared: false);
    }
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<Task>> addTask(String listId, String title, {required String byId}) async {
    final task = Task(id: _id('t'), listId: listId, title: title, byId: byId);
    _tasks.add(task);
    notifyListeners();
    return Result.ok(task);
  }

  @override
  Future<Result<void>> updateTask(Task task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return Result.error(Exception('Unknown task ${task.id}'));
    _tasks[i] = task;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<DeletedTask>> deleteTask(String id) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return Result.error(Exception('Unknown task $id'));
    final deleted = DeletedTask(task: _tasks.removeAt(i), index: i);
    notifyListeners();
    return Result.ok(deleted);
  }

  @override
  Future<Result<void>> restoreTask(DeletedTask deleted) async {
    _tasks.insert(deleted.index.clamp(0, _tasks.length), deleted.task);
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> reorderOpenTasks(String listId, List<String> openTaskIds) async {
    final byId = {for (final t in _tasks) t.id: t};
    var k = 0;
    for (var i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.listId == listId && !t.done && k < openTaskIds.length) {
        _tasks[i] = byId[openTaskIds[k++]]!;
      }
    }
    notifyListeners();
    return const Result.ok(null);
  }
}
