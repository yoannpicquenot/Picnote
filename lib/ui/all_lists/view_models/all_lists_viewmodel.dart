import 'package:flutter/foundation.dart';

import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../domain/models/list_stats.dart';
import '../../../domain/models/task_list.dart';
import '../../../utils/result.dart';

/// Every list, pinned ones (shown on home) first. "Edit" reveals pin and
/// delete buttons.
class AllListsViewModel extends ChangeNotifier {
  AllListsViewModel({required this._listRepository, required this._householdRepository}) {
    _listRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
  }

  final ListRepository _listRepository;
  final HouseholdRepository _householdRepository;

  bool editing = false;

  List<TaskList> get lists => _listRepository.lists;

  List<TaskList> get pinned => lists.where((l) => l.pinned).toList();

  List<TaskList> get others => lists.where((l) => !l.pinned).toList();

  /// No room left on home: unpin a list to pin another.
  bool get homeFull => pinned.length >= maxPinnedLists;

  bool get isSolo => _householdRepository.household?.isSolo ?? true;

  ListStats stats(TaskList list) {
    final tasks = _listRepository.tasks.where((t) => t.listId == list.id);
    return ListStats(total: tasks.length, open: tasks.where((t) => !t.done).length);
  }

  void toggleEditing() {
    editing = !editing;
    notifyListeners();
  }

  Future<void> setPinned(TaskList list, bool pinned) async {
    if (pinned && homeFull) return;
    await _listRepository.updateList(list.copyWith(pinned: pinned));
  }

  Future<DeletedList?> delete(TaskList list) async {
    final result = await _listRepository.deleteList(list.id);
    return result is Ok<DeletedList> ? result.value : null;
  }

  Future<void> restore(DeletedList deleted) => _listRepository.restoreList(deleted);

  @override
  void dispose() {
    _listRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
