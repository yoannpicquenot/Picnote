import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/live.dart';
import '../../../domain/models/note.dart';
import '../../model/rows.dart';
import 'live_repository.dart';

/// Keystrokes go over the household's private broadcast channel
/// `live:<householdId>` (only its members may join, see
/// supabase/migrations/*live_typing.sql), at most one message per
/// [throttle] for each note or list.
class LiveRepositorySupabase extends LiveRepository {
  LiveRepositorySupabase(this._client, {this.throttle = const Duration(milliseconds: 80)});

  final SupabaseClient _client;
  final Duration throttle;

  RealtimeChannel? _channel;
  String? _userId;

  /// The latest message for each note or list, waiting for its turn.
  final Map<String, (String, Map<String, dynamic>)> _pending = {};
  Timer? _flush;

  /// Joins [householdId]'s channel as [userId]; leaves it when either is
  /// null.
  Future<void> watch(String? userId, String? householdId) async {
    final previous = _channel;
    _channel = null;
    _flush?.cancel();
    _flush = null;
    _pending.clear();
    if (previous != null) await _client.removeChannel(previous);
    _userId = userId;
    forgetAll();
    if (userId == null || householdId == null) return;
    final channel = _client.channel('live:$householdId', opts: const RealtimeChannelConfig(private: true));
    channel
      ..onBroadcast(event: 'note', callback: _onNote)
      ..onBroadcast(event: 'draft', callback: _onDraft)
      ..subscribe();
    _channel = channel;
  }

  void _onNote(Map<String, dynamic> message) {
    try {
      final p = _payload(message);
      final userId = p['user'] as String;
      // The same person on another phone: their own edits, saved as usual.
      if (userId == _userId) return;
      receiveNote(
        p['id'] as String,
        LiveNote(
          userId: userId,
          title: p['title'] as String,
          blocks: blocksFromJson(p['blocks'] as List),
          cursor: p['cursor'] as int?,
        ),
      );
    } on Object catch (e) {
      debugPrint('Live note: $e');
    }
  }

  void _onDraft(Map<String, dynamic> message) {
    try {
      final p = _payload(message);
      final userId = p['user'] as String;
      if (userId == _userId) return;
      receiveDraft(p['list'] as String, LiveDraft(userId: userId, text: p['text'] as String));
    } on Object catch (e) {
      debugPrint('Live draft: $e');
    }
  }

  /// Broadcasts arrive as {event, payload, ...} or as the payload itself,
  /// depending on the client version.
  static Map<String, dynamic> _payload(Map<String, dynamic> message) =>
      message['payload'] is Map ? (message['payload'] as Map).cast<String, dynamic>() : message;

  @override
  void typeNote(String id, {required String title, required List<NoteBlock> blocks, int? cursor}) => _send(
    'note:$id',
    'note',
    {'user': _userId, 'id': id, 'title': title, 'blocks': blocksToJson(blocks), 'cursor': cursor},
  );

  @override
  void typeDraft(String listId, String text) =>
      _send('draft:$listId', 'draft', {'user': _userId, 'list': listId, 'text': text});

  void _send(String key, String event, Map<String, dynamic> payload) {
    if (_channel == null || _userId == null) return;
    _pending[key] = (event, payload);
    _flush ??= Timer(throttle, _sendPending);
  }

  void _sendPending() {
    _flush = null;
    final channel = _channel;
    if (channel == null) return;
    for (final (event, payload) in _pending.values) {
      unawaited(
        channel.sendBroadcastMessage(event: event, payload: payload).catchError((Object e) {
          debugPrint('Live: $e');
          return ChannelResponse.error;
        }),
      );
    }
    _pending.clear();
  }

  @override
  void dispose() {
    _flush?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}
