import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/memo/memo_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/memo_task.dart';
import '../../../utils/result.dart';

/// The household's Pense-bête: the tasks still to do, then those done.
/// Anyone may add, change, check or delete any task.
class MemoViewModel extends ChangeNotifier {
  MemoViewModel({
    required this._memoRepository,
    required this._authRepository,
    required this._householdRepository,
    required this._settingsRepository,
  }) {
    _memoRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
    _memoRepository.load();
  }

  final MemoRepository _memoRepository;
  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final SettingsRepository _settingsRepository;

  String get meId => _authRepository.user?.id ?? '';

  List<Member> get members => _householdRepository.household?.members ?? const [];

  /// Null while alone in the household.
  Member? get partner => _householdRepository.household?.partnerOf(meId);

  bool get isSolo => partner == null;

  List<MemoTask> get open => _memoRepository.tasks.where((t) => !t.done).toList();

  List<MemoTask> get done => _memoRepository.tasks.where((t) => t.done).toList();

  /// The hour a new reminder starts at: the one chosen in the
  /// notification settings, when it is one of [memoHours].
  int get defaultHour {
    final hour = int.tryParse(_settingsRepository.notifications.defaultTime.split(':').first);
    return memoHours.contains(hour) ? hour! : 9;
  }

  Future<void> add(MemoTask draft) => _memoRepository.addTask(draft, authorId: meId);

  Future<void> save(MemoTask task) => _memoRepository.updateTask(task);

  Future<void> toggle(MemoTask task) => _memoRepository.updateTask(task.copyWith(done: !task.done));

  Future<DeletedMemo?> delete(MemoTask task) async {
    final result = await _memoRepository.deleteTask(task.id);
    return result is Ok<DeletedMemo> ? result.value : null;
  }

  Future<void> restore(DeletedMemo deleted) => _memoRepository.restoreTask(deleted);

  @override
  void dispose() {
    _memoRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
