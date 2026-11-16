import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/push_service.dart';
import 'push_repository.dart';

/// Keeps this phone's Firebase token in `device_tokens` for whoever is
/// signed in. The notify function reads it to reach the phone.
class PushRepositorySupabase extends PushRepository {
  PushRepositorySupabase(this._client, this._push);

  final SupabaseClient _client;
  final PushService _push;

  String? _userId;
  StreamSubscription<String>? _refresh;

  @override
  Stream<String> get opened => _push.opened.map(routeOf).where((r) => r != null).cast<String>();

  @override
  Future<String?> takeLaunchRoute() async {
    try {
      return routeOf(await _push.launchData());
    } on Exception catch (e) {
      debugPrint('Push launch: $e');
      return null;
    }
  }

  @override
  Future<void> switchUser(String? userId) async {
    if (userId == _userId) return;
    final previous = _userId;
    _userId = userId;
    await _refresh?.cancel();
    _refresh = null;
    try {
      // Signed out already, so the row can't be deleted: the token is
      // dropped instead, and the notify function forgets it on next send.
      if (previous != null) await _push.deleteToken();
      if (userId == null) return;
      final token = await _push.token();
      if (token == null || _userId != userId) return;
      await _register(token);
      _refresh = _push.tokenRefresh.listen(_register);
    } on Exception catch (e) {
      debugPrint('Push registration: $e');
    }
  }

  Future<void> _register(String token) async {
    try {
      await _client.rpc<void>(
        'register_device',
        params: {
          'device_token': token,
          'device_platform': 'android',
          'device_locale': PlatformDispatcher.instance.locale.languageCode == 'fr' ? 'fr' : 'en',
          // The reminders go out at 9:00, 12:00… phone time.
          'device_utc_offset': DateTime.now().timeZoneOffset.inMinutes,
        },
      );
    } on Exception catch (e) {
      debugPrint('Push registration: $e');
    }
  }

  /// Only the screens of a list or a note, whatever the message says.
  @visibleForTesting
  static String? routeOf(Map<String, dynamic>? data) {
    final route = data?['route'];
    if (route is! String) return null;
    return RegExp(r'^/(lists|notes)/[\w-]+$').hasMatch(route) ? route : null;
  }
}
