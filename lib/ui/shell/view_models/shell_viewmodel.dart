import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/task_list.dart';
import '../../../utils/result.dart';

/// A list or a note the housemate just created, or [edited].
typedef Creation = ({Member author, String name, String id, bool isNote, bool edited});

/// The bottom bar's "+" creates a list or a note. Also notices when a
/// pinned list gets done, to offer unpinning it, clears yesterday's
/// checked tasks at midnight, and tells when the housemate creates or
/// changes a list or a note.
class ShellViewModel extends ChangeNotifier {
  ShellViewModel({
    required this._authRepository,
    required this._householdRepository,
    required this._listRepository,
    required this._noteRepository,
    required this._settingsRepository,
  }) {
    _householdRepository.addListener(notifyListeners);
    _listRepository.addListener(_checkDone);
    _listRepository.addListener(_checkNew);
    _noteRepository.addListener(_checkNew);
    _checkDone();
    _scheduleMidnight();
    _checkNew();
  }

  Timer? _midnight;

  /// A second past midnight, so the new day has surely begun.
  void _scheduleMidnight() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), () {
      archiveStaleTasks();
      _scheduleMidnight();
    });
  }

  /// Also called when the app comes back: a sleeping phone may run the
  /// midnight timer late.
  Future<void> archiveStaleTasks() => _listRepository.archiveStaleTasks();

  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final ListRepository _listRepository;
  final NoteRepository _noteRepository;
  final SettingsRepository _settingsRepository;

  /// Whether each list was done when last seen. Lists seen for the first
  /// time (first load) never count as just done.
  final Map<String, bool> _done = {};
  final _completed = StreamController<TaskList>.broadcast();

  /// Pinned lists whose last open item was just checked.
  Stream<TaskList> get completedPinned => _completed.stream;

  void _checkDone() {
    final tasks = _listRepository.tasks;
    for (final list in _listRepository.lists) {
      final own = tasks.where((t) => t.listId == list.id);
      final done = own.isNotEmpty && own.every((t) => t.done);
      final was = _done[list.id];
      _done[list.id] = done;
      if (was == false && done && list.pinned) _completed.add(list);
    }
  }

  /// Lists and notes already seen: only the others can be news.
  final Set<String> _seen = {};

  /// The housemate's new notes, still blank: told once they have a title or
  /// some text (a blank note is thrown away when left).
  final Set<String> _blank = {};

  final _created = StreamController<Creation>.broadcast();

  /// Lists and notes the housemate just created.
  Stream<Creation> get partnerCreated => _created.stream;

  void _checkNew() {
    _checkEdits();
    // Older ones were there before: a first load, not news.
    final recent = DateTime.now().subtract(const Duration(minutes: 5));
    for (final list in _listRepository.lists) {
      if (!_seen.add(list.id)) continue;
      final createdAt = list.createdAt;
      if (createdAt == null || createdAt.isBefore(recent)) continue;
      _tell(list.ownerId, list.name, list.id, isNote: false);
    }
    final notes = _noteRepository.notes;
    for (final note in notes) {
      if (_seen.add(note.id)) {
        if (note.editedAt.isBefore(recent)) continue;
        if (note.isBlank) {
          if (note.authorId != _meId) _blank.add(note.id);
          continue;
        }
      } else if (note.isBlank || !_blank.remove(note.id)) {
        continue;
      }
      _tell(note.authorId, note.title, note.id, isNote: true);
    }
    _blank.removeWhere((id) => !notes.any((n) => n.id == id));
  }

  void _tell(String? authorId, String name, String id, {required bool isNote, bool edited = false}) {
    if (authorId == null || authorId == _meId) return;
    final author = _householdRepository.household?.member(authorId);
    if (author == null) return;
    // One word per burst of changes: typing a note saves it again and again.
    final now = DateTime.now();
    final told = _toldAt[id];
    if (edited && told != null && now.difference(told) < quietAfterTelling) return;
    _toldAt[id] = now;
    _created.add((author: author, name: name, id: id, isNote: isNote, edited: edited));
  }

  /// After telling about a list or a note, its next changes go untold for
  /// this long.
  static const quietAfterTelling = Duration(minutes: 2);
  final Map<String, DateTime> _toldAt = {};

  /// When each note was last edited, as last seen.
  final Map<String, DateTime> _noteEdits = {};

  /// Each task's title and check, as last seen, and the lists seen so far:
  /// a task in a list seen before is new, the others come with their list.
  final Map<String, (String, bool)> _tasks = {};
  final Set<String> _listsSeen = {};

  void _checkEdits() {
    for (final note in _noteRepository.notes) {
      final was = _noteEdits[note.id];
      _noteEdits[note.id] = note.editedAt;
      if (was == null || !note.editedAt.isAfter(was) || note.isBlank) continue;
      // A blank note just given its title is a creation, told as such.
      if (_blank.contains(note.id)) continue;
      _tell(note.editedById, note.title, note.id, isNote: true, edited: true);
    }
    final lists = {for (final l in _listRepository.lists) l.id: l};
    for (final task in _listRepository.tasks) {
      final was = _tasks[task.id];
      final now = (task.title, task.done);
      _tasks[task.id] = now;
      final changed = was == null ? _listsSeen.contains(task.listId) : was != now;
      final list = lists[task.listId];
      if (changed && list != null) _tell(task.byId, list.name, list.id, isNote: false, edited: true);
    }
    _listsSeen.addAll(lists.keys);
  }

  Future<void> unpin(TaskList list) async {
    final current = _listRepository.lists.where((l) => l.id == list.id).firstOrNull;
    if (current != null) await _listRepository.updateList(current.copyWith(pinned: false, pinOrder: () => null));
  }

  String get _meId => _authRepository.user?.id ?? '';

  List<Member> get members => _householdRepository.household?.members ?? const [];

  /// Null while alone in the household.
  Member? get partner => _householdRepository.household?.partnerOf(_meId);

  String get defaultTime => _settingsRepository.notifications.defaultTime;

  /// A new list takes the color after the last created one's, so that
  /// lists side by side differ. Lists are newest first.
  ListColor get nextColor {
    final lists = _listRepository.lists;
    if (lists.isEmpty) return ListColor.values.first;
    return ListColor.values[(lists.first.color.index + 1) % ListColor.values.length];
  }

  /// Returns the new list's id.
  Future<String?> createList(TaskList draft) async {
    final result = await _listRepository.createList(draft);
    return result is Ok<TaskList> ? result.value.id : null;
  }

  Future<String?> createNote({required String title, required bool shared}) async {
    final result = await _noteRepository.createNote(title: title, isShared: partner != null && shared, authorId: _meId);
    return switch (result) {
      Ok(:final value) => value.id,
      Error() => null,
    };
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _householdRepository.removeListener(notifyListeners);
    _listRepository.removeListener(_checkDone);
    _listRepository.removeListener(_checkNew);
    _noteRepository.removeListener(_checkNew);
    _created.close();
    _completed.close();
    super.dispose();
  }
}
