import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../domain/models/household.dart';
import '../../../utils/result.dart';

enum JoinHouseholdState { idle, loading, invalid, full, failed, joined }

/// "Join a household." from the avatars' menu, while alone: the invite code,
/// checked at the 6th character. This user's lists and notes come along as
/// personal; an invitation they had sent goes with their old household.
class JoinHouseholdViewModel extends ChangeNotifier {
  JoinHouseholdViewModel({
    required this._authRepository,
    required this._householdRepository,
    required this._listRepository,
    required this._noteRepository,
  });

  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final ListRepository _listRepository;
  final NoteRepository _noteRepository;

  String code = '';
  JoinHouseholdState state = JoinHouseholdState.idle;

  /// The household joined, for "You joined …".
  String get householdName => _householdRepository.household?.name ?? '';

  Member get _me {
    final user = _authRepository.user;
    return Member(id: user?.id ?? '', name: user?.name ?? '', color: user?.color ?? 0xFFAF5C3C);
  }

  Future<void> setCode(String v) async {
    if (state == JoinHouseholdState.loading || state == JoinHouseholdState.joined) return;
    code = v;
    state = JoinHouseholdState.idle;
    notifyListeners();
    if (v.length < 6) return;
    state = JoinHouseholdState.loading;
    notifyListeners();
    final result = await _householdRepository.switchHousehold(v, _me);
    switch (result) {
      case Ok():
        await _listRepository.makeAllPersonal();
        await _noteRepository.makeAllPersonal();
        state = JoinHouseholdState.joined;
      case Error(:final error):
        state = switch (error) {
          InvalidInviteException() => JoinHouseholdState.invalid,
          HouseholdFullException() => JoinHouseholdState.full,
          _ => JoinHouseholdState.failed,
        };
    }
    notifyListeners();
  }
}
