import 'package:flutter/foundation.dart';

import '../../../domain/models/notification_prefs.dart';
import '../../../utils/result.dart';

abstract class SettingsRepository extends ChangeNotifier {
  NotificationPrefs get notifications;

  Future<Result<void>> updateNotifications(NotificationPrefs prefs);
}

class SettingsRepositoryLocal extends SettingsRepository {
  NotificationPrefs _prefs = const NotificationPrefs();

  @override
  NotificationPrefs get notifications => _prefs;

  @override
  Future<Result<void>> updateNotifications(NotificationPrefs prefs) async {
    _prefs = prefs;
    notifyListeners();
    return const Result.ok(null);
  }
}
