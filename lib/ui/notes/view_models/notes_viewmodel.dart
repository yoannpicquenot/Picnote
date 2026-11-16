import 'package:flutter/foundation.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/note.dart';
import '../../core/view_models/who_is_here.dart';

/// Notes tab: most recently edited first.
class NotesViewModel extends ChangeNotifier {
  NotesViewModel({
    required this._noteRepository,
    required this._householdRepository,
    required ListRepository listRepository,
    required AuthRepository authRepository,
    required this._activityRepository,
  }) : whoIsHere = WhoIsHere(
         activityRepository: _activityRepository,
         householdRepository: _householdRepository,
         listRepository: listRepository,
         noteRepository: _noteRepository,
         meId: authRepository.user?.id ?? '',
       ) {
    _noteRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
    _activityRepository.addListener(notifyListeners);
  }

  final NoteRepository _noteRepository;
  final HouseholdRepository _householdRepository;
  final ActivityRepository _activityRepository;

  /// The header's "who's here" panel.
  final WhoIsHere whoIsHere;

  List<Note> get notes => _noteRepository.notes;

  List<Member> get members => _householdRepository.household?.members ?? const [];

  bool get isSolo => _householdRepository.household?.isSolo ?? true;

  Member? editor(Note note) => _householdRepository.household?.member(note.editedById);

  @override
  void dispose() {
    _noteRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    _activityRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
