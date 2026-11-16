import 'package:flutter/foundation.dart';

import '../../../data/repositories/household/household_repository.dart';
import '../../../domain/models/household.dart';
import '../../../utils/command.dart';

/// Inviting the other person from the app (lists, notes, settings).
class InviteViewModel extends ChangeNotifier {
  InviteViewModel({required this._householdRepository}) {
    _householdRepository.addListener(notifyListeners);
    send = Command1(_householdRepository.sendInvite);
    resend = Command0(_householdRepository.resendInvite);
    cancel = Command0(_householdRepository.cancelInvite);
  }

  final HouseholdRepository _householdRepository;

  late final Command1<void, String> send;
  late final Command0<void> resend;
  late final Command0<void> cancel;

  Invite? get invite => _householdRepository.household?.invite;

  String get householdName => _householdRepository.household?.name ?? '';

  @override
  void dispose() {
    _householdRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
