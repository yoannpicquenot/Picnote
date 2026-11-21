import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/household/household_repository.dart';
import '../../../data/repositories/list/list_repository.dart';
import '../../../data/repositories/note/note_repository.dart';
import '../../../domain/models/household.dart';
import '../../../utils/result.dart';

/// The onboarding screens, in order:
///
/// - [name] (04), then [householdStart] (06): create or join.
/// - Create: [household] (06c, just me or the two of us), [create] (07,
///   household name), [avatar] (05). Just me then goes home; the two of us go
///   on to [inviteHow] (05a), then [inviteEmail] (08) or [inviteCode] (08b).
/// - Join: [joinCode] (06a), [join] (09, the household's preview), [avatar]
///   (09c).
enum OnboardingStep {
  name,
  householdStart,
  household,
  create,
  avatar,
  inviteHow,
  inviteEmail,
  inviteCode,
  joinCode,
  join,
}

enum JoinCodeState { idle, loading, error }

/// After sign-in: first name, then create a household (and invite someone)
/// or join one with an invite code. The avatar color comes last, once the
/// household is known.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required this._authRepository,
    required this._householdRepository,
    required this._listRepository,
    required this._noteRepository,
    this.sentAnimation = const Duration(milliseconds: 1900),
  }) {
    final user = _authRepository.user;
    name = user?.name ?? '';
    color = user?.color ?? avatarColors.first;
    _householdRepository.addListener(notifyListeners);
  }

  static const avatarColors = [0xFFAF5C3C, 0xFF3F7063, 0xFF7A5412, 0xFF8C323E, 0xFF5E3E2C];

  final AuthRepository _authRepository;
  final HouseholdRepository _householdRepository;
  final ListRepository _listRepository;
  final NoteRepository _noteRepository;

  /// How long "Invitation sent." shows before home.
  final Duration sentAnimation;

  OnboardingStep step = OnboardingStep.name;
  String name = '';
  late int color;
  bool solo = false;
  String householdName = '';
  bool busy = false;

  /// On the color screen after previewing a household to join, rather than
  /// after naming a new one.
  bool joining = false;

  /// The intro of "Your household." plays on the first visit only.
  bool householdIntroPlayed = false;

  String joinCode = '';
  JoinCodeState joinState = JoinCodeState.idle;
  HouseholdPreview? preview;

  /// The address the invitation just went to, while "Invitation sent." shows.
  String? sentTo;
  bool inviteFailed = false;
  Timer? _sentTimer;

  /// The code to give by hand (08b), once fetched.
  String? inviteCode;
  bool inviteCodeFailed = false;

  /// "Code copied" shows for 2 s when the share sheet is not available.
  bool codeCopied = false;
  Timer? _copiedTimer;

  /// Set once onboarding is complete; the screen then leaves for home.
  bool finished = false;

  String get initial => name.trim().isEmpty ? 'M' : name.trim().substring(0, 1).toUpperCase();

  Member get me => Member(id: _authRepository.user?.id ?? 'me', name: name.trim(), color: color);

  String get currentHouseholdName => _householdRepository.household?.name ?? householdName.trim();

  /// Members of the household being joined who already wear a color.
  List<Member> get colorOwners => joining ? [...?preview?.members] : const [];

  Set<int> get takenColors => {for (final m in colorOwners) m.color};

  void goTo(OnboardingStep s) {
    step = s;
    if (s == OnboardingStep.joinCode) {
      joinCode = '';
      joinState = JoinCodeState.idle;
    }
    if (s == OnboardingStep.avatar && takenColors.contains(color)) {
      color = avatarColors.firstWhere((c) => !takenColors.contains(c));
    }
    notifyListeners();
  }

  /// Where the back button of the current step leads.
  OnboardingStep? get back => switch (step) {
    OnboardingStep.name => null,
    OnboardingStep.householdStart => OnboardingStep.name,
    OnboardingStep.household => OnboardingStep.householdStart,
    OnboardingStep.create => OnboardingStep.household,
    OnboardingStep.avatar => joining ? OnboardingStep.join : OnboardingStep.create,
    OnboardingStep.inviteHow => OnboardingStep.avatar,
    OnboardingStep.inviteEmail || OnboardingStep.inviteCode => OnboardingStep.inviteHow,
    OnboardingStep.joinCode => OnboardingStep.householdStart,
    OnboardingStep.join => OnboardingStep.joinCode,
  };

  void goBack() {
    final b = back;
    if (b != null) goTo(b);
  }

  void householdIntroDone() {
    householdIntroPlayed = true;
  }

  void setName(String v) {
    name = v;
    notifyListeners();
  }

  void setColor(int c) {
    if (takenColors.contains(c)) return;
    color = c;
    notifyListeners();
  }

  void setHouseholdName(String v) {
    householdName = v;
    notifyListeners();
  }

  void choose({required bool solo}) {
    this.solo = solo;
    joining = false;
    goTo(OnboardingStep.create);
  }

  void submitHouseholdName() {
    if (householdName.trim().isEmpty) return;
    goTo(OnboardingStep.avatar);
  }

  /// "Join the household" on the preview: the color comes first.
  void previewJoin() {
    joining = true;
    goTo(OnboardingStep.avatar);
  }

  /// The main button of the color screen: joins, or creates the household
  /// then goes home (just me) or on to the invitation (the two of us).
  Future<void> confirmAvatar() async {
    if (busy) return;
    if (joining) return _join();
    busy = true;
    notifyListeners();
    await _authRepository.updateProfile(name: name.trim(), color: color);
    if (_householdRepository.household == null) {
      await _householdRepository.create(householdName.trim(), me);
    } else {
      // Back here from the invitation: the name or color may have changed.
      await _householdRepository.rename(householdName.trim());
      await _householdRepository.updateMember(me);
    }
    busy = false;
    if (solo) {
      finished = true;
    } else {
      step = OnboardingStep.inviteHow;
    }
    notifyListeners();
  }

  void inviteByEmail() {
    inviteFailed = false;
    goTo(OnboardingStep.inviteEmail);
  }

  /// Sends the invitation, shows "Invitation sent." for a moment, then home.
  /// The invitation stays pending in the household settings.
  Future<void> sendInvite(String email) async {
    if (busy) return;
    busy = true;
    inviteFailed = false;
    notifyListeners();
    final result = await _householdRepository.sendInvite(email);
    busy = false;
    switch (result) {
      case Ok():
        sentTo = email;
        _sentTimer?.cancel();
        _sentTimer = Timer(sentAnimation, finish);
      case Error():
        inviteFailed = true;
    }
    notifyListeners();
  }

  Future<void> inviteByCode() async {
    inviteCodeFailed = false;
    goTo(OnboardingStep.inviteCode);
    if (inviteCode != null) return;
    final result = await _householdRepository.createInviteCode();
    switch (result) {
      case Ok():
        inviteCode = result.value;
      case Error():
        inviteCodeFailed = true;
    }
    notifyListeners();
  }

  void showCodeCopied() {
    codeCopied = true;
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      codeCopied = false;
      notifyListeners();
    });
    notifyListeners();
  }

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
  Future<void> _join() async {
    busy = true;
    notifyListeners();
    await _authRepository.updateProfile(name: name.trim(), color: color);
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
    _sentTimer?.cancel();
    _copiedTimer?.cancel();
    _householdRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
