import 'package:flutter/foundation.dart';

import '../../../domain/models/household.dart';
import '../../../utils/result.dart';

/// The invite code is unknown or has expired.
class InvalidInviteException implements Exception {}

/// The household already has 2 members.
class HouseholdFullException implements Exception {}

/// Source of truth for the household: its name, members and pending invite.
/// [household] is null until onboarding creates or joins one.
abstract class HouseholdRepository extends ChangeNotifier {
  Household? get household;

  Future<Result<void>> create(String name, Member me);

  /// Shows who is in the household behind an invite code, before joining.
  Future<Result<HouseholdPreview>> lookUpInvite(String code);

  Future<Result<void>> join(String code, Member me);

  Future<Result<void>> rename(String name);

  /// Keeps [me] in sync when the profile name or color changes.
  Future<Result<void>> updateMember(Member me);

  Future<Result<void>> sendInvite(String email);

  /// Restarts the 7 days.
  Future<Result<void>> resendInvite();

  Future<Result<void>> cancelInvite();

  Future<Result<void>> removeMember(String memberId);

  Future<Result<void>> leave();
}
