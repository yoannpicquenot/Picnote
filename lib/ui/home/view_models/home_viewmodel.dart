import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/invite_prompt/invite_prompt_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/memo/memo_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/list_stats.dart';
import '../../../domain/models/memo_task.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/task_list.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._listRepository,
    required this._authRepository,
    required this._householdRepository,
    required this._noteRepository,
    required this._invitePromptRepository,
    required this._memoRepository,
  }) {
    _listRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
    _noteRepository.addListener(notifyListeners);
    _invitePromptRepository.addListener(notifyListeners);
    _memoRepository.addListener(notifyListeners);
    load = Command0(_load)..execute();
  }

  final ListRepository _listRepository;
  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final NoteRepository _noteRepository;
  final InvitePromptRepository _invitePromptRepository;
  final MemoRepository _memoRepository;

  late final Command0<void> load;

  String get _meId => _authRepository.user?.id ?? '';

  String get name => _authRepository.user?.name ?? '';

  List<Member> get members => _householdRepository.household?.members ?? const [];

  bool get isSolo => _householdRepository.household?.isSolo ?? true;

  /// "Invite your other half.": alone in the household, nobody invited by
  /// email (a code given by hand does not count), and not put away since
  /// signing in.
  bool get showInviteCard {
    final household = _householdRepository.household;
    return household != null &&
        household.isSolo &&
        household.pendingInvite == null &&
        !_invitePromptRepository.dismissed;
  }

  /// Shown instead of the invite card until the other person joins.
  Invite? get pendingInvite {
    final household = _householdRepository.household;
    return household != null && household.isSolo ? household.pendingInvite : null;
  }

  Future<void> resendInvite() => _householdRepository.resendInvite();

  Future<void> cancelInvite() => _householdRepository.cancelInvite();

  /// "Later" on the card.
  Future<void> dismissInviteCard() => _invitePromptRepository.dismiss();

  /// This user, for the avatar on the invite card.
  Member get me => Member(id: _meId, name: name, color: _authRepository.user?.color ?? 0xFFAF5C3C);

  /// The pinned lists.
  List<TaskList> get visibleLists => pinnedInOrder(_listRepository.lists).take(maxPinnedLists).toList();

  int get listCount => _listRepository.lists.length;

  /// From the cards, rearranged on home.
  Future<void> reorderPinned(List<String> ids) => _listRepository.reorderPinned(ids);

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

  /// Null while alone in the household.
  Member? get partner => _householdRepository.household?.partnerOf(_meId);

  /// What is left in the Pense-bête, for its card.
  ({int open, int mine, int theirs}) get memoCount => countMemos(_memoRepository.tasks, _meId, partner?.id);

  /// The Pense-bête's reminders of day [n] (0 today, 1 tomorrow) that
  /// concern me: mine, ours, or no one's in particular. A missed one is
  /// today's.
  List<MemoTask> _memosOn(int n) {
    final mine = _memoRepository.tasks.where(
      (t) => t.hasReminder && daysFromToday(t.day!) == n && (isSolo || t.concerns(_meId)),
    );
    return [...mine.where((t) => !t.done), ...mine.where((t) => t.done)];
  }

  List<MemoTask> get memosToday => _memosOn(0);

  List<MemoTask> get memosTomorrow => _memosOn(1);

  /// Checks it in the Pense-bête too.
  Future<void> toggleMemo(MemoTask task) => _memoRepository.updateTask(task.copyWith(done: !task.done));

  Future<Result<void>> _load() async {
    final results = await Future.wait([_listRepository.load(), _noteRepository.load(), _memoRepository.load()]);
    for (final r in results) {
      if (r case Error(:final error)) return Result.error(error);
    }
    return const Result.ok(null);
  }

  Future<void> toggle(Task task) => _listRepository.updateTask(task.copyWith(done: !task.done, byId: _meId));

  @override
  void dispose() {
    _listRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    _noteRepository.removeListener(notifyListeners);
    _invitePromptRepository.removeListener(notifyListeners);
    _memoRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
