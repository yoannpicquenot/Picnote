import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging: this phone's address for push notifications,
/// and the notifications the user taps.
class PushService {
  PushService._(this._messaging);

  final FirebaseMessaging _messaging;

  /// Null where push is not set up: off Android (iOS needs an APNs key
  /// first), or without android/app/google-services.json.
  static Future<PushService?> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      await Firebase.initializeApp();
      return PushService._(FirebaseMessaging.instance);
    } on Exception catch (e) {
      debugPrint('Push notifications off: $e');
      return null;
    }
  }

  /// Asks for the permission (Android 13+) the first time, then gives the
  /// token, even if it was refused: the user may allow it later in the
  /// system settings.
  Future<String?> token() async {
    await _messaging.requestPermission();
    // FCM tokens, not the newer installation ids: they are what the notify
    // function sends to.
    // ignore: deprecated_member_use
    return _messaging.getToken();
  }

  // ignore: deprecated_member_use
  Stream<String> get tokenRefresh => _messaging.onTokenRefresh;

  /// The old token stops working: notifications sent to it are dropped.
  // ignore: deprecated_member_use
  Future<void> deleteToken() => _messaging.deleteToken();

  /// The data of each notification tapped while the app runs.
  Stream<Map<String, dynamic>> get opened => FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);

  /// The data of the notification whose tap launched the app.
  Future<Map<String, dynamic>?> launchData() async => (await _messaging.getInitialMessage())?.data;
}
