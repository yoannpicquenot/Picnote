import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import '../../model/rows.dart';
import 'auth_repository.dart';

/// Email + 6-digit code sign-in with Supabase Auth. The profile (name,
/// color) lives in the `profiles` table.
///
/// The Supabase "Magic Link" and "Confirm signup" email templates must show
/// `{{ .Token }}` for the code to reach the user.
class AuthRepositorySupabase extends AuthRepository {
  AuthRepositorySupabase(this._client);

  final sb.SupabaseClient _client;

  User? _user;
  String? _email;
  DateTime? _deletionDate;
  StreamSubscription<sb.AuthState>? _authChanges;

  /// Runs before listeners hear of a new user (or of signing out), so the
  /// household is already known when the router redirects.
  Future<void> Function(User? user)? onUserChanged;

  @override
  User? get user => _user;

  @override
  DateTime? get deletionDate => _deletionDate;

  /// Restores the saved session, if any.
  Future<void> init() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      try {
        await _setUser(await _loadProfile(session.user.id));
      } on Exception catch (e) {
        debugPrint('Could not restore the session: $e');
      }
    }
    _authChanges = _client.auth.onAuthStateChange.listen((state) {
      if (state.event == sb.AuthChangeEvent.signedOut && _user != null) _setUser(null);
    });
  }

  Future<User> _loadProfile(String id) async {
    final row = await _client.from('profiles').select().eq('id', id).single();
    final requested = row['deletion_requested_at'] as String?;
    _deletionDate = requested == null ? null : DateTime.parse(requested).toLocal().add(const Duration(days: 15));
    return userFromRow(row);
  }

  Future<void> _setUser(User? user) async {
    final changed = user?.id != _user?.id;
    _user = user;
    if (changed) await onUserChanged?.call(user);
    notifyListeners();
  }

  @override
  Future<Result<void>> requestCode(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email, shouldCreateUser: true);
      _email = email;
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(_authError(e));
    }
  }

  @override
  Future<Result<User>> verifyCode(String code) async {
    final email = _email;
    if (email == null) return Result.error(ExpiredCodeException());
    try {
      final response = await _client.auth.verifyOTP(type: sb.OtpType.email, email: email, token: code);
      final id = response.user?.id;
      if (id == null) return Result.error(WrongCodeException());
      final user = await _loadProfile(id);
      await _setUser(user);
      return Result.ok(user);
    } on Exception catch (e) {
      return Result.error(_authError(e));
    }
  }

  @override
  Future<Result<User>> updateProfile({String? name, int? color}) async {
    final current = _user;
    if (current == null) return Result.error(Exception('Not signed in'));
    try {
      await _client.from('profiles').update({'name': ?name, 'color': ?color}).eq('id', current.id);
      final user = current.copyWith(name: name, color: color);
      _user = user;
      notifyListeners();
      return Result.ok(user);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
    } on Exception catch (e) {
      // Signed out locally even when the server can't be told.
      debugPrint('Sign-out: $e');
    }
    if (_user != null) await _setUser(null);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      final erasedOn = await _client.rpc<String>('request_account_deletion');
      _deletionDate = DateTime.parse(erasedOn).toLocal();
      notifyListeners();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> cancelDeletion() async {
    try {
      await _client.rpc<void>('cancel_account_deletion');
      _deletionDate = null;
      notifyListeners();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  /// Supabase answers "otp_expired" both for a wrong and an expired code.
  Exception _authError(Exception e) => switch (e) {
    sb.AuthRetryableFetchException() => OfflineException(),
    sb.AuthException(statusCode: '429') => TooManyAttemptsException(),
    sb.AuthException(code: 'otp_expired') => WrongCodeException(),
    _ => e,
  };

  @override
  void dispose() {
    _authChanges?.cancel();
    super.dispose();
  }
}
