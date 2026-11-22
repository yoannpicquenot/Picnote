import '../../../domain/models/activity.dart';
import '../../../utils/result.dart';
import 'activity_repository.dart';

/// In-memory changes, newest first, for the demo and tests. Everyone in
/// [online] is shown as here.
class ActivityRepositoryLocal extends ActivityRepository {
  ActivityRepositoryLocal({List<Activity> entries = const [], Set<String> online = const {}})
    : _entries = [...entries],
      _online = {...online};

  final List<Activity> _entries;
  final Set<String> _online;

  @override
  Set<String> get online => _online;

  /// [memberId] opens or closes the app.
  void setOnline(String memberId, bool online) {
    final changed = online ? _online.add(memberId) : _online.remove(memberId);
    if (changed) notifyListeners();
  }

  @override
  Future<Result<List<Activity>>> latestFor({required bool isNote, required String id, int limit = 3}) async =>
      Result.ok(_entries.where((e) => e.isNote == isNote && e.itemId == id).take(limit).toList());

  @override
  Future<Result<Map<String, Activity>>> latestByMember(List<String> memberIds) async => Result.ok({
    for (final id in memberIds)
      for (final e in _entries.where((e) => e.actorId == id).take(1)) id: e,
  });

  /// What [release] was called with, in order.
  final released = <String>[];

  @override
  Future<void> release(String id) async => released.add(id);
}
