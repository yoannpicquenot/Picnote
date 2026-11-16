import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/task.dart';
import '../../../domain/models/task_list.dart';
import '../../../utils/result.dart';
import '../../model/rows.dart';
import '../synced_repository.dart';
import 'list_repository.dart';

/// Lists and tasks from Supabase, kept live. Row level security decides what
/// is visible: the user's personal lists and their household's shared ones.
class ListRepositorySupabase extends ListRepository with SyncedRepository {
  ListRepositorySupabase(this.client);

  @override
  final SupabaseClient client;

  static const _uuid = Uuid();

  List<TaskList> _lists = [];
  List<Task> _tasks = [];

  /// Server-only fields, kept so a deleted row can be put back in place.
  final Map<String, String> _createdAt = {};
  final Map<String, double> _position = {};

  @override
  List<TaskList> get lists => List.unmodifiable(_lists);

  @override
  List<Task> get tasks => List.unmodifiable(_tasks);

  @override
  List<String> get watchedTables => const ['lists', 'tasks'];

  @override
  void clear() {
    _lists = [];
    _tasks = [];
    _createdAt.clear();
    _position.clear();
  }

  @override
  Future<void Function()> fetch() async {
    final (listRows, taskRows) = await (
      client.from('lists').select().order('created_at', ascending: false),
      // Creation time breaks ties: never any other order than the user's.
      // Ascending spelled out: postgrest sorts descending by default, which
      // flipped every list on each refetch.
      client
          .from('tasks')
          .select()
          .isFilter('archived_at', null)
          .order('position', ascending: true)
          .order('created_at', ascending: true),
    ).wait;
    return () {
      clear();
      _lists = [for (final r in listRows) listFromRow(r)];
      _tasks = [for (final r in taskRows) taskFromRow(r)];
      for (final r in listRows) {
        _createdAt[r['id'] as String] = r['created_at'] as String;
      }
      for (final r in taskRows) {
        _position[r['id'] as String] = (r['position'] as num).toDouble();
      }
      // Checked yesterday while no device was open: archived now.
      if (_tasks.any((t) => t.isStale)) scheduleMicrotask(archiveStaleTasks);
    };
  }

  @override
  Future<Result<void>> load() => ensureLoaded();

  /// Both members' apps may do it; the second finds nothing left to archive.
  @override
  Future<Result<void>> archiveStaleTasks() async {
    final ids = [
      for (final t in _tasks)
        if (t.isStale) t.id,
    ];
    if (ids.isEmpty) return const Result.ok(null);
    _tasks.removeWhere((t) => ids.contains(t.id));
    return push(
      () => client
          .from('tasks')
          .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
          .inFilter('id', ids)
          .isFilter('archived_at', null),
    );
  }

  @override
  Future<Result<TaskList>> createList(TaskList draft) async {
    final list = TaskList(
      id: _uuid.v4(),
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
    final result = await push(() => client.from('lists').insert(listToRow(list)));
    return switch (result) {
      Ok() => Result.ok(list),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> updateList(TaskList list) async {
    final i = _lists.indexWhere((l) => l.id == list.id);
    if (i < 0) return Result.error(Exception('Unknown list ${list.id}'));
    final wasShared = _lists[i].isShared;
    _lists[i] = list;
    return push(
      () => client.from('lists').update(listToRow(list)).eq('id', list.id),
      // The other member gets no event for a row they can no longer see.
      ping: wasShared && !list.isShared,
    );
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
    final result = await push(() => client.from('lists').delete().eq('id', id));
    return switch (result) {
      Ok() => Result.ok(deleted),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> restoreList(DeletedList deleted) async {
    final list = deleted.list;
    _lists.insert(deleted.index.clamp(0, _lists.length), list);
    _tasks.addAll(deleted.tasks);
    return push(() async {
      await client.from('lists').insert({...listToRow(list), 'created_at': ?_createdAt[list.id]});
      if (deleted.tasks.isNotEmpty) {
        await client.from('tasks').insert([
          for (final t in deleted.tasks) taskToRow(t, position: _position[t.id] ?? 0),
        ]);
      }
    });
  }

  /// Personal lists stay personal when joining a household; there is
  /// nothing to change on the server.
  @override
  Future<Result<void>> makeAllPersonal() => refresh();

  @override
  Future<Result<Task>> addTask(String listId, String title, {required String byId}) async {
    final task = Task(id: _uuid.v4(), listId: listId, title: title, byId: byId);
    final position =
        [
          for (final t in _tasks)
            if (t.listId == listId) _position[t.id] ?? 0,
        ].fold<double>(0, (a, b) => a > b ? a : b) +
        1;
    _position[task.id] = position;
    _tasks.add(task);
    final result = await push(() => client.from('tasks').insert(taskToRow(task, position: position)));
    return switch (result) {
      Ok() => Result.ok(task),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> updateTask(Task task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return Result.error(Exception('Unknown task ${task.id}'));
    _tasks[i] = task;
    return push(
      () => client
          .from('tasks')
          .update({
            'title': task.title,
            'done': task.done,
            'done_at': task.doneAt?.toUtc().toIso8601String(),
            'by_id': task.byId,
            'today': task.today,
          })
          .eq('id', task.id),
    );
  }

  @override
  Future<Result<DeletedTask>> deleteTask(String id) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return Result.error(Exception('Unknown task $id'));
    final deleted = DeletedTask(task: _tasks.removeAt(i), index: i);
    final result = await push(() => client.from('tasks').delete().eq('id', id));
    return switch (result) {
      Ok() => Result.ok(deleted),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> restoreTask(DeletedTask deleted) async {
    final task = deleted.task;
    _tasks.insert(deleted.index.clamp(0, _tasks.length), task);
    return push(() => client.from('tasks').insert(taskToRow(task, position: _position[task.id] ?? 0)));
  }

  /// The reordered tasks take over the positions the open tasks had, so done
  /// tasks keep theirs.
  @override
  Future<Result<void>> reorderOpenTasks(String listId, List<String> openTaskIds) async {
    final open = [
      for (final t in _tasks)
        if (t.listId == listId && !t.done) t,
    ];
    final slots = [for (final t in open) _position[t.id] ?? 0]..sort();
    final byId = {for (final t in open) t.id: t};
    final reordered = [for (final id in openTaskIds) ?byId[id]];
    if (reordered.length != slots.length) return Result.error(Exception('Stale order'));
    for (var k = 0; k < reordered.length; k++) {
      _position[reordered[k].id] = slots[k];
    }
    var k = 0;
    _tasks = [
      for (final t in _tasks)
        if (t.listId == listId && !t.done) reordered[k++] else t,
    ];
    return push(
      () => client.from('tasks').upsert([for (final t in reordered) taskToRow(t, position: _position[t.id]!)]),
    );
  }
}
