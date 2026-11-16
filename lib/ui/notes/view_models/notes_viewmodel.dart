import 'package:flutter/foundation.dart';

import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/note.dart';

/// Notes tab: most recently edited first.
class NotesViewModel extends ChangeNotifier {
  NotesViewModel({required this._noteRepository, required this._householdRepository}) {
    _noteRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
  }

  final NoteRepository _noteRepository;
  final HouseholdRepository _householdRepository;

  List<Note> get notes => _noteRepository.notes;

  List<Member> get members => _householdRepository.household?.members ?? const [];

  bool get isSolo => _householdRepository.household?.isSolo ?? true;

  Member? editor(Note note) => _householdRepository.household?.member(note.editedById);

  @override
  void dispose() {
    _noteRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
