import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls [onChange] (debounced) whenever a row of [tables] changes in a way
/// the signed-in user may see, or when another client on the same [topic]
/// calls [ping].
///
/// Supabase only sends a change when the new row passes row level security,
/// so a row that stops being visible (a list made personal again by the
/// other member) sends nothing: whoever makes that change pings instead.
class TableWatcher {
  TableWatcher(
    this._client, {
    required this.topic,
    required this.tables,
    required this.onChange,
    this.debounce = const Duration(milliseconds: 250),
  });

  static const _pingEvent = 'changed';

  final SupabaseClient _client;
  final String topic;
  final List<String> tables;
  final void Function() onChange;
  final Duration debounce;

  RealtimeChannel? _channel;
  Timer? _timer;

  void start() {
    final channel = _client.channel(topic);
    for (final table in tables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _schedule(),
      );
    }
    channel.onBroadcast(event: _pingEvent, callback: (_) => _schedule());
    // After a reconnection, catch up on whatever was missed meanwhile.
    var connectedOnce = false;
    channel.subscribe((status, _) {
      if (status != RealtimeSubscribeStatus.subscribed) return;
      if (connectedOnce) _schedule();
      connectedOnce = true;
    });
    _channel = channel;
  }

  /// Tells the other clients on [topic] to refetch.
  Future<void> ping() async {
    await _channel?.sendBroadcastMessage(event: _pingEvent, payload: const {});
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, onChange);
  }

  Future<void> stop() async {
    _timer?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) await _client.removeChannel(channel);
  }
}
