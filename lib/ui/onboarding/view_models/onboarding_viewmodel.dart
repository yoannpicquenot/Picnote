import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../domain/models/household.dart';
import '../../../utils/result.dart';

enum OnboardingStep { name, avatar, household, create, invite, joinCode, join }

enum JoinCodeState { idle, loading, error }

/// After sign-in: first name, avatar color, then "Just me" / "The two of us"
/// (create + invite), or joining with an invite code.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required this._authRepository,
    required this._householdRepository,
    required this._listRepository,
    required this._noteRepository,
  }) {
    final user = _authRepository.user;
    name = user?.name ?? '';
    color = user?.color ?? 0xFFAF5C3C;
    _householdRepository.addListener(notifyListeners);
  }

  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final ListRepository _listRepository;
  final NoteRepository _noteRepository;

  OnboardingStep step = OnboardingStep.name;
  String name = '';
  late int color;
  bool solo = false;
  String householdName = '';
  bool busy = false;

  String joinCode = '';
  JoinCodeState joinState = JoinCodeState.idle;
  HouseholdPreview? preview;

  /// Set once onboarding is complete; the screen then leaves for home.
  bool finished = false;

  String get initial => name.trim().isEmpty ? 'M' : name.trim().substring(0, 1).toUpperCase();

  Member get me => Member(id: _authRepository.user?.id ?? 'me', name: name.trim(), color: color);

  Invite? get invite => _householdRepository.household?.invite;

  /// The invited person accepted while we were waiting.
  bool get partnerJoined => step == OnboardingStep.invite && (_householdRepository.household?.members.length ?? 0) > 1;

  Member? get joinedPartner => _householdRepository.household?.partnerOf(me.id);

  String get currentHouseholdName => _householdRepository.household?.name ?? householdName.trim();

  /// The color picked earlier was already worn in the household being
  /// joined: another one was picked instead, and the person is told.
  bool colorWasTaken = false;

  /// Colors already worn by members of the household being joined.
  Set<int> get takenColors => {...?preview?.members.map((m) => m.color)};

  void goTo(OnboardingStep s) {
    step = s;
    if (s == OnboardingStep.joinCode) {
      joinCode = '';
      joinState = JoinCodeState.idle;
    }
    if (s == OnboardingStep.join) colorWasTaken = takenColors.contains(color);
    if (s == OnboardingStep.join && colorWasTaken) {
      color = [0xFFAF5C3C, 0xFF3F7063, 0xFF7A5412, 0xFF8C323E, 0xFF5E3E2C].firstWhere((c) => !takenColors.contains(c));
    }
    notifyListeners();
  }

  void setName(String v) {
    name = v;
    notifyListeners();
  }

  void setColor(int c) {
    color = c;
    notifyListeners();
  }

  void setHouseholdName(String v) {
    householdName = v;
    notifyListeners();
  }

  void choose({required bool solo}) {
    this.solo = solo;
    goTo(OnboardingStep.create);
  }

  Future<void> _saveProfile() => _authRepository.updateProfile(name: name.trim(), color: color);

  /// "Create" (just me) finishes; "Continue" (the two of us) goes on to the
  /// invitation.
  Future<void> createHousehold() async {
    if (householdName.trim().isEmpty || busy) return;
    busy = true;
    notifyListeners();
    await _saveProfile();
    if (_householdRepository.household == null) {
      await _householdRepository.create(householdName.trim(), me);
    } else {
      await _householdRepository.rename(householdName.trim());
    }
    busy = false;
    if (solo) {
      finished = true;
    } else {
      step = OnboardingStep.invite;
    }
    notifyListeners();
  }

  Future<void> sendInvite(String email) => _householdRepository.sendInvite(email);

  Future<void> resendInvite() => _householdRepository.resendInvite();

  Future<void> cancelInvite() => _householdRepository.cancelInvite();

  void finish() {
    finished = true;
    notifyListeners();
  }

  Future<void> setJoinCode(String v) async {
    joinCode = v;
    joinState = JoinCodeState.idle;
    notifyListeners();
    if (v.length < 6) return;
    joinState = JoinCodeState.loading;
    notifyListeners();
    final result = await _householdRepository.lookUpInvite(v);
    if (joinCode != v) return;
    switch (result) {
      case Ok():
        preview = result.value;
        joinState = JoinCodeState.idle;
        goTo(OnboardingStep.join);
      case Error():
        joinState = JoinCodeState.error;
        notifyListeners();
    }
  }

  /// Joins the previewed household. Lists and notes made before come along
  /// as personal.
  Future<void> join() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    await _saveProfile();
    if (_householdRepository.household != null) await _householdRepository.leave();
    final result = await _householdRepository.join(joinCode, me);
    busy = false;
    if (result is Ok) {
      await _listRepository.makeAllPersonal();
      await _noteRepository.makeAllPersonal();
      finished = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _householdRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
