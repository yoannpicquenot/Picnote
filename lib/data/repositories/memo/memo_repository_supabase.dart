import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/memo_task.dart';
import '../../../utils/result.dart';
import '../../model/rows.dart';
import '../synced_repository.dart';
import 'memo_repository.dart';

/// The household's Pense-bête from Supabase, kept live. Row level security
/// shows the user their household's tasks; the household is set by the
/// database.
class MemoRepositorySupabase extends MemoRepository with SyncedRepository {
  MemoRepositorySupabase(this.client);

  @override
  final SupabaseClient client;

  static const _uuid = Uuid();

  List<MemoTask> _tasks = [];

  /// Server-only fields, kept so a deleted row goes back in its place.
  final Map<String, double> _position = {};
  final Map<String, String> _createdAt = {};

  @override
  List<MemoTask> get tasks => List.unmodifiable(_tasks);

  @override
  List<String> get watchedTables => const ['memo_tasks'];

  @override
  void clear() {
    _tasks = [];
    _position.clear();
    _createdAt.clear();
  }

  @override
  Future<void Function()> fetch() async {
    // Ascending spelled out: postgrest sorts descending by default.
    final rows = await client
        .from('memo_tasks')
        .select()
        .isFilter('archived_at', null)
        .order('position', ascending: true)
        .order('created_at', ascending: true);
    return () {
      clear();
      _tasks = [for (final r in rows) memoFromRow(r)];
      for (final r in rows) {
        _position[r['id'] as String] = (r['position'] as num).toDouble();
        _createdAt[r['id'] as String] = r['created_at'] as String;
      }
      if (_tasks.any((t) => t.isStale)) scheduleMicrotask(archiveStaleTasks);
    };
  }

  @override
  Future<Result<void>> load() => ensureLoaded();

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
          .from('memo_tasks')
          .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
          .inFilter('id', ids)
          .isFilter('archived_at', null),
    );
  }

  @override
  Future<Result<MemoTask>> addTask(MemoTask draft, {required String authorId}) async {
    final task = MemoTask(
      id: _uuid.v4(),
      title: draft.title,
      forId: draft.forId,
      forBoth: draft.forBoth,
      remindOn: draft.remindOn,
      remindHour: draft.remindHour,
      repeat: draft.repeat,
      authorId: authorId,
    );
    final position = _position.values.fold<double>(0, (a, b) => a > b ? a : b) + 1;
    _position[task.id] = position;
    _tasks.add(task);
    final result = await push(() => client.from('memo_tasks').insert(memoToRow(task, position: position)));
    return switch (result) {
      Ok() => Result.ok(task),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> updateTask(MemoTask task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return Result.error(Exception('Unknown task ${task.id}'));
    final before = _tasks[i];
    _tasks[i] = task;
    final row = memoToRow(task, position: _position[task.id] ?? 0)
      ..remove('id')
      ..remove('position')
      ..remove('author_id');
    // A new reminder rings again.
    if (before.remindOn != task.remindOn || before.remindHour != task.remindHour) row['notified_on'] = null;
    return push(() => client.from('memo_tasks').update(row).eq('id', task.id));
  }

  @override
  Future<Result<DeletedMemo>> deleteTask(String id) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return Result.error(Exception('Unknown task $id'));
    final deleted = DeletedMemo(task: _tasks.removeAt(i), index: i);
    final result = await push(() => client.from('memo_tasks').delete().eq('id', id));
    return switch (result) {
      Ok() => Result.ok(deleted),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> restoreTask(DeletedMemo deleted) async {
    final task = deleted.task;
    _tasks.insert(deleted.index.clamp(0, _tasks.length), task);
    return push(
      () => client.from('memo_tasks').insert({
        ...memoToRow(task, position: _position[task.id] ?? 0),
        'created_at': ?_createdAt[task.id],
      }),
    );
  }
}
