import 'package:flutter/foundation.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../core/view_models/who_is_here.dart';

/// The header shared by Lists and Notes, which stays in place while
/// swiping between them: who is in the household and who is here.
class HeaderViewModel extends ChangeNotifier {
  HeaderViewModel({
    required ActivityRepository activityRepository,
    required AuthRepository authRepository,
    required HouseholdRepository householdRepository,
    required ListRepository listRepository,
    required NoteRepository noteRepository,
  }) : _activityRepository = activityRepository,
       _householdRepository = householdRepository,
       whoIsHere = WhoIsHere(
         activityRepository: activityRepository,
         householdRepository: householdRepository,
         listRepository: listRepository,
         noteRepository: noteRepository,
         meId: authRepository.user?.id ?? '',
       ) {
    _householdRepository.addListener(notifyListeners);
    _activityRepository.addListener(notifyListeners);
  }

  final ActivityRepository _activityRepository;
  final HouseholdRepository _householdRepository;

  /// The header's "who's here" panel.
  final WhoIsHere whoIsHere;

  @override
  void dispose() {
    _householdRepository.removeListener(notifyListeners);
    _activityRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
