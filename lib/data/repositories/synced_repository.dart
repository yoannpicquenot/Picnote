import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/result.dart';
import '../services/table_watcher.dart';

/// Shared behavior of the Supabase repositories: keep a local copy of what
/// the user can see, apply their own changes to it at once, send them, and
/// refetch whenever the server reports a change.
///
/// A refetch never lands while a change is still on its way (it would undo
/// it on screen); it waits for the change to be sent instead.
mixin SyncedRepository on ChangeNotifier {
  SupabaseClient get client;

  /// Tables whose changes trigger a refetch.
  List<String> get watchedTables;

  /// Reads the server state; the returned callback swaps it into the local
  /// copy.
  Future<void Function()> fetch();

  /// Empties the local copy (signed out, or another user).
  void clear();

  String? _userId;
  TableWatcher? _watcher;
  int _inFlight = 0;
  int _session = 0;
  int _generation = 0;
  Future<Result<void>>? _fetching;
  bool _stale = false;
  bool _loaded = false;

  /// The signed-in user, null when signed out.
  String? get userId => _userId;

  /// Starts over for [userId] (null when signed out). [topic] names the
  /// realtime channel; clients sharing it can [ping] each other.
  Future<void> watch(String? userId, {required String topic}) async {
    final previous = _watcher;
    _watcher = null;
    await previous?.stop();
    _userId = userId;
    _generation++;
    // Changes still on their way belong to the previous user.
    _session++;
    _inFlight = 0;
    _loaded = false;
    clear();
    if (userId == null) {
      notifyListeners();
      return;
    }
    _watcher = TableWatcher(client, topic: topic, tables: watchedTables, onChange: refresh)..start();
    await refresh();
  }

  /// Fetches everything again. Coalesces calls made while a fetch runs.
  Future<Result<void>> refresh() {
    if (_userId == null) return Future.value(const Result.ok(null));
    _stale = true;
    return _fetching ??= _fetchUntilFresh().whenComplete(() => _fetching = null);
  }

  Future<Result<void>> _fetchUntilFresh() async {
    try {
      while (_stale && _inFlight == 0) {
        _stale = false;
        final generation = _generation;
        final apply = await fetch();
        if (generation == _generation && _inFlight == 0) {
          apply();
          _loaded = true;
          notifyListeners();
        } else if (_userId != null) {
          _stale = true;
        }
      }
      return const Result.ok(null);
    } on Exception catch (e) {
      debugPrint('$runtimeType: $e');
      return Result.error(e);
    }
  }

  /// Fetches only the first time: after that, realtime keeps the local copy
  /// up to date.
  Future<Result<void>> ensureLoaded() => _loaded ? Future.value(const Result.ok(null)) : refresh();

  /// Marks a local change that [send] will deliver. Listeners are notified
  /// right away; on failure, a refetch puts the server state back.
  Future<Result<void>> push(Future<void> Function() send, {bool ping = false}) async {
    final write = beginWrite();
    notifyListeners();
    return endWrite(write, send, ping: ping);
  }

  /// Like [push], for changes whose sending is delayed (typing in a note):
  /// call [beginWrite] when the change is made, and [endWrite] with what it
  /// returned to send it.
  @protected
  int beginWrite() {
    _generation++;
    _inFlight++;
    return _session;
  }

  @protected
  Future<Result<void>> endWrite(int write, Future<void> Function() send, {bool ping = false}) async {
    try {
      await send();
      if (ping) unawaited(_watcher?.ping());
      return const Result.ok(null);
    } on Exception catch (e) {
      debugPrint('$runtimeType: $e');
      _stale = true;
      return Result.error(e);
    } finally {
      if (write == _session) {
        _inFlight--;
        if (_inFlight == 0 && _stale) unawaited(refresh());
      }
    }
  }

  @override
  void dispose() {
    _watcher?.stop();
    super.dispose();
  }
}
