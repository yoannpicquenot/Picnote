import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/notification_prefs.dart';

/// Settings home, plus the account screen built on the same state.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required this._authRepository,
    required this._householdRepository,
    required this._settingsRepository,
    required this._listRepository,
    required this._noteRepository,
  }) {
    _authRepository.addListener(notifyListeners);
    _householdRepository.addListener(notifyListeners);
    _settingsRepository.addListener(notifyListeners);
  }

  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final SettingsRepository _settingsRepository;
  final ListRepository _listRepository;
  final NoteRepository _noteRepository;

  String get _meId => _authRepository.user?.id ?? '';

  Member get me {
    final u = _authRepository.user;
    return Member(id: _meId, name: u?.name ?? '', color: u?.color ?? 0xFFAF5C3C);
  }

  String get email => _authRepository.user?.email ?? '';

  String get householdName => _householdRepository.household?.name ?? '';

  Member? get partner => _householdRepository.household?.partnerOf(_meId);

  Invite? get invite => _householdRepository.household?.invite;

  DateTime? get deletionDate => _authRepository.deletionDate;

  NotificationPrefs get notifications => _settingsRepository.notifications;

  int get personalLists => _listRepository.lists.where((l) => !l.isShared).length;

  int get personalNotes => _noteRepository.notes.where((n) => !n.isShared).length;

  Future<void> renameHousehold(String name) => _householdRepository.rename(name);

  Future<void> removePartner() async {
    final p = partner;
    if (p != null) await _householdRepository.removeMember(p.id);
  }

  Future<void> leaveHousehold() => _householdRepository.leave();

  Future<void> resendInvite() => _householdRepository.resendInvite();

  Future<void> cancelInvite() => _householdRepository.cancelInvite();

  Future<void> cancelDeletion() => _authRepository.cancelDeletion();

  Future<void> deleteAccount() => _authRepository.deleteAccount();

  Future<void> signOut() => _authRepository.signOut();

  Future<void> setName(String name) async {
    await _authRepository.updateProfile(name: name);
    await _householdRepository.updateMember(me);
  }

  Future<void> setColor(int color) async {
    await _authRepository.updateProfile(color: color);
    await _householdRepository.updateMember(me);
  }

  Future<void> updateNotifications(NotificationPrefs prefs) => _settingsRepository.updateNotifications(prefs);

  @override
  void dispose() {
    _authRepository.removeListener(notifyListeners);
    _householdRepository.removeListener(notifyListeners);
    _settingsRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
