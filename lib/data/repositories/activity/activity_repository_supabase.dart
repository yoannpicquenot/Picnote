import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/activity.dart';
import '../../../utils/result.dart';
import '../../model/rows.dart';
import 'activity_repository.dart';

/// Presence on a realtime channel per household; the change log is written
/// by database triggers (see supabase/migrations) and read here.
class ActivityRepositorySupabase extends ActivityRepository {
  ActivityRepositorySupabase(this._client);

  final SupabaseClient _client;

  RealtimeChannel? _channel;
  Set<String> _online = {};

  @override
  Set<String> get online => _online;

  /// Joins the household's presence channel as [userId]; leaves it when
  /// either is null.
  Future<void> watch(String? userId, String? householdId) async {
    final previous = _channel;
    _channel = null;
    if (previous != null) await _client.removeChannel(previous);
    _online = {};
    notifyListeners();
    if (userId == null || householdId == null) return;
    final channel = _client.channel('presence:$householdId', opts: RealtimeChannelConfig(key: userId));
    channel.onPresenceSync((_) {
      _online = {
        for (final s in channel.presenceState())
          for (final p in s.presences)
            if (p.payload['user_id'] case final String id) id,
      };
      notifyListeners();
    });
    channel.subscribe((status, _) {
      if (status == RealtimeSubscribeStatus.subscribed) channel.track({'user_id': userId});
    });
    _channel = channel;
  }

  @override
  Future<Result<List<Activity>>> latestFor({required bool isNote, required String id, int limit = 3}) async {
    try {
      final rows = await _client
          .from('activity')
          .select()
          .eq(isNote ? 'note_id' : 'list_id', id)
          .order('at', ascending: false)
          .limit(limit);
      return Result.ok([for (final r in rows) activityFromRow(r)]);
    } on Exception catch (e) {
      debugPrint('Activity: $e');
      return Result.error(e);
    }
  }

  @override
  Future<Result<Map<String, Activity>>> latestByMember(List<String> memberIds) async {
    try {
      final rows = await Future.wait([
        for (final id in memberIds)
          _client.from('activity').select().eq('actor_id', id).order('at', ascending: false).limit(1),
      ]);
      return Result.ok({for (final r in rows.expand((r) => r)) r['actor_id'] as String: activityFromRow(r)});
    } on Exception catch (e) {
      debugPrint('Activity: $e');
      return Result.error(e);
    }
  }

  @override
  Future<void> release(String id) async {
    try {
      await _client.rpc<void>('release_activity', params: {'item': id});
    } on Exception catch (e) {
      // Sent a minute later anyway.
      debugPrint('Activity: $e');
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) _client.removeChannel(channel);
    super.dispose();
  }
}
