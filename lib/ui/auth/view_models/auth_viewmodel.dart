import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/invite_prompt/invite_prompt_repository.dart';
import '../../../utils/result.dart';
import '../../../utils/validation.dart';

enum AuthStep { welcome, email, code }

enum CodeError { wrong, expired, locked }

/// Passwordless sign-in: welcome, email, then the 6-digit code. The code is
/// checked as soon as the 6th digit is typed. The router takes over once the
/// person is signed in.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this._authRepository, this._invitePromptRepository, this.resendDelay = 30});

  final AuthRepository _authRepository;

  /// Signing in brings back "Invite your other half." if it was put away.
  final InvitePromptRepository? _invitePromptRepository;

  /// Seconds before "Resend code" is available.
  final int resendDelay;

  AuthStep step = AuthStep.welcome;
  String email = '';
  bool emailInvalid = false;
  bool offline = false;
  bool sending = false;

  String code = '';
  CodeError? codeError;
  bool checking = false;
  int resendIn = 0;
  Timer? _countdown;

  void goTo(AuthStep s) {
    step = s;
    notifyListeners();
  }

  void setEmail(String value) {
    email = value;
    emailInvalid = false;
    notifyListeners();
  }

  Future<void> submitEmail() async {
    if (!looksLikeEmail(email)) {
      emailInvalid = true;
      notifyListeners();
      return;
    }
    sending = true;
    notifyListeners();
    final result = await _authRepository.requestCode(email.trim());
    sending = false;
    switch (result) {
      case Ok():
        offline = false;
        code = '';
        codeError = null;
        step = AuthStep.code;
        _startCountdown();
      case Error(:final error):
        offline = error is OfflineException;
    }
    notifyListeners();
  }

  void setCode(String value) {
    if (codeError == CodeError.locked || checking) return;
    code = value;
    codeError = null;
    notifyListeners();
    if (value.length == 6) _check();
  }

  Future<void> _check() async {
    checking = true;
    notifyListeners();
    // Before signing in: the router leaves this screen as soon as it succeeds.
    await _invitePromptRepository?.reset();
    final result = await _authRepository.verifyCode(code);
    checking = false;
    if (result case Error(:final error)) {
      codeError = switch (error) {
        ExpiredCodeException() => CodeError.expired,
        TooManyAttemptsException() => CodeError.locked,
        _ => CodeError.wrong,
      };
    }
    notifyListeners();
  }

  /// "Resend code" and, after expiry, "Get a new code".
  Future<void> resendCode() async {
    code = '';
    codeError = null;
    await _authRepository.requestCode(email.trim());
    _startCountdown();
    notifyListeners();
  }

  void _startCountdown() {
    _countdown?.cancel();
    resendIn = resendDelay;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      resendIn--;
      if (resendIn <= 0) t.cancel();
      notifyListeners();
    });
  }

  bool _disposed = false;

  /// A successful sign-in makes the router leave this screen (disposing this
  /// view model) before [verifyCode] returns, so late updates are dropped.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _countdown?.cancel();
    super.dispose();
  }
}
