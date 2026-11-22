import 'package:flutter/foundation.dart';

import '../../../data/repositories/household/household_repository.dart';
import '../../../domain/models/household.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// The steps of the invite panel: choose how, by email (the form, then the
/// pending invitation), or a code to give by hand.
enum InviteStep { choose, email, code }

/// The invite panel, the same from home, the avatars' menu, the settings, a
/// list or a note. It opens on the pending invitation when there is one,
/// otherwise on the choice.
class InviteViewModel extends ChangeNotifier {
  InviteViewModel({required this._householdRepository}) {
    _householdRepository.addListener(notifyListeners);
    step = pending != null ? InviteStep.email : InviteStep.choose;
    send = Command1(_send);
    resend = Command0(_householdRepository.resendInvite);
    cancel = Command0(_cancel);
    createCode = Command0(_householdRepository.createInviteCode);
  }

  final HouseholdRepository _householdRepository;

  late InviteStep step;

  late final Command1<void, String> send;
  late final Command0<void> resend;
  late final Command0<void> cancel;

  /// The code to give by hand: the household's current code, or a new one.
  /// Giving it is not an invitation: nobody is shown as invited.
  late final Command0<String> createCode;

  /// The address just sent to: "Invitation sent." shows until the panel
  /// closes.
  String? sentTo;

  /// The address of the invitation just cancelled, back in the field.
  String cancelledEmail = '';

  Invite? get pending => _householdRepository.household?.pendingInvite;

  /// The code of the pending invitation, in its own card.
  String? get pendingCode => pending?.code;

  String? get code => switch (createCode.result) {
    Ok(:final value) => value,
    _ => null,
  };

  String get householdName => _householdRepository.household?.name ?? '';

  void goTo(InviteStep s) {
    step = s;
    if (s == InviteStep.code && code == null && !createCode.running) createCode.execute();
    notifyListeners();
  }

  Future<Result<void>> _send(String email) async {
    final result = await _householdRepository.sendInvite(email);
    if (result is Ok) {
      sentTo = email;
      notifyListeners();
    }
    return result;
  }

  /// Back to the field, with the address to fix.
  Future<Result<void>> _cancel() async {
    final email = pending?.email ?? '';
    final result = await _householdRepository.cancelInvite();
    if (result is Ok) {
      cancelledEmail = email;
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    _householdRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
