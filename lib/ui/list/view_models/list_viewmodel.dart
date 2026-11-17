import 'package:flutter/foundation.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/live/live_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/activity.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/live.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/task_list.dart';
import '../../../utils/result.dart';
import '../../core/ui/mascot_data.dart';

/// One open list: its tasks, sharing, and the mascot that cheers as items
/// get checked.
class ListViewModel extends ChangeNotifier {
  ListViewModel({
    required this.listId,
    required this._listRepository,
    required this._authRepository,
    required this._householdRepository,
    required this._settingsRepository,
    required this._activityRepository,
    required this._liveRepository,
  }) {
    _listRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
    _liveRepository.addListener(_liveChanged);
    _draft = _liveRepository.draft(listId);
  }

  final String listId;
  final ListRepository _listRepository;
  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final SettingsRepository _settingsRepository;
  final ActivityRepository _activityRepository;
  final LiveRepository _liveRepository;

  String get _meId => _authRepository.user?.id ?? '';

  String get meId => _meId;

  /// The 3 latest changes, for the "⋯" menu.
  Future<List<Activity>> latestChanges() async {
    final result = await _activityRepository.latestFor(isNote: false, id: listId);
    return result is Ok<List<Activity>> ? result.value : const [];
  }

  TaskList? get list {
    for (final l in _listRepository.lists) {
      if (l.id == listId) return l;
    }
    return null;
  }

  List<Task> get _tasks => _listRepository.tasks.where((t) => t.listId == listId).toList();

  List<Task> get openTasks => _tasks.where((t) => !t.done).toList();

  List<Task> get doneTasks => _tasks.where((t) => t.done).toList();

  int get taskCount => _tasks.length;

  List<Member> get members => _householdRepository.household?.members ?? const [];

  Member? get partner => _householdRepository.household?.partnerOf(_meId);

  String get defaultTime => _settingsRepository.notifications.defaultTime;

  /// Someone else changed it: show their avatar.
  Member? authorOf(Task task) => task.byId == _meId ? null : _householdRepository.household?.member(task.byId);

  /// Cheerful when starting, wink near the end, love when all done.
  MascotMood get mood {
    final total = taskCount;
    final p = total == 0 ? 0 : doneTasks.length / total;
    if (p >= 1) return MascotMood.love;
    if (p < 0.25) return MascotMood.cheerful;
    if (p < 0.5) return MascotMood.happy;
    if (p < 0.75) return MascotMood.joy;
    return MascotMood.wink;
  }

  /// The item this user is typing, sent to the housemate on a shared list.
  void typing(String text) {
    if (list?.isShared ?? false) _liveRepository.typeDraft(listId, text);
  }

  LiveDraft? _draft;

  /// The item the housemate is typing, while they are.
  LiveDraft? get draft => _draft;

  /// Who is typing [draft].
  Member? get drafter => _householdRepository.household?.member(_draft?.userId);

  void _liveChanged() {
    final draft = _liveRepository.draft(listId);
    if (identical(draft, _draft)) return;
    _draft = draft;
    notifyListeners();
  }

  Future<void> addTask(String title) => _change(_listRepository.addTask(listId, title, byId: _meId));

  Future<void> toggle(Task task) => _change(_listRepository.updateTask(task.copyWith(done: !task.done, byId: _meId)));

  Future<void> rename(Task task, String title) =>
      _change(_listRepository.updateTask(task.copyWith(title: title, byId: _meId)));

  Future<DeletedTask?> deleteTask(Task task) async {
    final result = await _change(_listRepository.deleteTask(task.id));
    return result is Ok<DeletedTask> ? result.value : null;
  }

  Future<void> restoreTask(DeletedTask deleted) => _change(_listRepository.restoreTask(deleted));

  /// [newIndex] is the position once [oldIndex] has been taken out.
  Future<void> reorder(int oldIndex, int newIndex) {
    final ids = openTasks.map((t) => t.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    return _listRepository.reorderOpenTasks(listId, ids);
  }

  /// Home shows [maxPinnedLists] lists at most.
  bool get homeFull => _listRepository.lists.where((l) => l.pinned).length >= maxPinnedLists;

  Future<void> setPinned(bool pinned) async {
    final l = list;
    if (l == null) return;
    final order = pinned ? nextPinOrder(_listRepository.lists) : null;
    await _listRepository.updateList(l.copyWith(pinned: pinned, pinOrder: () => order));
  }

  Future<void> toggleShared() async {
    final l = list;
    if (l != null) await _listRepository.updateList(l.copyWith(isShared: !l.isShared));
  }

  Future<void> update(TaskList edited) => _listRepository.updateList(edited);

  Future<DeletedList?> deleteList() async {
    final result = await _listRepository.deleteList(listId);
    return result is Ok<DeletedList> ? result.value : null;
  }

  Future<void> restoreList(DeletedList deleted) => _listRepository.restoreList(deleted);

  /// Changes the housemates hear about, since the last [release].
  final _changes = <Future<Object?>>[];

  Future<T> _change<T>(Future<T> write) {
    _changes.add(write);
    return write;
  }

  /// The user leaves the list (or the app): once their changes are saved,
  /// the housemates are told now rather than a minute later.
  Future<void> release() async {
    if (_changes.isEmpty) return;
    final changes = [..._changes];
    _changes.clear();
    await Future.wait(changes);
    await _activityRepository.release(listId);
  }

  @override
  void dispose() {
    _listRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    _liveRepository.removeListener(_liveChanged);
    super.dispose();
  }
}
