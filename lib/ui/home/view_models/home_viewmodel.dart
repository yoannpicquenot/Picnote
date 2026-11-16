import 'package:flutter/foundation.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/list_stats.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/task_list.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/view_models/who_is_here.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._listRepository,
    required this._authRepository,
    required this._householdRepository,
    required this._noteRepository,
    required this._activityRepository,
  }) : whoIsHere = WhoIsHere(
         activityRepository: _activityRepository,
         householdRepository: _householdRepository,
         listRepository: _listRepository,
         noteRepository: _noteRepository,
         meId: _authRepository.user?.id ?? '',
       ) {
    _listRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
    _noteRepository.addListener(notifyListeners);
    _activityRepository.addListener(notifyListeners);
    load = Command0(_load)..execute();
  }

  final ListRepository _listRepository;
  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final NoteRepository _noteRepository;
  final ActivityRepository _activityRepository;

  /// The header's "who's here" panel.
  final WhoIsHere whoIsHere;

  late final Command0<void> load;

  String get _meId => _authRepository.user?.id ?? '';

  String get name => _authRepository.user?.name ?? '';

  List<Member> get members => _householdRepository.household?.members ?? const [];

  bool get isSolo => _householdRepository.household?.isSolo ?? true;

  /// The pinned lists.
  List<TaskList> get visibleLists => _listRepository.lists.where((l) => l.pinned).take(maxPinnedLists).toList();

  int get listCount => _listRepository.lists.length;

  /// Nothing yet: right after onboarding.
  bool get isEmpty => _listRepository.lists.isEmpty && _noteRepository.notes.isEmpty;

  ListStats stats(TaskList list) {
    final tasks = _listRepository.tasks.where((t) => t.listId == list.id);
    return ListStats(total: tasks.length, open: tasks.where((t) => !t.done).length);
  }

  TaskList? listOf(Task task) {
    for (final l in _listRepository.lists) {
      if (l.id == task.listId) return l;
    }
    return null;
  }

  /// Someone else changed it: show their avatar.
  Member? authorOf(Task task) => task.byId == _meId ? null : _householdRepository.household?.member(task.byId);

  int? _dayOf(Task t) {
    if (t.today) return 0;
    final day = listOf(t)?.day;
    return day == null ? null : daysFromToday(effectiveDay(day));
  }

  List<Task> get today => _openFirst(_listRepository.tasks.where((t) => _dayOf(t) == 0));

  List<Task> get tomorrow => _openFirst(_listRepository.tasks.where((t) => _dayOf(t) == 1));

  /// Unchecked first, then checked, each kept in its own order.
  static List<Task> _openFirst(Iterable<Task> tasks) => [...tasks.where((t) => !t.done), ...tasks.where((t) => t.done)];

  Future<Result<void>> _load() async {
    final results = await Future.wait([_listRepository.load(), _noteRepository.load()]);
    for (final r in results) {
      if (r case Error(:final error)) return Result.error(error);
    }
    return const Result.ok(null);
  }

  Future<void> toggle(Task task) => _listRepository.updateTask(task.copyWith(done: !task.done, byId: _meId));

  Future<DeletedTask?> delete(Task task) async {
    final result = await _listRepository.deleteTask(task.id);
    return result is Ok<DeletedTask> ? result.value : null;
  }

  Future<void> restore(DeletedTask deleted) => _listRepository.restoreTask(deleted);

  @override
  void dispose() {
    _listRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    _noteRepository.removeListener(notifyListeners);
    _activityRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
