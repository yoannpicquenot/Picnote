import 'package:picnote/data/repositories/list/list_repository_local.dart';
import 'package:picnote/domain/models/task.dart';
import 'package:picnote/domain/models/task_list.dart';
import 'package:picnote/utils/result.dart';

/// In-memory lists whose [load] can be made to fail.
class FakeListRepository extends ListRepositoryLocal {
  FakeListRepository({super.lists, super.tasks, this.failing = false});

  bool failing;

  @override
  Future<Result<void>> load() async {
    if (failing) return Result.error(Exception('load failed'));
    return const Result.ok(null);
  }
}

/// [count] lists named "List 0", "List 1"…
/// [count] lists, the first [pinned] of them pinned to home.
List<TaskList> manyLists(int count, {int pinned = 0}) => [
  for (var i = 0; i < count; i++) TaskList(id: 'l$i', name: 'List $i', pinned: i < pinned),
];

/// Tasks for a list: [open] unchecked then [done] checked.
List<Task> tasksFor(String listId, {int open = 0, int done = 0}) => [
  for (var i = 0; i < open; i++) Task(id: '$listId-o$i', listId: listId, title: 'Open $i'),
  for (var i = 0; i < done; i++) Task(id: '$listId-d$i', listId: listId, title: 'Done $i', done: true),
];
