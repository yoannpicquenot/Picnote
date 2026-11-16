import 'package:flutter/foundation.dart';

import '../../../domain/models/user.dart';
import '../../../utils/result.dart';

/// No network: the code can't be sent or checked.
class OfflineException implements Exception {}

/// The code doesn't match the one sent by email.
class WrongCodeException implements Exception {}

/// The code is too old; a new one must be requested.
class ExpiredCodeException implements Exception {}

/// Too many wrong codes; sign-in is locked for a few minutes.
class TooManyAttemptsException implements Exception {}

/// Passwordless sign-in: an email, then a 6-digit code sent to it.
abstract class AuthRepository extends ChangeNotifier {
  User? get user;

  /// Set while the account waits out its 15 days before being erased.
  DateTime? get deletionDate;

  Future<Result<void>> requestCode(String email);

  Future<Result<User>> verifyCode(String code);

  Future<Result<User>> updateProfile({String? name, int? color});

  Future<Result<void>> signOut();

  /// Deactivates the account; it is erased for good 15 days later.
  Future<Result<void>> deleteAccount();

  Future<Result<void>> cancelDeletion();
}
