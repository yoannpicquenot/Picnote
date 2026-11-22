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
/// - Create: [create] (07, household name), then [avatar] (05), then home.
///   Inviting someone happens from home.
/// - Join: [joinCode] (06a), [join] (09, the household's preview), [avatar]
///   (09c), then home.
enum OnboardingStep { name, householdStart, create, avatar, joinCode, join }

enum JoinCodeState { idle, loading, error }

/// After sign-in: first name, then create a household or join one with an
/// invite code. The avatar color comes last, once the household is known.
/// A new household has one member until someone joins it.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required this._authRepository,
    required this._householdRepository,
    required this._listRepository,
    required this._noteRepository,
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

  OnboardingStep step = OnboardingStep.name;
  String name = '';
  late int color;
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

  /// Set once onboarding is complete; the screen then leaves for home.
  bool finished = false;

  String get initial => name.trim().isEmpty ? 'M' : name.trim().substring(0, 1).toUpperCase();

  Member get me => Member(id: _authRepository.user?.id ?? 'me', name: name.trim(), color: color);

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
    OnboardingStep.create => OnboardingStep.householdStart,
    OnboardingStep.avatar => joining ? OnboardingStep.join : OnboardingStep.create,
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

  /// "Create a household" on 06, or "Create my household" when the one to
  /// join is full.
  void startCreating() {
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

  /// "Go to my household" on the color screen: joins, or creates the
  /// household, then home.
  Future<void> confirmAvatar() async {
    if (busy) return;
    if (joining) return _join();
    busy = true;
    notifyListeners();
    await _authRepository.updateProfile(name: name.trim(), color: color);
    final result = await _householdRepository.create(householdName.trim(), me);
    busy = false;
    if (result is Ok) finished = true;
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
    _householdRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
