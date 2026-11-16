import 'package:flutter/foundation.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/live/live_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/activity.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/live.dart';
import '../../../domain/models/note.dart';
import '../../../domain/models/reminder.dart';
import '../../../utils/result.dart';

/// One open note and its block editor.
class NoteViewModel extends ChangeNotifier {
  NoteViewModel({
    required this.noteId,
    required this._noteRepository,
    required this._authRepository,
    required this._householdRepository,
    required this._settingsRepository,
    required this._activityRepository,
    required this._liveRepository,
  }) {
    _noteRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
    _liveRepository.addListener(_liveChanged);
    _live = _liveRepository.note(noteId);
  }

  final String noteId;
  final NoteRepository _noteRepository;
  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final SettingsRepository _settingsRepository;
  final ActivityRepository _activityRepository;
  final LiveRepository _liveRepository;
  int _nextBlock = 0;

  /// Edited since the last [release].
  bool _edited = false;

  String get _meId => _authRepository.user?.id ?? '';

  String get meId => _meId;

  /// The 3 latest changes, for the "⋯" menu.
  Future<List<Activity>> latestChanges() async {
    final result = await _activityRepository.latestFor(isNote: true, id: noteId);
    return result is Ok<List<Activity>> ? result.value : const [];
  }

  Note? get note {
    for (final n in _noteRepository.notes) {
      if (n.id == noteId) return n;
    }
    return null;
  }

  List<Member> get members => _householdRepository.household?.members ?? const [];

  Member? get partner => _householdRepository.household?.partnerOf(_meId);

  Member? get editor => _householdRepository.household?.member(note?.editedById);

  bool get editedByMe => note?.editedById == _meId;

  String get defaultTime => _settingsRepository.notifications.defaultTime;

  /// Only the author can make a shared note personal again, or delete it.
  bool get canUnshareOrDelete {
    final n = note;
    return n != null && (!n.isShared || n.authorId == _meId);
  }

  Future<void> _save(Note Function(Note) edit) async {
    final n = note;
    if (n == null) return;
    _edited = true;
    await _noteRepository.updateNote(edit(n).copyWith(editedById: _meId, editedAt: DateTime.now()));
  }

  Future<void> setTitle(String title) {
    _sendLive(title: title);
    return _save((n) => n.copyWith(title: title));
  }

  /// The whole body, as the editor has it now, with the cursor at [cursor].
  Future<void> setBlocks(List<NoteBlock> blocks, {int? cursor}) {
    _sendLive(blocks: blocks, cursor: cursor);
    return _save((n) => n.copyWith(blocks: blocks));
  }

  /// Keystrokes of a shared note go to the housemate as they are typed.
  void _sendLive({String? title, List<NoteBlock>? blocks, int? cursor}) {
    final n = note;
    if (n == null || !n.isShared) return;
    _liveRepository.typeNote(noteId, title: title ?? n.title, blocks: blocks ?? n.blocks, cursor: cursor);
  }

  LiveNote? _live;

  /// The note as the housemate is typing it, while they are.
  LiveNote? get live => _live;

  /// Who is typing [live].
  Member? get typist => _householdRepository.household?.member(_live?.userId);

  void _liveChanged() {
    final live = _liveRepository.note(noteId);
    if (identical(live, _live)) return;
    _live = live;
    notifyListeners();
  }

  /// For a line added in the editor.
  String newBlockId() => '${noteId}_${DateTime.now().microsecondsSinceEpoch}_${_nextBlock++}';

  Future<void> toggleShared() => _save((n) => n.copyWith(isShared: !n.isShared));

  Future<void> setReminder(Reminder? r) => _save((n) => n.copyWith(reminder: () => r));

  Future<DeletedNote?> delete() async {
    final result = await _noteRepository.deleteNote(noteId);
    return result is Ok<DeletedNote> ? result.value : null;
  }

  Future<void> restore(DeletedNote deleted) => _noteRepository.restoreNote(deleted);

  /// Leaving an empty note discards it.
  Future<void> close() async {
    final n = note;
    if (n != null && n.isBlank) {
      await _noteRepository.deleteNote(n.id);
    } else {
      await release();
    }
  }

  /// The user leaves the note (or the app): once their edits are saved, the
  /// housemates are told now rather than a minute later.
  Future<void> release() async {
    if (!_edited) return;
    _edited = false;
    await _noteRepository.flush();
    await _activityRepository.release(noteId);
  }

  @override
  void dispose() {
    _noteRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    _liveRepository.removeListener(_liveChanged);
    super.dispose();
  }
}
