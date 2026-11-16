import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/notification_prefs.dart';
import '../../../utils/result.dart';
import '../../model/rows.dart';
import 'settings_repository.dart';

/// Notification preferences, stored on the user's `profiles` row.
class SettingsRepositorySupabase extends SettingsRepository {
  SettingsRepositorySupabase(this._client);

  final SupabaseClient _client;

  String? _userId;
  NotificationPrefs _prefs = const NotificationPrefs();

  @override
  NotificationPrefs get notifications => _prefs;

  Future<void> switchUser(String? userId) async {
    _userId = userId;
    _prefs = const NotificationPrefs();
    if (userId != null) {
      try {
        final row = await _client.from('profiles').select().eq('id', userId).single();
        if (_userId == userId) _prefs = prefsFromRow(row);
      } on Exception catch (e) {
        debugPrint('Could not load settings: $e');
      }
    }
    notifyListeners();
  }

  @override
  Future<Result<void>> updateNotifications(NotificationPrefs prefs) async {
    final userId = _userId;
    if (userId == null) return Result.error(Exception('Not signed in'));
    final previous = _prefs;
    _prefs = prefs;
    notifyListeners();
    try {
      await _client.from('profiles').update(prefsToRow(prefs)).eq('id', userId);
      return const Result.ok(null);
    } on Exception catch (e) {
      _prefs = previous;
      notifyListeners();
      return Result.error(e);
    }
  }
}
