import 'package:flutter/foundation.dart';

/// Whether "Invite your other half." was put away on home. It stays away,
/// even after the app restarts, until the next sign-in.
abstract class InvitePromptRepository extends ChangeNotifier {
  bool get dismissed;

  Future<void> dismiss();

  /// A new sign-in: the card may show again.
  Future<void> reset();
}

/// In memory, for development and tests.
class InvitePromptRepositoryLocal extends InvitePromptRepository {
  InvitePromptRepositoryLocal({bool dismissed = false}) : _dismissed = dismissed;

  bool _dismissed;

  @override
  bool get dismissed => _dismissed;

  @override
  Future<void> dismiss() async {
    _dismissed = true;
    notifyListeners();
  }

  @override
  Future<void> reset() async {
    _dismissed = false;
    notifyListeners();
  }
}
